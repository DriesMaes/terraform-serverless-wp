variable "ecs_cluster_name" {
  type        = string
  default     = "ecs-wof"
  description = "The name of the ecs cluster used for Wordpress"
}

variable "vpc_name" {
  type    = string
  default = "vpc-eu-west-1-dev-web-app"
}

variable "network" {
  type = map(object({
    name = string
    CIDR = string
  }))
  default = {
    VPC = {
      name = "VPC"
      CIDR = "10.0.0.0/16"
    }
    Public0 = {
      name = "Public0"
      CIDR = "10.0.0.0/24"
    }
    Public1 = {
      name = "Public1"
      CIDR = "10.0.1.0/24"
    }
    Private0 = {
      name = "Private0"
      CIDR = "10.0.2.0/24"
    }
    Private1 = {
      name = "Private1"
      CIDR = "10.0.3.0/24"
    }
  }
}

variable "AZRegions" {
  type = map(object({
    AZs = list(string)
  }))
  default = {
    "eu-west-1" = {
      AZs = ["a", "b"]
    }
  }
}
