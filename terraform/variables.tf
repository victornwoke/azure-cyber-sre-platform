variable "subscription_id" {
  description = "The Azure subscription ID"
  type        = string
}

variable "location" {
  type    = string
  default = "uksouth"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "unique_suffix" {
  type = string
}

variable "project_name" {
  type    = string
  default = "cyber-sre-platform"
}

variable "address_prefixes" {
  type = list(string)
}

variable "subnet_address_prefixes" {
  type = list(string)
}
