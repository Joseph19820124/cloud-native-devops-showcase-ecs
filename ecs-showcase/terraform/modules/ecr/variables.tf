variable "name_prefix" {
  type = string
}

variable "repository_names" {
  type    = list(string)
  default = ["frontend", "backend"]
}

variable "image_tag_mutability" {
  type    = string
  default = "MUTABLE"
}

variable "force_delete" {
  description = "Allow terraform destroy to delete repos that still contain images"
  type        = bool
  default     = true
}

variable "tags" {
  type    = map(string)
  default = {}
}
