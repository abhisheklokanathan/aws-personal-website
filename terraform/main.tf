resource "aws_s3_bucket" "source" {
    bucket = var.aws_s3_bucket 
}

resource "aws_s3_bucket_public_access_block" "static_site_access" {
    bucket = aws_s3_bucket.source.id
    block_public_acls = true
    block_public_policy = true
    ignore_public_acls = true
    restrict_public_buckets = true
    
}

resource "aws_acm_certificate" "studysite_cert" {
           domain_name = "studysite.shop"
           validation_method = "DNS"
           subject_alternative_names = ["www.studysite.shop"]

          tags = {
            Name = "My SSL cert"
          }
          lifecycle {
            create_before_destroy = true
          }
}