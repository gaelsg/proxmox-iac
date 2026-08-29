output "vm_id" {
  value       = proxmox_virtual_environment_container.this.vm_id
  description = "VMID asignado por Proxmox"
}

output "ipv4_address" {
  value       = var.ipv4_address
  description = "IP estatica asignada al contenedor"
}
