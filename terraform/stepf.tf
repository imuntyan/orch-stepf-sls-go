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
          "iam:PassRole",
        ]
        Effect   = "Allow"
        Resource = [
          aws_iam_role.ecs_execution.arn,
          aws_iam_role.ecs_task.arn,
        ]
      },
      {
        Action = [
          "lambda:InvokeFunction",
        ]
        Effect   = "Allow"
        Resource = aws_lambda_function.worker.arn
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:RunTask"
        ],
        "Resource": [
          "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/*"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "ecs:StopTask",
          "ecs:DescribeTasks"
        ],
        "Resource": "*"
      },
      {
        "Effect": "Allow",
        "Action": [
          "events:PutTargets",
          "events:PutRule",
          "events:DescribeRule"
        ],
        "Resource": [
          "arn:aws:events:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:rule/StepFunctionsGetEventsForECSTaskRule"
        ]
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

data "local_file" "stepf_pipeline_template" {
  filename = "pipeline.json"
}

data "template_file" "stef_pipeline_input" {
  template = data.local_file.stepf_pipeline_template.content
  vars     = {
    region = data.aws_region.current.name
    account_id = data.aws_caller_identity.current.account_id
    prefix = var.prefix
    subnet = var.AWS_SUBNET
  }
}

resource "aws_sfn_state_machine" "sfn_state_machine" {
  name     = "${var.prefix}_statemachine"
  role_arn = aws_iam_role.stepf_role.arn

  definition = data.template_file.stef_pipeline_input.rendered

#  logging_configuration {
#    log_destination        = "${data.aws_cloudwatch_log_group.stepf_lambda_log.arn}:*"
#    include_execution_data = true
#    level                  = "ERROR"
#  }
}
