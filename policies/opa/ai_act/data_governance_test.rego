package ai_act.data_governance_test

import data.ai_act.data_governance
import rego.v1

full_manifest := {
	"dataset": "customer-support-tickets-v3",
	"source": "internal-crm-export",
	"license": "internal-use-only",
	"collected_at": "2026-03-01",
	"approved_by": "dpo@itlusions.nl",
	"pii_scrubbed": true,
	"contains_personal_data": true,
	"bias_assessment": "reports/bias-2026-03.md",
}

train_input(manifest, risk) := {
	"stage": "train",
	"risk_class": risk,
	"dataset": {"lineage_manifest": manifest},
}

test_complete_manifest_allowed if {
	count(data_governance.deny) == 0 with input as train_input(full_manifest, "high")
}

test_missing_manifest_denied if {
	i := {"stage": "train", "risk_class": "high", "dataset": {}}
	some msg in data_governance.deny with input as i
	contains(msg, "mist lineage-manifest")
}

test_missing_license_denied if {
	m := object.union(full_manifest, {"license": ""})
	some msg in data_governance.deny with input as train_input(m, "high")
	contains(msg, "license")
}

test_personal_data_without_scrub_or_dpia_denied if {
	m := object.union(full_manifest, {"pii_scrubbed": false})
	some msg in data_governance.deny with input as train_input(m, "high")
	contains(msg, "DPIA")
}

test_personal_data_with_dpia_allowed if {
	m := object.union(full_manifest, {"pii_scrubbed": false, "dpia_reference": "DPIA-2026-07"})
	count(data_governance.deny) == 0 with input as train_input(m, "high")
}

test_high_risk_requires_bias_assessment if {
	m := object.remove(full_manifest, {"bias_assessment"})
	some msg in data_governance.deny with input as train_input(m, "high")
	contains(msg, "bias-assessment")
}

test_limited_risk_without_bias_assessment_allowed if {
	m := object.remove(full_manifest, {"bias_assessment"})
	count(data_governance.deny) == 0 with input as train_input(m, "limited")
}

test_inference_stage_not_gated if {
	i := {"stage": "inference", "risk_class": "high", "dataset": {}}
	count(data_governance.deny) == 0 with input as i
}
