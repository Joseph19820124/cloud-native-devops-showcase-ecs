variable "name_prefix" {
  type = string
}

variable "bucket_suffix" {
  type    = string
  default = "assets"
}

variable "tags" {
  type    = map(string)
  default = {}
}
