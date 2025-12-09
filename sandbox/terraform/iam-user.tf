# Automatic IAM User Creation for Student Accounts
# Creates user with hardcoded default password that MUST be changed on first login

# Get current account details
data "aws_caller_identity" "current" {}

# Hardcoded default password for all student accounts
# Students MUST change this on first login
locals {
  default_password = "Welcome@Student2025"
}

# Create IAM user for console access
resource "aws_iam_user" "student" {
  name = "student"

  tags = {
    Name      = "Student Console User"
    ManagedBy = "AFT"
    Purpose   = "Console Access"
  }
}

# Use Python script to create login profile with specific password
# Python boto3 is more reliable in CodeBuild environment than AWS CLI
resource "null_resource" "create_student_login" {
  depends_on = [
    aws_iam_user.student,
    aws_iam_user_policy_attachment.student_admin
  ]
  
  provisioner "local-exec" {
    command = "python3 ${path.module}/../api_helpers/python/create_student_user.py"
  }
  
  triggers = {
    # Run every time to ensure password is set
    user_arn = aws_iam_user.student.arn
  }
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
output "student_login_info" {
  description = "Student login credentials - share this with students"
  value = <<-EOT
    ═══════════════════════════════════════════════════════════════
    STUDENT LOGIN CREDENTIALS
    ═══════════════════════════════════════════════════════════════
    
    Account ID: ${data.aws_caller_identity.current.account_id}
    
    LOGIN INFORMATION:
    URL: https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console
    Username: student
    Password: ${local.default_password}
    
    ⚠️  IMPORTANT: Password MUST be changed on first login
    
    ═══════════════════════════════════════════════════════════════
    CLI/SDK ACCESS (Optional):
    ═══════════════════════════════════════════════════════════════
    
    AWS_ACCESS_KEY_ID: ${aws_iam_access_key.student_key.id}
    AWS_SECRET_ACCESS_KEY: ${aws_iam_access_key.student_key.secret}
    
    ═══════════════════════════════════════════════════════════════
  EOT
  sensitive = false
}

output "student_credentials_summary" {
  description = "Quick reference"
  value = {
    account_id    = data.aws_caller_identity.current.account_id
    login_url     = "https://${data.aws_caller_identity.current.account_id}.signin.aws.amazon.com/console"
    username      = "student"
    password      = local.default_password
    password_note = "MUST be changed on first login"
  }
  sensitive = false
}
