provider "aws" {
  region  = "eu-west-1"
  profile = "terraform"
}

resource "aws_vpc" "main" {
  cidr_block           = var.network.VPC.CIDR
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name        = var.vpc_name
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
  }
}

resource "aws_subnet" "main_public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.network.Public0.CIDR
  map_public_ip_on_launch = true
  availability_zone       = join("", ["eu-west-1", lookup(var.AZRegions["eu-west-1"], "AZs", [])[0]])
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
    Name        = join("-", [var.vpc_name, "public", lookup(var.AZRegions["eu-west-1"], "AZs", [])[0]])
  }
}

resource "aws_subnet" "PublicSubnet1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.network.Public1.CIDR
  map_public_ip_on_launch = true
  availability_zone       = join("", ["eu-west-1", lookup(var.AZRegions["eu-west-1"], "AZs", [])[1]])
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
    Name        = join("-", [var.vpc_name, "public", lookup(var.AZRegions["eu-west-1"], "AZs", [])[1]])
  }
}

resource "aws_subnet" "PrivateSubnet0" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network.Private0.CIDR
  availability_zone = join("", ["eu-west-1", lookup(var.AZRegions["eu-west-1"], "AZs", [])[0]])
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Private"
    Name        = join("-", [var.vpc_name, "private", lookup(var.AZRegions["eu-west-1"], "AZs", [])[0]])
  }
}

resource "aws_subnet" "PrivateSubnet1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.network.Private1.CIDR
  availability_zone = join("", ["eu-west-1", lookup(var.AZRegions["eu-west-1"], "AZs", [])[1]])
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Private"
    Name        = join("-", [var.vpc_name, "private", lookup(var.AZRegions["eu-west-1"], "AZs", [])[1]])
  }
}

resource "aws_internet_gateway" "vpc-eu-west-1-dev-web-app-IGW" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = join("-", [var.vpc_name, "IGW"])
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc-eu-west-1-dev-web-app-IGW.id
  }
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
    Name        = join("-", [var.vpc_name, "public-route-table"])
  }
}

resource "aws_route_table_association" "public0" {
  subnet_id      = aws_subnet.main_public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public1" {
  subnet_id      = aws_subnet.PublicSubnet1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private0" {
  subnet_id      = aws_subnet.PrivateSubnet0.id
  route_table_id = aws_route_table.private1.id
}

resource "aws_route_table_association" "private1" {
  subnet_id      = aws_subnet.PrivateSubnet1.id
  route_table_id = aws_route_table.private2.id
}

resource "aws_network_acl" "public" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = [aws_subnet.main_public_1.id, aws_subnet.PublicSubnet1.id]
  tags = {
    Application = "Wordpress-on-Fargate"
    Network     = "Public"
    Name        = join("-", [var.vpc_name, "public-nacl"])
  }
}

resource "aws_network_acl_rule" "egress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = true
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

resource "aws_network_acl_rule" "ingress" {
  network_acl_id = aws_network_acl.public.id
  rule_number    = 100
  egress         = false
  protocol       = "all"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 65535
}

resource "aws_eip" "IP1" {
  domain = "vpc"
}

resource "aws_eip" "IP2" {
  domain = "vpc"
}

resource "aws_nat_gateway" "public_nat1" {
  allocation_id = aws_eip.IP1.allocation_id
  subnet_id     = aws_subnet.main_public_1.id
}

resource "aws_nat_gateway" "public_nat2" {
  allocation_id = aws_eip.IP2.allocation_id
  subnet_id     = aws_subnet.PublicSubnet1.id
}

resource "aws_route_table" "private1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public_nat1.id
  }

  tags = {
    Name = join("-", [var.vpc_name, "private-route-table-1"])
  }
}

resource "aws_route_table" "private2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.public_nat2.id
  }

  tags = {
    Name = join("-", [var.vpc_name, "private-route-table-2"])
  }
}

resource "aws_efs_file_system" "wordpress" {
  creation_token = "driesmaes.be"
  tags = {
    Name = "driesmaes.be"
  }
}

resource "aws_efs_mount_target" "efs_mount_target_1" {
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.PrivateSubnet0.id
  security_groups = [aws_security_group.mount_target_sg.id]
}

resource "aws_efs_mount_target" "efs_mount_target_2" {
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = aws_subnet.PrivateSubnet1.id
  security_groups = [aws_security_group.mount_target_sg.id]
}

resource "aws_efs_access_point" "efs_access_point" {
  file_system_id = aws_efs_file_system.wordpress.id
  posix_user {
    uid = 1000
    gid = 1000
  }
  root_directory {
    creation_info {
      owner_gid   = 1000
      owner_uid   = 1000
      permissions = 0777
    }
    path = "/bitnami"
  }
}

resource "aws_db_subnet_group" "wordpress" {
  name        = "wordpress-db-subnet-group"
  description = "The subnet group for the RDS DB"
  subnet_ids  = [aws_subnet.main_public_1.id, aws_subnet.PublicSubnet1.id]
  tags = {
    Name = "DB-subnet-group"
  }
}

resource "aws_db_instance" "default" {
  db_name                 = "wordpress"
  instance_class          = "db.t3.micro"
  engine                  = "mysql"
  username                = "bitnami"
  password                = "bitnami_password" #TODO remove secret from terraform
  publicly_accessible     = false
  db_subnet_group_name    = aws_db_subnet_group.wordpress.name
  allocated_storage       = 20
  identifier              = "wp-db-1"
  vpc_security_group_ids  = [aws_security_group.wordpress-rds.id]
  apply_immediately       = true
  skip_final_snapshot     = true
  backup_retention_period = 0

}



resource "aws_alb" "wordpress-alb" {
  name            = "wof-load-balancer"
  security_groups = [aws_security_group.ALB.id]
  subnets         = [aws_subnet.main_public_1.id, aws_subnet.PublicSubnet1.id]
}

resource "aws_alb_target_group" "wordpress-target-group" {
  name        = "WordpressTargetGroup"
  target_type = "ip"
  port        = 8080
  protocol    = "HTTP"
  stickiness {
    type = "lb_cookie"
  }
  health_check {
    port = 8080
  }
  vpc_id = aws_vpc.main.id
}

resource "aws_alb_listener" "ALBListener" {
  load_balancer_arn = aws_alb.wordpress-alb.arn
  protocol          = "HTTP"
  port              = 80
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.wordpress-target-group.arn
  }
}

data "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"
}

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


/**
data "aws_ami" "amzLinux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-gp2"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}


resource "aws_instance" "bastion" {
  ami           = data.aws_ami.amzLinux.id
  instance_type = "t2.micro"
  tags = {
    Name = "Public Bastion"
  }
  subnet_id = aws_subnet.main_public_1.id
}

resource "aws_security_group" "allowSSH" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.main.id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "icmp"
    from_port   = 0
    to_port     = 0
  }

  tags = {
    Name = "allow_ssh"
  }
}

resource "aws_key_pair" "Test" {
  key_name   = "NAT-troubleshoot"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCekpG1HXLMC7mYhKF7ngiu9m7fCx0fXjm8RhxHHJnVH3ETvGaeeIbhYXpJs0PJfY/f4IDHlbK/HNA5VHSS34b0RCoPdEaSorgqKHnQY8qNz/4dccZL9ThHQdNrtE+Z/EhEeICKQB+XR8PhG701uX9mjTQ7Xbumyy8MCZGRTExWz5P0AnTCBxBKpqwy4T+j5FQBuVIc1S595aaR1vrpIKCEI5ZfjaZyJh9u6XcS6ZWgbN2GpZawr42nOtLp8+Rg3J6rlwIzaY9B28ISY9g3zSMLj+Ax46vjN0c7AzYzUk33Gx9IfQ6WHsOerqWVduyds4BH8vpm1wdPJqu7QXir6+iLoFyfeuzYH86kK8rOuS0yYf7AQV6aB7oFTA03NGc1JJdMKQTNEbbF9rbd4iVXwqt6HUBtA1xZf3QgpFpIiDE58UZZS8CWYZU7XaUk4mJj+b7uPgJ+m1MB7jcLFAuGPre0wadk5jKlYRl1MGz0ksAzhlGdwfao468YB8iHJO5y5bPYzOYWj0n3hJcR4q0kkbIu55uWXolY1sBUha68UJ4Phig7jzwA/VtjnxLxheuyLmwnQZlgUf6dyUvxzPdZgHrwTeeyZkrGvRGBEJmPWrhicXVr8g18vztwMRPh8sBws9uQQrzoZtda7cAcjEd0vWcbPKBmV2z9B3L8qQFX79Cekw== dmaes@MBP.local"
}

resource "aws_instance" "private-instance" {
  depends_on    = [aws_key_pair.Test]
  ami           = data.aws_ami.amzLinux.id
  instance_type = "t2.micro"
  tags = {
    Name = "Private - Test"
  }
  key_name        = aws_key_pair.Test.key_name
  subnet_id       = aws_subnet.PrivateSubnet0.id
  security_groups = [aws_security_group.allowSSH.id]
}**/

