
provider "aws" {
     region = "us-east-2"
     access_key = "###############"
     secret_key = "###############################"
 }
 

module s3 {
    source = "./modules/s3"
}

module iam {
    source = "./modules/iam"
    bucket_arn = module.s3.bucket_arn 
}

# module cloudfront {
#     source = "./modules/cloudformation"
#     domain_name = module.s3.domain_name
#     bucket_id = module.s3.bucket_id
#     bucket_arn = module.s3.bucket_arn
# }
