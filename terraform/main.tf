resource "aws_s3_bucket" "source" {
    bucket = var.aws_s3_bucket  
}

resource "aws_s3_bucket_website_configuration" "static_website_config" {
    bucket = aws_s3_bucket.source.id
    index_document {
      suffix = "index.html"
    }
}

resource "aws_s3_bucket_policy" "static_site_policy" {
    bucket = aws_s3_bucket.source.id
   policy = jsondecode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": "*",
      "Action": [
        "s3:GetObject"
      ],
      "Resource": "aws_s3_bucket.source.arn/*"
    }
  ]
})
  depends_on = [ aws_s3_account_public_access_block.static_site_access ]
}

resource "aws_s3_account_public_access_block" "static_site_access" {
    block_public_acls = false
    block_public_policy = false
    ignore_public_acls = false
    restrict_public_buckets = false
    
}