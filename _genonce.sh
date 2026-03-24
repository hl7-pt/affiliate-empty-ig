#!/bin/bash

# ──────────────────────────────────────────────
# Parse --mode flag (optional, overrides auto-detection)
#   --mode 1  force native Java
#   --mode 2  force Docker + local jar (pin publisher version)
#   --mode 3  force Docker bundled image
# ──────────────────────────────────────────────
force_mode=""
args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      force_mode="$2"
      if [[ "$force_mode" != "1" && "$force_mode" != "2" && "$force_mode" != "3" ]]; then
        echo "Error: --mode must be 1, 2, or 3"; exit 1
      fi
      shift 2 ;;
    *) args+=("$1"); shift ;;
  esac
done
set -- "${args[@]}"

# ──────────────────────────────────────────────
# Internet / terminology server check
# ──────────────────────────────────────────────
echo "Checking internet connection..."
tx_args=()
if curl -sSf tx.fhir.org > /dev/null; then
    echo "Online"
else
    echo "Offline"
    tx_args=(-tx n/a)
fi

# ──────────────────────────────────────────────
# Locate publisher.jar (input-cache first, then parent folder)
# ──────────────────────────────────────────────
publisher_jar=""
if test -f "./input-cache/publisher.jar"; then
  publisher_jar="$(realpath ./input-cache/publisher.jar)"
elif test -f "../publisher.jar"; then
  publisher_jar="$(realpath ../publisher.jar)"
fi

# ──────────────────────────────────────────────
# Check native dependencies required to run without Docker
# ──────────────────────────────────────────────
has_cmd() { command -v "$1" > /dev/null 2>&1; }

native_deps_ok=true
for dep in java ruby jekyll perl; do
  if ! has_cmd "$dep"; then
    echo "Missing dependency: $dep"
    native_deps_ok=false
  fi
done

# ──────────────────────────────────────────────
# Run strategy
# ──────────────────────────────────────────────

# Determine mode: forced or auto-detected
if [[ -n "$force_mode" ]]; then
  mode="$force_mode"
  echo "Mode forced: $mode"
elif [[ -n "$publisher_jar" && "$native_deps_ok" == true ]]; then
  mode=1
elif [[ -n "$publisher_jar" ]]; then
  mode=2
else
  mode=3
fi

# Docker: force linux/amd64 on macOS — the image has no arm64 manifest
platform_args=()
if [[ "$OSTYPE" == "darwin"* ]]; then
  platform_args=(--platform linux/amd64)
fi

case "$mode" in
  1)
    # ── Strategy 1: native Java (fastest) ──────
    if [[ -z "$publisher_jar" ]]; then
      echo "Error: --mode 1 requires publisher.jar in input-cache/ or parent folder."; exit 1
    fi
    echo "Running natively with Java: $publisher_jar"
    export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS -Dfile.encoding=UTF-8"
    java -jar "$publisher_jar" -ig . "${tx_args[@]}" "$@"
    ;;
  2)
    # ── Strategy 2: Docker + local jar ─────────
    # Uses trifork image for the full environment (Sushi, Node, etc.)
    # but overrides the bundled publisher with the local jar.
    # Useful when the local jar is newer than the bundled one in the image.
    if [[ -z "$publisher_jar" ]]; then
      echo "Error: --mode 2 requires publisher.jar in input-cache/ or parent folder."; exit 1
    fi
    echo "Using Docker with local publisher.jar: $publisher_jar"
    docker run --rm "${platform_args[@]}" \
      -v "$(pwd)":/tmp/ig \
      -v "$publisher_jar":/publisher.jar \
      -v "$HOME/.fhir":/root/.fhir \
      --entrypoint java \
      ghcr.io/trifork/ig-publisher:latest \
      -jar /publisher.jar -ig /tmp/ig "${tx_args[@]}" "$@"
    ;;
  3)
    # ── Strategy 3: Docker bundled image ───────
    echo "Using ghcr.io/trifork/ig-publisher:latest"
    docker run --rm "${platform_args[@]}" \
      -v "$(pwd)":/tmp/ig \
      -v "$HOME/.fhir":/root/.fhir \
      ghcr.io/trifork/ig-publisher:latest \
      -ig /tmp/ig "${tx_args[@]}" "$@"
    ;;
esac
