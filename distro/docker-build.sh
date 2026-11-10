#!/usr/bin/env bash
# Construit l'ISO dans un conteneur Debian 13, depuis n'importe quelle machine Linux avec Docker.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

docker run --rm --privileged \
	-v "$ROOT":/src -w /src \
	debian:trixie \
	bash -c "sed -i 's/^Components: main$/Components: main contrib non-free-firmware/' /etc/apt/sources.list.d/debian.sources && apt-get update && apt-get install -y --no-install-recommends live-build librsvg2-bin rsync ca-certificates fonts-inter dpkg-dev debhelper cmake python3 qt6-base-dev qt6-declarative-dev qt6-svg-dev liblayershellqtinterface-dev qml6-module-qtquick qml6-module-qtquick-window qml6-module-qtqml-workerscript qml6-module-qttest && ./distro/build.sh"
