extends RigidBody3D

@onready var Explosion = preload("res://explosion.tscn")
var ShooterID

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	#create explosion
	if body.name != ShooterID: 
		print(body)
		var explosion_area = Explosion.instantiate()
		add_sibling(explosion_area)
		explosion_area.transform = self.global_transform
		queue_free()
		
	
