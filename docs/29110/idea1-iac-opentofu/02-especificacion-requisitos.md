# Especificación de Requisitos — Idea 1: IaC (OpenTofu)

Según proceso **SI.2 (Software Requirements Analysis)** del Perfil Básico ISO/IEC 29110.

## Requisitos funcionales

| ID | Requisito |
|---|---|
| RF1 | El sistema debe crear un contenedor LXC en el nodo `batman01` a partir de un template Debian, especificando vía variables: hostname, recursos (vCPU/RAM/disco), IP estática y pool de Proxmox. |
| RF2 | El módulo debe ser reusable — parametrizado, no hardcodeado al primer caso de uso (`observability`), para que futuras ideas (ej. Idea 6, VM para k3s) lo reutilicen sin duplicar código. |
| RF3 | El estado de Tofu debe reflejar con precisión el recurso real en Proxmox — `tofu plan` sin cambios pendientes tras un `apply` exitoso (sin drift inmediato). |
| RF4 | Debe ser posible destruir y recrear el recurso de forma idempotente (`tofu destroy && tofu apply` produce el mismo resultado). |

## Requisitos no funcionales

| ID | Requisito |
|---|---|
| RNF1 | Credenciales del provider (token de Proxmox) nunca en texto plano en archivos versionados — solo vía variables de entorno o `.tfvars` gitignored. |
| RNF2 | El usuario/token de Proxmox usado por Tofu debe operar con privilegio mínimo: alcance limitado al pool `iac` y a los storages estrictamente necesarios (`local`, `local-zfs`) — no `/` completo, siguiendo el mismo criterio ya aplicado a `mcp-agent` en `proxmox-mcp-server`. |
| RNF3 | El código debe correr con OpenTofu (no Terraform propietario) — decisión consciente de usar la variante open-source tras el cambio de licencia de HashiCorp en 2023. |
| RNF4 | El módulo debe documentar sus variables y outputs (vía `variables.tf`/`outputs.tf` con `description`), suficiente para que alguien sin contexto previo entienda qué configura sin leer el `.tf` completo. |

## Trazabilidad
RF1-RF4 cubren el objetivo del plan ("reemplazar aprovisionamiento manual por declarativo"). RNF1-RNF2 heredan directamente el criterio de seguridad ya establecido en todo el proyecto "Modo Ingeniería" (credenciales dedicadas, mínimo privilegio) — no son requisitos nuevos, son la aplicación del mismo estándar a una herramienta nueva.
