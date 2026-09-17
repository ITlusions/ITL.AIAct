# Runbook — ernstig incident melden (Art. 73)

Een ernstig incident is onder meer: overlijden of ernstige schade aan gezondheid,
ernstige en onomkeerbare verstoring van kritieke infrastructuur, schending van
grondrechten, of ernstige schade aan eigendom of milieu.

## Termijnen (Art. 73)
| Situatie | Termijn na kennisname |
|---|---|
| Algemeen ernstig incident | uiterlijk 15 dagen |
| Wijdverbreide inbreuk of verstoring kritieke infrastructuur | uiterlijk 2 dagen |
| Overlijden | uiterlijk 10 dagen |

De teller start bij kennisname van het verband tussen het AI-systeem en het
incident. Een onvolledige eerste melding mag; aanvullen kan later.

## Stappen
1. Open een incidentticket; zet `ai_act_unreported_serious_incidents` op 1 zodat
   de alert `SeriousIncidentReportingWindow` de termijn bewaakt.
2. Overweeg de kill-switch (`docs/runbook-kill-switch.md`).
3. Bevries evidence: audit-logs, model card van de draaiende versie, input/output
   van het betrokken verzoek (correlatie-id uit `X-AI-Correlation-Id`).
4. Compliance stelt de melding op voor de markttoezichthouder van de lidstaat
   waar het incident plaatsvond.
5. Onderzoek uitvoeren, risicoanalyse (C-02) bijwerken, correctieve maatregel
   doorvoeren en de controlmatrix actualiseren.
6. Zet de metric terug op 0 zodra de melding verstuurd is; bewaar de bevestiging
   als evidence voor control C-17.

## Contact
Markttoezichthouder NL: Rijksinspectie Digitale Infrastructuur (RDI) / AP,
afhankelijk van het domein. Verifieer het actuele loket vóór verzending.
