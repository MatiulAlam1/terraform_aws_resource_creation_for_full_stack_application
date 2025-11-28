include "root" { path = find_in_parent_folders() }
terraform { source = "../../../modules//s3" }
inputs = {
  s3_bucket_name = "my-react-bucket-prod-2232131-${get_env("AWS_REGION", "ap-south-1")}"
  tags           = { Environment = "prod" }
}
