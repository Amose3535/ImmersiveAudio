# ImmersiveAudioServer.gd
extends Node
## Contains all utilities and APIs for handling stuff used by ImmersiveAudioPlayer3D-s and other useful stuff (can be seen as utility)


## Creates a new audio bus in Audio server, calls it in a specific way to differentiate between normal and addon-generated buses and returns its index.
func create_audio_bus(bus_send : String = "Master") -> Dictionary:
	# Create an audio bus to control the effects
	var bus_id : int = AudioServer.bus_count
	var bus_name : String = "ImmersiveBus:"+str(bus_id)
	AudioServer.add_bus(bus_id)
	AudioServer.set_bus_name(bus_id,bus_name)
	AudioServer.set_bus_send(bus_id,bus_send)
	return {"ID":bus_id,"NAME":bus_name}

## Adds a new reverb effect (layer 0) on a bus at a certain index and returns the effect for utility
func add_reverb_to_bus(at_index : int) -> AudioEffect:
	AudioServer.add_bus_effect(at_index,AudioEffectReverb.new(),0)
	var effect = AudioServer.get_bus_effect(at_index,0)
	return effect

## Adds a new lowpass filter effect (layer 1) on a bus at a certain index and returns the effect for utility
func add_lowpass_to_bus(at_index : int) -> AudioEffect:
	AudioServer.add_bus_effect(at_index,AudioEffectLowPassFilter.new(),1)
	var effect = AudioServer.get_bus_effect(at_index,1)
	return effect

## Accesses a certain effect for a specific bus (used in case the accessing of the effect happens AFTER the creation of the effect BUT there is no original reference from effect creation)
func get_effect_from_bus(at_index: int, effect : Variant) -> AudioEffect:
	var effect_layer : int = 0
	if effect is String:
		match effect.to_lower():
			"reverb":
				effect_layer = 0
			"lowpass":
				effect_layer = 1
	elif effect is int:
		if effect_layer in range(2):
			effect_layer = effect
	return AudioServer.get_bus_effect(at_index,effect_layer)

## Deletes a specific audio bus to prevent clutter (used by ImmersiveAudioPlayers3D's when removed from scene tree).[br]
## Incapsulates AudioServer.remove_bus() method
func remove_audio_bus(at_index : int) -> void:
	AudioServer.remove_bus(at_index)
