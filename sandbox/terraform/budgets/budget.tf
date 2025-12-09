# AWS Budget - $200 Monthly Limit with Alerts
# This will be automatically applied to all accounts created with AFT

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Get current account ID
data "aws_caller_identity" "current" {}

# Get account email from SSM parameter (set by AFT)
data "aws_ssm_parameter" "account_email" {
  name = "/aft/account-request/custom-fields/account_email"
}

# Create SNS topic for budget alerts
resource "aws_sns_topic" "budget_alerts" {
  name = "budget-alerts-200-limit"

  tags = {
    Name        = "Budget Alerts - $200 Limit"
    ManagedBy   = "AFT"
    Purpose     = "Cost Control"
  }
}

# Subscribe email to SNS topic
resource "aws_sns_topic_subscription" "budget_email" {
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = "ravish.snkhyn@gmail.com"  # Change this to your email
}

# Monthly budget with $200 limit
resource "aws_budgets_budget" "monthly_cost_budget" {
  name              = "monthly-budget-200-usd"
  budget_type       = "COST"
  limit_amount      = "200"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2025-12-01_00:00"

  # Alert at 80% ($160)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["ravish.snkhyn@gmail.com"]
  }

  # Alert at 90% ($180)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["ravish.snkhyn@gmail.com"]
  }

  # Alert at 100% ($200)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["ravish.snkhyn@gmail.com"]
  }

  # Forecasted alert at 100%
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["ravish.snkhyn@gmail.com"]
  }

  # Cost filters (optional - can filter by service, tag, etc.)
  cost_filter {
    name = "LinkedAccount"
    values = [
      data.aws_caller_identity.current.account_id
    ]
  }

  tags = {
    Name      = "Monthly Budget $200"
    ManagedBy = "AFT"
    Limit     = "200-USD"
  }
}

# Output budget details
output "budget_name" {
  description = "Name of the budget"
  value       = aws_budgets_budget.monthly_cost_budget.name
}

output "budget_limit" {
  description = "Budget limit in USD"
  value       = "${aws_budgets_budget.monthly_cost_budget.limit_amount} ${aws_budgets_budget.monthly_cost_budget.limit_unit}"
}

output "sns_topic_arn" {
  description = "ARN of SNS topic for budget alerts"
  value       = aws_sns_topic.budget_alerts.arn
}

