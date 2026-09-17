package ai_act.release_test

import data.ai_act.release
import rego.v1

good := {
	"risk_class": "high",
	"artifacts": {"model_card": "model-card-v2.3.1.md", "signed": true, "monitoring_plan": "monitoring/plan.md"},
	"evaluation": {"accuracy": 0.94, "threshold": 0.90},
	"logging": {"retention_days": 2555},
}

test_compliant_release_allowed if {
	count(release.deny) == 0 with input as good
}

test_missing_model_card_denied if {
	# object.union mergt genest recursief, dus eerst het hele artifacts-object
	# weghalen voordat de uitgeklede variant erin gaat.
	i := object.union(
		object.remove(good, {"artifacts"}),
		{"artifacts": object.remove(good.artifacts, {"model_card"})},
	)
	some msg in release.deny with input as i
	contains(msg, "model card")
}

test_unsigned_artifact_denied if {
	i := object.union(good, {"artifacts": object.union(good.artifacts, {"signed": false})})
	some msg in release.deny with input as i
	contains(msg, "cosign")
}

test_accuracy_below_threshold_denied if {
	i := object.union(good, {"evaluation": {"accuracy": 0.81, "threshold": 0.90}})
	some msg in release.deny with input as i
	contains(msg, "drempel")
}

test_short_retention_denied if {
	i := object.union(good, {"logging": {"retention_days": 30}})
	some msg in release.deny with input as i
	contains(msg, "Art. 12")
}
