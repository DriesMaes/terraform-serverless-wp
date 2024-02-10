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
