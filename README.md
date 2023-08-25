
# React Deployment with Terraform: Gitab IAM, S3, Cloudfront 


## Descriptioon

3 terraform modules are created and used to make a reusable project deployment process for web development


### Author

- [@elijahlogan](https://www.linkedin.com/in/elijah-logan/)

#  Initial deployment 
### main module 
#### cloudfront commented out because s3 and iam modules need to be created first before they can be used by it 



```terraform

provider "aws" {
     region = "us-east-2"
     access_key = "################"
     secret_key = "################################"
 }
 

module s3 {
    source = "./modules/s3"
}

module iam {
    source = "./modules/iam"
    bucket_arn = module.s3.bucket_arn 
}

// module cloudfront{
//     source = "./modules/cloudformation"
//     domain_name = module.s3.domain_name
//     bucket_id = module.s3.bucket_id
//     bucket_arn = module.s3.bucket_arn
// }
```




## pre-step create iam user 

* create iam user  in terminal

```bash
aws iam create-user --user-name  <-gitlab-user>

```



 

## s3 module
### Creates s3 and blocks all public access to it 


```terraform 
resource "aws_s3_bucket" "static_react_bucket" {
  bucket = '<s3-bucket>'
  acl    = "private"

  tags = {
    Name = "my-react-bucket"
  }

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_public_access_block" "block_public_access" {
  bucket = aws_s3_bucket.static_react_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

```


 ## iam module
-  Retrieve <gitlab-user> as a resource
- Create a policy to access the S3 bucket
- Attach the policy to <gitlab-user> 
 
 ```terraform 
data "aws_iam_user" "user" {
  user_name = "<gitlab-user>"
}

resource "aws_iam_policy" "ci_policy" {
  name        = "gitlab-ci-policy"
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


resource "aws_iam_policy_attachment" "gitlab_ci_attachment" {
  name       = "gitlab-ci-attachment"
  users      = [data.aws_iam_user.user.user_name]
  policy_arn = aws_iam_policy.ci_policy.arn
}
 ```

##  Run  Terraform to Create S3 bucket and  grant iam user permissions necessary to push files into created S3 bucket

```bash
terraform plan -out=iams3.plan 
terraform show plan 
terrafrom apply iams3.plan 
```



# Setiing up gitlab 


## Create a project on gitlab
-  create a new or existing react project 
- inside it initialize git then connect git remote to your site on gitlab

```bash
cd existing_project/new_project
git remote add origin https://gitlab.com/<gitlab_project>/e.git
git branch -M main
git push -uf origin main
```

### create secret/access key from <gitlab_user>

```bash
aws iam create-access-key --user-name <gitlab_user>
```
It should return an object that looks like: 

```bash
{
    "AccessKey": {
        "UserName": "<gitlab-user>",
        "AccessKeyId": "Areefervervdcververer,
        "Status": "Active",     
           "SecretAccessKey": "reevegverg9fg03fg0efyhfnsd0duveere",
        "CreateDate": "2023-07-05T21:40:09Z"
    }
}


```

# Add iam keys allowing gitlab runner to push site files into s3

## gitlab project > Settings > variables 

Create AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY variables using values returned from terminal 


# add pipeline configuration to site files 

## pipeline will put files into s3 bucket created in the s3 module 

## .gitlab-ci.yml

```yml
image: nikolaik/python-nodejs:python3.11-nodejs16-slim

variables:
  REGION: us-east-1

before_script:
  - yarn

stages:
  - deploy

deploy:
  stage: deploy
  only:
    refs:
      - main
  script:
    - pip3 install awscli
    - CI=false yarn build
    - aws --region $REGION s3 cp --recursive ./build/ s3://<s3-bucket>/


```



##

## Second  Deployment
### main module
### cloudformation uncommented 
```terraform

provider "aws" {
     region = "us-east-2"
     access_key = "################"
     secret_key = "################################"
 }
 

module s3 {
    source = "./modules/s3"
}

module iam {
    source = "./modules/iam"
    bucket_arn = module.s3.bucket_arn 
}

module cloudfront {
    source = "./modules/cloudformation"
    domain_name = module.s3.domain_name
    bucket_id = module.s3.bucket_id
    bucket_arn = module.s3.bucket_arn
}
```


## cloudfront 

- Create an Origin Access Identity (OAI) to restrict access to the S3 bucket and an IAM policy to grant the OAI access to the S3 bucket.
- Create a CloudFront distribution the React application hosted on the previously created S3 bucket. 

- Configures the CloudFront distribution to use the OAI, and sets up the default cache behavior and custom error responses. 
- Sets the viewer certificate to use the CloudFront default certificate.

```terraform 

locals {
  s3_origin_id = "sports_S3-origin-react-app"
}

resource "aws_cloudfront_origin_access_identity" "ai" {
  comment = "my-react-app OAI"
}

resource "aws_cloudfront_distribution" "cf_distribution" {
  origin {
    domain_name = var.domain_name
    origin_id   = local.s3_origin_id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }
  enabled         = true
  is_ipv6_enabled = true

  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
  }

  ordered_cache_behavior {
    path_pattern     = "/index.html"
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    target_origin_id = local.s3_origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_100"



  retain_on_delete = true

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 403
    response_code         = 200
    response_page_path    = "/index.html"
  }

  custom_error_response {
    error_caching_min_ttl = 300
    error_code            = 404
    response_code         = 200
    response_page_path    = "/index.html"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}


data "aws_iam_policy_document" "react_app_s3_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${var.bucket_arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
  }
}

resource "aws_s3_bucket_policy" "react_app_bucket_policy" {
  bucket = var.bucket_id
  policy = data.aws_iam_policy_document.react_app_s3_policy.json
}


```


## Deploy cloudfront with Terraform

```bash
terraform plan -out=cloudfront.plan 
terraform show cloudfront.plan
terrafrom apply cloudfront.plan 

```

## Amazon CloudFront is a content delivery network operated by Amazon Web Services. The content delivery network was created to provide a globally-distributed network of proxy servers to cache content, such as web videos or other bulky media, more locally to consumers, to improve access speed for downloading the content


