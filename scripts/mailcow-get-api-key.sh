#!/bin/bash
#
# Mailcow API Key Setup Helper
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Mailcow API Key Setup${NC}"
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""

# Check if API key already exists
if [[ -f "secrets/mailcow_api_key.txt" ]]; then
    echo -e "${GREEN}✓ API key already exists!${NC}"
    echo ""
    API_KEY=$(cat secrets/mailcow_api_key.txt)
    echo "API Key: ${API_KEY:0:10}...${API_KEY: -10}"
    echo ""
    read -p "Test this API key? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Testing API access..."
        RESPONSE=$(curl -s "https://mail.securenexus.net/api/v1/get/status/version" \
          -H "X-API-Key: ${API_KEY}" 2>&1)

        if echo "$RESPONSE" | grep -q "version"; then
            echo -e "${GREEN}✓ API key is valid!${NC}"
            echo "Mailcow version: $(echo $RESPONSE | jq -r .version 2>/dev/null || echo 'unknown')"
            exit 0
        else
            echo -e "${RED}✗ API key is invalid${NC}"
            echo "Response: $RESPONSE"
            echo ""
            echo "You need to generate a new API key."
        fi
    fi
fi

echo ""
echo -e "${YELLOW}To generate a Mailcow API key:${NC}"
echo ""
echo "1. Open your browser and go to:"
echo -e "   ${GREEN}https://mail.securenexus.net${NC}"
echo ""
echo "2. Login with admin credentials:"
echo "   Username: ${GREEN}admin${NC}"
echo "   Password: [your Mailcow admin password]"
echo ""
echo -e "${YELLOW}   Don't have the password? Try these:${NC}"
echo "   • Check your initial Mailcow setup notes"
echo "   • Default is often: moohoo (if never changed)"
echo "   • Reset it with: docker exec -it mailcowdockerized-php-fpm-mailcow-1 /bin/bash"
echo "     then: cd /web && php -f /web/inc/init_db.inc.php"
echo ""
echo "3. Once logged in:"
echo "   • Click your username (top right corner)"
echo "   • Select 'Edit'"
echo "   • Scroll to 'API' section"
echo "   • Click 'Read/Write access' "
echo "   • Check 'Activate API'"
echo "   • Copy the API key (looks like: XXXXX-XXXXX-XXXXX-XXXXX-XXXXX)"
echo ""
echo "4. Save the API key:"
echo -e "   ${GREEN}echo 'YOUR-API-KEY' > secrets/mailcow_api_key.txt${NC}"
echo -e "   ${GREEN}chmod 600 secrets/mailcow_api_key.txt${NC}"
echo ""
echo "5. Test it:"
echo -e "   ${GREEN}./scripts/mailcow-get-api-key.sh${NC}"
echo ""
echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
echo ""
read -p "Press Enter to open Mailcow in browser (if available)..."

# Try to open browser (works on systems with xdg-open)
if command -v xdg-open > /dev/null; then
    xdg-open "https://mail.securenexus.net" 2>/dev/null &
    echo "Browser opened!"
elif command -v open > /dev/null; then
    open "https://mail.securenexus.net" 2>/dev/null &
    echo "Browser opened!"
else
    echo "Please open this URL manually: https://mail.securenexus.net"
fi

echo ""
echo "After generating the API key, run this script again to test it."
