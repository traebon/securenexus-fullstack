# DNS Records for SecureNexus Mail Server

Add these DNS records to your domain configuration:

## A Records
```
mail.securenexus.net.     A     YOUR_SERVER_IP
```

## MX Record
```
securenexus.net.          MX    10 mail.securenexus.net.
```

## SPF Record (TXT)
```
securenexus.net.          TXT   "v=spf1 mx ~all"
```

## DMARC Record (TXT)
```
_dmarc.securenexus.net.   TXT   "v=DMARC1; p=quarantine; rua=mailto:tristian@securenexus.net"
```

## DKIM Record (TXT)
Generate DKIM key with Stalwart and add:
```
default._domainkey.securenexus.net.  TXT  "v=DKIM1; k=rsa; p=YOUR_DKIM_PUBLIC_KEY"
```

## Reverse DNS (PTR)
Configure with your hosting provider:
```
YOUR_SERVER_IP -> mail.securenexus.net
```

## Optional: CAA Record
```
securenexus.net.          CAA   0 issue "letsencrypt.org"
```

## Mail-specific DNS Settings
- Ensure TTL is set to 300 (5 minutes) initially for testing
- After verification, increase TTL to 3600 (1 hour) or higher
- Test with: dig mx securenexus.net
- Verify SPF: dig txt securenexus.net