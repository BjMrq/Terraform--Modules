
variable "priceClass" {
  default = "PriceClass_100"
  type    = string
}

variable "mainDocument" {
  default = "index.html"
  type    = string
}
variable "aliases" {
  default = []
  type    = list(string)
}

variable "cloudfrontDefaultCertificate" {
  default = true
  type    = bool
}

variable "certificateArn" {
  default = null
  type    = string
}

variable "sslSupportMethod" {
  default = null
  type    = string
}

variable "environment" {
  type = string
}

variable "bucketName" {
  type = string
}
