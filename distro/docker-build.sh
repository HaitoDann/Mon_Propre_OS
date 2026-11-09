#!/usr/bin/env bash
# Construit l'ISO dans un conteneur Debian 13, depuis n'importe quelle machine Linux avec Docker.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

docker run --rm --privileged \
	-v "$ROOT":/src -w /src \
	debian:trixie \
	bash -c "apt-get update && apt-get install -y --no-install-recommends live-build librsvg2-bin rsync ca-certificates fonts-inter && ./distro/build.sh"
