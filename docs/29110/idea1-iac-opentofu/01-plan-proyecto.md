# Plan de Proyecto — Idea 1: Infraestructura como Código (OpenTofu)

Documento de planificación según el proceso **PM.1 (Project Management)** del Perfil Básico de ISO/IEC 29110 para VSE (Very Small Entities). Adaptado a una entidad de una sola persona: alcance y formato deliberadamente ligeros.

## Objetivo
Reemplazar el aprovisionamiento manual de infraestructura en Proxmox VE (hecho hasta ahora vía UI, como en LXC 100/101) por definiciones declarativas versionadas en Git, usando OpenTofu, para toda infraestructura **nueva** de aquí en adelante.

## Alcance

**Incluye:**
- Módulo reusable de OpenTofu para crear contenedores LXC en el nodo `batman01`.
- Un primer ambiente concreto (`environments/observability`) que instancia ese módulo para crear el LXC que usará la Idea 3 (Observabilidad: Prometheus/Grafana/Alertmanager).
- Usuario y token de Proxmox dedicados (`tofu@pve`), con permisos mínimos necesarios (pool `iac` + storage `local`/`local-zfs`), sin tocar los permisos de `mcp-agent` existentes.
- Documentación ISO/IEC 29110 (este set de 4 documentos) + bitácora de implementación.

**No incluye (fuera de alcance, explícitamente):**
- Importar a Terraform la infraestructura ya existente (LXC 100 Nextcloud, LXC 101 docker-host) — decisión tomada con el usuario para no arriesgar servicios en uso diario. Ver [[decision-alcance-iac]] en la bitácora.
- Backend remoto de estado (state file queda local, gitignored) — un solo operador, no hay necesidad de locking distribuido todavía. Se reevaluará cuando exista CI/CD (Idea 4) aplicando cambios de infraestructura.
- Instalar software dentro del LXC creado (Prometheus, Grafana, etc.) — eso es responsabilidad de la Idea 3, este proyecto solo entrega el contenedor provisionado y accesible por red/SSH.

## Entregables
1. Repo `proxmox-iac` en GitHub (público), con módulo `modules/lxc` y ambiente `environments/observability`.
2. LXC real, provisionado y verificado, corriendo en `batman01`.
3. Esta serie de documentos 29110 + entrada de bitácora.

## Riesgos identificados
| Riesgo | Mitigación |
|---|---|
| Permisos del rol `tofu@pve` insuficientes o excesivos en el primer intento | Empezar con el set mínimo documentado en el diseño; iterar si `tofu apply` falla por permisos (mismo patrón que la saga de RBAC de Portainer en Idea 3 del roadmap anterior) |
| Credenciales del token en texto plano en `.tfvars` | `.gitignore` cubre `*.tfvars` desde el primer commit; solo se versiona `*.tfvars.example` |
| Cambios manuales futuros en el LXC generen drift no detectado | Fuera de alcance de v1; documentado como mejora futura (posible CI que corra `tofu plan` periódicamente) |

## Criterios de aceptación
- `tofu plan` y `tofu apply` corren limpio contra el pool `iac`.
- El LXC resultante es alcanzable por red desde la workstation (ping + puerto SSH).
- `tofu destroy` + `tofu apply` reproduce el mismo resultado (prueba de idempotencia/reproducibilidad — el punto central de IaC).
- Ningún secreto (token de Proxmox) queda en el historial de Git.
