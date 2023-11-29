extends Node3D

var explosion_force = 25

# Called when the node enters the scene tree for the first time.
func _ready():
	var timer = $Timer
	timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_area_3d_body_entered(body):
	var vector_to_body = body.global_transform.origin - global_transform.origin
	var direction = vector_to_body.normalized()
	var distance = vector_to_body.length()
	var knockback = explosion_force/distance
	
	knockback = clamp(knockback, 10, 50)
	direction.y += 1
	var push_vector = direction * knockback
	
	body.velocity += push_vector
	#body.stunned = true
	
func _on_timer_timeout():
	queue_free()
