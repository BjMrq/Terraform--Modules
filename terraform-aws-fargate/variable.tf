variable "ecsServiceConfig" {
  description = "Basic information for task and service"
  type        = map(string)
  default = {
    applicationName = ""
    containerPort   = 80
  }
}

variable "capacity" {
  description = "Autoscaling capacity"
  type        = map(number)
  default = {
    min           = 1
    max           = 1
    cpuPercentage = 70
  }
}

variable "environment" {
  description = "Environment of the application"
  type        = string
}

variable "region" {
  description = "Region where the application will be deployed"
  type        = string
  default     = "ca-central-1"
}

variable "dockerImage" {
  description = "Docker image to be used by task"
  type        = string
}

variable "fargateRoleArn" {
  type = string
}

variable "repositoryAuthSecretArn" {
  description = "Arn of secret holding info auth info to access docker registry"
  type        = string
}

variable "cpu" {
  type    = number
  default = 256
}

variable "memory" {
  type    = number
  default = 512
}

variable "cluster" {
  type = map(string)
  default = {
    arn  = ""
    name = ""
  }
}

variable "desiredCount" {
  type    = number
  default = 1
}

variable "subnets" {
  type = list(string)
}


variable "targetGroupArn" {
  type = string
}

variable "VPCId" {
  type = string
}

variable "securityCidrBlocks" {
  type = list(string)
}
