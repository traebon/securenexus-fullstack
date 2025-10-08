# Authentik Branding Customization Guide

## Current Branding Setup

Your Authentik instance already has branding assets configured:

### 📁 Branding Assets Location
**Directory:** `/home/tristian/securenexus-fullstack/branding/`

**Current Assets:**
```
branding/
├── favicon.ico           (4.3 KB)
├── favicon.png           (2.9 KB)
├── icon.png              (7.5 KB)
├── icon.svg              (2.7 KB)
├── logo.png              (64 KB)
├── logo.svg              (2.3 KB)
├── login-background.png  (152 KB)
├── login-background.svg  (3.3 KB)
├── mobile-background.png (73 KB)
├── mobile-background.svg (1.6 KB)
├── sn.css                (4.1 KB - custom CSS)
└── securenexus-branding-bundle/
```

**Static Server:** `https://brand.securenexus.net`
- Served by nginx container
- Maps to `./branding` directory
- Public access (for loading assets)

---

## How to Customize Authentik Branding

### Method 1: Web UI (Recommended for Quick Changes)

#### Step 1: Access Authentik Admin
1. Open browser to: `https://sso.securenexus.net/if/admin/`
2. Login with admin credentials

#### Step 2: Navigate to Branding Settings
1. Click **"System"** in left sidebar
2. Click **"Brands"** or **"Customisation"** → **"Branding"**
3. Click on your brand (usually "authentik Default")

#### Step 3: Customize Appearance
**Logo:**
- Upload new logo image (PNG, SVG recommended)
- Or use URL: `https://brand.securenexus.net/logo.png`

**Favicon:**
- Upload favicon (ICO or PNG)
- Or use URL: `https://brand.securenexus.net/favicon.ico`

**Background (Login Page):**
- Upload background image
- Or use URL: `https://brand.securenexus.net/login-background.png`

**Mobile Background:**
- Upload mobile-optimized image
- Or use URL: `https://brand.securenexus.net/mobile-background.png`

**Branding Title:**
- Set to "SecureNexus" or your preferred name

**Custom CSS:**
- Add custom styling
- Or reference: `https://brand.securenexus.net/sn.css`

---

### Method 2: Update Files (For Complete Redesign)

#### Step 1: Replace Branding Assets
```bash
cd /home/tristian/securenexus-fullstack/branding/

# Replace logo
cp /path/to/new-logo.png logo.png
cp /path/to/new-logo.svg logo.svg

# Replace favicon
cp /path/to/new-favicon.ico favicon.ico
cp /path/to/new-favicon.png favicon.png

# Replace backgrounds
cp /path/to/new-login-bg.png login-background.png
cp /path/to/new-mobile-bg.png mobile-background.png
```

#### Step 2: Update Authentik to Use New Assets
1. Open Authentik Admin UI: `https://sso.securenexus.net/if/admin/`
2. Go to **System** → **Brands**
3. Edit brand settings
4. Update URLs to:
   - Logo: `https://brand.securenexus.net/logo.png`
   - Favicon: `https://brand.securenexus.net/favicon.ico`
   - Background: `https://brand.securenexus.net/login-background.png`
   - Mobile BG: `https://brand.securenexus.net/mobile-background.png`

#### Step 3: Clear Browser Cache
- Hard refresh: `Ctrl + Shift + R` (or `Cmd + Shift + R` on Mac)
- Or clear browser cache completely

---

### Method 3: Custom CSS Styling

#### Current Custom CSS
Location: `branding/sn.css`

To modify:
```bash
# Edit the CSS file
nano branding/sn.css

# Test changes
curl https://brand.securenexus.net/sn.css
```

#### Apply Custom CSS in Authentik
1. Open Authentik Admin: `https://sso.securenexus.net/if/admin/`
2. Go to **System** → **Brands** → Edit brand
3. In **"Branding Settings"** section:
   - Add custom CSS directly
   - Or add import: `@import url("https://brand.securenexus.net/sn.css");`

---

## Asset Requirements & Best Practices

### Logo
- **Format:** PNG or SVG (SVG preferred for scalability)
- **Size:** Recommended 400x100px to 800x200px
- **Background:** Transparent
- **Use:** Navigation bar, header

### Favicon
- **Format:** ICO (16x16, 32x32) or PNG
- **Size:** 32x32px recommended
- **Use:** Browser tab icon

### Login Background
- **Format:** PNG, JPG, or SVG
- **Size:** 1920x1080px or higher
- **Aspect Ratio:** 16:9 recommended
- **File Size:** < 500 KB for performance

### Mobile Background
- **Format:** PNG, JPG, or SVG
- **Size:** 1080x1920px (portrait)
- **Aspect Ratio:** 9:16 (mobile)
- **File Size:** < 300 KB

### Color Scheme
- Choose colors that match your brand
- Ensure sufficient contrast for accessibility
- Test dark/light mode appearance

---

## Quick Redesign Workflow

### Option A: Create New Assets

1. **Design new assets** (logo, backgrounds, favicons)
2. **Save with same filenames** in `branding/` directory
3. **Restart brand-static container** (if needed):
   ```bash
   docker compose restart brand-static
   ```
4. **Update Authentik settings** via admin UI
5. **Test** by logging out and viewing login page

### Option B: Use Different Files

1. **Add new files** to `branding/` directory:
   ```bash
   cp new-logo.png branding/new-logo.png
   ```
2. **Update Authentik brand settings** to use new URLs:
   - `https://brand.securenexus.net/new-logo.png`
3. **Keep old files** for rollback if needed

---

## Example: Complete Rebrand

```bash
# 1. Backup current branding
cd /home/tristian/securenexus-fullstack
tar -czf branding-backup-$(date +%Y%m%d).tar.gz branding/

# 2. Replace assets (example)
cd branding/
# Upload your new files via SCP, or download
wget https://example.com/assets/my-new-logo.png -O logo.png
wget https://example.com/assets/my-new-bg.jpg -O login-background.jpg

# 3. Restart brand server
cd ..
docker compose restart brand-static

# 4. Update Authentik (via web UI)
# - Navigate to: https://sso.securenexus.net/if/admin/
# - System → Brands → Edit
# - Update Logo URL: https://brand.securenexus.net/logo.png
# - Update Background: https://brand.securenexus.net/login-background.jpg
# - Save changes

# 5. Test
# - Logout of Authentik
# - View login page
# - Check all assets load correctly
```

---

## Color Customization

### Via Custom CSS
Edit `branding/sn.css`:

```css
/* Primary brand color */
:root {
    --ak-accent: #your-color-here;
    --ak-accent-light: #lighter-shade;
    --ak-accent-dark: #darker-shade;
}

/* Background colors */
.pf-c-login__main {
    background: linear-gradient(135deg, #color1 0%, #color2 100%);
}

/* Button colors */
.pf-c-button.pf-m-primary {
    background-color: #your-primary-color;
    border-color: #your-primary-color;
}

/* Logo sizing */
.pf-c-brand {
    max-width: 300px;
    height: auto;
}
```

### Via Authentik Theme Settings
1. Admin UI → **System** → **Brands**
2. Set **"Theme"** to custom values
3. Define primary/secondary colors

---

## Troubleshooting

### Assets Not Loading
**Problem:** New images don't appear
**Solution:**
```bash
# Check file exists
ls -la branding/logo.png

# Check permissions
chmod 644 branding/*.png

# Restart container
docker compose restart brand-static

# Verify URL
curl -I https://brand.securenexus.net/logo.png

# Clear browser cache
```

### Wrong Aspect Ratio
**Problem:** Background image looks stretched
**Solution:**
- Use recommended dimensions
- Ensure 16:9 aspect ratio for desktop
- Use CSS: `background-size: cover;`

### Custom CSS Not Applied
**Problem:** CSS changes don't show
**Solution:**
1. Verify file served: `curl https://brand.securenexus.net/sn.css`
2. Check Authentik brand settings reference correct URL
3. Hard refresh browser: `Ctrl + Shift + R`
4. Check browser console for errors

---

## Current Branding Files

You already have these files ready to use or replace:

| File | Purpose | Current Size | URL |
|------|---------|--------------|-----|
| logo.png | Main logo | 64 KB | https://brand.securenexus.net/logo.png |
| logo.svg | Vector logo | 2.3 KB | https://brand.securenexus.net/logo.svg |
| favicon.ico | Browser icon | 4.3 KB | https://brand.securenexus.net/favicon.ico |
| login-background.png | Desktop login | 152 KB | https://brand.securenexus.net/login-background.png |
| mobile-background.png | Mobile login | 73 KB | https://brand.securenexus.net/mobile-background.png |
| sn.css | Custom styling | 4.1 KB | https://brand.securenexus.net/sn.css |

---

## Quick Start: Update Branding Now

### Step 1: Access Admin Interface
```
URL: https://sso.securenexus.net/if/admin/
```

### Step 2: Navigate to Branding
1. Click **"System"** (left sidebar)
2. Click **"Brands"**
3. Click on your brand name (likely "authentik Default")

### Step 3: Update Settings
**Branding Title:** SecureNexus (or your choice)

**Logo:**
- URL: `https://brand.securenexus.net/logo.png`
- Or upload new file

**Favicon:**
- URL: `https://brand.securenexus.net/favicon.ico`
- Or upload new file

**Branding Settings → Flow background:**
- URL: `https://brand.securenexus.net/login-background.png`
- Or upload new file

### Step 4: Save & Test
1. Click **"Update"**
2. Logout
3. View login page to see changes

---

## Next Steps

1. **View current branding:** Visit `https://sso.securenexus.net` (logout to see login page)
2. **Decide on changes:** What do you want to change?
   - Logo only?
   - Complete redesign?
   - Color scheme?
3. **Prepare assets:** Create/source new images
4. **Apply changes:** Use web UI or replace files
5. **Test thoroughly:** Check all pages, dark/light mode

---

## Resources

- **Authentik Docs:** https://docs.goauthentik.io/docs/customize/
- **Current Assets:** `/home/tristian/securenexus-fullstack/branding/`
- **Static Server:** `https://brand.securenexus.net`
- **Admin UI:** `https://sso.securenexus.net/if/admin/`

---

**Need Help?**
- View current assets: `ls -la /home/tristian/securenexus-fullstack/branding/`
- Check what's served: `curl https://brand.securenexus.net/`
- Test asset: `curl -I https://brand.securenexus.net/logo.png`
