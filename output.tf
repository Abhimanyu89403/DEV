output "load_balancer_arn" {
    description = "load balancer arn is"
    value = aws_lb.pgagi_lb.arn
}

output "fe_target_group_arn" {
    description = "fe target Group arn"
    value = aws_lb_target_group.pgagi_fe_target_group.arn
}

output "be_target_group" {
    description = "be target group arn"
    value = aws_lb_target_group.pgagi_be_target_group.arn
}


