# Art. 11, 12, 15, 17 — release-gate voor modelartifacten
package ai_act.release

import rego.v1

deny contains msg if {
	input.risk_class == "high"
	not input.artifacts.model_card
	msg := "Release van hoogrisicosysteem zonder model card (Art. 11, Bijlage IV)"
}

deny contains msg if {
	input.risk_class == "high"
	not input.artifacts.signed
	msg := "Modelartifact is niet gesigneerd met cosign (Art. 15)"
}

deny contains msg if {
	input.risk_class == "high"
	object.get(input, ["evaluation", "accuracy"], 0) < input.evaluation.threshold
	msg := sprintf(
		"Nauwkeurigheid %v onder afgesproken drempel %v (Art. 15 lid 1)",
		[input.evaluation.accuracy, input.evaluation.threshold],
	)
}

deny contains msg if {
	input.risk_class in {"high", "limited"}
	not input.artifacts.monitoring_plan
	msg := "Post-market monitoringplan ontbreekt (Art. 72)"
}

deny contains msg if {
	input.risk_class == "high"
	object.get(input, ["logging", "retention_days"], 0) < 180
	msg := "Logretentie < 180 dagen voldoet niet aan Art. 12 lid 3"
}
