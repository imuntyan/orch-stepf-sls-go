data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


resource "aws_iam_role" "stepf_role" {
  name = "poc-stepf-statemachine-role"

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
  name = "stepf_policy"
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
        Resource = "arn:aws:lambda:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:function:poc-stepf-igor-hello"
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

data "aws_lambda_function" "stepf_lambda" {
  function_name = "poc-stepf-igor-hello"
}

data "aws_cloudwatch_log_group" "stepf_lambda_log" {
  name = "/aws/lambda/poc-stepf-igor-hello"
}

data "local_file" "stepf_helloworld_template" {
  filename = "hello-world.json.tmpl"
}

data "template_file" "stef_helloworld_input" {
  template = data.local_file.stepf_helloworld_template.content
  vars     = {
    hello_fn_arn = data.aws_lambda_function.stepf_lambda.arn
  }
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "my-state-machine"
  role_arn = aws_iam_role.stepf_role.arn

  definition = data.template_file.stef_helloworld_input.rendered

#  logging_configuration {
#    log_destination        = "${data.aws_cloudwatch_log_group.stepf_lambda_log.arn}:*"
#    include_execution_data = true
#    level                  = "ERROR"
#  }
}
