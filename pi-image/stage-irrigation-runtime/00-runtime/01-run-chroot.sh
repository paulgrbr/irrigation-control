#!/bin/bash -e

# Grant Docker CLI access to the default user and enable startup services.
usermod -aG docker irrigation

service_env_file="/etc/default/irrigation-control-bootstrap"
if [ -f "$service_env_file" ]; then
	install -d -m 0755 /etc/systemd/system/irrigation-control-bootstrap.service.d
	cat >/etc/systemd/system/irrigation-control-bootstrap.service.d/10-portainer-env.conf <<'EOF'
[Service]
EnvironmentFile=-/etc/default/irrigation-control-bootstrap
EOF
fi

# Enable I2C for the LCD hardware on first boot images.
boot_config_file="/boot/firmware/config.txt"
if [ -f "$boot_config_file" ] && ! grep -Eq '^\s*dtparam=i2c_arm=on\s*$' "$boot_config_file"; then
	echo "dtparam=i2c_arm=on" >>"$boot_config_file"
fi

install -d -m 0755 /etc/modules-load.d
cat >/etc/modules-load.d/i2c-dev.conf <<'EOF'
i2c-dev
EOF

systemctl enable docker.service
systemctl enable irrigation-control-bootstrap.service
