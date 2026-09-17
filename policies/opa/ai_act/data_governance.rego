# Art. 10 — Data en datagovernance
# Gate op de training/finetune-stap in CI: zonder compleet lineage-manifest
# geen training run.
package ai_act.data_governance

import rego.v1

required_manifest_fields := {"dataset", "source", "license", "collected_at", "approved_by"}

training_stage if input.stage in {"train", "finetune", "evaluate"}

manifest := input.dataset.lineage_manifest

deny contains msg if {
	training_stage
	not input.dataset.lineage_manifest
	msg := "Trainingsdata mist lineage-manifest (bron, licentie, verzameldatum, goedkeuring)"
}

deny contains msg if {
	training_stage
	some field in required_manifest_fields
	value := object.get(manifest, field, "")
	value == ""
	msg := sprintf("Lineage-manifest mist verplicht veld '%v'", [field])
}

# Persoonsgegevens: ofwel gescrubd, ofwel een expliciete DPIA-referentie.
deny contains msg if {
	training_stage
	manifest.contains_personal_data == true
	manifest.pii_scrubbed != true
	not manifest.dpia_reference
	msg := "Dataset bevat persoonsgegevens zonder scrubbing en zonder DPIA-referentie"
}

deny contains msg if {
	training_stage
	manifest.license == "unknown"
	msg := "Licentie 'unknown' is niet toegestaan voor trainingsdata"
}

# Art. 10 lid 2 sub f/g — bias-onderzoek moet aantoonbaar zijn uitgevoerd.
deny contains msg if {
	training_stage
	input.risk_class == "high"
	not manifest.bias_assessment
	msg := "Hoogrisicosysteem: bias-assessment ontbreekt in lineage-manifest (Art. 10 lid 2)"
}

warn contains msg if {
	training_stage
	manifest.collected_at < "2020-01-01"
	msg := sprintf("Dataset '%v' is ouder dan 2020 — controleer representativiteit", [manifest.dataset])
}
