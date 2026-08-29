variable "proxmox_endpoint" {
  type        = string
  description = "URL de la API de Proxmox, ej. https://192.168.8.75:8006/"
}

variable "proxmox_token_id" {
  type        = string
  description = "Token ID completo, ej. tofu@pve!tofu-iac"
}

variable "proxmox_token_secret" {
  type        = string
  sensitive   = true
  description = "Secret del token de Proxmox"
}

variable "proxmox_insecure" {
  type        = bool
  default     = true
  description = "Proxmox usa certificado autofirmado en este homelab"
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "Llaves SSH publicas autorizadas dentro del contenedor"
}
