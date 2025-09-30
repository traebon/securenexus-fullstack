#!/usr/bin/env python3
"""
ACME DNS-01 Challenge Webhook for CoreDNS with etcd backend
This webhook receives requests from Traefik to set/delete TXT records for Let's Encrypt validation
"""

import os
import json
import etcd3
from flask import Flask, request, jsonify

app = Flask(__name__)

# Configuration
ETCD_HOST = os.environ.get('ETCD_HOST', 'etcd')
ETCD_PORT = int(os.environ.get('ETCD_PORT', 2379))
DNS_TTL = int(os.environ.get('DNS_TTL', 120))

# Connect to etcd
etcd = etcd3.client(host=ETCD_HOST, port=ETCD_PORT)

def set_txt_record(domain, challenge):
    """Set a TXT record in etcd for ACME challenge"""
    # Remove any trailing dots from domain
    domain = domain.rstrip('.')

    # Extract base domain and subdomain
    parts = domain.split('.')
    if len(parts) >= 2:
        base_domain = '.'.join(parts[-2:])
        subdomain = '_acme-challenge'
        if len(parts) > 2:
            subdomain = f"_acme-challenge.{'.'.join(parts[:-2])}"
    else:
        return False, "Invalid domain format"

    # Create etcd key path for CoreDNS
    # CoreDNS expects records in /coredns/<domain>/<name>/<type>
    key = f"/coredns/{base_domain}/{subdomain}/TXT"

    # Create value for the TXT record
    value = json.dumps({
        "text": challenge,
        "ttl": DNS_TTL
    })

    try:
        # Set the record in etcd
        etcd.put(key, value)
        app.logger.info(f"Set TXT record: {subdomain}.{base_domain} = {challenge}")
        return True, "Record created"
    except Exception as e:
        app.logger.error(f"Failed to set TXT record: {e}")
        return False, str(e)


def delete_txt_record(domain):
    """Delete a TXT record from etcd"""
    # Remove any trailing dots from domain
    domain = domain.rstrip('.')

    # Extract base domain and subdomain
    parts = domain.split('.')
    if len(parts) >= 2:
        base_domain = '.'.join(parts[-2:])
        subdomain = '_acme-challenge'
        if len(parts) > 2:
            subdomain = f"_acme-challenge.{'.'.join(parts[:-2])}"
    else:
        return False, "Invalid domain format"

    # Create etcd key path
    key = f"/coredns/{base_domain}/{subdomain}/TXT"

    try:
        # Delete the record from etcd
        deleted = etcd.delete(key)
        if deleted:
            app.logger.info(f"Deleted TXT record: {subdomain}.{base_domain}")
            return True, "Record deleted"
        else:
            app.logger.warning(f"TXT record not found: {subdomain}.{base_domain}")
            return True, "Record not found (already deleted)"
    except Exception as e:
        app.logger.error(f"Failed to delete TXT record: {e}")
        return False, str(e)


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint"""
    try:
        # Check etcd connection
        etcd.status()
        return jsonify({"status": "healthy", "etcd": "connected"}), 200
    except Exception as e:
        return jsonify({"status": "unhealthy", "error": str(e)}), 503


@app.route('/update-txt-record', methods=['POST'])
def update_txt_record():
    """
    Endpoint for Traefik to set ACME challenge TXT records
    Expected JSON payload:
    {
        "domain": "example.com",
        "challenge": "challenge_value",
        "action": "set" | "delete"
    }
    """
    data = request.get_json()

    if not data:
        return jsonify({"error": "No JSON data provided"}), 400

    domain = data.get('domain')
    action = data.get('action', 'set')

    if not domain:
        return jsonify({"error": "Domain is required"}), 400

    if action == 'set':
        challenge = data.get('challenge')
        if not challenge:
            return jsonify({"error": "Challenge value is required for 'set' action"}), 400

        success, message = set_txt_record(domain, challenge)
        if success:
            return jsonify({"status": "success", "message": message}), 200
        else:
            return jsonify({"status": "error", "message": message}), 500

    elif action == 'delete':
        success, message = delete_txt_record(domain)
        if success:
            return jsonify({"status": "success", "message": message}), 200
        else:
            return jsonify({"status": "error", "message": message}), 500

    else:
        return jsonify({"error": f"Invalid action: {action}"}), 400


@app.route('/set-txt', methods=['POST'])
def set_txt():
    """Legacy endpoint for compatibility"""
    data = request.get_json()
    if data:
        data['action'] = 'set'
    return update_txt_record()


@app.route('/delete-txt', methods=['POST'])
def delete_txt():
    """Legacy endpoint for compatibility"""
    data = request.get_json()
    if data:
        data['action'] = 'delete'
    return update_txt_record()


if __name__ == '__main__':
    # Configure logging
    import logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )

    app.logger.info(f"Starting ACME Webhook for CoreDNS")
    app.logger.info(f"etcd endpoint: {ETCD_HOST}:{ETCD_PORT}")
    app.logger.info(f"DNS TTL: {DNS_TTL} seconds")

    # Run the Flask app
    app.run(host='0.0.0.0', port=5000)