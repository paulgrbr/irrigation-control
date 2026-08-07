# Raspberry Pi Image

The GitHub Actions workflow builds a plain Raspberry Pi OS Lite image for ARM64
devices. It combines the standard pi-gen Lite stages with a project stage that
installs Docker and configures the runtime deployment.

## Current Configuration

| Area              | Configuration                                             |
| ----------------- | --------------------------------------------------------- |
| Architecture      | ARM64                                                     |
| Base system       | Raspberry Pi OS Trixie Lite                               |
| pi-gen source     | `RPi-Distro/pi-gen` tag `2026-06-18-raspios-trixie-arm64` |
| Build stages      | Lite stages plus `stage-irrigation-runtime`               |
| Hostname          | `irrigation-control`                                      |
| Initial user      | `irrigation`                                              |
| Locale            | `de_DE.UTF-8`                                             |
| Keyboard          | German layout and `de` keymap                             |
| Timezone          | `Europe/Berlin`                                           |
| SSH               | Enabled; public-key authentication only                   |
| Container runtime | Docker Engine and Docker Compose                          |
| Container updates | Watchtower checks labeled app containers hourly           |
| Image format      | ZIP-compressed Lite image with SHA-256 checksum           |

The `irrigation` user is created during the image build and is not renamed on
first boot. Its local console password comes from a GitHub Actions secret. The
image contains no Wi-Fi credentials or static network configuration.

## Runtime Deployment

At every boot, `irrigation-control-bootstrap.service` waits for Docker and
network connectivity, downloads the current
`infrastructure/compose.yaml` from the public `main` branch, validates it, and
starts the stack. The local downloaded definition is stored at
`/opt/irrigation-control/compose.yaml`.

The initial stack provides Portainer at `https://<pi-host>:9443` plus runnable
backend and frontend example services on ports `8080` and `8081`. Details,
including how to replace the examples with Docker Hub application images, are
in `infrastructure/README.md`.

## Updates

The project does not currently install or configure automatic operating-system
package updates.
In particular, the selected pi-gen Lite stages do not install
`unattended-upgrades`. APT package-list refresh timers can still be supplied by
the base operating system; refreshing package lists does not install updates.

The application containers use Watchtower. It polls Docker Hub once per hour
and updates only the `backend` and `frontend` containers, which have an explicit
opt-in label. Portainer and Watchtower are not updated automatically. Changes
to the Compose definition itself are downloaded and applied on the next Pi
reboot.

## Build

The workflow at `.github/workflows/build-pi-image.yml` runs manually and for
pushes to `main` that change the workflow or files below `pi-image/`.

Before running it, add these repository Actions secrets:

- `PI_IMAGE_SSH_PUBLIC_KEY`: One complete OpenSSH public-key line, for example
  the contents of a `.pub` key file. Do not store a private key, a PEM file,
  shell command, quotation marks, or Markdown code fences in this secret. On
  macOS, `cat ~/.ssh/id_ed25519.pub` prints a suitable value.
- `PI_IMAGE_USER_PASSWORD`: A strong password for the `irrigation` user's local
  console login. pi-gen requires this to keep the configured username after
  first boot. The same secret is also reused for Portainer's initial admin
  account. SSH password authentication remains disabled.

The workflow validates both secrets before starting the image build. The
password permits a local console login only. Because `pubkey-only-ssh: 1` is
configured, SSH password authentication remains disabled.

After a successful build, download the `irrigation-control-lite-arm64` artifact
from the workflow run and flash the ZIP image using Raspberry Pi Imager or a
comparable tool. The artifact includes a `.sha256` checksum file. Verify the
download before flashing it with `shasum -a 256 -c <image-file>.sha256`.

## Reproducibility

The workflow pins the GitHub Actions to immutable commit IDs and uses the
published `RPi-Distro/pi-gen` ARM64/Trixie release tag. Image name, Raspberry
Pi OS release, and pi-gen stages are central workflow constants, so a specific
Git commit describes the intended build input completely.

The GitHub runner image and Raspberry Pi OS packages are fetched at build time.
Consequently, rebuilding the same repository commit later can produce different
bytes, change behavior, or fail if upstream repositories are no longer
available. Workflow artifacts expire after 14 days and are not a long-term
archive. For every deployed image, create a Git tag and retain the image and
its checksum in a GitHub Release or external artifact storage. A bit-identical
rebuild years later additionally requires an archived APT snapshot or a
controlled package mirror.

## Future Customization

The custom pi-gen stage is `stage-irrigation-runtime`. Add later image-time
configuration in another numbered directory below that stage, or add a separate
external stage after it in the workflow's `stage-list`.
