class_name Main
extends Node3D
## Entry point of VOID HORIZON.
## Phase 00: boots and reports readiness only. No gameplay is implemented here.

const PROJECT_NAME: String = "VOID HORIZON"
const PHASE: String = "00 - Project Foundation"


func _ready() -> void:
	print("%s booted. Phase %s." % [PROJECT_NAME, PHASE])
