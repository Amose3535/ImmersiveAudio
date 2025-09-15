# PlayerController.gd
@icon("res://icon.svg")
extends CharacterBody3D


@export_group("References")
@export var head_path: NodePath = ^"Head"
@export var camera_path: NodePath = ^"Head/Camera3D"
@export var anim_player_path: NodePath = ^"AnimationPlayer"

@export_group("Movement")
@export var walk_speed: float = 4.0
@export var run_speed: float = 7.5
@export var acceleration: float = 12.0
@export var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export_group("Look")
@export var mouse_sensitivity: float = 0.1  # gradi per pixel
@export var pitch_min_deg: float = -89.0
@export var pitch_max_deg: float = 89.0

@export_group("Interaction")
@export var interact_distance: float = 3.0
@export_flags_3d_physics var interact_mask: int = 0xFFFFFFFF

# internals
var _head: Node3D
var _cam: Camera3D
var _anim: AnimationPlayer
var _pitch_deg: float = 0.0
var _current_anim: StringName = &""

func _ready() -> void:
	_head = get_node_or_null(head_path)
	_cam = get_node_or_null(camera_path)
	_anim = get_node_or_null(anim_player_path)
	if not _head or not _cam or not _anim:
		push_error("[PlayerController] Missing node refs. Check head_path/camera_path/anim_player_path.")
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	# Mouse look
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var motion := event as InputEventMouseMotion
		# yaw sul body
		rotate_y(deg_to_rad(-motion.relative.x * mouse_sensitivity))
		# pitch sulla head (clamp)
		_pitch_deg = clamp(_pitch_deg - motion.relative.y * mouse_sensitivity, pitch_min_deg, pitch_max_deg)
		_head.rotation_degrees.x = _pitch_deg
	
	# Toggle mouse
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = (Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
	
	# Interact
	if event.is_action_pressed("interact"):
		_try_interact()

func _physics_process(delta: float) -> void:
	# movimento orizzontale
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var wish_dir := (transform.basis * Vector3(input_vec.x, 0, input_vec.y)).normalized()
	var target_speed := (run_speed if Input.is_action_pressed("run") else walk_speed)
	var target_vel := wish_dir * target_speed
	
	# blend smussato
	var horiz := velocity
	horiz.y = 0.0
	horiz = horiz.lerp(target_vel, clamp(acceleration * delta, 0.0, 1.0))
	velocity.x = horiz.x
	velocity.z = horiz.z
	
	# gravità (se non hai salti, basta tenerla)
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0
	
	move_and_slide()
	_update_animation()

func _update_animation() -> void:
	if not _anim: return
	var speed := Vector2(velocity.x, velocity.z).length()
	var next := &"idle"
	if speed > 0.1:
		next = (&"run" if speed > (walk_speed + run_speed) * 0.25 else &"walk")
	if _current_anim == &"interact" and _anim.is_playing():
		return
	if next != _current_anim:
		_anim.play(next)
		_current_anim = next

func _try_interact() -> void:
	if not _cam: return
	var from := _cam.global_transform.origin
	var dir := -_cam.global_transform.basis.z
	var to := from + dir * interact_distance
	
	var params := PhysicsRayQueryParameters3D.create(from, to)
	params.collision_mask = interact_mask
	params.collide_with_bodies = true
	params.collide_with_areas = true
	
	var hit := get_world_3d().direct_space_state.intersect_ray(params)
	if hit.is_empty():
		return
	
	var collider := hit.get("collider", null)
	if collider == null:
		return
	

	if collider.has_method("interact"):
		collider.call("interact", self)
	elif collider is Node:
		print("[Interact] Hit:", (collider as Node).name)
	
	# anim "interact" se esiste
	if _anim and _anim.has_animation("interact"):
		_anim.play("interact")
		_current_anim = &"interact"
