output "bucket_arn"{
    value = aws_s3_bucket.static_react_bucket.arn
}

output "domain_name"{
    value = aws_s3_bucket.static_react_bucket.bucket_regional_domain_name
}

output "bucket_id"{
    value = aws_s3_bucket.static_react_bucket.id
}


