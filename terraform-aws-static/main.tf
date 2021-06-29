# Cloudfront

resource "aws_cloudfront_origin_access_identity" "cloudfrontAccessIdentity" {
  comment = "Origin Access Identity for S3"
}

resource "aws_cloudfront_distribution" "cloudfrontDistribution" {
  aliases = var.aliases

  origin {
    domain_name = aws_s3_bucket.s3Bucket.bucket_domain_name
    origin_id   = aws_s3_bucket.s3Bucket.id

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cloudfrontAccessIdentity.cloudfront_access_identity_path
    }
  }

  custom_error_response {
    error_code         = 403
    response_page_path = "/${var.mainDocument}"
    response_code      = 200
  }

  custom_error_response {
    error_code         = 404
    response_page_path = "/${var.mainDocument}"
    response_code      = 200
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  price_class         = var.priceClass
  default_root_object = var.mainDocument

  viewer_certificate {
    cloudfront_default_certificate = var.cloudfrontDefaultCertificate

    acm_certificate_arn = var.certificateArn
    ssl_support_method  = var.sslSupportMethod
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = aws_s3_bucket.s3Bucket.id
    compress         = true

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

  tags = {
    Name        = "${var.bucketName}-cloudfront"
    Environment = var.environment
  }

  depends_on = [aws_s3_bucket.s3Bucket]
}

# S3
resource "aws_s3_bucket" "s3Bucket" {
  bucket = var.bucketName
  acl    = "public-read"

  website {
    index_document = var.mainDocument
    error_document = var.mainDocument
  }

  versioning {
    enabled = true
  }

  lifecycle {
    prevent_destroy = false
  }

  tags = {
    Name        = var.bucketName
    Environment = var.environment
  }
}

# Iam
resource "aws_s3_bucket_policy" "s3BucketPolicy" {
  bucket = aws_s3_bucket.s3Bucket.id

  policy = data.aws_iam_policy_document.s3BucketPolicyDocument.json
}

data "aws_iam_policy_document" "s3BucketPolicyDocument" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.s3Bucket.arn}/*"]
    effect    = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cloudfrontAccessIdentity.iam_arn]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.s3Bucket.arn]
    effect    = "Allow"

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.cloudfrontAccessIdentity.iam_arn]
    }
  }

  depends_on = [aws_s3_bucket.s3Bucket]
}
