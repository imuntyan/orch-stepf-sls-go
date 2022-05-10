resource "aws_ecr_repository" "worker" {
  name = "${var.prefix}_worker"
}

resource "aws_iam_role" "ecs_role" {
  name = "${var.prefix}_ecs_role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = "AllowAssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      },
    ]
  })
}
