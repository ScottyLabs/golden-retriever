provider "github" {
  owner = var.github_owner
  token = var.github_token
}

provider "forgejo" {
  host      = var.forgejo_host
  api_token = var.forgejo_api_token
}
