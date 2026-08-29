# Verificación — Idea 1: IaC (OpenTofu)

Según proceso **SI.5 (Software Integration and Tests)** del Perfil Básico ISO/IEC 29110. Casos de prueba mapeados a los criterios de aceptación del [plan de proyecto](01-plan-proyecto.md).

| # | Caso de prueba | Resultado |
|---|---|---|
| 1 | `tofu plan` corre limpio contra el pool `iac` | ✅ Plan generado sin errores tras resolver permisos (ver incidentes abajo) |
| 2 | `tofu apply` crea el LXC real en `batman01` | ✅ VMID 102, `Creation complete after 4s` |
| 3 | El LXC es alcanzable por red desde la workstation | ✅ `ping` responde, puerto 22/tcp abierto, `ssh -i ~/.ssh/id_ed25519_iac root@192.168.8.90` entra y devuelve hostname correcto (`observability`) y SO correcto (`Ubuntu 26.04 LTS`) |
| 4 | `tofu plan` posterior a un `apply` exitoso no muestra cambios (sin drift) | ✅ `No changes. Your infrastructure matches the configuration.` |
| 5 | `tofu destroy` + `tofu apply` reproduce el mismo resultado | ✅ Mismo VMID (102, reasignado), misma config completa, SSH funcional tras recrear (una vez limpiada la entrada vieja de `known_hosts` — el host key cambia entre recreaciones, esperado) |
| 6 | Ningún secreto queda en el historial de Git | ✅ `terraform.tfvars` (contiene el token real) nunca se stageó — cubierto por `.gitignore` desde el primer commit; verificado con `git status` antes de cada commit |

## Incidentes durante la verificación (documentados, no ocultados)

**Token creado bajo `root@pam` en el primer intento**, no bajo `tofu@pve` como estaba diseñado — pegado en el chat, por lo tanto tratado como comprometido: revocado sin usarlo, nunca llegó a un `.tfvars`. Detectado comparando el token recibido contra lo que pedían las instrucciones, confirmado con `curl` contra la API de Proxmox (`/access/users/tofu@pve/token` devolvía `[]`) antes de aceptarlo.

**Rol `TofuStorage` con el privilegio equivocado**: quedó `Datastore.Allocate` (administrar datastores completos) en vez de `Datastore.AllocateSpace` (reservar espacio para un disco). Mismo mecanismo de detección — se listó el rol vía API (`/access/roles/TofuStorage`) en vez de asumir que la UI se configuró como se pidió. Corregido en la UI, reverificado por API antes de continuar.

**Permiso `SDN.Use` faltante**, no contemplado en el diseño original. Proxmox VE reciente envuelve incluso un bridge simple (`vmbr0`) en una zona SDN implícita (`localnetwork`), y valida `SDN.Use` sobre `/sdn/zones/localnetwork/<bridge>` al crear la interfaz de red del contenedor. Se resolvió agregando el rol integrado `PVESDNUser` (`SDN.Audit`, `SDN.Use`) en `/sdn/zones/localnetwork` con propagación — ningún selector de la UI ofrecía la ruta completa hasta el bridge, así que se usó la ruta del padre con `Propagate` en vez del path exacto del error.

## Conclusión
Los 4 criterios de aceptación del plan de proyecto se cumplen. El rol final de `tofu@pve` quedó documentado en [[03-diseno]] con una corrección respecto al diseño original (`SDN.Use` no estaba previsto) — el patrón de "iterar el rol cuando `apply` señala qué falta" es consistente con cómo se resolvió el RBAC de Portainer en un proyecto anterior del mismo roadmap: empezar mínimo, no adivinar de más.
