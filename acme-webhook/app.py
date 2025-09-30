from flask import Flask, request, jsonify
import os, requests

app = Flask(__name__)

PDNS_API = os.environ.get("PDNS_API_URL", "http://pdns:8081").rstrip("/")
PDNS_KEY = os.environ.get("PDNS_API_KEY", os.environ.get("PDNS_API_KEY_FILE",""))
TTL = int(os.environ.get("DNS_TTL","120"))

if PDNS_KEY and os.path.exists(PDNS_KEY):
    with open(PDNS_KEY, "r") as f:
        PDNS_KEY = f.read().strip()

def zone_name(domain):
    # find the longest matching zone
    parts = domain.strip(".").split(".")
    for i in range(len(parts)-1):
        z = ".".join(parts[i:]) + "."
        r = requests.get(f"{PDNS_API}/api/v1/servers/localhost/zones/{z}",
                         headers={"X-API-Key": PDNS_KEY})
        if r.status_code == 200:
            return z
    return ".".join(parts[-2:]) + "."

def patch_rrset(zone, name, rtype, values):
    payload = {
        "rrsets": [{
            "name": f"{name}.{zone}" if not name.endswith(".") else name,
            "type": rtype,
            "ttl": TTL,
            "changetype": "REPLACE",
            "records": [{"content": v, "disabled": False} for v in values]
        }]
    }
    r = requests.patch(f"{PDNS_API}/api/v1/servers/localhost/zones/{zone}",
                       json=payload, headers={"X-API-Key": PDNS_KEY})
    return r.status_code, r.text

@app.route("/set-txt", methods=["POST"])
def set_txt():
    data = request.get_json(force=True)
    domain = data.get("domain")
    name = data.get("name") or f"_acme-challenge.{domain}"
    values = data.get("values") or [data.get("value")]
    if not domain or not values or not all(values):
        return jsonify(error="domain and value(s) required"), 400
    zone = zone_name(domain)
    sub = name.replace(f".{zone}", "").rstrip(".")
    code, body = patch_rrset(zone, sub, "TXT", [f"\"{v}\"" for v in values])
    return jsonify(ok=code in (200,204), zone=zone, name=name, code=code, body=body), (200 if code in (200,204) else 500)

@app.route("/del-txt", methods=["POST"])
def del_txt():
    data = request.get_json(force=True)
    domain = data.get("domain")
    name = data.get("name") or f"_acme-challenge.{domain}"
    if not domain:
        return jsonify(error="domain required"), 400
    zone = zone_name(domain)
    sub = name.replace(f".{zone}", "").rstrip(".")
    code, body = patch_rrset(zone, sub, "TXT", [])
    return jsonify(ok=code in (200,204), zone=zone, name=name, code=code, body=body), (200 if code in (200,204) else 500)

@app.route("/healthz")
def health():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
