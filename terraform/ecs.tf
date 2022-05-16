resource "aws_ecr_repository" "worker" {
  name = "${var.prefix}_worker"
}

resource "aws_cloudwatch_log_group" "worker" {
  name              = "/ecs/${var.prefix}_worker"
  retention_in_days = 60

  tags = {
    Name = "${var.prefix}_worker"
  }
}

resource "aws_iam_role" "ecs_task" {
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

#data "aws_iam_policy_document" "ecs_task" {
#}
#
#resource "aws_iam_role_policy" "ecs_task" {
#  name   = aws_iam_role.ecs_task.name
#  role   = aws_iam_role.ecs_task.id
#  policy = data.aws_iam_policy_document.ecs_task.json
#}

resource "aws_iam_role" "ecs_execution" {
  name = "${var.prefix}_ecs_execution_role"

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

resource "aws_iam_role_policy" "ecs_execution" {
  name = aws_iam_role.ecs_execution.name
  role = aws_iam_role.ecs_execution.id

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action   = "ecr:GetAuthorizationToken"
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
        ]
        Effect   = "Allow"
        Resource = aws_ecr_repository.worker.arn
      },
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.worker.arn}:*"
      },
    ]
  })
}


resource "aws_ecs_cluster" "app" {
  name = "${var.prefix}_worker"
}

resource "aws_ecs_service" "app" {
  name                  = "${var.prefix}_worker"
  cluster               = aws_ecs_cluster.app.id
  launch_type           = "FARGATE"
  platform_version      = "1.4.0"
  task_definition       = aws_ecs_task_definition.app.arn
  desired_count         = 0
  wait_for_steady_state = false
  network_configuration {
    subnets         = [var.AWS_SUBNET]
  }
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.prefix}_worker"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  #  container_definitions    = local.app_definition_template
  container_definitions    = jsonencode([
    {
      name      = "${var.prefix}_worker"
      image     = "${aws_ecr_repository.worker.repository_url}:latest"
      environment = [
        {
          name = "COMMON_ENV_VAR"
          value = "COMMON_ENV_VAR_VALUE"
        }
      ]
      essential = true
      networkMode = "awsvpc"
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group = aws_cloudwatch_log_group.worker.name
          awslogs-region = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    },
  ])
  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn

  volume {
    name = "scratch"
  }
}

