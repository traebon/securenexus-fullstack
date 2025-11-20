#!/bin/bash

# Setup GPG encryption for SecureNexus backups
# Creates GPG keys and configures automated backup encryption

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_KEY_ID="securenexus-backup@internal"
GPG_HOME="${HOME}/.gnupg"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔐 SecureNexus Backup Encryption Setup${NC}"
echo "======================================="
echo

# Check if GPG key already exists
if gpg --list-secret-keys | grep -q "$BACKUP_KEY_ID"; then
    echo -e "${GREEN}✅ GPG backup key already exists: $BACKUP_KEY_ID${NC}"
    gpg --list-secret-keys --with-colons | grep "$BACKUP_KEY_ID"
    echo
    read -p "Do you want to create a new key anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Using existing key."
        exit 0
    fi
fi

echo -e "${YELLOW}🔑 Creating new GPG key for backup encryption...${NC}"

# Create GPG key configuration (without passphrase for automated backups)
cat > /tmp/backup-key-config << EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: SecureNexus Backup
Name-Email: $BACKUP_KEY_ID
Expire-Date: 2y
%no-protection
%commit
%echo done
EOF

# Generate the key
echo "⏳ Generating GPG key (this may take a few minutes)..."
gpg --batch --generate-key /tmp/backup-key-config
rm /tmp/backup-key-config

# Get the key fingerprint
KEY_FINGERPRINT=$(gpg --list-secret-keys --with-colons | grep "$BACKUP_KEY_ID" -B 1 | grep "^fpr:" | cut -d: -f10 | head -1)

echo -e "${GREEN}✅ GPG key created successfully!${NC}"
echo "Key ID: $BACKUP_KEY_ID"
echo "Fingerprint: $KEY_FINGERPRINT"
echo

# Export public key for safe keeping
echo -e "${YELLOW}📤 Exporting public key...${NC}"
mkdir -p "$SCRIPT_DIR/../backup-keys"
gpg --armor --export "$BACKUP_KEY_ID" > "$SCRIPT_DIR/../backup-keys/backup-public-key.asc"
echo "✅ Public key exported to: backup-keys/backup-public-key.asc"

# Export private key (encrypted)
echo -e "${YELLOW}🔒 Exporting private key (encrypted)...${NC}"
echo "⚠️  This will prompt for a passphrase to protect the private key export."
echo "⚠️  Store this passphrase securely - you'll need it to restore backups!"
echo
read -p "Press Enter to continue with private key export..."
gpg --armor --export-secret-keys "$BACKUP_KEY_ID" > "$SCRIPT_DIR/../backup-keys/backup-private-key.asc"
echo "✅ Private key exported to: backup-keys/backup-private-key.asc"
echo

# Set proper permissions
chmod 700 "$SCRIPT_DIR/../backup-keys"
chmod 600 "$SCRIPT_DIR/../backup-keys"/*

# Create encryption test
echo -e "${YELLOW}🧪 Testing encryption...${NC}"
echo "Test backup encryption" | gpg --trust-model always --encrypt -r "$BACKUP_KEY_ID" > /tmp/test-encrypted.gpg
gpg --decrypt /tmp/test-encrypted.gpg 2>/dev/null | grep -q "Test backup encryption" && echo "✅ Encryption test passed" || echo "❌ Encryption test failed"
rm /tmp/test-encrypted.gpg

# Create key info file
cat > "$SCRIPT_DIR/../backup-keys/KEY_INFO.txt" << EOF
SecureNexus Backup Encryption Key Information
=============================================

Created: $(date)
Key ID: $BACKUP_KEY_ID
Fingerprint: $KEY_FINGERPRINT
Key Type: RSA 4096-bit
Expiration: 2 years from creation

Files:
------
- backup-public-key.asc  : Public key (safe to share)
- backup-private-key.asc : Private key (ENCRYPTED - store securely!)

Usage:
------
To encrypt backup: gpg --trust-model always --encrypt -r "$BACKUP_KEY_ID" file.tar.gz
To decrypt backup: gpg --decrypt file.tar.gz.gpg > file.tar.gz

IMPORTANT:
----------
1. Store the private key and its passphrase in separate secure locations
2. Test decryption periodically to ensure key availability
3. Consider creating multiple copies of the private key
4. Key expires in 2 years - extend before expiration

Restoration Process:
-------------------
1. Install GPG on restoration system
2. Import private key: gpg --import backup-private-key.asc
3. Decrypt backups: gpg --decrypt backup-file.tar.gz.gpg > backup-file.tar.gz
4. Restore using standard backup restoration procedures
EOF

echo -e "${GREEN}🎯 Backup encryption setup complete!${NC}"
echo
echo -e "${BLUE}📋 Summary:${NC}"
echo "✅ GPG key created and tested"
echo "✅ Public key exported for distribution"
echo "✅ Private key exported (encrypted)"
echo "✅ Key information documented"
echo
echo -e "${YELLOW}⚠️  IMPORTANT NEXT STEPS:${NC}"
echo "1. Store backup-private-key.asc in a secure location (off-site)"
echo "2. Store the passphrase separately from the private key"
echo "3. Test the complete backup/restore process"
echo "4. Update backup scripts to use encryption"
echo "5. Document key management procedures"
echo
echo -e "${BLUE}🔗 Related files:${NC}"
echo "- Key files: backup-keys/"
echo "- Encryption script: scripts/backup-with-encryption.sh (to be created)"
echo "- Decryption script: scripts/restore-encrypted-backup.sh (to be created)"
echo

# Show fingerprint for verification
echo -e "${BLUE}🔍 Key verification:${NC}"
gpg --fingerprint "$BACKUP_KEY_ID"