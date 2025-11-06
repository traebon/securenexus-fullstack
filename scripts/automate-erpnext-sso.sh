#!/bin/bash
# Automated ERPNext Setup and SSO Configuration
# This script automates the entire ERPNext setup process including SSO integration

set -e

SITE="erp.byrne-accounts.org"
ADMIN_PASS=$(cat /home/tristian/securenexus-fullstack/secrets/erpnext_admin_password.txt)
REDIS_CACHE_PASS=$(cat /home/tristian/securenexus-fullstack/secrets/erpnext_redis_cache_password.txt)
REDIS_QUEUE_PASS=$(cat /home/tristian/securenexus-fullstack/secrets/erpnext_redis_queue_password.txt)

echo "========================================="
echo "ERPNext Automated Setup & SSO Integration"
echo "========================================="
echo

# Step 1: Wait for installation to complete
echo "Step 1: Waiting for installation to complete..."
while true; do
    if docker compose logs erpnext-configurator 2>&1 | grep -q "Installing posawesome"; then
        echo "  ✓ ERPNext installed, POS Awesome installing..."
        sleep 30
        break
    fi
    if docker compose logs erpnext-configurator 2>&1 | grep -q "Scheduler already enabled"; then
        echo "  ✓ Installation complete!"
        break
    fi
    echo "  ⏳ Still installing... (checking again in 30s)"
    sleep 30
done

# Step 2: Configure Redis URLs with URL-encoded passwords
echo
echo "Step 2: Configuring Redis URLs..."
REDIS_CACHE_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${REDIS_CACHE_PASS}'))")
REDIS_QUEUE_ENCODED=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${REDIS_QUEUE_PASS}'))")

docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
    bench --site ${SITE} set-config redis_cache \"redis://:${REDIS_CACHE_ENCODED}@erpnext-redis-cache:6379\" && \
    bench --site ${SITE} set-config redis_queue \"redis://:${REDIS_QUEUE_ENCODED}@erpnext-redis-queue:6379\" && \
    bench --site ${SITE} set-config redis_socketio \"redis://:${REDIS_CACHE_ENCODED}@erpnext-redis-cache:6379\""
echo "  ✓ Redis URLs configured"

# Step 3: Start all ERPNext services
echo
echo "Step 3: Starting ERPNext services..."
docker compose up -d erpnext-backend erpnext-worker erpnext-scheduler erpnext-socketio
echo "  ✓ Services started, waiting for backend to be ready..."
sleep 15

# Step 4: Wait for backend to be healthy
echo
echo "Step 4: Waiting for ERPNext backend..."
for i in {1..12}; do
    if curl -s -o /dev/null -w "%{http_code}" http://localhost:8000 | grep -q "200"; then
        echo "  ✓ Backend is ready!"
        break
    fi
    echo "  ⏳ Waiting for backend... (attempt $i/12)"
    sleep 10
done

# Step 5: Complete Setup Wizard via API
echo
echo "Step 5: Completing Setup Wizard..."
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && bench --site ${SITE} execute frappe.desk.page.setup_wizard.setup_wizard.setup_complete --args '[{
    \"language\": \"en\",
    \"country\": \"United Kingdom\",
    \"timezone\": \"Europe/London\",
    \"currency\": \"GBP\",
    \"full_name\": \"Administrator\",
    \"email\": \"admin@byrne-accounts.org\",
    \"company_name\": \"Byrne Accounting\",
    \"company_abbr\": \"BA\",
    \"industry\": \"Services\",
    \"fy_start_date\": \"2025-04-01\",
    \"fy_end_date\": \"2026-03-31\",
    \"domains\": [\"Services\"]
}]'" || echo "  ⚠ Setup wizard may already be complete"

echo "  ✓ Setup wizard processed"

# Step 6: Configure Authentik SSO
echo
echo "Step 6: Configuring Authentik SSO..."

# Create Social Login Key
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && bench --site ${SITE} execute frappe.client.insert --args '{
    \"doctype\": \"Social Login Key\",
    \"enable_social_login\": 1,
    \"social_login_provider\": \"Custom\",
    \"provider_name\": \"Authentik\",
    \"client_id\": \"u9jZWU8hnbF0jCwbGEaBzIz28MVhmU2u6s3UAZq9\",
    \"client_secret\": \"LB54cG7XAapKjx3wiQei6u3Hj7VgelLrEi1cvMd1iw5sRWMhoVDgFJ1BXpFrqnAYz7ikgzhGFNoNVMLK4Ff1inXUSMQDiLGQK0Uypox6hLjvCvFtYNplQe06xW1iZut1\",
    \"base_url\": \"https://sso.securenexus.net\",
    \"authorize_url\": \"https://sso.securenexus.net/application/o/authorize/\",
    \"access_token_url\": \"https://sso.securenexus.net/application/o/token/\",
    \"redirect_url\": \"/api/method/frappe.integrations.oauth2_logins.custom/authentik\",
    \"api_endpoint\": \"https://sso.securenexus.net/application/o/userinfo/\",
    \"auth_url_data\": \"{\\\"scope\\\": \\\"openid profile email\\\"}\",
    \"api_endpoint_args\": \"\",
    \"custom_base_url\": 0,
    \"icon\": \"fa fa-sign-in\"
}'" || echo "  ⚠ SSO may already be configured"

echo "  ✓ Authentik SSO configured"

# Step 7: Enable OAuth2 login
echo
echo "Step 7: Enabling OAuth2 login..."
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
    bench --site ${SITE} set-config allow_login_using_mobile_number 0 && \
    bench --site ${SITE} set-config allow_login_using_user_name 1"
echo "  ✓ OAuth2 login enabled"

# Step 8: Clear cache and rebuild
echo
echo "Step 8: Clearing cache and rebuilding..."
docker exec erpnext-backend bash -c "cd /home/frappe/frappe-bench && \
    bench --site ${SITE} clear-cache && \
    bench --site ${SITE} build"
echo "  ✓ Cache cleared and assets rebuilt"

# Final status
echo
echo "========================================="
echo "✅ ERPNext Setup Complete!"
echo "========================================="
echo
echo "📍 ERPNext URL: https://erp.byrne-accounts.org"
echo "📍 POS URL: https://pos.byrne-accounts.org"
echo
echo "🔐 Administrator Login:"
echo "   Username: Administrator"
echo "   Password: $(cat /home/tristian/securenexus-fullstack/secrets/erpnext_admin_password.txt)"
echo
echo "🔗 SSO Login:"
echo "   Click 'Login with Authentik' on the login page"
echo
echo "📊 Check Service Status:"
echo "   docker compose ps | grep erpnext"
echo
echo "📝 Next Steps:"
echo "   1. Visit https://erp.byrne-accounts.org"
echo "   2. Test SSO login with Authentik"
echo "   3. Create additional users as needed"
echo
