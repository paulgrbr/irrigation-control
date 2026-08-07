#!/bin/bash -e

# Prepare directories and install runtime bootstrap files into target rootfs.
install -d -m 0755 "${ROOTFS_DIR}/opt/irrigation-control"
install -d -m 0755 "${ROOTFS_DIR}/usr/local/sbin"
install -d -m 0755 "${ROOTFS_DIR}/etc/systemd/system"
install -m 0755 files/irrigation-control-bootstrap \
  "${ROOTFS_DIR}/usr/local/sbin/irrigation-control-bootstrap"
install -m 0755 files/irrigation-control-display \
  "${ROOTFS_DIR}/usr/local/sbin/irrigation-control-display"
install -m 0644 files/irrigation-control-bootstrap.service \
  "${ROOTFS_DIR}/etc/systemd/system/irrigation-control-bootstrap.service"