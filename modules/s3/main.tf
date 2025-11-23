module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "~> 4.2.0"

  bucket = var.s3_bucket_name

  # Enable website hosting (index and error documents)
  website = {
    index_document = "index.html"
    error_document = "error.html"
  }

  # Allow public access
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false

  # Bucket policy for public read access
  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "arn:aws:s3:::${var.s3_bucket_name}/*"
      }
    ]
  })

  versioning = {
    enabled = true
  }

  # Optional: Server-side encryption
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  # Allow easy cleanup during development (removes all objects on destroy)
  force_destroy = true

  tags = var.tags
}