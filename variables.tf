variable "github_owner" {
  type        = string
  description = "GitHub organization or user that owns the teams and repositories."
  default     = ""
}

variable "github_token" {
  type        = string
  sensitive   = true
  description = "GitHub personal access token with org and repo scopes. Can also be set via GITHUB_TOKEN env var."
  default     = null
}

variable "forgejo_host" {
  type        = string
  description = "Base URL of the Forgejo instance (e.g. https://codeberg.org). Can also be set via FORGEJO_HOST env var."
  default     = null
}

variable "forgejo_owner" {
  type        = string
  description = "Forgejo organization that owns the teams and repositories."
  default     = ""
}

variable "forgejo_api_token" {
  type        = string
  sensitive   = true
  description = "Forgejo API token with org and repo scopes. Can also be set via FORGEJO_API_TOKEN env var."
  default     = null
}
