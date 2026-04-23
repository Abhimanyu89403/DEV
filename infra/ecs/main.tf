resource "aws_ecs_cluster" "pgagi_cluster" {
  name = "pgagi-cluster"
  tags = {
    owner = var.owner
    team  = var.team
    grade = var.environment
  }
}
resource "aws_cloudwatch_log_group" "pgagi_fe_logs" {
  name              = "/ecs/fe"
  retention_in_days = 7
}
resource "aws_cloudwatch_log_group" "pgagi_be_logs" {
  name              = "/ecs/be"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "pgagi_fe_task" {
  family                   = "pgagi-frontend_taskdef"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 1024
  memory                   = 2048
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      name   = "fe_container"
      image  = "396608811643.dkr.ecr.ap-south-1.amazonaws.com/prod_cart_repo:f1"
      cpu    = 1024
      memory = 2048
      portMapping = [{
        containerPort = var.fe_port
        host_port = var.fe_port
        protocol = "http"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.pgagi_fe_logs.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "/fe/ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "pgagi_be_task" {
  family                   = "pgagi-backend-taskdef"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  requires_compatibilities = ["FARGATE"]
  cpu                      = 512
  memory                   = 1024
  network_mode             = "awsvpc"
  container_definitions = jsonencode([
    {
      name   = "be_container"
      image  = "396608811643.dkr.ecr.ap-south-1.amazonaws.com/prod_cart_repo:v2"
      cpu    = 512
      memory = 1024
      portMappings = [{
        containerPort = var.be_port
        hostPort = var.be_port
        protocol = "http"
      }]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.pgagi_be_logs.name
          awslogs-region        = "ap-south-1"
          awslogs-stream-prefix = "/be/ecs"
        }
      }
    }
  ])
}

data "aws_subnet" "public1"{
    id = "subnet-05207240c37099e10"
}
data "aws_subnet" "public2"{
    id = "subnet-0f8ad6e7c5490bd81"
}
data "aws_lb_target_group" "fe_target" {
  name = "FE-TG"
}
data "aws_lb_target_group" "be_target" {
  name = "BE-TG"
}
data "aws_security_group" "sg" {
  id = "sg-0966fcd25a003d478"
}

resource "aws_ecs_service" "pgagi_fe_service" {
  name            = "ecs-fe-service"
  cluster         = aws_ecs_cluster.pgagi_cluster.id
  task_definition = aws_ecs_task_definition.pgagi_fe_task.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [ data.aws_subnet.public1.id , data.aws_subnet.public2.id ]
    security_groups = [data.aws_security_group.sg.id]
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = data.aws_lb_target_group.fe_target.arn
    container_port   = var.fe_port
    container_name   = "fe_container"
  }
}

resource "aws_ecs_service" "pgagi_be_service" {
  name            = "ecs-be-service"
  cluster         = aws_ecs_cluster.pgagi_cluster.id
  task_definition = aws_ecs_task_definition.pgagi_be_task.arn
  desired_count   = 3
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = [ data.aws_subnet.public1.id , data.aws_subnet.public2.id ]
  }
  load_balancer {
    target_group_arn = data.aws_lb_target_group.be_target.arn
    container_port   = var.be_port
    container_name   = "be_container"
  }
}

resource "aws_appautoscaling_target" "pgagi_fe_scaling" {
  max_capacity       = 6
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.pgagi_cluster.name}/${aws_ecs_service.pgagi_fe_service.name}"
  service_namespace  = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
}

resource "aws_appautoscaling_policy" "pgagi_fe_scaling_policy" {
  name               = "fe_autoscaling"
  policy_type        = "TargetTrackingScaling"
  service_namespace  = aws_appautoscaling_target.pgagi_fe_scaling.service_namespace
  scalable_dimension = aws_appautoscaling_target.pgagi_fe_scaling.scalable_dimension
  resource_id        = aws_appautoscaling_target.pgagi_fe_scaling.resource_id

  target_tracking_scaling_policy_configuration {
    target_value = 70
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPuUtilization"
    }
    scale_in_cooldown = 60
    scale_out_cooldown = 60
  }
}
resource "aws_appautoscaling_target" "pgagi_be_scaling" {
  max_capacity = 6
  min_capacity = 2
  resource_id = "service/${aws_ecs_cluster.pgagi_cluster.id}/${aws_ecs_service.pgagi_be_service.name}"
  service_namespace = "ecs"
  scalable_dimension = "ecs:service:DesiredCount"
}
resource "aws_appautoscaling_policy" "pgagi_be_scaling_policy" {
  name = "be_autoscaling"
  policy_type = "TargetTrackingScaling"
  service_namespace = aws_appautoscaling_target.pgagi_be_scaling.service_namespace
  scalable_dimension = aws_appautoscaling_target.pgagi_be_scaling.scalable_dimension
  resource_id = aws_appautoscaling_target.pgagi_be_scaling.resource_id
  target_tracking_scaling_policy_configuration {
    target_value = 70
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    scale_in_cooldown = 60
    scale_out_cooldown = 60
  }
}