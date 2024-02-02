variable "description" {
  default = ""
  type    = string
}

variable "cidr_blocks" {
  type    = list(string)
  default = [""]
}

variable "type" {
  default = "ingress"
  type    = string
}

variable "to_port" {
  default = 22
  type    = number
}

variable "from_port" {
  default = 22
  type    = number
}

variable "protocol" {
  default = "tcp"
  type    = string

  validation {
    condition     = can(regex("^(icmp|icmpv6|tcp|udp|all)$", var.protocol))
    error_message = "Invalid protocol. Protocol must be icmp, icmpv6, tcp, udp, or all."
  }
}

variable "security_group_id" {
  default = "default"
  type    = string
}

variable "source_security_group_id" {
  default = "default"
  type    = string
}
