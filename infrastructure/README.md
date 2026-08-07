# Runtime Deployment

`compose.yaml` is the public deployment definition used by Raspberry Pi
devices. At every boot, the image downloads the current version from the
`main` branch and starts it with Docker Compose.

## Services

| Service          | Initial image                   | Host access              |
| ---------------- | ------------------------------- | ------------------------ |
| Portainer        | `portainer/portainer-ce:2.21.5` | `https://<pi-host>:9443` |
| Backend example  | `traefik/whoami:v1.10.3`        | `http://<pi-host>:8080`  |
| Frontend example | `nginx:1.27-alpine`             | `http://<pi-host>:8081`  |

Portainer asks for its administrator password on first access and stores its
state in the `portainer_data` Docker volume.

## Updates

Watchtower checks Docker Hub once per hour and only updates the services marked
with `com.centurylinklabs.watchtower.enable: "true"`. Initially these are the
`backend` and `frontend` example services. Portainer and Watchtower themselves
are deliberately excluded.

To deploy the actual application later, replace the `backend` and `frontend`
`image` values with the desired Docker Hub image names and tags. The changed
Compose file is used at the next Pi reboot. A mutable application tag can then
be updated by Watchtower; an immutable tag changes only after updating the
Compose file and rebooting the Pi.

Because `main` is a boot-time deployment channel, protect it with branch
protection and review requirements. Revert a deployment by reverting its commit
on `main` and rebooting the affected Pi.
