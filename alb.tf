resource "aws_alb" "wordpress-alb" {
  name            = "wof-load-balancer-test"
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
