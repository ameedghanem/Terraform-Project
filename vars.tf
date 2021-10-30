variable "accessKey" {
  type        = string
  description = "The access key of your aws user."
}

variable "secretKey" {
  type        = string
  description = "The secret key of your aws user"
}

variable "instance_count" {
  default = "2"
}

variable "instance_tags" {
  type = list
  default = ["webserver-1", "webserver-2"]
}

variable "instance_type" {
  default = "t2.micro"
}