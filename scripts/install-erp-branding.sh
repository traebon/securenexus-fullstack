#!/bin/bash
# ERPNext Custom Branding Installation Script
# This script applies Byrne Accounting branding to ERPNext

set -e

SITE="erp.byrne-accounts.org"
BENCH_DIR="/home/frappe/frappe-bench"

echo "========================================="
echo "Installing Byrne Accounting Branding"
echo "========================================="

cd "$BENCH_DIR"

# Check if site exists
if [ ! -d "sites/$SITE" ]; then
    echo "Error: Site $SITE not found"
    exit 1
fi

echo "✓ Site found: $SITE"

# Create custom app directory if it doesn't exist
mkdir -p "sites/$SITE/public"

# Copy logo if exists
if [ -f "/branding/logo.png" ]; then
    cp /branding/logo.png "sites/$SITE/public/byrne-logo.png"
    echo "✓ Logo copied"
else
    echo "⚠ Logo file not found at /branding/logo.png"
fi

# Install custom CSS
echo "Installing custom CSS..."
cat > "sites/$SITE/public/byrne-custom.css" << 'EOF'
/* Byrne Accounting Custom Branding */

/* Color Variables */
:root {
    --primary-blue: #3b82f6;
    --secondary-green: #10b981;
    --text-dark: #1f2937;
    --text-light: #6b7280;
}

/* Login Page Branding */
.for-login {
    background: linear-gradient(135deg, var(--primary-blue) 0%, var(--secondary-green) 100%);
}

.login-content {
    background: white;
    border-radius: 12px;
    box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1);
}

.page-card-head .brand-logo {
    max-width: 200px;
    height: auto;
}

/* Main App Branding */
.navbar {
    background: white !important;
    border-bottom: 3px solid var(--primary-blue);
}

.navbar-brand img {
    max-height: 40px;
}

/* Buttons */
.btn-primary {
    background-color: var(--primary-blue) !important;
    border-color: var(--primary-blue) !important;
}

.btn-primary:hover {
    background-color: #2563eb !important;
    border-color: #2563eb !important;
}

.btn-success {
    background-color: var(--secondary-green) !important;
    border-color: var(--secondary-green) !important;
}

/* Cards and Panels */
.card {
    border-radius: 8px;
    border: 1px solid #e5e7eb;
}

.card-header {
    background: linear-gradient(90deg, var(--primary-blue), var(--secondary-green));
    color: white;
    border-radius: 8px 8px 0 0;
}

/* POS Interface */
.pos-page {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
}

.pos-page .btn-primary {
    background: var(--primary-blue);
}

/* Footer Branding */
.web-footer {
    background: var(--text-dark);
    color: white;
    padding: 2rem 0;
}

.web-footer a {
    color: var(--primary-blue);
}

/* Sidebar */
.desk-sidebar {
    background: #f9fafb;
}

.desk-sidebar .standard-sidebar-label {
    color: var(--text-dark);
}

/* Links */
a {
    color: var(--primary-blue);
}

a:hover {
    color: #2563eb;
}

/* Custom tagline */
.login-tagline {
    text-align: center;
    margin-top: 1rem;
    color: white;
    font-size: 14px;
    font-weight: 500;
}
EOF

echo "✓ Custom CSS installed"

# Add custom JavaScript for additional branding
echo "Installing custom JavaScript..."
cat > "sites/$SITE/public/byrne-custom.js" << 'EOF'
// Byrne Accounting Custom JavaScript

frappe.ready(function() {
    // Add company tagline to login page
    if (window.location.pathname === '/login') {
        setTimeout(function() {
            var loginCard = document.querySelector('.page-card-head');
            if (loginCard && !document.querySelector('.login-tagline')) {
                var tagline = document.createElement('div');
                tagline.className = 'login-tagline';
                tagline.textContent = 'Professional Accounting Services';
                loginCard.appendChild(tagline);
            }
        }, 100);
    }

    // Set default theme preferences
    if (frappe.boot.user && frappe.boot.user.name !== 'Guest') {
        // You can add more customizations here
        console.log('Byrne Accounting branding loaded');
    }
});

// POS-specific branding
if (window.location.pathname.includes('pos')) {
    frappe.ready(function() {
        console.log('POS Awesome - Byrne Accounting Edition');
    });
}
EOF

echo "✓ Custom JavaScript installed"

# Update website settings to include custom CSS/JS
echo "Updating website settings..."
bench --site "$SITE" console << 'PYTHON'
import frappe

# Update Website Settings
doc = frappe.get_single('Website Settings')

# Add custom CSS
if '/files/byrne-custom.css' not in (doc.custom_css or ''):
    doc.custom_css = (doc.custom_css or '') + '\n/files/byrne-custom.css'

# Add custom JS
if '/files/byrne-custom.js' not in (doc.custom_html or ''):
    doc.custom_html = (doc.custom_html or '') + '\n<script src="/files/byrne-custom.js"></script>'

doc.save()
frappe.db.commit()

print('✓ Website settings updated')
PYTHON

# Clear cache
echo "Clearing cache..."
bench --site "$SITE" clear-cache
bench --site "$SITE" clear-website-cache

# Build assets
echo "Building assets..."
bench build --app frappe

echo ""
echo "========================================="
echo "✓ Branding Installation Complete!"
echo "========================================="
echo ""
echo "Changes applied:"
echo "  • Custom CSS with Byrne colors"
echo "  • Custom JavaScript enhancements"
echo "  • Logo integration"
echo "  • Website settings updated"
echo "  • Cache cleared"
echo ""
echo "Please logout and login again to see changes."
echo "Visit: https://erp.byrne-accounts.org"
echo ""
