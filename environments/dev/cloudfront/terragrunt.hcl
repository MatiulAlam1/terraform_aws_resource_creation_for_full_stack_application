include "root" { path = find_in_parent_folders() }

dependency "s3" {
  config_path = "../s3"
  mock_outputs = {
    s3_bucket_id = "mock-bucket"
    s3_bucket_domain_name = "mock-bucket.s3.amazonaws.com"
  }
}

terraform { source = "../../../modules//cloudfront" }

inputs = {
  s3_bucket_name        = dependency.s3.outputs.s3_bucket_id
  s3_bucket_domain_name = dependency.s3.outputs.s3_bucket_domain_name
  tags                  = { Environment = "dev" }
}
