# Art. 6/7 + Bijlage III — AI-systeemregister
# Elke AI-workload die naar het cluster gaat moet een entry hebben in het
# AI-systeemregister (data.ai_registry.systems, geladen uit docs/ai-systeemregister.yaml).
package ai_act.inventory

import rego.v1

risk_classes := {"unacceptable", "high", "limited", "minimal"}

is_ai_workload(obj) if {
	obj.kind in {"Deployment", "StatefulSet"}
	obj.metadata.labels["workload-type"] == "ai-inference"
}

system_id(obj) := obj.metadata.labels["ai-act.system-id"]

registry_entry(id) := entry if {
	some entry in data.ai_registry.systems
	entry.id == id
}

deny contains msg if {
	is_ai_workload(input)
	not input.metadata.labels["ai-act.system-id"]
	msg := sprintf("AI-systeem '%v' mist label ai-act.system-id", [input.metadata.name])
}

deny contains msg if {
	is_ai_workload(input)
	id := system_id(input)
	not registry_entry(id)
	msg := sprintf("AI-systeem '%v' (id %v) is niet geregistreerd in het AI-systeemregister", [input.metadata.name, id])
}

deny contains msg if {
	is_ai_workload(input)
	klass := input.metadata.labels["ai-act.risk-class"]
	not klass in risk_classes
	msg := sprintf("Ongeldige risicoklasse '%v' op '%v'; toegestaan: %v", [klass, input.metadata.name, risk_classes])
}

# De klasse op de workload moet overeenkomen met de klasse in het register:
# stille downgrade van 'high' naar 'limited' omzeilt Art. 9-15.
deny contains msg if {
	is_ai_workload(input)
	entry := registry_entry(system_id(input))
	entry.risk_class != input.metadata.labels["ai-act.risk-class"]
	msg := sprintf(
		"Risicoklasse '%v' op '%v' wijkt af van register ('%v')",
		[input.metadata.labels["ai-act.risk-class"], input.metadata.name, entry.risk_class],
	)
}

deny contains msg if {
	is_ai_workload(input)
	entry := registry_entry(system_id(input))
	not entry.owner
	msg := sprintf("Registerentry '%v' mist een verantwoordelijke eigenaar", [entry.id])
}
