extends Area3D

@export var bullet_hole_decal : PackedScene
var speed := 50.0
var origin:Vector3

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	transform.origin += transform.basis.z * speed * delta


func _on_timer_timeout() -> void:
	queue_free()


func stick_decal(body: Node3D) -> void:
	#Stick a decal on the target or on whatever was hit
	var decal = bullet_hole_decal.instantiate()
	body.add_child(decal)
	decal.global_position = global_position
	decal.look_at(origin, Vector3.UP)


func _on_body_entered(body: Node3D) -> void:
	stick_decal(body)
	queue_free()


func _on_area_entered(area: Area3D) -> void:
	stick_decal(area)
	queue_free()
