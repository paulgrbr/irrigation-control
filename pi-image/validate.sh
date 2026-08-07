#!/bin/bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
runtime_dir="${repo_root}/pi-image/stage-irrigation-runtime/00-runtime"

for script in \
	"${runtime_dir}/00-run.sh" \
	"${runtime_dir}/01-run-chroot.sh" \
	"${runtime_dir}/files/irrigation-control-bootstrap" \
	"${runtime_dir}/files/irrigation-control-display-early"; do
	bash -n "$script"
done

python3 -m py_compile "${runtime_dir}/files/irrigation-control-display"

python3 - "${runtime_dir}/files/irrigation-control-display" <<'PY'
import importlib.util
import sys
import tempfile
import types
from importlib.machinery import SourceFileLoader
from pathlib import Path


class FakeBus:
    def __init__(self, bus_id):
        pass

    def write_byte(self, address, value):
        pass

    def close(self):
        pass


sys.modules["smbus"] = types.SimpleNamespace(SMBus=FakeBus)
script_path = sys.argv[1]
loader = SourceFileLoader("display", script_path)
spec = importlib.util.spec_from_loader("display", loader)
display = importlib.util.module_from_spec(spec)
loader.exec_module(display)

for state, (step, total) in display.STATE_META.items():
    lines = display.build_lines(state, 50, "", 0, 0, 0, 0, 0)
    assert lines[0] == "Setup"
    assert lines[1] == f"{step:02d}/{total:02d}"
    assert len(lines[3]) == display.LCD_WIDTH

assert display.build_line3("WAIT_DOCKER", "", 0, 0, 3, 30, 0) == "Docker Check 3/30"
assert display.build_line3("FETCH_COMPOSE", "", 2, 5, 0, 0, 0) == "Konfig Versuch 2/5"
assert display.build_line3("WAIT_BACKEND", "", 0, 0, 0, 0, 42) == "Health in 42s"
assert len(display.progress_bar(0)) == display.LCD_WIDTH
assert len(display.progress_bar(100)) == display.LCD_WIDTH

with tempfile.TemporaryDirectory() as temporary_directory:
	display.INIT_MARKER_PATH = Path(temporary_directory) / "display.initialized"
	render_calls = []

	def fake_render(lines, bus_id, addresses, initialize_display):
		render_calls.append(initialize_display)
		return 0

	display.render = fake_render
	sys.argv = [script_path, "--state", "BOOTING"]
	assert display.main() == 0
	sys.argv = [script_path, "--state", "READY", "--percent", "100"]
	assert display.main() == 0
	assert render_calls == [True, False]
PY

config_file="$(mktemp)"
unit_root="$(mktemp -d)"
trap 'rm -f "$config_file"; rm -rf "$unit_root"' EXIT
test_password='space quote" dollar$ slash\ single'"'"'quote'
{
	printf 'PORTAINER_ADMIN_USERNAME=%q\n' "irrigation"
	printf 'PORTAINER_ADMIN_PASSWORD=%q\n' "$test_password"
} >"$config_file"
unset PORTAINER_ADMIN_USERNAME PORTAINER_ADMIN_PASSWORD
# shellcheck disable=SC1090
. "$config_file"
[[ "$PORTAINER_ADMIN_USERNAME" = "irrigation" ]]
[[ "$PORTAINER_ADMIN_PASSWORD" = "$test_password" ]]

if command -v systemd-analyze >/dev/null 2>&1; then
	install -d "${unit_root}/etc/systemd/system"
	for target in sysinit.target basic.target network-online.target; do
		printf '[Unit]\nDescription=Validation stub\n' \
			>"${unit_root}/etc/systemd/system/${target}"
	done
	install -D -m 0755 /usr/bin/true "${unit_root}/usr/bin/true"
	for service in docker.service systemd-modules-load.service; do
		printf '[Service]\nType=oneshot\nExecStart=/usr/bin/true\n' \
			>"${unit_root}/etc/systemd/system/${service}"
	done
	install -D -m 0755 \
		"${runtime_dir}/files/irrigation-control-bootstrap" \
		"${unit_root}/usr/local/sbin/irrigation-control-bootstrap"
	install -D -m 0755 \
		"${runtime_dir}/files/irrigation-control-display-early" \
		"${unit_root}/usr/local/sbin/irrigation-control-display-early"
	install -D -m 0644 \
		"${runtime_dir}/files/irrigation-control-bootstrap.service" \
		"${unit_root}/etc/systemd/system/irrigation-control-bootstrap.service"
	install -D -m 0644 \
		"${runtime_dir}/files/irrigation-control-display-early.service" \
		"${unit_root}/etc/systemd/system/irrigation-control-display-early.service"
	systemd-analyze verify --root="$unit_root" \
		irrigation-control-bootstrap.service \
		irrigation-control-display-early.service
fi

docker compose -f "${repo_root}/infrastructure/compose.yaml" config --quiet
