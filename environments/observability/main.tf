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

  # nesting=true por dos razones: Idea 3 va a correr Prometheus/Grafana/
  # Alertmanager como contenedores Docker aqui (mismo patron que docker-host,
  # LXC 101), Y ademas el template Ubuntu 26.04 (systemd 259) lo necesita para
  # operar bien dentro de un LXC sin privilegios aunque no se use Docker -
  # confirmado al crear el LXC de vault sin nesting, que quedo "running" pero
  # sin red hasta activarlo. Ver docs/29110/idea1-iac-opentofu/04-verificacion.md.
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
