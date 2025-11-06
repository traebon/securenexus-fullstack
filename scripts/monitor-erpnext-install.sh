#!/bin/bash
# Monitor ERPNext Installation Progress

echo "Monitoring ERPNext installation..."
echo "This may take 5-10 minutes."
echo

while true; do
    # Check if configurator is still running
    if ! docker ps | grep -q erpnext-configurator; then
        echo "✅ Installation complete!"
        break
    fi

    # Show last few log lines
    clear
    echo "ERPNext Installation Progress"
    echo "============================="
    echo
    docker compose logs erpnext-configurator | grep -E "(Installing|Updating DocTypes|SUCCESS)" | tail -5
    echo
    echo "Checking again in 30 seconds..."
    echo "(Press Ctrl+C to stop monitoring)"

    sleep 30
done

echo
echo "Next steps:"
echo "1. Start ERPNext services: docker compose up -d erpnext-backend erpnext-worker erpnext-scheduler erpnext-socketio"
echo "2. Check backend health: docker compose ps | grep erpnext-backend"
echo "3. Visit: https://erp.byrne-accounts.org"
echo "4. Login: Administrator / (password in secrets/erpnext_admin_password.txt)"
