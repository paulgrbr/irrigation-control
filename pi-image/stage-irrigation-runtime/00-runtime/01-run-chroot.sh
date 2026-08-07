#!/bin/bash -e

# Grant Docker CLI access to the default user and enable startup services.
usermod -aG docker irrigation
systemctl enable docker.service
systemctl enable irrigation-control-bootstrap.service