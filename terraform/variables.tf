variable "aws_s3_bucket" {
    type = string
    default = "aws-mypersonal-website"
}
variable "region" {
  description = "The AWS region to create the S3 bucket in"
  type        = string
  default     = "ap-south-1"  # Optional default
}