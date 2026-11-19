variable "project_name" {
  description = "Short name used in resource names"
  type        = string
}

variable "environment" {
  description = "Environment name used in resource names"
  type        = string
}

variable "images_to_keep" {
  description = "Number of images kept in the registry. Older ones are deleted automatically."
  type        = number
  default     = 10
}
