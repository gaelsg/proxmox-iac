# proxmox-iac

Infraestructura como código para el cluster Proxmox VE casero (`batman01`), vía [OpenTofu](https://opentofu.org/) + el provider [`bpg/proxmox`](https://registry.terraform.io/providers/bpg/proxmox/latest). Idea 1 de un roadmap de 6 (IaC → Secretos → Observabilidad → CI/CD → Evals de RAG → Kubernetes), pensado para dejar aprendizaje aplicable a infraestructura de cualquier tamaño, no solo homelab.

Documentación formal bajo `docs/29110/` (Perfil Básico de ISO/IEC 29110). `docs/bitacora/` es el diario de implementación.

## Alcance

Solo gestiona **infraestructura nueva** — LXC 100 (Nextcloud) y 101 (docker-host) de este mismo homelab se quedan gestionados a mano, deliberadamente, para no arriesgar servicios en uso diario con un `terraform import` prematuro. Ver [decisión completa](docs/29110/idea1-iac-opentofu/01-plan-proyecto.md).

## Arquitectura

```
modules/lxc/              # modulo reusable: 1 LXC parametrizado
environments/
  observability/          # primer caso de uso: LXC para la Idea 3 (Prometheus/Grafana/Alertmanager)
```

Cada ambiente nuevo (ej. una VM para k3s en la Idea 6) instancia el mismo módulo con sus propios parámetros.

## Seguridad: usuario y token dedicados

`tofu@pve`, sin privilege separation en su token (identidad de un solo propósito, no hay nada que separar). Permisos, todos scoped, ninguno en `/`:

| Path | Rol | Para qué |
|---|---|---|
| `/pool/iac` | `PVEVMAdmin` (integrado) | ciclo de vida de VM/CT — todo lo que Tofu crea vive en este pool |
| `/storage/local`, `/storage/local-zfs` | `TofuStorage` (custom: `Datastore.AllocateSpace`, `Datastore.AllocateTemplate`, `Datastore.Audit`) | reservar espacio de disco y leer templates |
| `/sdn/zones/localnetwork` | `PVESDNUser` (integrado) | adjuntar la interfaz de red — Proxmox reciente lo exige incluso para un bridge simple |

SSH a los contenedores provisionados vía llave dedicada (`~/.ssh/id_ed25519_iac`), no la llave personal.

## Setup

```bash
sudo pacman -S opentofu   # ya en repos oficiales de Arch/CachyOS, sin AUR

cd environments/observability
cp terraform.tfvars.example terraform.tfvars   # completar con el token de tofu@pve
tofu init
tofu plan
tofu apply
```

## Estado

State local (`*.tfstate`, gitignored) — un solo operador, sin necesidad de backend remoto con locking todavía. Se reevaluará si algún día un pipeline de CI (Idea 4) llega a correr `tofu apply` automáticamente.
