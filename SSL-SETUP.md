# SSL/HTTPS Setup for GitHub Pages with Custom Domain

This document explains how to enable and maintain HTTPS for the GitHub Pages site with the custom domain `bdali.com`.

## Overview

**Important:** GitHub Pages automatically provisions and renews SSL certificates for custom domains using Let's Encrypt. You **do not** need to manually obtain or upload SSL certificates. This is all handled automatically by GitHub once properly configured.

## Quick Start

If HTTPS is not working for your site, follow these steps:

1. Go to your repository Settings → Pages
2. Verify that "Custom domain" shows `bdali.com`
3. Check the "Enforce HTTPS" checkbox
4. Wait up to 24 hours for certificate provisioning

That's it! GitHub handles the rest automatically.

## Detailed Setup Instructions

### Step 1: Verify DNS Configuration

Before GitHub can provision an SSL certificate, your DNS must be correctly configured to point to GitHub Pages.

**Required DNS Records:**

For an apex domain (bdali.com), configure **A records** pointing to GitHub's IP addresses:

```
185.199.108.153
185.199.109.153
185.199.110.153
185.199.111.153
```

**Optional but recommended:** Configure **AAAA records** for IPv6 support:

```
2606:50c0:8000::153
2606:50c0:8001::153
2606:50c0:8002::153
2606:50c0:8003::153
```

To verify your DNS configuration:
```bash
dig +short A bdali.com
dig +short AAAA bdali.com
```

### Step 2: Configure Custom Domain in GitHub Pages

1. Navigate to your repository on GitHub
2. Click on **Settings** tab
3. Scroll down to the **Pages** section in the left sidebar
4. Under "Custom domain", enter: `bdali.com`
5. Click **Save**

This will automatically create/update the `CNAME` file in your repository.

### Step 3: Enable HTTPS

After configuring the custom domain:

1. In the same GitHub Pages settings section
2. Look for the **"Enforce HTTPS"** checkbox
3. If it's disabled (grayed out), wait a few minutes for DNS propagation
4. Once enabled, check the **"Enforce HTTPS"** checkbox
5. Click **Save**

**Note:** It may take up to 24 hours for GitHub to provision the SSL certificate. During this time, the "Enforce HTTPS" option might be unavailable.

### Step 4: Verify HTTPS is Working

After enabling HTTPS, verify it's working correctly:

1. Visit `https://bdali.com` in your browser
2. Check for the padlock icon in the address bar
3. Verify that `http://bdali.com` redirects to `https://bdali.com`

You can also use the health check script:
```bash
cd scripts
./check-ssl.sh
```

## Certificate Management

### Automatic Renewal

GitHub Pages **automatically renews** Let's Encrypt certificates before they expire. You don't need to take any manual action for renewals.

Let's Encrypt certificates are valid for 90 days and are automatically renewed by GitHub approximately 30 days before expiration.

### Monitoring Certificate Health

This repository includes automated monitoring:

1. **GitHub Actions Workflow** (`.github/workflows/check-https.yml`)
   - Runs weekly every Monday at 9 AM UTC
   - Runs on every push to master/main branch
   - Can be triggered manually from the Actions tab
   - Checks:
     - HTTPS availability
     - Certificate validity and expiration
     - Certificate issuer (should be Let's Encrypt)
     - HTTP to HTTPS redirect
     - DNS configuration

2. **Health Check Script** (`scripts/check-ssl.sh`)
   - Run locally to check SSL status
   - Provides colored output for easy reading
   - Usage: `cd scripts && ./check-ssl.sh`

## Troubleshooting

### Issue: "Enforce HTTPS" checkbox is disabled

**Possible causes:**
- DNS records not properly configured
- DNS propagation still in progress (can take up to 24-48 hours)
- Custom domain not correctly set

**Solutions:**
1. Verify DNS configuration (see Step 1)
2. Wait 24-48 hours for DNS propagation
3. Remove and re-add the custom domain in Settings → Pages
4. Check that the CNAME file in your repository contains only `bdali.com`

### Issue: Certificate not provisioning

**Possible causes:**
- DNS not pointing to GitHub Pages
- CAA records blocking Let's Encrypt
- Domain validation failing

**Solutions:**
1. Verify A/AAAA records are correct
2. Check if CAA DNS records exist: `dig +short CAA bdali.com`
   - If CAA records exist, ensure they allow Let's Encrypt: `0 issue "letsencrypt.org"`
3. Try removing and re-adding the custom domain
4. Contact GitHub Support if issue persists after 48 hours

### Issue: Certificate expired

GitHub should automatically renew certificates, but if you see an expired certificate:

1. Go to Settings → Pages
2. Remove the custom domain and save
3. Wait a few minutes
4. Re-add the custom domain and save
5. Wait for certificate re-provisioning (up to 24 hours)

### Issue: Mixed content warnings

If your site loads but shows security warnings:

**Cause:** Your HTML is loading some resources (images, scripts, CSS) over HTTP instead of HTTPS.

**Solution:**
- Update all resource URLs to use HTTPS or protocol-relative URLs (`//example.com/image.png`)
- Use relative URLs for internal resources (`/images/logo.png`)

### Issue: DNS not propagating

Check DNS propagation status:
- Online tool: https://www.whatsmydns.net/
- Command line: `dig +trace bdali.com`

DNS changes can take up to 48 hours to propagate globally, though typically it's much faster (minutes to hours).

## Verification Commands

### Check SSL Certificate Details
```bash
echo | openssl s_client -servername bdali.com -connect bdali.com:443 2>/dev/null | openssl x509 -noout -text
```

### Check Certificate Expiration
```bash
echo | openssl s_client -servername bdali.com -connect bdali.com:443 2>/dev/null | openssl x509 -noout -dates
```

### Check Certificate Issuer
```bash
echo | openssl s_client -servername bdali.com -connect bdali.com:443 2>/dev/null | openssl x509 -noout -issuer
```

### Test HTTPS Availability
```bash
curl -I https://bdali.com
```

### Test HTTP to HTTPS Redirect
```bash
curl -I http://bdali.com
```

## Security Best Practices

1. **Always enforce HTTPS** - Never disable the "Enforce HTTPS" setting once enabled
2. **Monitor certificate expiration** - Use the automated workflow to get alerts
3. **Use HTTPS for all resources** - Ensure images, scripts, and stylesheets use HTTPS
4. **Set HSTS header** - GitHub Pages automatically sets this for custom domains with HTTPS
5. **Regular audits** - Run the health check script monthly or use the GitHub Actions workflow

## GitHub Pages SSL Certificate Details

- **Certificate Authority:** Let's Encrypt
- **Certificate Type:** Domain Validated (DV)
- **Validity Period:** 90 days
- **Renewal:** Automatic (approximately 30 days before expiration)
- **Cost:** Free
- **SANs (Subject Alternative Names):** Typically includes both apex and www subdomain

## Additional Resources

- [GitHub Pages Documentation](https://docs.github.com/en/pages)
- [Configuring a custom domain for GitHub Pages](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site)
- [Securing your GitHub Pages site with HTTPS](https://docs.github.com/en/pages/getting-started-with-github-pages/securing-your-github-pages-site-with-https)
- [Let's Encrypt Documentation](https://letsencrypt.org/docs/)

## Support

If you encounter issues not covered in this guide:

1. Check GitHub Status: https://www.githubstatus.com/
2. GitHub Pages troubleshooting: https://docs.github.com/en/pages/getting-started-with-github-pages/troubleshooting-404-errors-for-github-pages-sites
3. Contact GitHub Support: https://support.github.com/

## Summary

Remember: **GitHub handles SSL certificate provisioning and renewal automatically.** You just need to:
1. Configure DNS correctly
2. Set your custom domain in Settings → Pages
3. Enable "Enforce HTTPS"
4. Let GitHub do the rest!

The monitoring tools in this repository will alert you if anything goes wrong with the certificate.
