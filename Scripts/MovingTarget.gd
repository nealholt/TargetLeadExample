extends CharacterBody3D

@export var speed := 150.0
@export var move_x := true
@export var acceleration := 50.0

func _physics_process(delta: float) -> void:
	# Accelerate
	#speed += acceleration * delta
	if move_x:
		velocity.x = speed * delta
	else:
		velocity.z = speed * delta
	move_and_slide()
	#global_position += Vector3(0.0,0.0,1.0) * delta
