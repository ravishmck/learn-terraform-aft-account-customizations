# Automatic IAM User Creation for Student Accounts
# Creates user with fixed default password that MUST be rotated on first login

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
resource "aws_iam_user" "student" {
  name = "student"

  tags = {
    Name      = "Student Console User"
    ManagedBy = "AFT"
    Purpose   = "Console Access"
  }
}

# Set console password with fixed default that must be changed
resource "aws_iam_user_login_profile" "student_login" {
  user    = aws_iam_user.student.name
  
  # IMPORTANT: pgp_key is intentionally not used here for simplicity
  # Password will be visible in Terraform state and outputs
  # This is acceptable for student training accounts
  password_reset_required = true
}

# Attach AdministratorAccess policy
resource "aws_iam_user_policy_attachment" "student_admin" {
  user       = aws_iam_user.student.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create access key for CLI/SDK access
resource "aws_iam_access_key" "student_key" {
  user = aws_iam_user.student.name
}

# Output student login information
output "student_login_credentials" {
  description = "Student login information - share with student"
  value = <<-EOT
    ═══════════════════════════════════════════════════════════════
    STUDENT LOGIN CREDENTIALS
    ═══════════════════════════════════════════════════════════════
    
    Account ID: ${data.aws_caller_identity.current.account_id}
    
    Console Login:
      URL: https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console
      Username: student
      Password: ${aws_iam_user_login_profile.student_login.password}
    
    ⚠️  IMPORTANT: You MUST change your password on first login
    
    CLI/SDK Access:
      AWS_ACCESS_KEY_ID: ${aws_iam_access_key.student_key.id}
      AWS_SECRET_ACCESS_KEY: ${aws_iam_access_key.student_key.secret}
    
    ═══════════════════════════════════════════════════════════════
  EOT
  sensitive = true
}

output "student_password" {
  description = "Terraform-generated password (must be changed on first login)"
  value       = aws_iam_user_login_profile.student_login.password
  sensitive   = true
}

output "student_login_url" {
  description = "Direct login URL for student"
  value       = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
}
