variable "prefix" {}
variable "AWS_SUBNET" {}

resource "aws_iam_role" "stepf_role" {
  name = "${var.prefix}_statemachine_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = "AllowAssumeRole"
        Principal = {
          Service = "states.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "stepf_policy" {
  name = "${var.prefix}_statemachine_policy"
  role = aws_iam_role.stepf_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.worker.arn
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogDelivery",
          "logs:GetLogDelivery",
          "logs:UpdateLogDelivery",
          "logs:DeleteLogDelivery",
          "logs:ListLogDeliveries",
          "logs:PutResourcePolicy",
          "logs:DescribeResourcePolicies",
          "logs:DescribeLogGroups"
        ],
        "Resource" : "*"
      }
    ]
  })
}

data "local_file" "stepf_helloworld_template" {
  filename = "hello-world.json.tmpl"
}

data "template_file" "stef_helloworld_input" {
  template = data.local_file.stepf_helloworld_template.content
  vars     = {
    hello_fn_name = aws_lambda_function.worker.function_name
  }
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.prefix}_statemachine"
  role_arn = aws_iam_role.stepf_role.arn

  definition = data.template_file.stef_helloworld_input.rendered

#  logging_configuration {
#    log_destination        = "${data.aws_cloudwatch_log_group.stepf_lambda_log.arn}:*"
#    include_execution_data = true
#    level                  = "ERROR"
#  }
}
