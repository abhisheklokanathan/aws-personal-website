resource "aws_s3_bucket" "source" {
    bucket = var.aws_s3_bucket 
}

resource "aws_route53_zone" "public_zone" {
  name = var.aws_route53_zone
  
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


data "aws_route53_zone" "domain_zone" {
  name = "studysite.shop"
  depends_on = [ aws_route53_zone.public_zone ]
}

resource "aws_route53_record" "studysite_validation" {
  for_each = {
    for dvo in aws_acm_certificate.studysite_cert.domain_validation_options : dvo.domain_name
    =>{
       name = dvo.resource_record_name
       record = dvo.resource_record_value
       type = dvo.resource_record_type
    }

  }

  name = each.value.name
  records = [each.value.record]
  ttl = 60
  type = each.value.type
  zone_id = data.aws_route53_zone.domain_zone.zone_id

}

resource "aws_acm_certificate_validation" "studysite_validation" {
  certificate_arn = aws_acm_certificate.studysite_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.studysite_validation : record.fqdn ]
  
}

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "oac${aws_s3_bucket.source.bucket}"
  description                       = "OAC for ${aws_s3_bucket.source.bucket}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name              = aws_s3_bucket.source.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
    origin_id                = "S3-${aws_s3_bucket.source.bucket}"
  }

  enabled             = true
  is_ipv6_enabled     = true
  comment             = "Cloudfront distribution for -${aws_s3_bucket.source.bucket}"
  default_root_object = "index.html"

  aliases = ["studysite.shop", "www.studysite.shop"]

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.source.bucket}"

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
  }



  price_class = "PriceClass_200"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.studysite_cert.arn
    ssl_support_method = "sni-only"
  }
  depends_on = [ aws_acm_certificate_validation.studysite_validation ]
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.source.id
  policy = jsonencode({
    Version = "2022-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action = "s3.GetObject"
        Resource = "${aws_s3_bucket.source.arn}/*"
        Condition = {
          StingEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
})
  
}