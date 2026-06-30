#!/usr/bin/env bash
set -euo pipefail

# Regenerate golden images on Linux, the canonical platform for our goldens.
# Goldens render differently on macOS vs Linux, so the *.png baselines are
# always generated under Linux to match the ubuntu-latest CI runner. The golden
# tests themselves skip on non-Linux hosts (skip: !Platform.isLinux).
#
# Run from the repo root with podman/docker:
#   podman run --rm --platform linux/amd64 \
#     -v "$PWD":/repo:Z ghcr.io/cirruslabs/flutter:stable \
#     bash /repo/tool/update_goldens.sh
#
# Pin the bundled Flutter SDK to the exact version CI uses (3.44.1) so golden
# rendering is byte-identical to the ubuntu-latest CI runner.
cd /sdks/flutter
git config --global --add safe.directory '*' || true
git fetch --depth 1 origin refs/tags/3.44.1:refs/tags/3.44.1
git checkout 3.44.1
flutter --version
flutter precache --universal >/dev/null

cd /repo
echo "=== pub get ==="
flutter pub get
echo "=== build_runner ==="
dart run build_runner build --delete-conflicting-outputs
echo "=== update goldens ==="
flutter test --update-goldens \
  test/ui/today/risk_display_golden_test.dart \
  test/ui/shared/mascot/blob_painter_golden_test.dart \
  test/ui/shared/mascot/mascot_golden_test.dart
echo "=== DONE ==="
