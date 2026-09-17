#!/usr/bin/env bash
# Control C-01 — elke AI-workload in deploy/ staat in het AI-systeemregister.
# Gebruik: ci/check-registry.sh [deploy-dir]
set -euo pipefail

DEPLOY_DIR="${1:-deploy}"
REGISTER="${REGISTER:-docs/ai-systeemregister.yaml}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

python3 -c "
import json, sys, yaml
json.dump({'ai_registry': yaml.safe_load(open('$REGISTER', encoding='utf-8'))}, open('$WORK/registry.json','w'))
"

# Splits alle manifests in losse JSON-documenten.
python3 - "$DEPLOY_DIR" "$WORK" <<'PY'
import json, pathlib, sys, yaml
deploy, work = pathlib.Path(sys.argv[1]), pathlib.Path(sys.argv[2])
n = 0
for path in sorted(deploy.rglob("*.y*ml")):
    for doc in yaml.safe_load_all(path.read_text(encoding="utf-8")):
        if not doc:
            continue
        (work / f"doc-{n:03d}.json").write_text(
            json.dumps({"_source": str(path), **doc}), encoding="utf-8")
        n += 1
print(f"{n} manifest(s) gevonden in {deploy}")
PY

FAILED=0
shopt -s nullglob
for doc in "$WORK"/doc-*.json; do
  result="$(opa eval --format raw --data policies/opa --data "$WORK/registry.json" \
      --input "$doc" 'data.ai_act.inventory.deny')"
  if [[ "$result" != "[]" ]]; then
    src="$(python3 -c "import json;print(json.load(open('$doc'))['_source'])")"
    echo "[$src] $result" >&2
    FAILED=1
  fi
done

if [[ "$FAILED" -ne 0 ]]; then
  echo "AI-systeemregister gate FAILED" >&2
  exit 1
fi
echo "AI-systeemregister gate OK"
