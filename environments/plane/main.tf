module "plane" {
  source = "../../modules/lxc"

  node_name         = "batman01"
  hostname          = "plane"
  pool_id           = "iac"
  template_file_id  = "local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
  disk_datastore_id = "local-zfs"
  disk_size_gb      = 30
  cores             = 4
  memory_mb         = 6144
  ipv4_address      = "192.168.8.93/24"
  ipv4_gateway      = "192.168.8.1"
  ssh_public_keys   = var.ssh_public_keys

  # nesting=true: el stack de Plane corre via docker-compose (web, api, admin,
  # space, live, worker, beat-worker, postgres, redis, minio) -- mismo motivo
  # que observability (Idea 3) y ademas requisito del template Ubuntu 26.04
  # dentro de un LXC sin privilegios. Mas RAM que observability/vault (6GB vs
  # 2GB) porque el stack de Plane trae bastantes mas contenedores que
  # Prometheus+Grafana+Alertmanager.
  nesting = true
}

output "plane_ip" {
  value       = module.plane.ipv4_address
  description = "IP del contenedor de Plane"
}

output "plane_vm_id" {
  value       = module.plane.vm_id
  description = "VMID asignado por Proxmox"
}
