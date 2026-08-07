# Runtime Deployment

`compose.yaml` is the public deployment definition used by Raspberry Pi
devices. At every boot, the image downloads the current version from the
`main` branch and starts it with Docker Compose.

## Services

| Service          | Initial image                                | Host access              |
| ---------------- | -------------------------------------------- | ------------------------ |
| Portainer        | `portainer/portainer-ce:2.21.5`              | `https://<pi-host>:9443` |
| Backend          | `paulgrbr/irrigation-control-backend:latest` | `http://<pi-host>:8080`  |
| Frontend example | `nginx:1.27-alpine`                          | `http://<pi-host>:8081`  |

Portainer's first administrator is bootstrapped automatically during the Pi's
first boot. The image creates the single `irrigation` admin account with the
same password as the initial image user. Portainer stores its state in the
`portainer_data` Docker volume.

The backend waits until the Pi bootstrap has finished its LCD progress display.
It then writes `Willkommen` to the attached 20x4 I2C LCD and activates each
relay once. It uses BCM GPIO pins `17, 27, 22, 10, 5, 9, 6, 11`; these match
`pins.sh`. The relays are LOW-active. The service needs privileged device access
because it operates the Pi GPIO controller and I2C bus.

The backend responds on `http://<pi-host>:8080/health` while it waits for this
handoff, so the Pi bootstrap can finish. A relay-test failure later reports HTTP
503 and writes the failure to the LCD and container log.

## Updates

Watchtower checks Docker Hub once per hour and only updates the services marked
with `com.centurylinklabs.watchtower.enable: "true"`. Initially these are the
`backend` and `frontend` example services. Portainer and Watchtower themselves
are deliberately excluded.

`publish-backend.yml` builds an ARM64 image on every `main` change below
`apps/backend/` and pushes both `latest` and the Git commit SHA to Docker Hub.
It requires these repository Actions secrets:

- `DOCKERHUB_USERNAME`: Docker Hub account that owns `paulgrbr/irrigation-control-backend`.
- `DOCKERHUB_TOKEN`: Docker Hub access token with write permission for that repository.

Watchtower observes the mutable `latest` tag hourly and restarts the backend
when a new image is available. The changed Compose file is used at the next Pi
reboot.

Because `main` is a boot-time deployment channel, protect it with branch
protection and review requirements. Revert a deployment by reverting its commit
on `main` and rebooting the affected Pi.
