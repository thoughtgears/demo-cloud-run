variable "project_id" {
  type        = string
  description = "The project ID to deploy resources"
}

variable "project_number" {
  type        = string
  description = "The project number to deploy resources"
}


variable "region" {
  type        = string
  description = "The region to deploy resources"
}

variable "organization_id" {
  type        = string
  description = "The organization ID to deploy resources"
}

variable "github_pat" {
  type        = string
  description = "The GitHub personal access token"
}

variable "github_app_installation_id" {
  type        = number
  description = "The GitHub app installation ID"
}

variable "spacelift_api_key" {
  type        = string
  description = "The Spacelift API key"
}

variable "spacelift_api_key_id" {
  type        = string
  description = "The Spacelift API key ID"
}

variable "spacelift_stack_id" {
  type        = string
  description = "The Spacelift stack ID"
}