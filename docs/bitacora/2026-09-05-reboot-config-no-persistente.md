# 2026-09-05 — Config no persistente que el reinicio del kernel dejó al descubierto

Surgió como efecto secundario del trabajo de seguridad de red del día (segmentación
con `pve-firewall`): al probar Nextcloud (LXC 100) desde afuera de casa vía
Tailscale (celular, datos móviles), las subidas de archivos se quedaban colgadas
indefinidamente, aunque el login/navegación parecían funcionar (datos cacheados en
la app). El firewall nuevo de Nextcloud quedó descartado como causa temprano
(verificado con el visor de logs de Proxmox: cero entradas, ni siquiera "no
content" con tráfico real pasando).

La causa real fueron **tres configuraciones que nunca se guardaron de forma
persistente**, y el reinicio de `batman01` de esta misma mañana (parche del kernel,
CVE-2026-46242) las resetó todas de un saque. Documentado para que si esto vuelve a
pasar en un reinicio futuro, el diagnóstico sea directo en vez de otra sesión larga
de prueba y error.

## 1. `net.ipv4.ip_forward` reseteado a `0`

Necesario para que `batman01` reenvíe tráfico entre la interfaz de Tailscale y la
LAN (rol de subnet router). Se había seteado alguna vez con `sysctl -w` suelto, sin
guardarlo en `/etc/sysctl.d/`. Fix aplicado y persistido:

```bash
sysctl -w net.ipv4.ip_forward=1
echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-tailscale-forwarding.conf
```

## 2. `/dev/net/tun` nunca habilitado de forma persistente en la LXC `docker-host` (101)

Una LXC sin privilegios necesita que Proxmox le habilite el dispositivo TUN
explícitamente en su config — no alcanza con montarlo como volumen en
`docker-compose.yml`, hace falta el permiso a nivel de cgroup. Nunca estaba en
`/etc/pve/lxc/101.conf`. Agregado:

```
lxc.cgroup2.devices.allow: c 10:200 rwm
lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file 0 0
```

(el módulo `tun` del kernel de Proxmox está compilado `builtin`, no hace falta
cargarlo aparte — se investigó como posible causa y se descartó).

## 3. El contenedor de Tailscale nunca tenía `TS_STATE_DIR`/`TS_USERSPACE` seteados

Esta es la causa raíz real, probablemente rota desde antes de hoy (no algo que el
reinicio causó, sino algo que el reinicio expuso). El volumen `/var/lib/tailscale`
estaba montado en el `docker-compose.yml` de `/root/tailscale/` (LXC 101), pero sin
`TS_STATE_DIR` apuntando ahí explícitamente, el contenedor caía al default del
propio entrypoint: `--state=mem:` (memoria, nunca a disco) y
`--tun=userspace-networking` (sin interfaz de red real, no puede hacer de subnet
router). Resultado: cada reinicio del contenedor generaba una identidad de Tailscale
nueva (`tailscale-router-2`, `-3`, `-4`...) en vez de recuperar la anterior — de ahí
la lista larga de "routers" expirados en el panel de Tailscale.

Fix en el `environment:` del compose (variables agregadas, valores reales del
`TS_AUTHKEY` existente sin tocar/exponer acá):

```yaml
- TS_USERSPACE=false
- TS_STATE_DIR=/var/lib/tailscale
```

## Verificado real

- `ip a` dentro del contenedor mostrando `tailscale0` real, con IP asignada
  (interfaz que nunca había existido en ninguno de los intentos previos).
- Ruta `192.168.8.0/24` aprobada manualmente para la nueva identidad (las
  aprobaciones de rutas no se heredan entre identidades distintas).
- Subida de fotos completada de punta a punta desde el celular, por datos móviles,
  confirmado por el usuario en vivo.

## Pendiente

- Limpiar del panel de Tailscale las identidades fantasma generadas durante el
  debugging (`tailscale-router` a `tailscale-router-5`, todas expiradas).
- Rotar el `TS_AUTHKEY` de este contenedor — quedó visible en texto plano durante
  el diagnóstico (`docker inspect`), buena práctica tratarlo como potencialmente
  expuesto aunque el riesgo real sea bajo.
- Llevar `/root/tailscale/docker-compose.yml` (hoy solo vive en la LXC, sin
  versionar) a un repo propio si se lo quiere gestionar con el mismo criterio que
  el resto del portafolio — quedó fuera de alcance por hoy, era un side-quest de
  un problema de seguridad de red, no un ítem planeado del roadmap.
