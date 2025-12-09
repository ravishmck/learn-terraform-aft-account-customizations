# AFT Account Customizations - Sandbox
# This configuration is automatically applied to all accounts
# created with the "sandbox" customization profile

terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Apply budget with $200 monthly limit
module "budget_enforcement" {
  source = "./budgets"
}

# Output budget information
output "budget_configuration" {
  description = "Budget enforcement details"
  value = {
    budget_name  = module.budget_enforcement.budget_name
    budget_limit = module.budget_enforcement.budget_limit
    sns_topic    = module.budget_enforcement.sns_topic_arn
  }
}

# Note: IAM user is created directly in iam-user.tf
# This provides console access for students with username/password

