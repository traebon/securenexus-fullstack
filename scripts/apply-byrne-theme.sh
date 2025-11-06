#!/bin/bash
# Apply SecureNexus Global Theme to Byrne Accounting ERP

set -e

SITE="erp.byrne-accounts.org"
THEME_CSS="/assets/css/byrne-securenexus-theme.css"

echo "🎨 Applying SecureNexus Global Theme to Byrne Accounting"
echo "   Site: $SITE"
echo ""

# Copy CSS file to assets
echo "[1/5] Copying theme CSS to container..."
if [ -f "/tmp/byrne-securenexus-theme.css" ]; then
    docker cp /tmp/byrne-securenexus-theme.css erpnext-backend:/home/frappe/frappe-bench/sites/assets/css/
    echo "   ✓ Theme CSS copied"
else
    echo "   ✗ Theme file not found at /tmp/byrne-securenexus-theme.css"
    exit 1
fi

# Create JavaScript injection script
echo "[2/5] Creating CSS injection script..."
cat > /tmp/inject_byrne_theme.js << 'EOFJS'
// Inject Byrne SecureNexus theme CSS on all desk pages
(function() {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = '/assets/css/byrne-securenexus-theme.css';
    link.id = 'byrne-securenexus-theme-css';

    // Only inject if not already present
    if (!document.getElementById('byrne-securenexus-theme-css')) {
        document.head.appendChild(link);
        console.log('✅ Byrne SecureNexus theme CSS loaded');
    }
})();
EOFJS

docker cp /tmp/inject_byrne_theme.js erpnext-backend:/home/frappe/frappe-bench/sites/assets/js/
echo "   ✓ Injection script created"

# Update Website Settings
echo "[3/5] Updating Website Settings..."
echo "
import frappe

# Update Website Settings to load theme
doc = frappe.get_doc('Website Settings')
doc.head_html = '''
<link rel=\"stylesheet\" href=\"$THEME_CSS\">
<script src=\"/assets/js/inject_byrne_theme.js\"></script>
'''
doc.save()
frappe.db.commit()

print('✅ Website Settings updated')
print('Theme: SecureNexus Global')
print('CSS: $THEME_CSS')
" | docker exec -i erpnext-backend bench --site $SITE console 2>&1 | grep -E "(✅|Theme:|CSS:)"

# Clear cache
echo "[4/5] Clearing cache..."
docker exec erpnext-backend bench --site $SITE clear-cache > /dev/null 2>&1
echo "   ✓ Cache cleared"

# Restart services
echo "[5/5] Restarting ERPNext services..."
docker compose restart erpnext-backend erpnext-scheduler erpnext-worker > /dev/null 2>&1
echo "   ✓ Services restarted"

echo ""
echo "✅ Byrne SecureNexus theme applied successfully!"
echo ""
echo "Access your ERP at:"
echo "   🌐 https://erp.byrne-accounts.org"
echo "   🛒 https://pos.byrne-accounts.org"
echo ""
echo "Theme colors:"
echo "   • SecureNexus Blue: #3b82f6"
echo "   • SecureNexus Green: #10b981"
echo ""
echo "⚠️  Clear your browser cache (Ctrl+Shift+Delete) to see the new theme"
