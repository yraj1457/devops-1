provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.1.0"

  name = "simple-vpc"
  cidr = var.vpc_cidr

  azs = ["${var.aws_region}a", "${var.aws_region}b"]
  public_subnets = var.public_subnets
  private_subnets = var.private_subnets

  enable_nat_gateway = true
  single_nat_gateway = true
}

resource "aws_security_group" "alb_sg" {
  name = "alb-sg"
  description = "allow HTTP traffic"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_sg" {
  name = "ecs-sg"
  description = "traffic from ALB only"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port = 5050
    to_port = 5050
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = "simple-cluster"
}

resource "aws_iam_role" "task_exec_role" {
  name = "ecsTaskExecRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = "sts:AssumeRole",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_exec_policy" {
  role = aws_iam_role.task_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "task_def" {
  family = "simple-task"
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = "256"
  memory = "512"
  execution_role_arn = aws_iam_role.task_exec_role.arn

  container_definitions = jsonencode([
    {
      name = "simple-time",
      image = var.docker_image,
      essential = true,
      portMappings = [{
        containerPort = 5050,
        protocol = "tcp"
      }]
    }
  ])
}

resource "aws_lb" "alb" {
  name = "simple-alb"
  internal = false
  load_balancer_type = "application"
  subnets = module.vpc.public_subnets
  security_groups = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name = "simple-tg"
  port = 5050
  protocol = "HTTP"
  vpc_id = module.vpc.vpc_id
  target_type = "ip"

  health_check {
    path = "/"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
    matcher = "200"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_ecs_service" "svc" {
  name = "simple-service"
  cluster = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.task_def.arn
  launch_type = "FARGATE"
  desired_count = 1

  network_configuration {
    subnets = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name = "simple-time"
    container_port = 5050
  }

  depends_on = [aws_lb_listener.listener]
}
