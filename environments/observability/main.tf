module "observability" {
  source = "../../modules/lxc"

  node_name         = "batman01"
  hostname          = "observability"
  pool_id           = "iac"
  template_file_id  = "local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
  disk_datastore_id = "local-zfs"
  disk_size_gb      = 16
  cores             = 2
  memory_mb         = 2048
  ipv4_address      = "192.168.8.90/24"
  ipv4_gateway      = "192.168.8.1"
  ssh_public_keys   = var.ssh_public_keys

  # Idea 3 (Observabilidad) va a correr Prometheus/Grafana/Alertmanager como
  # contenedores Docker aqui adentro, mismo patron que docker-host (LXC 101) -
  # nesting se habilita ahora para no tener que recrear el LXC despues.
  nesting = true
}

output "observability_ip" {
  value       = module.observability.ipv4_address
  description = "IP del contenedor de observabilidad"
}

output "observability_vm_id" {
  value       = module.observability.vm_id
  description = "VMID asignado por Proxmox"
}
