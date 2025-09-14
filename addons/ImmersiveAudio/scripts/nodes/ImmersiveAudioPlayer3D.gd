#ImmersiveAudioPlayer3D.gd
@icon("res://addons/ImmersiveAudio/resources/assets/icons/ImmersiveAudioPlayer3D/ImmersiveAudioPlayer3D.svg")
extends AudioStreamPlayer3D
class_name ImmersiveAudioPlayer3D

@export_group("Raycasts")
## The amount of rays used to determine the geometry of the scene in which ImmersiveAudioPlayer3D is placed.[br]A higher count will have more precise results BUT will impact more the preformance. 
@export_range(6,100,1) var max_rays : int = 12
## The amount of times each ray can bounce before stopping.[br]max_bounces = 0 means that raypathing won't happen, hence sound won't be able to reach around obstacles
@export_range(0,10,1) var max_bounces : int = 2
## How far (in units) each ray can travel
@export_range(1,100,0.1) var max_ray_length : float = 50
## The algorithm used to determine how the raycasts should be distributed.[br]NOTE: CUBE_MAPPED is the best for indoors, geometric and symmetric scenes, while FIBONACCI_SPIRAL is the best for outdoors, asymmetric and non repetitive scenes
@export var raycast_positioning_algorithm : PlotAlgorithm = PlotAlgorithm.CUBE_MAPPED
## How often (in seconds) the raycasts should be updated
@export_range(0.1,5,0.1) var update_interval : float = 0.5

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

# Raycasts:
## An enumeration to select the distribution algorithm.
enum PlotAlgorithm {
	## Plots points onto a sphere using the fibonacci spiral algorithm.[br]This distributes the most uniformly the points BUT in symmtetric scenes can cause issues or biases towards a certain direction if the ray count is too small.
	FIBONACCI_SPIRAL,
	## (SUGGESTED) Maps points plotted on a cube onto a sphere.[br]This is the ideal in symmetric rooms but can lead to issues in irregularscene sin some edge cases. 
	CUBE_MAPPED
	}
## Array containing the raycasts of my ImmersiveAudioPlayer3D 
var _raycast_array : Array[RayCast3D] = []
## Dictionary containing matrices nxm where m is a certain ray and n is the n-th bounce for that m ray
var _raycast_collisions_data : Dictionary[String, Array] = {
	"OBJECTS":[],
	"POSITIONS":[]
	}

func _ready() -> void:
	# Create a special audio bus to control the effects.
	# Then make the new bus connect to the bus set in the editor for this node,
	var bus_info : Dictionary = ImmersiveAudioServer.create_audio_bus(bus)
	# then edit the parameters and reroute the node's bus to the new special one 
	# (basically making a pipeline since that is then connected to the older bus).
	setup_immersive_player(bus_info)
	# Create reverb and lowpass filter effects.
	_reverb_effect = ImmersiveAudioServer.add_reverb_to_bus(_audio_bus_idx)
	_lowpass_filter = ImmersiveAudioServer.add_lowpass_to_bus(_audio_bus_idx)
	# Create and append raycasts to the
	_generate_raycasts()
	

## Setups the parameters of this node based on the info gotten from the creation of the bus. Also routes the sound pipeline for this node
func setup_immersive_player(info : Dictionary) -> void:
	# Set bus name and index
	_audio_bus_idx = info["ID"]
	_audio_bus_name = info["NAME"]
	# Reroute AudioStreamPlayer3D's bus into the custom bus
	bus = info["NAME"]
	# Capture target volume : from no sound, lerp to where it should be
	_target_volume_db = volume_db
	volume_db = -60

func _generate_raycasts() -> void:
	for raycast_idx in range(max_rays):
		var new_raycast : RayCast3D = RayCast3D.new()
		var new_raycast_coordinates = get_point_on_sphere(raycast_idx,max_rays,PlotAlgorithm.CUBE_MAPPED)
		_raycast_array.append(new_raycast)

## Returns the coordinates of a point on a normalized sphere.
##
## @param index The current point's number (from 0 to max_targets - 1).
## @param max_targets The total number of points to distribute.
## @param algorithm The distribution algorithm to use.
## @return The normalized Vector3 coordinates of the point.
func get_point_on_sphere(index: int, max_targets: int, algorithm: PlotAlgorithm) -> Vector3:
	var point: Vector3
	
	match algorithm:
		PlotAlgorithm.FIBONACCI_SPIRAL:
			# Fibonacci spiral algorithm for uniform distribution. (literally copy-paste from google lmao)
			const PHI = (1.0 + sqrt(5.0)) / 2.0
			var i: float = float(index) + 0.5
			var phi: float = acos(1.0 - 2.0 * i / float(max_targets))
			var theta: float = 2.0 * PI * i / PHI
			
			var x: float = cos(theta) * sin(phi)
			var y: float = sin(theta) * sin(phi)
			var z: float = cos(phi)
			
			point = Vector3(x, y, z)
			
		PlotAlgorithm.CUBE_MAPPED:
			# Maps points from a cube to a sphere.
			if max_targets <= 0:
				return Vector3.ZERO
			
			# Determine the cube's face and the 2D position on it.
			var face_size_per_side: int = int(ceil(sqrt(float(max_targets) / 6.0)))
			var total_points_per_side: int = face_size_per_side * face_size_per_side
			var face_index: int = index / total_points_per_side
			var local_index: int = index % total_points_per_side
			var local_x: int = local_index % face_size_per_side
			var local_y: int = local_index / face_size_per_side
			
			# Normalize the local coordinates and map them from [-1, 1] to [-0.5, 0.5].
			var x_norm: float = (float(local_x) / float(face_size_per_side - 1) - 0.5) * 2.0
			var y_norm: float = (float(local_y) / float(face_size_per_side - 1) - 0.5) * 2.0
			
			match face_index:
				0: point = Vector3(x_norm, y_norm, 1.0) # Forward (+Z)
				1: point = Vector3(x_norm, y_norm, -1.0) # Back (-Z)
				2: point = Vector3(x_norm, 1.0, y_norm) # Up (+Y)
				3: point = Vector3(x_norm, -1.0, y_norm) # Down (-Y)
				4: point = Vector3(1.0, y_norm, x_norm) # Right (+X)
				5: point = Vector3(-1.0, y_norm, x_norm) # Left (-X)
			
			point = point.normalized()
			
		_: # In case of an unknown algorithm, default to CubeMap.
			push_warning("Unknown algorithm. Defaulting to Fibonacci Spiral.")
			point = get_point_on_sphere(index, max_targets, PlotAlgorithm.CUBE_MAPPED)

	return point
