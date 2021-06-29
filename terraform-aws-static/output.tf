# Output
output "BucketId" {
  description = "The ID of the S3 Bucket hosting the party builder in dev"
  value       = aws_s3_bucket.s3Bucket.id
}

output "BucketCloudfrontId" {
  description = "The ID of the CloudFront distribution fronting the party builder in dev"
  value       = aws_cloudfront_distribution.cloudfrontDistribution.id
}

output "BucketDomainName" {
  description = "The CloudFront domain name for party builder in dev"
  value       = aws_cloudfront_distribution.cloudfrontDistribution.domain_name
}
