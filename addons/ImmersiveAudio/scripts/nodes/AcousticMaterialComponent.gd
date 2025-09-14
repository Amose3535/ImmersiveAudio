#AcousticMaterialComponent.gd
extends Node
## A component that carries various info for interactions with ImmersiveAudioPlayer
##
## This node contains the necessary info for ImmersiveAudioPlayer.[br][br]
## [b]Example[/b]: A glass vase would behave different from a carpet upon interaction with sound waves. Therefore, with ImmersiveAudioPlayer, this component can greatly increase immersion without tweaking much the already existing assets in the scene.
class_name AcousticMaterialComponent


#region internals
enum MATS {
	## Good enough for most basic scenes (same as not having any AcousticMaterialComponent applied).
	DEFAULT,
	## Good for scenes that have a little reverb and medium-high low frequency passtrhough.
	WOOD,
	## Good for scenes with medium-high reverb and medium frequency passtrhough.
	STONE,
	## Good for scenes with high reverb and high frequency passthrough.
	GLASS,
	## Good for scenees with low reverb and low frequency passthrough.
	CLOTH,
	## Allows to parametrize the material to have a more customized experience.
	CUSTOM}
#endregion


# TODO: 
#       - Add export for absorption_6bands (from 0 to 1) (how much energy is depleted for each bounce: 0=none, 1=all )
#       - Add export for transmission_loss6bands_db (dB) (how much energy is depleted upon exiting wall)
# MAYBE - Add export for scattering (from 0 to 1) (how much the sound is scattered upon bounce: 0=not dispersed at all, 1=very dispersed)

## Some presets for the parameters used by ImmersiveAudioPlayer3D on interaction.
@export var preset_material: MATS = MATS.DEFAULT:
	set(new_material):
		_apply_material_preset(new_material)

## Enables/Disables the current material.[br]Useful for quick testing.
@export var enabled: bool = true


func _apply_material_preset(material_string : int) -> void:
	match material_string:
		MATS.DEFAULT:
			pass
		
		MATS.WOOD:
			pass
		
		MATS.STONE:
			pass
		
		MATS.GLASS:
			pass
		
		MATS.CLOTH:
			pass
		
		MATS.CUSTOM:
			pass
		
		_:
			pass
