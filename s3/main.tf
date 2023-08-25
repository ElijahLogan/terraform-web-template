resource "aws_s3_bucket" "sports_static_react_bucket" {
  bucket = var.bucket_name
  acl    = "private"

  tags = {
    Name = "my-react-sports-bucket"
  }

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "sports_block_public_access" {
  bucket = aws_s3_bucket.sports_static_react_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}