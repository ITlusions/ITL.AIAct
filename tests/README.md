# Tests

| Test | Artikel | Draaien |
|---|---|---|
| `policies/opa/**/*_test.rego` | Art. 10, 11, 12, 15, 72 | `opa test policies/opa -v` |
| `policies/kyverno/tests/` | Art. 6, 12, 14, 15, 50 | `kyverno test policies/kyverno/tests` |
| `tests/test_transparency_contract.py` | Art. 13, 50 | `AI_GATEWAY_URL=… pytest tests/` |

De eerste twee draaien offline en zitten in de CI-workflow `ai-act-compliance`.
De contract-test vereist een bereikbare gateway en wordt in de staging-pipeline
gedraaid.
