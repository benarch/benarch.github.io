#!/bin/bash

# SSL Certificate Health Check Script for bdali.com
# This script checks the SSL certificate validity and HTTPS configuration
# Usage: ./check-ssl.sh
# Note: Requires GNU date (Linux) or BSD date (macOS)

set -e

DOMAIN="bdali.com"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "================================================"
echo "SSL Certificate Health Check for $DOMAIN"
echo "================================================"
echo ""

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if domain is reachable
echo "1. Checking HTTPS availability..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN)

if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 301 ] || [ "$HTTP_CODE" -eq 302 ]; then
    print_success "Site is accessible via HTTPS (Status: $HTTP_CODE)"
else
    print_error "Site returned unexpected status code: $HTTP_CODE"
    exit 1
fi

echo ""

# Check SSL certificate
echo "2. Checking SSL certificate validity..."
CERT_INFO=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null)

if [ -z "$CERT_INFO" ]; then
    print_error "Unable to retrieve SSL certificate information"
    exit 1
fi

# Parse certificate dates
NOT_BEFORE=$(echo "$CERT_INFO" | grep "notBefore" | cut -d= -f2)
NOT_AFTER=$(echo "$CERT_INFO" | grep "notAfter" | cut -d= -f2)

echo "   Certificate valid from: $NOT_BEFORE"
echo "   Certificate expires:    $NOT_AFTER"

# Calculate days until expiration (platform-independent)
if date --version >/dev/null 2>&1; then
    # GNU date (Linux)
    EXPIRY_EPOCH=$(date -d "$NOT_AFTER" +%s)
else
    # BSD date (macOS)
    EXPIRY_EPOCH=$(date -j -f "%b %d %H:%M:%S %Y %Z" "$NOT_AFTER" +%s 2>/dev/null || date -j -f "%b %e %H:%M:%S %Y %Z" "$NOT_AFTER" +%s)
fi
CURRENT_EPOCH=$(date +%s)
DAYS_UNTIL_EXPIRY=$(( ($EXPIRY_EPOCH - $CURRENT_EPOCH) / 86400 ))

if [ $DAYS_UNTIL_EXPIRY -lt 0 ]; then
    print_error "Certificate has EXPIRED!"
    exit 1
elif [ $DAYS_UNTIL_EXPIRY -lt 30 ]; then
    print_warning "Certificate expires in $DAYS_UNTIL_EXPIRY days - renewal needed soon"
else
    print_success "Certificate is valid for $DAYS_UNTIL_EXPIRY more days"
fi

echo ""

# Check certificate issuer
echo "3. Checking certificate issuer..."
ISSUER=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -issuer 2>/dev/null)

echo "   Issuer: $ISSUER"

if echo "$ISSUER" | grep -q "Let's Encrypt"; then
    print_success "Certificate issued by Let's Encrypt (GitHub Pages default)"
else
    print_warning "Certificate not issued by Let's Encrypt"
fi

echo ""

# Check HTTP to HTTPS redirect
echo "4. Checking HTTP to HTTPS redirect..."
REDIRECT_URL=$(curl -s -L -o /dev/null -w "%{url_effective}" http://$DOMAIN)

if echo "$REDIRECT_URL" | grep -q "^https://"; then
    print_success "HTTP correctly redirects to HTTPS"
else
    print_warning "HTTP does not redirect to HTTPS - 'Enforce HTTPS' may not be enabled in GitHub Pages settings"
fi

echo ""

# Check DNS configuration
echo "5. Checking DNS configuration..."
A_RECORDS=$(dig +short A $DOMAIN 2>/dev/null || true)
if [ -n "$A_RECORDS" ]; then
    echo "   A Records:"
    echo "$A_RECORDS" | sed 's/^/      /'
    print_success "A records configured"
else
    print_warning "No A records found"
fi

AAAA_RECORDS=$(dig +short AAAA $DOMAIN 2>/dev/null || true)
if [ -n "$AAAA_RECORDS" ]; then
    echo "   AAAA Records:"
    echo "$AAAA_RECORDS" | sed 's/^/      /'
    print_success "AAAA records configured"
else
    echo "   No AAAA records found (optional)"
fi

echo ""
echo "================================================"
echo "Health check completed successfully!"
echo "================================================"
