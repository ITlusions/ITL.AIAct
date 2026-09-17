#!/usr/bin/env bash
# Art. 11/12/15/72 — release-gate op modelartifacten.
# Gebruik: ci/check-release.sh <version-tag>
set -euo pipefail

VERSION="${1:?geef versietag}"
BUILD_DIR="${BUILD_DIR:-build}"
mkdir -p "$BUILD_DIR"

MODEL_CARD="$(ls "$BUILD_DIR"/model-card-*.md 2>/dev/null | head -1 || true)"
SIGNED=false
if cosign verify "registry.itlusions.nl/models/${MODEL_NAME:-amalia}:${VERSION}" >/dev/null 2>&1; then
  SIGNED=true
fi

ACCURACY="$(jq -r '.summary.accuracy // 0' "$BUILD_DIR/test-results.json" 2>/dev/null || echo 0)"
THRESHOLD="${ACCURACY_THRESHOLD:-0.90}"

cat >"$BUILD_DIR/release-input.json" <<JSON
{
  "risk_class": "${RISK_CLASS:-high}",
  "version": "${VERSION}",
  "artifacts": {
    "model_card": "${MODEL_CARD}",
    "signed": ${SIGNED},
    "monitoring_plan": "monitoring/prometheus-rules.yaml"
  },
  "evaluation": { "accuracy": ${ACCURACY}, "threshold": ${THRESHOLD} },
  "logging": { "retention_days": ${LOG_RETENTION_DAYS:-2555} }
}
JSON

RESULT="$(opa eval --format raw --data policies/opa \
  --input "$BUILD_DIR/release-input.json" 'data.ai_act.release.deny')"

if [[ "$RESULT" != "[]" ]]; then
  echo "AI Act release gate FAILED:" >&2
  echo "$RESULT" >&2
  exit 1
fi
echo "Release gate OK voor $VERSION"
