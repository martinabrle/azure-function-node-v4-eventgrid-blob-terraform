variable "project" {
  type = string
  description = "Project name"
}

variable "environment" {
  type = string
  description = "Environment (dev / stage / prod)"
}

variable "location" {
  type = string
  description = "Azure region"
}


variable "inbox_container_name" {
  type = string
  description = "Inbox container"
}

variable "destination_file_share_name" {
  type = string
  description = "File share"
}
