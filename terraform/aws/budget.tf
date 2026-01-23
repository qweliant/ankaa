resource "aws_budgets_budget" "cost_control" {
  name              = "monthly-budget-limit"
  budget_type       = "COST"
  limit_amount      = "50" # set limit in USD
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80 # 80% makes an alert
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED" # Alert if AWS thinks I WILL hit it
    subscriber_email_addresses = ["dmtorcode@tutanota.com"]
  }
  
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100 # 100% makes an alert
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = ["dmtorcode@tutanota.com"]
  }
}