# Diseño — Idea 1: IaC (OpenTofu)

Según proceso **SI.3 (Software Architecture and Detailed Design)** del Perfil Básico ISO/IEC 29110.

## Arquitectura

```
proxmox-iac/
├── modules/lxc/              # modulo reusable: 1 LXC parametrizado
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── environments/
    └── observability/        # primer caso de uso concreto del modulo
        ├── providers.tf
        ├── variables.tf
        ├── main.tf
        └── terraform.tfvars.example
```

Patrón **módulo + ambientes**, no un único `main.tf` monolítico: cada ambiente (`observability` hoy, `k3s` en la Idea 6 más adelante) instancia el mismo módulo `lxc` con sus propios parámetros. Evita duplicar la definición del recurso cada vez que se necesita un contenedor nuevo.

## Decisiones técnicas

**OpenTofu, no Terraform.** Fork open-source tras el cambio de licencia BSL de HashiCorp (2023), gobernado por Linux Foundation. Sintaxis idéntica a Terraform — el provider `bpg/proxmox` se instala igual desde ambos registries.

**Provider `bpg/proxmox`, no `telmate/proxmox`.** Es el mantenido activamente a 2026; `telmate/proxmox` lleva tiempo con poco mantenimiento. Recurso usado: `proxmox_virtual_environment_container`.

**Pool `iac` como límite de aislamiento.** Todo lo que Tofu gestiona vive en ese pool. El usuario dedicado `tofu@pve` solo tiene `PVEVMAdmin` ahí — no puede tocar LXC 100/101 aunque quisiera, ni por accidente en un `apply` mal escrito.

**Permisos compuestos, no un rol monolítico.** En vez de un único rol custom con todos los privilegios, se usa el rol integrado `PVEVMAdmin` (ciclo de vida de VM/CT) en `/pool/iac`, más un rol custom mínimo `TofuStorage` (`Datastore.AllocateSpace`, `Datastore.AllocateTemplate`, `Datastore.Audit`) en `/storage/local` y `/storage/local-zfs` — porque Proxmox valida el permiso de asignar espacio contra el path del *storage*, no contra el pool del recurso. Mismo principio de mínimo privilegio que `mcp-agent`, aplicado con la topología de ACLs correcta para este caso.

Un tercer permiso se agregó durante la verificación, no estaba previsto en el diseño original: el rol integrado `PVESDNUser` (`SDN.Audit`, `SDN.Use`) en `/sdn/zones/localnetwork`. Proxmox VE reciente exige `SDN.Use` incluso para adjuntar una interfaz de red a un bridge simple como `vmbr0`, porque lo envuelve en una zona SDN implícita. Ver [[04-verificacion]] para el detalle del incidente.

**Token sin privilege separation.** A diferencia de `mcp-agent` (que sí la usa, para separar su token de lectura del de escritura sobre la misma identidad), `tofu@pve` es una identidad de un solo propósito — no hay nada que separar dentro de ella misma.

**Template usado: el que ya existe en el nodo.** `local:vztmpl/ubuntu-26.04-standard_26.04-1_amd64.tar.zst` ya estaba descargado (usado para LXC 100/101 probablemente) — se reutiliza en vez de bajar un template Debian nuevo, para no depender de `Datastore.AllocateTemplate` funcionando correctamente en el primer `apply` (igual se le da el permiso, por si se necesita a futuro).

**IP estática `192.168.8.90/24`.** Mismo esquema manual que ya usa el resto de la infra (100→.88, 101→.82) — verificada libre antes de asignarla (`ping` sin respuesta).

**SSH key dedicada, no la personal.** `~/.ssh/id_ed25519_iac` generada específicamente para infraestructura provisionada por Tofu — no se reutiliza ninguna llave de otro propósito (no existía ninguna en esta máquina antes de este proyecto).

**`nesting = true` en el ambiente `observability`, decidido con anticipación.** La Idea 3 (Observabilidad) casi con certeza va a correr Prometheus/Grafana/Alertmanager como contenedores Docker dentro de este LXC, igual que `docker-host`. Nesting no se puede activar sin reiniciar el contenedor después — se prefiere pagar ese costo ahora, en la creación, documentado explícitamente aquí como una decisión que técnicamente pertenece a la Idea 3 pero que había que tomar en la Idea 1.

**State local, sin backend remoto (por ahora).** Un solo operador (yo), sin necesidad de locking distribuido. Se reevaluará al llegar a CI/CD (Idea 4) — si un pipeline llega a correr `tofu apply`, ahí sí hace falta backend remoto con locking para evitar carreras entre ejecuciones manuales y automatizadas.

## Fuera de diseño (explícitamente)
Nada de esto se decide aquí — queda para cuando llegue su idea correspondiente:
- Qué se instala dentro del contenedor (Idea 3).
- Backend remoto de state (Idea 4, si aplica).
- Cómo se inyecta el secret del token de Proxmox sin vivir en un `.tfvars` local (Idea 2, secretos).
