### Added outbound HTTPS (443) & UDP (53) rules to ECS cluster task SG
### Manually change SGs to connect to RDS

resource "aws_security_group" "wordpress-rds" {
  name        = "Wordpress-RDS-SG"
  description = "RDS Security Group"
  vpc_id      = aws_vpc.main.id
}

/*
resource "aws_security_group_rule" "acceptTrafficFromTask" {
  type                     = "ingress"
  to_port                  = 3306
  from_port                = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.wordpress-rds.id
  source_security_group_id = aws_security_group.ecs_service_sg.id
}
*/

module "vpc_module" {
  source                   = "./modules/vpc"
  protocol                 = "tcp"
  security_group_id        = aws_security_group.wordpress-rds.id
  source_security_group_id = aws_security_group.ecs_service_sg.id
}

resource "aws_security_group_rule" "acceptTrafficFromRDS" {
  type                     = "egress"
  to_port                  = 3306
  from_port                = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service_sg.id
  source_security_group_id = aws_security_group.wordpress-rds.id
}

resource "aws_security_group" "ALB" {
  name        = "wordpress-alb-sg"
  description = "ALB Security Group"
  vpc_id      = aws_vpc.main.id
  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_service_sg" {
  name        = "Svc-Wordpress-on-Fargate"
  description = "Security Group for ECS Service"
  vpc_id      = aws_vpc.main.id
}

resource "aws_security_group_rule" "AllowHTTPS2FetchImage" {
  type              = "egress"
  to_port           = 443
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.ecs_service_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "AllowUDP2FetchImage" {
  type              = "egress"
  to_port           = 53
  from_port         = 53
  protocol          = "-1"
  security_group_id = aws_security_group.ecs_service_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "acceptALBTraffic" {
  type                     = "ingress"
  to_port                  = 8080
  from_port                = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service_sg.id
  source_security_group_id = aws_security_group.ALB.id
}

resource "aws_security_group_rule" "sometestfuck" {
  type                     = "egress"
  to_port                  = 8080
  from_port                = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ALB.id
  source_security_group_id = aws_security_group.ecs_service_sg.id
}

resource "aws_security_group_rule" "HTTPFromAnywhere" {
  type                     = "ingress"
  to_port                  = 80
  from_port                = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service_sg.id
  source_security_group_id = aws_security_group.ALB.id
}

resource "aws_security_group_rule" "HTTPSFromAnywhere" {
  type                     = "ingress"
  to_port                  = 443
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service_sg.id
  source_security_group_id = aws_security_group.ALB.id
}

resource "aws_security_group_rule" "SSHFromAnywhere" {
  type                     = "ingress"
  to_port                  = 22
  from_port                = 22
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_service_sg.id
  source_security_group_id = aws_security_group.ALB.id
}

resource "aws_security_group" "mount_target_sg" {
  description = "FileSystem Security Group"
  vpc_id      = aws_vpc.main.id
  name        = "Wordpress-EFS-SG"
  ingress {
    protocol    = "tcp"
    from_port   = "2049"
    to_port     = "2049"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

