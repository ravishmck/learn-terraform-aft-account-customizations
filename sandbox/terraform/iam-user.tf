# Automatic IAM User Creation for Each Account
# This creates a console user with admin access for easy student login

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

# Get account name from SSM (set by AFT)
data "aws_ssm_parameter" "account_name" {
  name = "/aft/account/account-name"
}

# Create IAM user for console access
resource "aws_iam_user" "console_user" {
  name = "student"

  tags = {
    Name        = "Student Console User"
    ManagedBy   = "AFT"
    Purpose     = "Console Access"
    AccountName = data.aws_ssm_parameter.account_name.value
  }
}

# Create console password for the user
resource "aws_iam_user_login_profile" "console_user_login" {
  user                    = aws_iam_user.console_user.name
  password_reset_required = true # Force password change on first login

  # Default password - students will be forced to change this on first login
  # You can change this to any password you want to use as default
  lifecycle {
    ignore_changes = [
      password_reset_required,
    ]
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

# Store password in SSM Parameter Store (encrypted)
resource "aws_ssm_parameter" "user_password" {
  name        = "/aft/iam-user/initial-password"
  description = "Initial password for student IAM user"
  type        = "SecureString"
  value       = "Welcome@2025"

  tags = {
    ManagedBy = "AFT"
    Purpose   = "IAM User Password"
  }
}

# Output login details
output "iam_user_details" {
  description = "IAM user login information"
  value = {
    username          = aws_iam_user.console_user.name
    account_id        = data.aws_caller_identity.current.account_id
    console_login_url = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
    initial_password  = "Welcome@2025"
    password_note     = "User must change password on first login"
  }
  sensitive = false
}

output "iam_user_access_key" {
  description = "Access key for programmatic access (optional)"
  value = {
    access_key_id     = aws_iam_access_key.console_user_key.id
    secret_access_key = aws_iam_access_key.console_user_key.secret
  }
  sensitive = true
}

output "student_credentials" {
  description = "Complete student login instructions"
  value = <<-EOT
    ═══════════════════════════════════════════════════════════════
    STUDENT LOGIN CREDENTIALS
    ═══════════════════════════════════════════════════════════════
    
    Account ID: ${data.aws_caller_identity.current.account_id}
    Account Name: ${data.aws_ssm_parameter.account_name.value}
    
    Login URL: https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console
    
    Username: ${aws_iam_user.console_user.name}
    Initial Password: Welcome@2025
    
    ⚠️  IMPORTANT: You will be required to change your password on first login
    
    ═══════════════════════════════════════════════════════════════
    PROGRAMMATIC ACCESS (Optional - for AWS CLI/SDK)
    ═══════════════════════════════════════════════════════════════
    
    AWS Access Key ID: ${aws_iam_access_key.console_user_key.id}
    AWS Secret Access Key: ${aws_iam_access_key.console_user_key.secret}
    
    ═══════════════════════════════════════════════════════════════
  EOT
  sensitive = false
}

