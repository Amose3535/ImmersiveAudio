extends Marker3D

var rot_speed : float = 0.5

func _physics_process(delta: float) -> void:
	self.rotation.y += delta*rot_speed
