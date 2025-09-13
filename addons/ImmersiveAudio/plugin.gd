@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	self.add_autoload_singleton("ImmersiveAudioServer","res://addons/ImmersiveAudio/scripts/autoload/ImmersiveAudioServer.gd")
	


func _exit_tree() -> void:
	# Clean-up of the plugin goes here.
	self.remove_autoload_singleton("ImmersiveAudioServer")
