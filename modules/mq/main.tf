resource "aws_mq_broker" "mq" {
  broker_name                = var.mq_name
  engine_type                = "RabbitMQ"
  engine_version             = var.engine_version
  host_instance_type         = var.instance_type
  deployment_mode            = "SINGLE_INSTANCE"
  auto_minor_version_upgrade = true

  subnet_ids      = [var.private_subnet_ids[0]]
  security_groups = [aws_security_group.mq_sg.id]

  user {
    username = var.username
    password = var.password
  }

  tags = var.tags
}

resource "aws_security_group" "mq_sg" {
  name_prefix = "${var.mq_name}-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}
