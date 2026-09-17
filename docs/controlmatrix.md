# AI Act controlmatrix — ITlusions

Stap 4 uit de aanpak: Artikel → Verplichting → Control → Implementatiemechanisme →
Eigenaar → Evidence → Status.

Status-waarden: `implemented` | `partial` | `planned` | `n/a`
Scope: op welke risicoklassen de control van toepassing is.

## Generieke controls

| ID | Artikel | Verplichting | Control | Implementatiemechanisme | Scope | Eigenaar | Evidence | Frequentie |
|---|---|---|---|---|---|---|---|---|
| C-01 | Art. 6, 7, Bijlage III | Risicoclassificatie per AI-systeem | Elke AI-workload draagt een geverifieerde risicoklasse en staat in het AI-systeemregister | `policies/kyverno/01-require-risk-class-label.yaml`, `policies/opa/ai_act/inventory.rego`, `docs/ai-systeemregister.yaml` | alle | compliance@itlusions.nl | Kyverno policy report, opa test-output, register in Git | per deploy + kwartaalreview |
| C-02 | Art. 9 | Risicomanagementsysteem over de hele levenscyclus | Risicoanalyse per systeem vastgelegd en herzien bij elke majorrelease | `docs/risicoanalyse-<system-id>.md`, reviewissue in GitHub | high | compliance@itlusions.nl | Ondertekende risicoanalyse, reviewhistorie in Git | per majorrelease + halfjaarlijks |
| C-03 | Art. 10 | Data governance en datakwaliteit | Geen training/finetune zonder compleet, gesigneerd lineage-manifest inclusief bias-assessment | `policies/opa/ai_act/data_governance.rego`, `ci/check-dataset.sh`, `examples/lineage-manifest.yaml` | high | dpo@itlusions.nl | CI-gate-log, cosign-signatuur op manifest, DPIA-referentie | per training run |
| C-04 | Art. 10, Art. 15 | Toegangsbeheer op trainingsdata | Just-in-time toegang tot dataopslag via Entra ID PIM en Conditional Access | Entra ID PIM-rol `AI-Data-Reader`, CA-policy `require-mfa-ai-data` | high, limited | security@itlusions.nl | PIM-activatielog, Entra sign-in logs | continu, kwartaalcontrole |
| C-05 | Art. 11, Bijlage IV | Technische documentatie | Model card wordt per release automatisch gegenereerd en gepubliceerd als artifact | `ci/generate-model-card.sh`, workflow `model-release` | high, limited | n.weistra@itlusions.nl | Model card per release-tag, GitHub artifact + Git-historie | per release |
| C-06 | Art. 12 | Automatische registratie van gebeurtenissen | Audit-sidecar wordt automatisch geïnjecteerd; logs hash-chained en herleidbaar tot SPIFFE-id | `policies/kyverno/02-inject-audit-sidecar.yaml` | high, limited | platform@itlusions.nl | Admission-log, steekproef audit-events met geldige hash-chain | per deploy + maandelijkse steekproef |
| C-07 | Art. 12 lid 3 | Logretentie gedurende de gedocumenteerde periode | Retentie afgedwongen als policy-as-code op storage (7 jaar) | `infra/azure-log-retention.json`, gate in `policies/opa/ai_act/release.rego` | high, limited | platform@itlusions.nl | Lifecycle-policy export, release-gate-output | per deploy + jaarlijkse controle |
| C-08 | Art. 13, Art. 50 | Transparantie richting eindgebruiker | Elke AI-respons draagt disclosure-headers; deployment draagt disclosure-metadata | `infra/gateway-transparency-plugin.yaml`, `policies/kyverno/06-require-transparency-metadata.yaml`, `tests/test_transparency_contract.py` | high, limited | product@itlusions.nl | Gateway-config in Git, contract-testresultaat per pipeline-run | per release |
| C-09 | Art. 14 | Menselijk toezicht bij productie-inzet | Deployment naar `ai-prod` vereist menselijke approval met traceerbaar ticket | `policies/kyverno/03-require-human-approval-prod.yaml`, GitHub environment `ai-production` | high, limited | compliance@itlusions.nl | Approval-annotatie op resource, GitHub environment approval-log | per deploy |
| C-10 | Art. 14 lid 4 | Onderbreken van de werking (kill-switch) | Hoogrisicosysteem exposeert een geteste kill-switch met runbook | `policies/kyverno/03-require-human-approval-prod.yaml` (rule `require-kill-switch-probe`), `docs/runbook-kill-switch.md` | high | platform@itlusions.nl | Runbook plus testbewijs van halfjaarlijkse kill-switch-oefening | halfjaarlijks |
| C-11 | Art. 15 | Integriteit van model en inferentie-image | Alleen cosign-gesigneerde images uit de eigen registry mogen draaien | `policies/kyverno/04-verify-model-signature.yaml` | alle | security@itlusions.nl | Sigstore-transparantielog (Rekor), Kyverno verifyImages-report | per deploy |
| C-12 | Art. 15 | Werkidentiteit en mTLS voor AI-verkeer | SPIFFE-id verplicht; hoogrisico alleen op TPM-geattesteerde Talos-nodes | `policies/kyverno/05-require-spiffe-attestation.yaml`, SPIRE-serverconfig | high, limited | platform@itlusions.nl | SPIRE attestation-log, nodelabel-audit | continu |
| C-13 | Art. 15 lid 1 | Nauwkeurigheid conform gedocumenteerd niveau | Release wordt geblokkeerd als de gemeten nauwkeurigheid onder de drempel ligt | `policies/opa/ai_act/release.rego`, `ci/check-release.sh` | high | n.weistra@itlusions.nl | `build/release-input.json` en gate-log per release | per release |
| C-14 | Art. 15 lid 5 | Weerbaarheid tegen aanvallen | Jaarlijkse pentest/redteam op AI-endpoints inclusief prompt injection en model extraction | Externe opdracht, bevindingen als GitHub issues | high | security@itlusions.nl | Pentestrapport, afgeronde remediatie-issues | jaarlijks |
| C-15 | Art. 17 | Kwaliteitsmanagementsysteem | Alle controls zijn policy-as-code in Git met verplichte review | Branch protection op `main`, CI-workflow `ai-act-compliance` | high | compliance@itlusions.nl | CI-runs, PR-reviewhistorie | continu |
| C-16 | Art. 72 | Post-market monitoring | Drift, nauwkeurigheid, override-ratio en loggingcontinuïteit worden gealerteerd | `monitoring/prometheus-rules.yaml` | high, limited | platform@itlusions.nl | Alertmanager-historie, dashboard-export, kwartaalrapportage | continu plus kwartaalrapportage |
| C-17 | Art. 73 | Melding van ernstige incidenten | Incidentproces met meldtermijn bewaakt door alert en runbook | `monitoring/prometheus-rules.yaml` (`SeriousIncidentReportingWindow`), `docs/runbook-incident.md` | high | compliance@itlusions.nl | Incidentregister, verzonden meldingen | per incident |
| C-18 | Art. 43 | Conformiteitsbeoordeling | Interne conformiteitsbeoordeling vóór ingebruikname, evidence-bundel per systeem | CI-artifacts plus controlmatrix-review | high | compliance@itlusions.nl | Evidence-bundel per systeem, ondertekende beoordeling | vóór ingebruikname en bij substantiële wijziging |
| C-19 | Art. 4 | AI-geletterdheid van personeel | Verplichte AI Act-training voor iedereen die AI-systemen bouwt of bedient | Trainingsprogramma plus registratie in HR-systeem | alle | hr@itlusions.nl | Deelnameregistratie, trainingsmateriaal met versiedatum | jaarlijks |

## Per systeem: AIS-001-amalia (Amalia — hoog risico, rol: aanbieder)

| Control | Status | Toelichting / openstaande actie |
|---|---|---|
| C-01 | implemented | Label en registerentry aanwezig |
| C-02 | planned | `docs/risicoanalyse-AIS-001-amalia.md` moet nog worden opgesteld |
| C-03 | partial | Lineage-manifest bestaat; bias-assessment nog niet uitgevoerd |
| C-04 | planned | PIM-rol `AI-Data-Reader` moet nog worden ingericht |
| C-05 | implemented | Model card wordt gegenereerd in workflow `model-release` |
| C-06 | implemented | Sidecar-injectie actief |
| C-07 | partial | Lifecycle-policy gedefinieerd, nog niet toegepast op het storage account |
| C-08 | implemented | Headers en contract-test aanwezig |
| C-09 | implemented | Approval-gate actief op `ai-prod` |
| C-10 | partial | Endpoint bestaat; halfjaarlijkse oefening nog niet gepland |
| C-11 | partial | Policy klaar; cosign public key moet nog worden ingevuld |
| C-12 | implemented | SPIFFE-id en nodeSelector afgedwongen |
| C-13 | implemented | Drempel 0,90 in de release-gate |
| C-14 | planned | Pentest nog te beleggen |
| C-15 | implemented | CI-workflow actief |
| C-16 | implemented | Alerts uitgerold |
| C-17 | planned | Incidentrunbook nog te schrijven |
| C-18 | planned | Conformiteitsbeoordeling nog niet uitgevoerd |
| C-19 | planned | Training nog te organiseren |

## Per systeem: AIS-002-braincell (BrainCell — beperkt risico, rol: gebruiksverantwoordelijke)

| Control | Status | Toelichting / openstaande actie |
|---|---|---|
| C-01 | implemented | Label en registerentry aanwezig |
| C-02 | n/a | Geen hoogrisicosysteem; wel jaarlijkse herbeoordeling van de classificatie |
| C-03 | n/a | Geen eigen training; alleen inferentie op ingekochte modellen |
| C-04 | n/a | Geen eigen trainingsdataopslag |
| C-05 | partial | Model card beperkt tot versie- en herkomstinformatie |
| C-06 | implemented | Sidecar-injectie actief |
| C-07 | implemented | Retentie 365 dagen |
| C-08 | implemented | Disclosure-headers actief (Art. 50) |
| C-09 | implemented | Approval-gate actief op `ai-prod` |
| C-10 | n/a | Geen hoogrisicosysteem |
| C-11 | partial | Policy klaar; cosign public key moet nog worden ingevuld |
| C-12 | implemented | SPIFFE-id afgedwongen |
| C-13 | n/a | Geen gedocumenteerd nauwkeurigheidsniveau |
| C-14 | planned | Meenemen in dezelfde pentestopdracht als Amalia |
| C-15 | implemented | CI-workflow actief |
| C-16 | partial | Alleen loggingcontinuïteit gealerteerd |
| C-17 | n/a | Meldplicht Art. 73 niet van toepassing; interne incidentafhandeling volstaat |
| C-18 | n/a | Geen conformiteitsbeoordeling vereist |
| C-19 | planned | Zelfde training als Amalia |

> De statuskolommen zijn een startpunt op basis van wat er nu in deze repo staat.
> Loop ze met de eigenaren na voordat je ze als evidence gebruikt. De
> risicoclassificaties zijn een werkhypothese, geen juridisch oordeel.
