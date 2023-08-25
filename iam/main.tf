# Retrieve gitlab-user as a resource
data "aws_iam_user" "user" {
  user_name = "gitlab-user"
}

# Create the policy to access the S3 bucket
resource "aws_iam_policy" "sports_ci_policy" {
  name        = "sports_gitlab-ci-policy"
  path        = "/"
  description = "Gitlab CI policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:PutObjectAcl"
        ],
        Effect = "Allow",
        Resource = [
          "${var.bucket_arn}/*"
        ]
      },
      {
        Action = [
          "s3:ListBucket"
        ],
        Effect = "Allow",
        Resource = [
        var.bucket_arn
        ]
      },
    ]
  })
}

# Attach the policy to our user
resource "aws_iam_policy_attachment" "gitlab_ci_attachment" {
  name       = "gitlab-ci-attachment"
  users      = [data.aws_iam_user.user.user_name]
  policy_arn = aws_iam_policy.sports_ci_policy.arn
}