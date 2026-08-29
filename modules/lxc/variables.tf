variable "node_name" {
  type        = string
  description = "Nodo Proxmox donde se crea el contenedor"
}

variable "vm_id" {
  type        = number
  default     = null
  description = "VMID numerico. Si es null, Proxmox asigna el siguiente disponible"
}

variable "hostname" {
  type        = string
  description = "Hostname del contenedor"
}

variable "pool_id" {
  type        = string
  description = "Pool de Proxmox al que pertenece (aisla permisos de lo gestionado por Tofu)"
}

variable "template_file_id" {
  type        = string
  description = "volid del template LXC ya presente en storage, ej. local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst"
}

variable "os_type" {
  type        = string
  default     = "ubuntu"
  description = "Tipo de SO para el contenedor (afecta scripts de inicializacion internos de Proxmox)"
}

variable "disk_datastore_id" {
  type        = string
  default     = "local-zfs"
  description = "Storage donde vive el rootfs del contenedor"
}

variable "disk_size_gb" {
  type        = number
  default     = 8
  description = "Tamano del disco raiz en GB"
}

variable "cores" {
  type        = number
  default     = 2
  description = "vCPUs asignados"
}

variable "memory_mb" {
  type        = number
  default     = 2048
  description = "RAM asignada en MB"
}

variable "bridge" {
  type        = string
  default     = "vmbr0"
  description = "Bridge de red de Proxmox"
}

variable "ipv4_address" {
  type        = string
  description = "IP estatica con mascara CIDR, ej. 192.168.8.90/24"
}

variable "ipv4_gateway" {
  type        = string
  default     = "192.168.8.1"
  description = "Gateway de la red"
}

variable "ssh_public_keys" {
  type        = list(string)
  description = "Llaves publicas SSH autorizadas para root dentro del contenedor"
}

variable "unprivileged" {
  type        = bool
  default     = true
  description = "Contenedor sin privilegios. Desactivar solo si algo dentro lo requiere explicitamente"
}

variable "nesting" {
  type        = bool
  default     = false
  description = "Habilita nesting (necesario para correr Docker/Podman dentro del contenedor)"
}

variable "start_on_boot" {
  type        = bool
  default     = true
  description = "Arranca junto con el nodo Proxmox"
}
