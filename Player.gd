extends CharacterBody3D

signal health_changed(health_value)

@onready var camera = $Camera3D
@onready var anim_player = $AnimationPlayer
@onready var muzzle_flash = $Camera3D/Pistol/MuzzleFlash
@onready var raycast = $Camera3D/RayCast3D
@onready var timer = $Timer
@onready var Bullet = preload("res://bullet.tscn")

var health = 3
var stunned = false
var bullet_speed = 150

var jumpImpulse = 4.0
var gravity = -10.0
var groundAcceleration = 60.0
var groundSpeedLimit = 120.0
var airAcceleration = 800.0
var airSpeedLimit = 2.0
var groundFriction = 0.9

var mouseSensitivity = 0.002

var restartTransform
var restartVelocity

func _enter_tree():
	set_multiplayer_authority(str(name).to_int())

func _ready():
	if not is_multiplayer_authority(): return
	
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.current = true
	
	restartTransform = self.global_transform
	restartVelocity = self.velocity
	
func _unhandled_input(event):
	if not is_multiplayer_authority(): return
	
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * mouseSensitivity)
		camera.rotate_x(-event.relative.y * mouseSensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)
		
	if Input.is_action_just_pressed("shoot") and anim_player.current_animation != "shoot":
		play_shoot_effects.rpc()
		#if raycast.is_colliding():
			#var hit_player = raycast.get_collider()
			#hit_player.receive_damage.rpc_id(hit_player.get_multiplayer_authority())

func _physics_process(delta):
	if not is_multiplayer_authority(): return
	
	# Apply gravity, jumping, and ground friction to velocity
	velocity.y += gravity * delta
	if is_on_floor():
		# By using is_action_pressed() rather than is_action_just_pressed()
		# we get automatic bunny hopping.
		if Input.is_action_pressed("move_jump"):
			velocity.y = jumpImpulse
		else:
			velocity *= groundFriction
	
	# Compute X/Z axis strafe vector from WASD inputs
	var basis = camera.get_global_transform().basis
	var strafeDir = Vector3(0, 0, 0)
	if not stunned:
		if Input.is_action_pressed("move_forward"):
			strafeDir -= basis.z
		if Input.is_action_pressed("move_backward"):
			strafeDir += basis.z
		if Input.is_action_pressed("move_left"):
			strafeDir -= basis.x
		if Input.is_action_pressed("move_right"):
			strafeDir += basis.x
	strafeDir.y = 0
	strafeDir = strafeDir.normalized()
	
	# Figure out which strafe force and speed limit applies
	var strafeAccel = groundAcceleration if is_on_floor() else airAcceleration
	var speedLimit = groundSpeedLimit if is_on_floor() else airSpeedLimit
	
	# Project current velocity onto the strafe direction, and compute a capped
	# acceleration such that *projected* speed will remain within the limit.
	var currentSpeed = strafeDir.dot(velocity)
	var accel = strafeAccel * delta
	accel = max(0, min(accel, speedLimit - currentSpeed))
	
	# Apply strafe acceleration to velocity and then integrate motion
	velocity += strafeDir * accel
	move_and_slide()
	
	
	###Useful stuff maybe?
	#if Input.is_action_pressed("move_fast"):
		#velocity = Vector3.ZERO
	#if Input.is_action_just_released("move_fast"):
		#velocity = -30 * basis.z
	
	#if Input.is_action_just_pressed("checkpoint"):
		#print("Saving Checkpoint: %s / %s" % [self.translation, self.velocity])
		#restartTransform = self.global_transform
		#restartVelocity = self.velocity	
	
	#if Input.is_action_just_pressed("restart"):
		#self.global_transform = restartTransform
		#self.velocity = restartVelocity
	
	
@rpc("call_local")
func play_shoot_effects():
	#bullet projectile code
	var projectile = Bullet.instantiate()
	
	add_sibling(projectile)
	projectile.ShooterID = self.name
	projectile.transform = raycast.global_transform
	projectile.linear_velocity = raycast.global_transform.basis.z * -1 * bullet_speed
	
	anim_player.stop()
	anim_player.play("shoot")
	muzzle_flash.restart()
	muzzle_flash.emitting = true

@rpc("any_peer")
func receive_damage():
	stunned = true
	timer.start()
	
	health -= 1
	if health <= 0:
		health = 3
		position = Vector3.ZERO
	health_changed.emit(health)

func _on_animation_player_animation_finished(anim_name):
	if anim_name == "shoot":
		anim_player.play("idle")


func _on_timer_timeout():
	if stunned:
		!stunned
