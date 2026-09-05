module "pki" {
  source = "../../modules/lxc"

  node_name         = "batman01"
  hostname          = "pki"
  pool_id           = "iac"
  template_file_id  = "local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
  disk_datastore_id = "local-zfs"
  disk_size_gb      = 10
  cores             = 2
  memory_mb         = 1024
  ipv4_address      = "192.168.8.95/24"
  ipv4_gateway      = "192.168.8.1"
  ssh_public_keys   = var.ssh_public_keys

  # nesting=true: step-ca corre via Docker (imagen oficial smallstep/step-ca).
  # Liviano -- una sola CA interna, sin base de datos externa, storage propio
  # en el volumen del contenedor.
  nesting = true
}

output "pki_ip" {
  value       = module.pki.ipv4_address
  description = "IP del contenedor de step-ca"
}

output "pki_vm_id" {
  value       = module.pki.vm_id
  description = "VMID asignado por Proxmox"
}
