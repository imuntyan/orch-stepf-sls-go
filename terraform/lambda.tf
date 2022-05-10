resource "aws_iam_role" "lambda_role" {
  name = "${var.prefix}_lambda_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = "AllowAssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.prefix}_lambda_policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*:*:*"
      }
    ]
  })
}

resource "aws_lambda_function" "worker" {
  filename      = "../bin/worker/handler.zip"
  function_name = "${var.prefix}_worker"
  role          = aws_iam_role.lambda_role.arn
  handler       = "handler"

  source_code_hash = filebase64sha256("../bin/worker/handler.zip")

  runtime = "go1.x"

#  environment {
#    variables = {
#      foo = "bar"
#    }
#  }
}
