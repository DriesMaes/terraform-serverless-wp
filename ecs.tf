
resource "aws_ecs_task_definition" "wordpress" {
  family                   = "service"
  network_mode             = "awsvpc"
  cpu                      = 1024
  memory                   = 3072
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = data.aws_iam_role.ecs_task_execution_role.arn
  container_definitions = jsonencode(
    [
      {
        "portMappings" : [
          {
            "containerPort" : 8080,
            "protocol" : "tcp"
          }
        ],
        "essential" : true,
        "name" : "wordpress",
        "image" : "public.ecr.aws/bitnami/wordpress:latest",
        "environment" : [
          {
            "name" : "MARIADB_HOST",
            "value" : aws_db_instance.default.address
          },
          {
            "name" : "WORDPRESS_DATABASE_USER",
            "value" : "bitnami"
          },
          {
            "name" : "WORDPRESS_DATABASE_PASSWORD",
            "value" : "bitnami_password" #replace password
          },
          {
            "name" : "WORDPRESS_DATABASE_NAME",
            "value" : "wordpress"
          },
          {
            "name" : "PHP_MEMORY_LIMIT",
            "value" : "512M"
          },
          {
            "name" : "enabled",
            "value" : "false"
          },
          {
            "name" : "ALLOW_EMPTY_PASSWORD",
            "value" : "yes"
          }
        ],
        "logConfiguration" : {
          "logDriver" : "awslogs",
          "options" : {
            "awslogs-group" : "wordpress-container",
            "awslogs-region" : "eu-west-1",
            "awslogs-create-group" : "true",
            "awslogs-stream-prefix" : "wordpress"
          }
        }
      }
    ]
  )
  volume {
    name = "wordpress"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.wordpress.id
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.efs_access_point.id
        iam             = "DISABLED"
      }
    }
  }
}

resource "aws_ecs_cluster" "ecs-fargate-wordpress" {
  name = "Wordpress-on-fargate"
}

resource "aws_ecs_service" "ecs-wordpress-service" {
  cluster                            = aws_ecs_cluster.ecs-fargate-wordpress.id
  name                               = "wof-efs-rw-service"
  desired_count                      = "2"
  task_definition                    = aws_ecs_task_definition.wordpress.arn
  platform_version                   = "1.4.0"
  launch_type                        = "FARGATE"
  deployment_maximum_percent         = "100"
  deployment_minimum_healthy_percent = "0"
  network_configuration {
    subnets          = [aws_subnet.PrivateSubnet0.id, aws_subnet.PrivateSubnet1.id]
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.wordpress-target-group.arn
    container_name   = "wordpress"
    container_port   = 8080
  }
}
