@tool
extends EditorPlugin

const INPUT_ACTIONS := {
	"move_forward": KEY_W,
	"move_back":    KEY_S,
	"move_left":    KEY_A,
	"move_right":   KEY_D,
	"run":          KEY_SHIFT,
	"interact":     KEY_E,
	"ui_cancel":    KEY_ESCAPE, # già standard in molti progetti, ma lo settiamo per sicurezza
}

func _enter_tree() -> void:
	# Autoload
	add_autoload_singleton("ImmersiveAudioServer", "res://addons/ImmersiveAudio/scripts/autoload/ImmersiveAudioServer.gd")
	
	# Setup InputMap
	_register_input_actions()


func _exit_tree() -> void:
	# Clean-up
	remove_autoload_singleton("ImmersiveAudioServer")


func _register_input_actions() -> void:
	for action_name in INPUT_ACTIONS.keys():
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			var keycode = INPUT_ACTIONS[action_name]
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action_name, ev)
			print("[ImmersiveAudio/Plugin.gd] Added input action:", action_name, " -> ", OS.get_keycode_string(keycode))
