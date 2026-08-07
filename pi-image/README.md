# Raspberry Pi Image

The GitHub Actions workflow builds a plain Raspberry Pi OS Lite image for ARM64
devices. It currently uses the standard pi-gen stages `stage0`, `stage1`, and
`stage2` only. No irrigation application, network configuration, packages, or
custom services are installed yet.

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
  first boot. SSH password authentication remains disabled.

The workflow validates both secrets before starting the image build. The
resulting image:

- targets ARM64 Raspberry Pi devices;
- is based on Raspberry Pi OS Trixie Lite;
- uses hostname `irrigation-control`;
- creates the `irrigation` user;
- enables SSH public-key authentication only; and
- uses German locale, keyboard layout, and the `Europe/Berlin` timezone.

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

Custom pi-gen stages and filesystem overlays belong in this directory. Add such
stages to the workflow's `stage-list` only when application installation or
device-specific configuration is introduced.
