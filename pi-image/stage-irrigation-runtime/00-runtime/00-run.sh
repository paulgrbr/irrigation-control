#!/bin/bash -e

# Prepare directories and install runtime bootstrap files into target rootfs.
install -d -m 0755 "${ROOTFS_DIR}/opt/irrigation-control"
install -d -m 0755 "${ROOTFS_DIR}/usr/local/sbin"
install -d -m 0755 "${ROOTFS_DIR}/etc/systemd/system"
portainer_admin_hash_file="../.portainer-admin-password.hash"
portainer_admin_override="${ROOTFS_DIR}/opt/irrigation-control/compose.portainer-admin.yaml"

if [ ! -r "$portainer_admin_hash_file" ]; then
  echo "Missing Portainer admin password hash: ${portainer_admin_hash_file}" >&2
  exit 1
fi

IFS= read -r portainer_admin_password_hash < "$portainer_admin_hash_file"
if [[ ! "$portainer_admin_password_hash" =~ ^\$2[aby]\$[0-9]{2}\$[./A-Za-z0-9]{53}$ ]]; then
  echo "Invalid Portainer admin bcrypt hash." >&2
  exit 1
fi

# Docker Compose expands a single dollar sign; use a doubled one in the override.
portainer_admin_password_hash_for_compose="${portainer_admin_password_hash//$/\$\$}"
{
  printf 'services:\n'
  printf '  portainer:\n'
  printf '    command:\n'
  printf '      - "--admin-password=%s"\n' "$portainer_admin_password_hash_for_compose"
} >"$portainer_admin_override"
chmod 0600 "$portainer_admin_override"
install -m 0755 files/irrigation-control-bootstrap \
  "${ROOTFS_DIR}/usr/local/sbin/irrigation-control-bootstrap"
install -m 0755 files/irrigation-control-display-early \
  "${ROOTFS_DIR}/usr/local/sbin/irrigation-control-display-early"
install -m 0755 files/irrigation-control-display \
  "${ROOTFS_DIR}/usr/local/sbin/irrigation-control-display"
install -m 0644 files/irrigation-control-display-early.service \
  "${ROOTFS_DIR}/etc/systemd/system/irrigation-control-display-early.service"
install -m 0644 files/irrigation-control-bootstrap.service \
  "${ROOTFS_DIR}/etc/systemd/system/irrigation-control-bootstrap.service"
