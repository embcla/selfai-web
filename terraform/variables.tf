variable "hcloud_token" {
  description = "Hetzner Cloud API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

variable "ts_client_token" {
  description = "Tailscale OAuth Client ID"
  type        = string
  sensitive   = true
}

variable "ts_client_secret" {
  description = "Tailscale OAuth Client Secret"
  type        = string
  sensitive   = true
}