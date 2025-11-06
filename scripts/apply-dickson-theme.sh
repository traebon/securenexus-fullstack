#!/bin/bash
# Apply Dickson Pharmaceutical Theme to Dickson Supplies ERP

set -e

SITE="erp.dickson-supplies.com"
THEME_CSS="/assets/css/dickson-theme.css"
POS_CSS="/assets/css/dickson-pos-theme.css"

echo "🎨 Applying Dickson Pharmaceutical Theme to Dickson Supplies"
echo "   Site: $SITE"
echo ""

# Copy CSS files to assets
echo "[1/5] Copying theme CSS files to container..."
if [ -f "/tmp/dickson-branding/dickson-theme.css" ]; then
    docker cp /tmp/dickson-branding/dickson-theme.css dickson-backend:/home/frappe/frappe-bench/sites/assets/css/
    echo "   ✓ Theme CSS copied"
else
    echo "   ✗ Theme file not found at /tmp/dickson-branding/dickson-theme.css"
    exit 1
fi

if [ -f "/tmp/dickson-branding/dickson-pos-theme.css" ]; then
    docker cp /tmp/dickson-branding/dickson-pos-theme.css dickson-backend:/home/frappe/frappe-bench/sites/assets/css/
    echo "   ✓ POS Theme CSS copied"
fi

# Create JavaScript injection script
echo "[2/5] Creating CSS injection script..."
cat > /tmp/inject_dickson_theme.js << 'EOFJS'
// Inject Dickson Pharmaceutical theme CSS on all desk pages
(function() {
    const link = document.createElement('link');
    link.rel = 'stylesheet';
    link.href = '/assets/css/dickson-theme.css';
    link.id = 'dickson-theme-css';

    // Only inject if not already present
    if (!document.getElementById('dickson-theme-css')) {
        document.head.appendChild(link);
        console.log('✅ Dickson Pharmaceutical theme CSS loaded');
    }
})();
EOFJS

docker cp /tmp/inject_dickson_theme.js dickson-backend:/home/frappe/frappe-bench/sites/assets/js/
echo "   ✓ Injection script created"

# Update Website Settings
echo "[3/5] Updating Website Settings..."
echo "
import frappe

# Update Website Settings to load theme
doc = frappe.get_doc('Website Settings')
doc.head_html = '''
<link rel=\"stylesheet\" href=\"$THEME_CSS\">
<script src=\"/assets/js/inject_dickson_theme.js\"></script>
'''
doc.save()
frappe.db.commit()

print('✅ Website Settings updated')
print('Theme: Dickson Pharmaceutical')
print('CSS: $THEME_CSS')
" | docker exec -i dickson-backend bench --site $SITE console 2>&1 | grep -E "(✅|Theme:|CSS:)"

# Clear cache
echo "[4/5] Clearing cache..."
docker exec dickson-backend bench --site $SITE clear-cache > /dev/null 2>&1
echo "   ✓ Cache cleared"

# Restart services
echo "[5/5] Restarting Dickson ERPNext services..."
docker compose restart dickson-backend dickson-scheduler dickson-worker > /dev/null 2>&1
echo "   ✓ Services restarted"

echo ""
echo "✅ Dickson Pharmaceutical theme applied successfully!"
echo ""
echo "Access Dickson ERP at:"
echo "   🌐 https://erp.dickson-supplies.com"
echo "   🛒 https://pos.dickson-supplies.com"
echo ""
echo "Theme colors:"
echo "   • Medical Blue: #0066cc"
echo "   • Healthcare Teal: #00A99D"
echo "   • Pharmacy Green: #2D9F84"
echo "   • Prescription Red: #DC3545"
echo ""
echo "⚠️  Clear your browser cache (Ctrl+Shift+Delete) to see the new theme"
