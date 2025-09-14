# OLD CODEBASE (To be restructured)
# SpatialAudioPlayer3D.gd
class_name SpatialAudioPlayer3D extends AudioStreamPlayer3D

@export var max_raycast_distance : float = 3.0
@export var update_frequency_seconds : float = 0.5
@export var max_reverb_wetness : float = 0.5
@export var wall_lowpass_cutoff_amount : int = 600

var _raycast_array : Array[RayCast3D] = []
var _distance_array : Array[float] = [0,0,0,0,0,0,0,0,0,0]
var _last_udpate_time : float = 0.0
var _update_distances : bool = true
var _current_raycast_index : int = 0

# Audio bus for this spatial audio player
var _audio_bus_idx = null
var _audio_bus_name = ""

# Effects
var _reverb_effect : AudioEffectReverb
var _lowpass_filter : AudioEffectLowPassFilter

# Target Parameters (will lerp over time)
var _target_lowpass_cutoff : float = 20000
var _target_reverb_room_size : float = 0.0
var _target_reverb_wetness : float = 0.0
var _target_volume_db : float = 0.0

func _ready() -> void: 
	# Create an audio bus to control the effects
	_audio_bus_idx = AudioServer.bus_count
	_audio_bus_name = "ImmersiveBus#"+str(_audio_bus_idx)
	AudioServer.add_bus(_audio_bus_idx)
	AudioServer.set_bus_name(_audio_bus_idx,_audio_bus_name)
	AudioServer.set_bus_send(_audio_bus_idx,bus)
	self.bus = _audio_bus_name
	
	# Add effects to custom audio bus
	AudioServer.add_bus_effect(_audio_bus_idx,AudioEffectReverb.new(),0)
	_reverb_effect = AudioServer.get_bus_effect(_audio_bus_idx,0)
	AudioServer.add_bus_effect(_audio_bus_idx,AudioEffectLowPassFilter.new(),1)
	_lowpass_filter = AudioServer.get_bus_effect(_audio_bus_idx,1)
	
	# Capture target volume : from no sound, lerp to where it should be
	_target_volume_db = volume_db
	volume_db = -60
	
	# Init all raycasts 
	$RaycastDown.target_position = Vector3(0,-max_raycast_distance,0)
	$RaycastLeft.target_position = Vector3(max_raycast_distance,0,0)
	$RaycastRight.target_position = Vector3(-max_raycast_distance,0,0)
	$RaycastForward.target_position = Vector3(0,0,max_raycast_distance)
	# [Da amose]: Continua per altri 6 raycast ma MI RIFIUTO di copiare a mano così tanti raycast
	
	# Append all raycasts into the array to be easier to cycle later
	_raycast_array.append($RaycastDown)
	_raycast_array.append($RaycastLeft)
	_raycast_array.append($RaycastRight)
	_raycast_array.append($RaycastForward)
	# [Da amose]: Anche qui continua per altri 6 raycast ma diventerebbe troppo tedioso. Cerca di capire cosa si sta facendo.


func _on_update_raycast(raycast : RayCast3D, raycast_index : int):
	raycast.force_raycast_update() # Does not require enabled to be true
	var collider = raycast.get_collider()
	if collider != null:
		_distance_array[raycast_index] = self.global_position.distance_to(raycast.get_collision_point())
	else:
		_distance_array[raycast_index] = -1
	raycast.enabled = false # Don't let this raycast run constantly


func _on_update_spatial_audio(player : Node3D):
	_on_update_reverb(player)
	_on_update_lowpass_filter(player)
	# If you want more effects create functions working in a similar way and add them here


func _on_update_reverb(_player : Node3D):
	if _reverb_effect != null:
		# Find reverb params
		var room_size = 0.0
		var wetness = 1.0
		for dist in _distance_array:
			if dist >= 0:
				# Find the average room size based on the raycast distances that are valid
				room_size+=(dist / max_raycast_distance) / (float(_distance_array.size()))
				room_size=min(room_size,1.0)
			else:
				# If a raycast did not hit an object we will reduce the reverb effect 
				wetness -= 1.0 / float(_distance_array.size())
				wetness = max(wetness,0.0)
		_target_reverb_wetness = wetness
		_target_reverb_room_size = room_size


func _on_update_lowpass_filter(_player : Node3D):
	if _lowpass_filter != null:
		$PlayerRaycast.target_position = (_player.global_position - self.global_position).normalized() * max_raycast_distance
		var collider = $PlayerRaycast.get_collider()
		var lowpass_cutoff = 20000 # init to a value where nothing gets cutoff
		if collider != null:
			var ray_distance = self.global_position.distance_to($PlayerRaycast.get_collision_point())
			var distance_to_player = self.global_position.distance_to(_player.global_position)
			var wall_to_player_ratio = ray_distance / max(distance_to_player,0.001)
			# Check if there's something between the source and the player by comparing distances and raycast collider point
			if ray_distance < distance_to_player:
				lowpass_cutoff = wall_lowpass_cutoff_amount * wall_to_player_ratio
		_target_lowpass_cutoff = lowpass_cutoff


func _lerp_parameters(delta):
	volume_db = lerp(volume_db, _target_volume_db, delta)
	_lowpass_filter.cutoff_hz = lerp(_lowpass_filter.cutoff_hz, _target_lowpass_cutoff, delta * 5.0)
	_reverb_effect.wet = lerp(_reverb_effect.wet, _target_reverb_wetness, delta * 5.0)
	_reverb_effect.room_size = lerp(_reverb_effect.room_size, _target_reverb_room_size, delta * 5.0)

func _physics_process(delta: float) -> void:
	# Optimization
	_last_udpate_time += delta
	
	# Should we update the raycast distance values
	if _update_distances:
		_on_update_raycast(_raycast_array[_current_raycast_index], _current_raycast_index)
		_current_raycast_index+=1
		if _current_raycast_index >= _distance_array.size():
			_current_raycast_index = 0
			_update_distances = false
	
	# Check if we should update the spatial sound values
	if _last_udpate_time > update_frequency_seconds:
		var player_camera = get_viewport().get_camera_3d() # This might change over time (OBVIOUSLY not multiplayer friendly)
		if player_camera != null:
			_on_update_spatial_audio(player_camera)
		_update_distances = true
		_last_udpate_time -= update_frequency_seconds # Don't set to 0 because if the frame didn't land exactly on update frequency value it might cause shorter and/or inconsistent update intervals over time
	
	# Smooth transition of parameters
	_lerp_parameters(delta)
