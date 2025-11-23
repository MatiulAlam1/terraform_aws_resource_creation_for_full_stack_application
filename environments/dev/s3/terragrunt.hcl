include "root" { path = find_in_parent_folders() }
terraform { source = "../../../modules//s3" }
inputs = {
  s3_bucket_name = "my-react-bucket-dev-2232131"
  tags           = { Environment = "dev" }
}
