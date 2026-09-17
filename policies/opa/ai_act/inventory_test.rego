package ai_act.inventory_test

import data.ai_act.inventory
import rego.v1

registry := {"systems": [
	{"id": "AIS-001-amalia", "name": "Amalia", "risk_class": "high", "owner": "compliance@itlusions.nl"},
	{"id": "AIS-002-braincell", "name": "BrainCell", "risk_class": "limited", "owner": "n.weistra@itlusions.nl"},
]}

deployment(name, labels) := {
	"kind": "Deployment",
	"metadata": {"name": name, "labels": labels},
}

compliant := deployment("amalia-inference", {
	"workload-type": "ai-inference",
	"ai-act.system-id": "AIS-001-amalia",
	"ai-act.risk-class": "high",
})

test_compliant_deployment_allowed if {
	count(inventory.deny) == 0 with input as compliant with data.ai_registry as registry
}

test_missing_system_id_denied if {
	d := deployment("rogue", {"workload-type": "ai-inference"})
	count(inventory.deny) > 0 with input as d with data.ai_registry as registry
}

test_unregistered_system_denied if {
	d := deployment("ghost", {
		"workload-type": "ai-inference",
		"ai-act.system-id": "AIS-404",
		"ai-act.risk-class": "high",
	})
	some msg in inventory.deny with input as d with data.ai_registry as registry
	contains(msg, "niet geregistreerd")
}

test_risk_class_downgrade_denied if {
	d := deployment("amalia-inference", {
		"workload-type": "ai-inference",
		"ai-act.system-id": "AIS-001-amalia",
		"ai-act.risk-class": "limited",
	})
	some msg in inventory.deny with input as d with data.ai_registry as registry
	contains(msg, "wijkt af van register")
}

test_invalid_risk_class_denied if {
	d := deployment("weird", {
		"workload-type": "ai-inference",
		"ai-act.system-id": "AIS-001-amalia",
		"ai-act.risk-class": "medium",
	})
	some msg in inventory.deny with input as d with data.ai_registry as registry
	contains(msg, "Ongeldige risicoklasse")
}

test_non_ai_workload_ignored if {
	d := deployment("webshop", {"workload-type": "web"})
	count(inventory.deny) == 0 with input as d with data.ai_registry as registry
}
