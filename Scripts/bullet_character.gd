extends CharacterBody3D

@export var bullet_hole_decal : PackedScene
var speed := 50.0
var origin:Vector3
var gravity := 0.0
var movement_vect := Vector3(0,0,1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	velocity = movement_vect * delta
	movement_vect += Vector3(0, gravity * delta, 0) # add gravity
	var collision:KinematicCollision3D = move_and_collide(velocity)
	if collision:
		stick_decal(collision)
		queue_free()


func _on_timer_timeout() -> void:
	queue_free()


func stick_decal(collision: KinematicCollision3D) -> void:
	#Stick a decal on the target or on whatever was hit
	var decal = bullet_hole_decal.instantiate()
	var body = collision.get_collider()
	body.add_child(decal)
	decal.global_position = collision.get_position()
	decal.look_at(origin, Vector3.UP)


func set_movement_vector() -> void:
	movement_vect = transform.basis.z.normalized() * speed
