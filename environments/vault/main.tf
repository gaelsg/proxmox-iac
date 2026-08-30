module "vault" {
  source = "../../modules/lxc"

  node_name         = "batman01"
  hostname          = "vault"
  pool_id           = "iac"
  template_file_id  = "local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
  disk_datastore_id = "local-zfs"
  disk_size_gb      = 8
  cores             = 1
  memory_mb         = 1024
  ipv4_address      = "192.168.8.91/24"
  ipv4_gateway      = "192.168.8.1"
  ssh_public_keys   = var.ssh_public_keys

  # nesting=true no es solo para Docker: el template Ubuntu 26.04 trae
  # systemd 259, que necesita nesting para operar bien dentro de un LXC sin
  # privilegios (cgroups/namespaces) - sin esto, servicios como
  # systemd-networkd se quedan a medias y el contenedor queda "running" pero
  # sin red (visto en la practica: warning del provider + 0 bytes de red).
  # Vault mismo se instala nativo (paquete oficial, systemd), no en Docker.
  nesting = true
}

output "vault_ip" {
  value       = module.vault.ipv4_address
  description = "IP del contenedor de Vault"
}

output "vault_vm_id" {
  value       = module.vault.vm_id
  description = "VMID asignado por Proxmox"
}
