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
