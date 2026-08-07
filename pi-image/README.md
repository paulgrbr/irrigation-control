# Raspberry Pi Image

The GitHub Actions workflow builds a plain Raspberry Pi OS Lite image for ARM64
devices. It currently uses the standard pi-gen stages `stage0`, `stage1`, and
`stage2` only. No irrigation application, network configuration, packages, or
custom services are installed yet.

## Build

The workflow at `.github/workflows/build-pi-image.yml` runs manually and for
pushes to `main` that change the workflow or files below `pi-image/`.

Before running it, add the repository Actions secret
`PI_IMAGE_SSH_PUBLIC_KEY`. Its value must be one complete OpenSSH public-key
line, for example the contents of a `.pub` key file. The resulting image:

- targets ARM64 Raspberry Pi devices;
- is based on Raspberry Pi OS Trixie Lite;
- uses hostname `irrigation-control`;
- creates the `irrigation` user;
- enables SSH public-key authentication only; and
- uses German locale, keyboard layout, and the `Europe/Berlin` timezone.

After a successful build, download the `irrigation-control-lite-arm64` artifact
from the workflow run and flash the ZIP image using Raspberry Pi Imager or a
comparable tool.

## Future Customization

Custom pi-gen stages and filesystem overlays belong in this directory. Add such
stages to the workflow's `stage-list` only when application installation or
device-specific configuration is introduced.
