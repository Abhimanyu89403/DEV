resource "aws_cloudwatch_metric_alarm" "high_latency_count" {
    alarm_name = "alb-latency-alarm"
    alarm_description = "Alert when latency is above 1 sec"
    comparison_operator = "GreaterThanThreshold"
    metric_name = "TargetResponseTime"
    statistic = "Average"

    threshold = 1
    evaluation_periods = 2
    period = 60


    namespace = "AWS/ApplicationLB"
    dimensions = {
      LoadBalancer = aws_lb.alarm_name.arn
    }
}