#!/usr/bin/env python3
"""
Create IAM student user with console access
This script is called by Terraform after the student IAM user is created
"""

import boto3
import sys
import json

# Hardcoded password - students MUST change on first login
DEFAULT_PASSWORD = "Welcome@Student2025"
USERNAME = "student"

def main():
    try:
        # Initialize IAM client
        iam = boto3.client('iam')
        sts = boto3.client('sts')
        
        # Get current account ID
        account_id = sts.get_caller_identity()['Account']
        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        print(f"Creating login profile for student user")
        print(f"Target Account: {account_id}")
        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        # Check if user exists
        try:
            user = iam.get_user(UserName=USERNAME)
            print(f"✅ IAM User '{USERNAME}' exists")
        except iam.exceptions.NoSuchEntityException:
            print(f"❌ IAM User '{USERNAME}' does not exist!")
            print("   The user should be created by Terraform first.")
            sys.exit(1)
        
        # Delete existing login profile if it exists
        try:
            iam.delete_login_profile(UserName=USERNAME)
            print(f"🗑️  Deleted existing login profile for '{USERNAME}'")
        except iam.exceptions.NoSuchEntityException:
            print(f"ℹ️  No existing login profile found for '{USERNAME}'")
        
        # Create new login profile with hardcoded password
        response = iam.create_login_profile(
            UserName=USERNAME,
            Password=DEFAULT_PASSWORD,
            PasswordResetRequired=True
        )
        
        print(f"✅ Login profile created successfully!")
        print(f"")
        print(f"═══════════════════════════════════════════════════════════════")
        print(f"STUDENT LOGIN CREDENTIALS")
        print(f"═══════════════════════════════════════════════════════════════")
        print(f"")
        print(f"Account ID: {account_id}")
        print(f"Login URL: https://{account_id}.signin.aws.amazon.com/console")
        print(f"")
        print(f"Username: {USERNAME}")
        print(f"Password: {DEFAULT_PASSWORD}")
        print(f"")
        print(f"⚠️  IMPORTANT: Password MUST be changed on first login")
        print(f"")
        print(f"═══════════════════════════════════════════════════════════════")
        print(f"━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        # Return success
        sys.exit(0)
        
    except Exception as e:
        print(f"❌ Error creating login profile: {str(e)}")
        print(f"   Exception type: {type(e).__name__}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    main()

