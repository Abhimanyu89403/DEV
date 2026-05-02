data "aws_subnet" "public1"{
    id = "subnet-0c99670ef9fe048fa"
}
data "aws_subnet" "public2" {
    id = "subnet-01adfa173e9bf5284"
}
data "aws_security_group" "vpc_sg" {
    id = "sg-053f8ba38946cb3ce"
}
data "aws_vpc" "vpc" {
    id = "vpc-06c3b905efd13fdf2"
}
resource "aws_lb" "pgagi_lb" {
    name = "PGAGI-prod-lb"
    internal = false
    load_balancer_type = "application"
    subnets = [data.aws_subnet.public1.id , data.aws_subnet.public2.id]
    security_groups = [data.aws_security_group.vpc_sg.id]
    tags = {
        Environment = "prod"
    }
    enable_cross_zone_load_balancing = true
    idle_timeout = 120
}

resource "aws_lb_target_group" "pgagi_fe_tg" {
    name = "FE-tagret-group"
    port = var.fe_port
    protocol = "HTTP"
    vpc_id = [data.aws_vpc.vpc.id]
    target_type = "ip"
    stickiness {
        type = "lb_cookie"
        enabled = true
    }
    health_check{
        path = "/health"
        matcher = 200
        interval = 30
        timeout = 5
        healthy_threshold = 3
        unhealthy_threshold = 2 
    }
    deregistration_delay = 60  #connection terminated gracefully when tg is unhealthy
    slow_start = 60   #gradually sending traffic to new containers
}

resource "aws_lb_target_group" "pgagi_be_tg" {
    name = "BE-target-group"
    port = var.be_port
    protocol = "HTTP"
    vpc_id = []
    target_type = "ip"
    deregistration_delay = 60
    slow_start = 60
    health_check {
        path = "/health"
        matcher = 200
        interval = 20
        timeout = 5
        healthy_threshold = 3
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener" "http_redirect" {
    load_balancer_arn = aws_lb.pgagi_lb.arn
    port = 80
    protocol = "http"

    default_action {
        type = "redirect"

        redirect {
            port = "443"
            protocol = "https"
            status_code = "HTTP-301"
    }
    }
}

resource "aws_lb_listener" "https_listener" {
    load_balancer_arn = aws_lb.pgagi_lb.arn
    port = 443
    protocol = "https"
    ssl_policy = ""
    certificate_arn = ""
    default_action {
        type = "forward"
        target_group_arn = aws_lb_target_group.pgagi_fe_tg.arn
    }
}

resource "aws_lb_listener_rule" "be_listener" {
    listener_arn = aws_lb_listener.https_listener.arn
    priority = 10

    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.pgagi_be_tg.arn
    }
    condition {
        path_pattern {
            values = ["/api/*"]
        }
    }
}