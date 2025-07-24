resource "aws_s3_bucket" "source" {
    bucket = var.aws_s3_bucket 
}

resource "aws_route53_zone" "public_zone" {
  name = var.aws_route53_zone
  zone_id = aws_route53_zone.public_zone.zone_id
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
  records = each.value.key
  ttl = 60
  type = each.value.type
  zone_id = data.aws_route53_zone.domain_zone.zone_id

}

resource "aws_acm_certificate_validation" "studysite_validation" {
  certificate_arn = aws_acm_certificate.studysite_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.studysite_validation : record.fqdn ]
  
}