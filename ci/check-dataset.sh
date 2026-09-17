#!/usr/bin/env bash
# Art. 10 — blokkeer een training/finetune run zonder compleet lineage-manifest.
# Gebruik: ci/check-dataset.sh <lineage-manifest.yaml> <risk-class>
set -euo pipefail

MANIFEST="${1:?geef pad naar lineage-manifest}"
RISK_CLASS="${2:-high}"

INPUT="$(mktemp)"
trap 'rm -f "$INPUT"' EXIT

# YAML -> JSON zonder extra tooling-afhankelijkheid buiten python3.
python3 - "$MANIFEST" "$RISK_CLASS" >"$INPUT" <<'PY'
import json, sys, yaml
manifest = yaml.safe_load(open(sys.argv[1], encoding="utf-8"))
json.dump({
    "stage": "train",
    "risk_class": sys.argv[2],
    "dataset": {"lineage_manifest": manifest},
}, sys.stdout)
PY

# Draai vanuit de repo-root.
RESULT="$(opa eval --format raw --data policies/opa --input "$INPUT" 'data.ai_act.data_governance.deny')"

if [[ "$RESULT" != "[]" ]]; then
  echo "AI Act data governance gate FAILED:" >&2
  echo "$RESULT" >&2
  exit 1
fi
echo "Data governance gate OK voor $MANIFEST (risk-class=$RISK_CLASS)"
