# 2026-09-05 — Fix del módulo: `firewall=1` faltante en las interfaces de red

Al configurar `pve-firewall` para restringir el acceso a Vault (LXC 103, ver
[`vault-secrets`](https://github.com/gaelsg/vault-secrets) para el detalle
completo), las reglas escritas en `/etc/pve/firewall/103.fw` no se aplicaban --
faltaba el flag `firewall=1` en la interfaz de red del contenedor
(`/etc/pve/lxc/103.conf`, línea `net0`), que el módulo compartido `modules/lxc`
nunca seteaba.

Corregido en `modules/lxc/main.tf`: el bloque `network_interface` ahora incluye
`firewall = true` siempre. Aplica a partir de la próxima LXC nueva creada con este
módulo -- las LXC existentes (100-107, salvo la 103 ya corregida a mano) no se
retro-actualizaron en esta vuelta porque no tienen reglas `.fw` restrictivas
propias, así que el flag no cambia nada de seguridad activo todavía ahí.
