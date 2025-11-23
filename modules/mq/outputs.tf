output "mq_arn" { value = aws_mq_broker.mq.arn }
output "mq_endpoint" { value = aws_mq_broker.mq.instances[0].console_url }  # Or AMQP endpoints