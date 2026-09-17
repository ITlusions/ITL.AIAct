# EU AI Act (Verordening 2024/1689) — Implementeerbare Controls

Bron: https://eur-lex.europa.eu/legal-content/NL/TXT/HTML/?uri=OJ:L_202401689

## Aanpak: van verordening naar controls

1. **Rol en risicoklasse bepalen** — aanbieder of gebruiksverantwoordelijke, en per AI-systeem: onaanvaardbaar / hoog / beperkt / minimaal risico (Art. 5-7, Bijlage III)
2. **Verplichtingen mappen naar controldomeinen** (voor hoogrisicosystemen, Art. 9-15 + 16-27)
3. **Vertalen naar implementeerbare controls** binnen bestaande stack (Kyverno/OPA, Entra ID, SPIFFE/SPIRE, Talos)
4. **Vastleggen in controlmatrix**: Artikel → Verplichting → Control → Implementatiemechanisme → Eigenaar → Evidence → Status

## Mapping artikelen naar controldomeinen

| Artikel | Verplichting | Controldomein |
|---|---|---|
| Art. 9 | Risicomanagementsysteem | Governance control |
| Art. 10 | Data governance & kwaliteit | Data control |
| Art. 11 | Technische documentatie | Documentatie control |
| Art. 12 | Logging (record-keeping) | Technische control |
| Art. 13 | Transparantie naar gebruiker | UX/documentatie control |
| Art. 14 | Menselijk toezicht | Proces control |
| Art. 15 | Nauwkeurigheid, robuustheid, cyberbeveiliging | Technische control |
| Art. 16-17 | QMS + post-market monitoring | Organisatorische control |
| Art. 43 | Conformiteitsbeoordeling | Audit control |

---

## 1. AI-systeem inventarisatie & risicoclassificatie

**Kyverno — verplicht risicoklasse-label:**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-ai-act-risk-label
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-risk-class-label
      match:
        any:
        - resources:
            kinds: [Deployment]
            selector:
              matchLabels:
                workload-type: ai-inference
      validate:
        message: "AI-workload moet 'ai-act.risk-class' label hebben (unacceptable|high|limited|minimal)"
        pattern:
          metadata:
            labels:
              ai-act.risk-class: "?*"
```

**OPA — registry-check in CI (rego):**
```rego
package ai_act.inventory

deny[msg] {
    input.kind == "Deployment"
    input.metadata.labels["workload-type"] == "ai-inference"
    not registry_entry_exists(input.metadata.name)
    msg := sprintf("AI-systeem '%v' niet geregistreerd in AI-systeemregister", [input.metadata.name])
}

registry_entry_exists(name) {
    some entry in data.ai_registry.systems
    entry.name == name
}
```

Evidence: admission-log + policy report / rego test suite in Git.

---

## 2. Data governance (Art. 10)

**OPA — lineage-manifest verplicht in CI pipeline:**
```rego
package ai_act.data_governance

deny[msg] {
    input.stage == "train"
    not input.dataset.lineage_manifest
    msg := "Trainingsdata mist lineage-manifest (bron, licentie, verzameldatum)"
}

deny[msg] {
    input.dataset.lineage_manifest.license == ""
    msg := "Lineage-manifest ontbreekt licentie-informatie"
}
```

**Lineage-manifest voorbeeld (in repo naast dataset):**
```yaml
dataset: customer-support-tickets-v3
source: internal-crm-export
license: internal-use-only
collected_at: 2026-03-01
pii_scrubbed: true
approved_by: dpo@itlusions.nl
```

**Toegangscontrole op trainingsdata:** Entra ID Conditional Access + PIM op storage accounts, alleen just-in-time toegang.

Evidence: manifest in repo (gesigneerd via cosign), Entra sign-in logs, PIM-activatielog.

---

## 3. Logging & audit trail (Art. 12)

**Kyverno — auto-inject logging sidecar:**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: inject-ai-audit-sidecar
spec:
  rules:
    - name: add-audit-sidecar
      match:
        any:
        - resources:
            kinds: [Pod]
            selector:
              matchLabels:
                workload-type: ai-inference
      mutate:
        patchStrategicMerge:
          spec:
            containers:
              - name: audit-logger
                image: registry.itlusions.nl/audit-sidecar:latest
                env:
                  - name: SPIFFE_ID
                    valueFrom:
                      fieldRef:
                        fieldPath: metadata.annotations['spiffe.io/spiffe-id']
```

**Storage-lifecycle policy (retentie afdwingen, Azure):**
```json
{
  "rules": [{
    "name": "ai-audit-log-retention",
    "enabled": true,
    "type": "Lifecycle",
    "definition": {
      "actions": { "delete": { "daysAfterModificationGreaterThan": 2555 } },
      "filters": { "blobIndexMatch": [{"name": "log-type", "op": "==", "value": "ai-inference-audit"}] }
    }
  }]
}
```

Evidence: log-retentie ≥ wettelijke termijn, hash-chained; storage-lifecycle policy-as-code.

---

## 4. Menselijk toezicht (Art. 14)

**Kyverno — approval-gate voor prod:**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-human-approval-prod
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-approval-annotation
      match:
        any:
        - resources:
            kinds: [Deployment]
            namespaces: ["ai-prod"]
      validate:
        message: "Deployment naar ai-prod vereist 'approved-by' annotatie van menselijke reviewer"
        pattern:
          metadata:
            annotations:
              approved-by: "?*"
              approval-ticket: "?*"
```

**GitHub Actions — approval als CI-gate:**
```yaml
jobs:
  deploy-prod:
    environment:
      name: ai-production
      # environment protection rule vereist reviewer-approval in GitHub settings
    steps:
      - run: kubectl apply -f deployment.yaml
```

Evidence: GitOps merge-approval log, runbook + test-evidence voor kill-switch, alertmanager-config + incident-log voor escalatiepad.

---

## 5. Nauwkeurigheid, robuustheid, cybersecurity (Art. 15)

**Kyverno — verplicht gesigneerde modellen (cosign):**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-model-image-signature
spec:
  rules:
    - name: check-signature
      match:
        any:
        - resources:
            kinds: [Pod]
            selector:
              matchLabels:
                workload-type: ai-inference
      verifyImages:
        - imageReferences:
            - "registry.itlusions.nl/models/*"
          attestors:
            - entries:
                - keys:
                    publicKeys: |
                      -----BEGIN PUBLIC KEY-----
                      <jullie cosign public key>
                      -----END PUBLIC KEY-----
```

**SPIFFE/SPIRE — mTLS enforcement (Kyverno deny zonder attestatie):**
```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: require-spiffe-attestation
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-spiffe-id
      match:
        any:
        - resources:
            kinds: [Pod]
            selector:
              matchLabels:
                workload-type: ai-inference
      validate:
        message: "AI-pod moet SPIFFE-identity annotatie hebben"
        pattern:
          metadata:
            annotations:
              spiffe.io/spiffe-id: "spiffe://itlusions.nl/ai/*"
```

**Hardened runtime:** Talos Linux + TPM-attestatie als verplichte basis voor elke AI-workload-node.

Evidence: attestation-log, Sigstore-transparantielog, pentest-/redteam-rapport, policy report.

---

## 6. Technische documentatie (Art. 11)

**CI-stap — auto-genereer model card:**
```yaml
- name: Generate model card
  run: |
    cat <<EOF > model-card-${{ github.ref_name }}.md
    # Model Card: ${{ env.MODEL_NAME }}
    Version: ${{ github.ref_name }}
    Dataset: $(cat dataset-manifest.yaml | yq .dataset)
    Test results: $(cat test-results.json | jq .summary)
    Known limitations: see LIMITATIONS.md
    Generated: $(date -u +%Y-%m-%dT%H:%M:%SZ)
    EOF
```

Evidence: gepubliceerd artifact per release-tag, Git-historie (versiegebonden documentatie).

---

## 7. Transparantie richting eindgebruiker (Art. 13, Art. 50)

**API-gateway policy — verplichte AI-disclosure header (Envoy/Kong voorbeeld):**
```yaml
plugins:
  - name: response-transformer
    config:
      add:
        headers:
          - "X-AI-Generated: true"
          - "X-AI-Info-URL: https://itlusions.nl/ai-transparency"
```

**Contract-test (verifieert header aanwezig):**
```python
def test_ai_disclosure_header():
    response = client.post("/api/inference", json=payload)
    assert response.headers.get("X-AI-Generated") == "true"
```

Evidence: gateway-configuratie, contract-test-resultaat.

---

## 8. Post-market monitoring (Art. 17, Art. 72)

**Prometheus alert-rule — drift-detectie:**
```yaml
groups:
  - name: ai-act-monitoring
    rules:
      - alert: ModelOutputDriftDetected
        expr: abs(ai_model_output_distribution_shift) > 0.15
        for: 10m
        labels:
          severity: high
          compliance: ai-act-art17
        annotations:
          summary: "Mogelijke model drift gedetecteerd — menselijke review vereist"
```

Evidence: dashboard-export, periodieke rapportage, runbook + incident-log voor incident-meldingsproces.
