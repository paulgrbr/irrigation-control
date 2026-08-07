#!/bin/bash -e

# Prepare directories and install runtime bootstrap files into target rootfs.
install -d -m 0755 "${ROOTFS_DIR}/opt/irrigation-control"
install -d -m 0755 "${ROOTFS_DIR}/usr/local/sbin"
install -d -m 0755 "${ROOTFS_DIR}/etc/systemd/system"
if [ -n "${PORTAINER_ADMIN_PASSWORD:-}" ]; then
  install -d -m 0755 "${ROOTFS_DIR}/etc/default"
  {
    printf 'PORTAINER_ADMIN_USERNAME=%q\n' "${PORTAINER_ADMIN_USERNAME:-irrigation}"
    printf 'PORTAINER_ADMIN_PASSWORD=%q\n' "${PORTAINER_ADMIN_PASSWORD}"
  } >"${ROOTFS_DIR}/etc/default/irrigation-control-bootstrap"
  chmod 0600 "${ROOTFS_DIR}/etc/default/irrigation-control-bootstrap"
fi
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
