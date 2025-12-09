#!/bin/bash
# Script to set password for student IAM user after account creation
# This runs automatically as part of AFT customizations

set -e

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
DEFAULT_PASSWORD="Welcome@2025"

echo "═══════════════════════════════════════════════════════════════"
echo "Setting password for student IAM user"
echo "Account: $ACCOUNT_ID"
echo "═══════════════════════════════════════════════════════════════"

# Check if user exists
if aws iam get-user --user-name student >/dev/null 2>&1; then
    echo "✅ IAM user 'student' exists"
    
    # Try to create login profile (set password)
    if aws iam create-login-profile \
        --user-name student \
        --password "$DEFAULT_PASSWORD" \
        --password-reset-required 2>&1; then
        
        echo "✅ Password set successfully"
        echo ""
        echo "Student Login Details:"
        echo "  URL: https://$ACCOUNT_ID.signin.aws.amazon.com/console"
        echo "  Username: student"
        echo "  Password: $DEFAULT_PASSWORD"
        echo "  Note: User must change password on first login"
        
    else
        echo "⚠️  Login profile already exists or failed to create"
        echo "   Password may already be set"
    fi
else
    echo "❌ IAM user 'student' not found"
    echo "   Terraform should have created this user"
    exit 1
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "✅ Password setup complete"
echo "═══════════════════════════════════════════════════════════════"

