module "sso" {
  source = "../../modules/lxc"

  node_name         = "batman01"
  hostname          = "sso"
  pool_id           = "iac"
  template_file_id  = "local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
  disk_datastore_id = "local-zfs"
  disk_size_gb      = 20
  cores             = 4
  memory_mb         = 4096
  ipv4_address      = "192.168.8.94/24"
  ipv4_gateway      = "192.168.8.1"
  ssh_public_keys   = var.ssh_public_keys

  # nesting=true: Authentik corre via docker-compose (server, worker,
  # postgresql, redis) -- mismo motivo que plane/observability/vault, y
  # requisito del template Ubuntu dentro de un LXC sin privilegios.
  nesting = true
}

output "sso_ip" {
  value       = module.sso.ipv4_address
  description = "IP del contenedor de Authentik"
}

output "sso_vm_id" {
  value       = module.sso.vm_id
  description = "VMID asignado por Proxmox"
}
