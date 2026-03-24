#!/bin/bash

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
if [[ -n "$publisher_jar" && "$native_deps_ok" == true ]]; then
  # ── Strategy 1: native Java (fastest) ──────
  echo "Running natively with Java: $publisher_jar"
  export JAVA_TOOL_OPTIONS="$JAVA_TOOL_OPTIONS -Dfile.encoding=UTF-8"
  java -jar "$publisher_jar" -ig . "${tx_args[@]}" "$@"

else
  # Docker: force linux/amd64 on macOS — the image has no arm64 manifest
  platform_args=()
  if [[ "$OSTYPE" == "darwin"* ]]; then
    platform_args=(--platform linux/amd64)
  fi

  if [[ -n "$publisher_jar" ]]; then
    # ── Strategy 2: Docker + local jar ─────────
    echo "Native deps missing. Using Docker with local publisher.jar: $publisher_jar"
    docker run --rm "${platform_args[@]}" \
      -v "$(pwd)":/tmp/ig \
      -v "$publisher_jar":/publisher.jar \
      -v "$HOME/.fhir":/root/.fhir \
      ghcr.io/fhir/ig-publisher-base \
      java -jar /publisher.jar -ig /tmp/ig "${tx_args[@]}" "$@"
  else
    # ── Strategy 3: Docker bundled image ───────
    echo "No publisher.jar found. Using ghcr.io/trifork/ig-publisher:latest"
    docker run --rm "${platform_args[@]}" \
      -v "$(pwd)":/tmp/ig \
      -v "$HOME/.fhir":/root/.fhir \
      ghcr.io/trifork/ig-publisher:latest \
      -ig /tmp/ig "${tx_args[@]}" "$@"
  fi
fi
