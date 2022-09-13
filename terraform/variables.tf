variable "ami" {
  description = "ubuntu 20.04"
  type        = string
  default     = "ami-08d4ac5b634553e16"
}

variable "instance_type" {
  type    = string
  default = "t2.small"
}

variable "key_name" {
  type    = string
  default = "myupgradec2new"
}

variable "prefix" {
  type    = string
  default = "514-umarf-c5"
}