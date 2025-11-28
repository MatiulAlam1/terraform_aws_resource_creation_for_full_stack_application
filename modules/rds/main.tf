module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "~> 6.13.0"
  count   = var.rds_count

  identifier        = "${var.rds_identifier}-${count.index + 1}"
  engine            = "postgres"
  engine_version    = "16"
  instance_class    = var.rds_instance_class
  allocated_storage = var.rds_storage
  family            = "postgres16"

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  create_db_subnet_group = true
  subnet_ids             = var.private_subnet_ids

  tags = var.tags
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.rds_identifier}-"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
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