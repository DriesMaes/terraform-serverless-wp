

output "VPCid" {
  value       = aws_vpc.main.id
  description = "The ID of the VPC used to deploy our infrastructure"
  sensitive   = false
}

output "PublicSubnet0" {
  value       = aws_subnet.main_public_1.id
  description = "SubnetID of public subnet 0"
}

output "PublicSubnet1" {
  value       = aws_subnet.PublicSubnet1.id
  description = "SubnetID of public subnet 1"
}

output "PrivateSubnet0" {
  value       = aws_subnet.PrivateSubnet0.id
  description = "SubnetID of private subnet 0"
}

output "PrivateSubnet1" {
  value       = aws_subnet.PrivateSubnet1.id
  description = "SubnetID of private subnet 1"
}

output "EFSId" {
  value       = aws_efs_file_system.wordpress.id
  description = "ID of EFS FS"
}

output "RDSEndpointAddress" {
  value       = aws_db_instance.default.endpoint
  description = "RDS Endpoint Address"
}

output "EFSAccessPoint" {
  value       = aws_efs_access_point.efs_access_point.id
  description = "EFS Access Point ID"
}

output "ALBSecurityGroup" {
  value       = aws_security_group.ALB.id
  description = "ALB Security Group"
}

output "WordpressTargetGroup" {
  value       = aws_alb_target_group.wordpress-target-group.name
  description = "ALB Target Group"
}
