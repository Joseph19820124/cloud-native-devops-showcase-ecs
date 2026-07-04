variable "name_prefix" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "frontend_port" {
  type    = number
  default = 8080
}

variable "backend_port" {
  type    = number
  default = 5000
}

variable "tags" {
  type    = map(string)
  default = {}
}
