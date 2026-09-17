# ITL.AIAct — EU AI Act als policy-as-code

Implementeerbare controls voor Verordening (EU) 2024/1689 binnen de ITlusions-stack
(Kubernetes/Talos, Kyverno, OPA, SPIFFE/SPIRE, Entra ID, GitHub Actions, Prometheus).

Bron van de verplichtingen: [Verordening 2024/1689](https://eur-lex.europa.eu/legal-content/NL/TXT/HTML/?uri=OJ:L_202401689).
De inhoudelijke uitwerking per artikel staat in [ITL-AIAct-controls.md](ITL-AIAct-controls.md).

## Repo-indeling

| Pad | Inhoud |
|---|---|
| `ITL-AIAct-controls.md` | Uitleg per controldomein, per artikel |
| `docs/controlmatrix.md` | Controlmatrix C-01 t/m C-19 plus status per AI-systeem |
| `docs/controlmatrix.csv` | Zelfde matrix voor Excel/GRC-tooling (gegenereerd) |
| `docs/ai-systeemregister.yaml` | Het register; tevens `data.ai_registry` voor OPA |
| `docs/runbook-*.md` | Kill-switch (Art. 14) en incidentmelding (Art. 73) |
| `policies/kyverno/` | Admission-controls, met `kyverno test`-suite |
| `policies/opa/ai_act/` | Rego-policies voor CI-gates, met unit tests |
| `ci/` | Gate-scripts en de model-card-generator |
| `.github/workflows/` | `ai-act-compliance` (policy tests) en `model-release` |
| `deploy/` | Voorbeelddeployments die de controls passeren |
| `examples/` | Lineage-manifest (Art. 10) |
| `monitoring/` | Prometheus-alerts voor Art. 12/14/15/72/73 |
| `infra/` | Logretentie (Azure) en gateway-transparantie |
| `tests/` | Contract-tests voor de disclosure-headers |

## Lokaal draaien

```bash
opa test policies/opa -v
```

```bash
kyverno test policies/kyverno/tests
```

```bash
python3 ci/matrix-to-csv.py
```

Benodigd: `opa` ≥ 0.68 (rego.v1-syntax), `kyverno` CLI ≥ 1.13, `python3` met `pyyaml`.
Beide policy-suites draaien ook in de CI-workflow `ai-act-compliance`.

## De labels en annotaties

Elke AI-workload draagt:

| Sleutel | Type | Waarde |
|---|---|---|
| `workload-type` | label | `ai-inference` — hierop matchen alle policies |
| `ai-act.risk-class` | label | `unacceptable` \| `high` \| `limited` \| `minimal` |
| `ai-act.system-id` | label | verwijzing naar `docs/ai-systeemregister.yaml` |
| `ai-act.approved-by` | annotatie | e-mailadres van de menselijke reviewer |
| `ai-act.approval-ticket` | annotatie | change-ticket |
| `ai-act.kill-switch-endpoint` | annotatie | verplicht bij `high` |
| `ai-act.disclosure-url` | annotatie | publieke transparantiepagina |
| `spiffe.io/spiffe-id` | annotatie | `spiffe://itlusions.nl/ai/<systeem>/<component>` |

## Nog in te vullen vóór uitrol

1. `policies/kyverno/04-verify-model-signature.yaml` — de cosign public key
   (`REPLACE_WITH_ITLUSIONS_COSIGN_PUBLIC_KEY`).
2. Registry-, gateway- en audit-endpoints controleren op de echte hostnames.
3. Risicoclassificaties in `docs/ai-systeemregister.yaml` juridisch laten toetsen —
   de huidige waarden zijn een werkhypothese.
4. `validationFailureAction: Enforce` eerst als `Audit` uitrollen, policy reports
   bekijken, daarna hard zetten.
5. Eigenaren in de controlmatrix bevestigen; de ingevulde adressen zijn voorstellen.

## Afbakening

Dit is een technische implementatie van controls, geen juridisch advies. De
classificatie van een systeem (Art. 6/7, Bijlage III) en de vraag of ITlusions
aanbieder of gebruiksverantwoordelijke is, moeten per systeem juridisch worden
vastgesteld; de controls dwingen daarna af dat die keuze zichtbaar en
handhaafbaar is.
