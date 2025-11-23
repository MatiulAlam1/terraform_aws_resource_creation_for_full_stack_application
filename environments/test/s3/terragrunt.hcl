include "root" { path = find_in_parent_folders() }
terraform { source = "../../../modules//s3" }
inputs = {
  s3_bucket_name = "my-react-bucket-test-2232131"
  tags           = { Environment = "test" }
}
