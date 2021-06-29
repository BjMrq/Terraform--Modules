locals {
  serviceName     = "${var.ecsServiceConfig.applicationName}Service${var.environment}"
  taskName        = "${var.ecsServiceConfig.applicationName}Task${var.environment}"
  applicationInfo = "${var.ecsServiceConfig.applicationName}-${var.environment}"
}

data "template_file" "taskDefinition" {
  template = file("${path.module}/task-templates/task_definition.json")


  vars = {
    env                     = var.environment
    taskDefinitionName      = local.taskName
    serviceName             = local.serviceName
    dockerImage             = var.dockerImage
    containerPort           = var.ecsServiceConfig.containerPort
    region                  = var.region
    repositoryAuthSecretArn = var.repositoryAuthSecretArn
  }

}


resource "aws_ecs_task_definition" "taskDefinition" {
  family = local.taskName

  container_definitions = data.template_file.taskDefinition.rendered

  cpu                      = var.cpu
  memory                   = var.memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = var.fargateRoleArn
  task_role_arn            = var.fargateRoleArn

  tags = {
    Application = var.ecsServiceConfig.applicationName
    Environment = var.environment
  }
}

resource "aws_ecs_service" "ecsService" {
  name = local.serviceName

  cluster = var.cluster.arn

  task_definition = aws_ecs_task_definition.taskDefinition.arn
  desired_count   = var.desiredCount
  launch_type     = "FARGATE"

  health_check_grace_period_seconds = 2147483647

  network_configuration {
    security_groups  = [aws_security_group.ecsServiceSecurityGroup.id]
    subnets          = var.subnets
    assign_public_ip = true
  }

  load_balancer {
    container_name   = local.taskName
    container_port   = var.ecsServiceConfig.containerPort
    target_group_arn = var.targetGroupArn
  }

  tags = {
    Application = var.ecsServiceConfig.applicationName
    Environment = var.environment
  }
}

resource "aws_security_group" "ecsServiceSecurityGroup" {
  name        = "${local.applicationInfo}-ecsService"
  description = "Security for ${local.applicationInfo} to communicate in and out"
  vpc_id      = var.VPCId

  ingress {
    from_port   = var.ecsServiceConfig.containerPort
    protocol    = "TCP"
    to_port     = var.ecsServiceConfig.containerPort
    cidr_blocks = var.securityCidrBlocks
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecsServiceSecurityGroup ${local.applicationInfo}"
  }
}

resource "aws_cloudwatch_log_group" "ecsServiceLogGroup" {
  name = "${local.serviceName}-LogGroup"
}


resource "aws_appautoscaling_target" "ecsAutoScalingTarget" {
  max_capacity       = var.capacity.max
  min_capacity       = var.capacity.min
  resource_id        = "service/${var.cluster.name}/${local.serviceName}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.ecsService]
}

resource "aws_appautoscaling_policy" "ecsAutoScalingPolicy" {
  name               = "${local.serviceName}ecsAutoScalingPolicy"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.ecsAutoScalingTarget.resource_id
  scalable_dimension = aws_appautoscaling_target.ecsAutoScalingTarget.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecsAutoScalingTarget.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = var.capacity.cpuPercentage
  }
}
