#!/usr/bin/env bash
# Art. 11 + Bijlage IV — technische documentatie per release.
# Gebruik: ci/generate-model-card.sh <model-name> <version>
set -euo pipefail

MODEL_NAME="${1:?geef modelnaam}"
VERSION="${2:?geef versie}"
BUILD_DIR="${BUILD_DIR:-build}"
mkdir -p "$BUILD_DIR"
OUT="$BUILD_DIR/model-card-${VERSION}.md"

DATASET="$(python3 -c 'import yaml;print(yaml.safe_load(open("examples/lineage-manifest.yaml"))["dataset"])' 2>/dev/null || echo "onbekend")"
TESTS="$(jq -c '.summary' "$BUILD_DIR/test-results.json" 2>/dev/null || echo '{"status":"geen testresultaten gevonden"}')"

cat >"$OUT" <<MD
# Model Card: ${MODEL_NAME}

| Veld | Waarde |
|---|---|
| Versie | ${VERSION} |
| AI-systeem-id | ${AI_ACT_SYSTEM_ID:-onbekend} |
| Risicoklasse | ${RISK_CLASS:-onbekend} |
| Aanbieder | ITlusions B.V. |
| Gegenereerd | $(date -u +%Y-%m-%dT%H:%M:%SZ) |
| Commit | ${GITHUB_SHA:-$(git rev-parse HEAD 2>/dev/null || echo n/a)} |

## Beoogd doel (Art. 11, Bijlage IV punt 1)
Zie \`docs/ai-systeemregister.yaml\`, entry \`${AI_ACT_SYSTEM_ID:-onbekend}\`.

## Data (Art. 10)
Dataset: ${DATASET}
Lineage-manifest: \`examples/lineage-manifest.yaml\`

## Prestaties en testresultaten (Art. 15)
\`\`\`json
${TESTS}
\`\`\`

## Bekende beperkingen
Zie \`LIMITATIONS.md\`.

## Menselijk toezicht (Art. 14)
Kill-switch en escalatiepad: zie \`docs/runbook-kill-switch.md\`.

## Logging (Art. 12)
Retentie: ${LOG_RETENTION_DAYS:-2555} dagen, hash-chained audit trail via audit-sidecar.
MD

echo "Model card geschreven naar $OUT"
