# Runbook — AI-systeem onderbreken (Art. 14 lid 4 sub e)

Doel: een aangewezen mens kan de werking van een hoogrisico AI-systeem stoppen
zonder tussenkomst van een engineer.

## Wanneer
- Alert `ModelAccuracyBelowThreshold` of `ModelOutputDriftDetected` blijft staan na triage
- Vermoeden van schadelijke output, discriminatie of datalek
- Verzoek van de toezichthouder

## Wie
Primair: dienstdoende platform-engineer. Escalatie: compliance@itlusions.nl.
Iedereen met de rol `ai-operator` in Entra ID mag de kill-switch bedienen.

## Stappen
1. Noteer tijdstip, aanleiding en het `ai-act.system-id` in het incidentticket.
2. Roep het kill-switch endpoint aan (uit `docs/ai-systeemregister.yaml`):
   `curl -X POST "$KILL_SWITCH_ENDPOINT" -H "Authorization: Bearer $TOKEN"`
3. Controleer dat inferentie stopt: `ai_inference_total` vlakt af binnen 60s.
4. Valt het endpoint uit, schaal dan de deployment naar nul:
   `kubectl -n ai-prod scale deployment/<naam> --replicas=0`
5. Controleer dat de audit-sidecar de laatste events heeft weggeschreven
   (alert `AIAuditLoggingStalled` mag pas ná stap 3 afgaan).
6. Meld intern binnen 1 uur; beoordeel of Art. 73 (ernstig incident) van
   toepassing is — zo ja, volg `docs/runbook-incident.md`.

## Herstart
Alleen na schriftelijke goedkeuring (`ai-act.approved-by` + ticket) en een
korte oorzaakanalyse in het ticket.

## Oefening
Halfjaarlijks in staging, met bewijs (ticket + Prometheus-screenshot) als
evidence voor control C-10.
