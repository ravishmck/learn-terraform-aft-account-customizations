# Automatic IAM User Creation for Each Account
# Creates IAM user with admin access
# Password must be set manually after creation (Terraform limitation)

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Get current account details
data "aws_caller_identity" "current" {}

# Create IAM user for console access
resource "aws_iam_user" "console_user" {
  name = "student"

  tags = {
    Name      = "Student Console User"
    ManagedBy = "AFT"
    Purpose   = "Console Access"
  }
}

# Attach AdministratorAccess policy to user
resource "aws_iam_user_policy_attachment" "admin_access" {
  user       = aws_iam_user.console_user.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create access key for programmatic access (optional)
resource "aws_iam_access_key" "console_user_key" {
  user = aws_iam_user.console_user.name
}

# Output setup instructions
output "student_setup_required" {
  description = "Password setup instructions"
  value = <<-EOT
    ═══════════════════════════════════════════════════════════════
    ✅ IAM USER CREATED - PASSWORD SETUP REQUIRED
    ═══════════════════════════════════════════════════════════════
    
    Account ID: ${data.aws_caller_identity.current.account_id}
    IAM User: ${aws_iam_user.console_user.name}
    Status: User created, password NOT set
    
    ═══════════════════════════════════════════════════════════════
    SET PASSWORD - Option 1: AWS Console (Easiest)
    ═══════════════════════════════════════════════════════════════
    
    1. Switch role to this account
    2. Go to: IAM → Users → student
    3. Security credentials tab → Console access → Enable
    4. Set password: Welcome@2025
    5. Check: "User must create new password at next sign-in"
    6. Apply
    
    ═══════════════════════════════════════════════════════════════
    SET PASSWORD - Option 2: AWS CLI
    ═══════════════════════════════════════════════════════════════
    
    aws iam create-login-profile \
      --user-name student \
      --password "Welcome@2025" \
      --password-reset-required
    
    ═══════════════════════════════════════════════════════════════
    STUDENT LOGIN (After Password Set):
    ═══════════════════════════════════════════════════════════════
    
    URL: https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console
    Username: student
    Password: Welcome@2025 (change on first login)
    
    ═══════════════════════════════════════════════════════════════
  EOT
}

output "iam_user_access_key" {
  description = "Access key for programmatic access"
  value = {
    account_id        = data.aws_caller_identity.current.account_id
    username          = aws_iam_user.console_user.name
    access_key_id     = aws_iam_access_key.console_user_key.id
    secret_access_key = aws_iam_access_key.console_user_key.secret
  }
  sensitive = true
}

output "quick_login_info" {
  description = "Quick reference for login"
  value = {
    account_id    = data.aws_caller_identity.current.account_id
    username      = aws_iam_user.console_user.name
    login_url     = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
    password_note = "Password must be set manually - see student_setup_required output"
  }
}
