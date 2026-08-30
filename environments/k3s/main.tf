module "k3s" {
  source = "../../modules/lxc"

  node_name         = "batman01"
  hostname          = "k3s"
  pool_id           = "iac"
  template_file_id  = "local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
  disk_datastore_id = "local-zfs"
  disk_size_gb      = 20
  cores             = 4
  memory_mb         = 4096
  ipv4_address      = "192.168.8.92/24"
  ipv4_gateway      = "192.168.8.1"
  ssh_public_keys   = var.ssh_public_keys

  # k3s (containerd por debajo) dentro de un LXC sin privilegios necesita
  # nesting (namespaces/cgroups anidados, mismo motivo que observability/vault).
  #
  # keyctl tambien suele recomendarse para containerd, pero NO se puede setear
  # con el token tofu@pve: Proxmox devuelve 403 "changing feature flags
  # (except nesting) is only allowed for root@pam" incluso en la creacion del
  # contenedor, no solo al actualizarlo -- a diferencia del error de SDN.Use
  # de la Idea 1, esto no es una ACL que se pueda otorgar via un rol: esta
  # hardcodeado a nivel de Proxmox, solo nesting tiene esa excepcion. Se
  # prueba primero sin keyctl (kernels/Proxmox recientes a veces alcanzan);
  # si k3s lo necesita de verdad, se habilita a mano como root@pam despues
  # del apply (`pct set <vmid> -features nesting=1,keyctl=1`), documentado
  # como paso manual explicito, no automatizable con este token.
  nesting = true
}

output "k3s_ip" {
  value       = module.k3s.ipv4_address
  description = "IP del contenedor de k3s"
}

output "k3s_vm_id" {
  value       = module.k3s.vm_id
  description = "VMID asignado por Proxmox"
}
