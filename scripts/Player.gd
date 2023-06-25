extends CharacterBody3D

#movement variables
const defaultheight = 1.5
const crouchheight = 0.7
var speed
const CROUCHSPEED = 1
const WALKSPEED = 3.0
const RUNSPEED = 5.0
const JUMP_VELOCITY = 4.5
const crouchtransisitionspeed = 20
const SENSITIVITY = 0.01
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

#bob variables
const BOB_FREQUENCY = 2.0
const BOB_AMP = 0.12
var toggleSpeed = 2.0
var t_bob = 0.0
@onready var pcol := $CollisionShape3D
@onready var neck := $Neck
@onready var camera := $Neck/Camera3D
@onready var startPos = camera.transform.origin
@onready var guncamera := $Neck/Camera3D/SubViewportContainer/SubViewport/Guncam

#audio
var canplayfootstepsound = true
var songfiles = []
var flashlightsoundfiles = []
var gunsoundfiles = []
var pickupsoundfile

var footstepsoundtype = 0
var grasssoundfiles = []
var concretesoundfiles = []

@onready var ambienceplayer = $Ambience
@onready var footstepsoundorigin = $Footstepsoundsorigin
@onready var flashlightsoundorigin = $Neck/flashlightsoundorigin
@onready var gunsoundorigin = $"Neck/Camera3D/Tri hands/gunsoundorigin"
@onready var footsteptimer = $Footstepsoundsorigin/Timer

#animation
@onready var handsanimplayer = $"Neck/Camera3D/Tri hands/AnimationPlayer"
@onready var gunanimplayer = $"Neck/Camera3D/Tri hands/hands armature/Skeleton3D/BoneAttachment3D/Tri shotgun/AnimationPlayer"

#UI
@onready var damageoverlay = $CanvasLayer/DamageOverlay
@onready var fade = $CanvasLayer/Black
@onready var message = $CanvasLayer/Message
@onready var ammotext = $CanvasLayer/Ammo
@onready var reservetext = $CanvasLayer/Reserve
@onready var texttimer = $TextTimer

#misc
var hp = 3
var dead = false

@onready var raycast = $Neck/Camera3D/RayCast3D
var ammo = 0
var reserveammo = 0

@onready var flashlight := $Neck/Camera3D/FlashLight
var flashlighton
@onready var hands = $"Neck/Camera3D/Tri hands"
var parts = 0

func _ready():
	grasssoundfiles.append(preload("res://audio/sounds/f_grass0.wav"))
	grasssoundfiles.append(preload("res://audio/sounds/f_grass1.wav"))
	grasssoundfiles.append(preload("res://audio/sounds/f_grass2.wav"))
	grasssoundfiles.append(preload("res://audio/sounds/f_grass3.wav"))
	grasssoundfiles.append(preload("res://audio/sounds/f_grass4.wav"))
	
	concretesoundfiles.append(preload("res://audio/sounds/f_concrete0.wav"))
	concretesoundfiles.append(preload("res://audio/sounds/f_concrete1.wav"))
	concretesoundfiles.append(preload("res://audio/sounds/f_concrete2.wav"))
	concretesoundfiles.append(preload("res://audio/sounds/f_concrete3.wav"))
	concretesoundfiles.append(preload("res://audio/sounds/f_concrete4.wav"))
	
	flashlightsoundfiles.append(preload("res://audio/sounds/flashlight on.wav"))
	flashlightsoundfiles.append(preload("res://audio/sounds/flashlight off.wav"))
	
	gunsoundfiles.append(preload("res://audio/sounds/gunshot.wav"))
	gunsoundfiles.append(preload("res://audio/sounds/reload.wav"))
	
	pickupsoundfile = preload("res://audio/sounds/item pickup.wav")
	handsanimplayer.play("Idle")
	gunanimplayer.play("Idle")
	
	if SkipIntro.introplayed == false:
		fade.visible = true
		message.text = "[center]My car needs 3 parts.[/center]"
		texttimer.start()
		await texttimer.timeout
		texttimer.stop()
		message.modulate = Color(1,1,1,0)
		SkipIntro.introplayed = true
		fade.visible = false
	
func _input(event):
	if event is InputEventMouseMotion:
		neck.rotate_y(-event.relative.x * SENSITIVITY)
		camera.rotate_x(-event.relative.y * SENSITIVITY)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-90), deg_to_rad(90))
		
func _process(_delta):
	if hp == 2:
		damageoverlay.visible = true
		damageoverlay.modulate = Color(1,1,1,0.2)
	elif hp == 1:
		damageoverlay.modulate = Color(1,1,1,0.5)
	elif hp == 0 and dead == false:
		dead = true
		message.modulate = Color(1,1,1,1)
		damageoverlay.visible = false
		fade.visible = true
		ammotext.visible = false
		reservetext.visible = false
		message.text = "[center]Letum.[/center]"
		texttimer.start()
		await texttimer.timeout
		texttimer.stop()
		message.modulate = Color(1,1,1,0)
		SkipIntro.introplayed = true
		get_tree().reload_current_scene()
	#FlashLight
	if Input.is_action_just_released("flashlight") and flashlight.is_visible_in_tree() and !handsanimplayer.current_animation == "Reload":
		flashlight.hide()
		flashlighton = false
		playsinglesound(flashlightsoundfiles[0], flashlightsoundorigin)
	elif Input.is_action_just_released("flashlight") and !flashlight.is_visible_in_tree() and !handsanimplayer.current_animation == "Reload":
		flashlight.show()
		flashlighton = true
		playsinglesound(flashlightsoundfiles[1], flashlightsoundorigin)
		
	if hands.visible == true:
		if Input.is_action_just_pressed("shoot") and !handsanimplayer.current_animation == "Reload" and ammo > 0:
			handsanimplayer.stop(true)
			gunanimplayer.stop(true)
			ammo -= 1
			ammotext.text = str(ammo)
			handsanimplayer.play("Shoot")
			gunanimplayer.play("Shoot")
			playsinglesound(gunsoundfiles[0], gunsoundorigin)
			await handsanimplayer.animation_finished
			handsanimplayer.play("Idle")
			gunanimplayer.play("Idle")
			if raycast.is_colliding():
				var target = raycast.get_collider()
				if "Enemy" in target.name:
					target.enemy_damage_dealt()
		elif Input.is_action_just_pressed("reload") and ammo < 3 and !handsanimplayer.current_animation == "Reload" and reserveammo >= 3:
			reserveammo -= 3
			reservetext.text = str(reserveammo)
			handsanimplayer.stop(true)
			gunanimplayer.stop(true)
			handsanimplayer.play("Reload")
			gunanimplayer.play("Reload")
			playsinglesound(gunsoundfiles[1], gunsoundorigin)
			await handsanimplayer.animation_finished
			ammo = 3
			ammotext.text = str(ammo)
			handsanimplayer.play("Idle")
			gunanimplayer.play("Idle")
			
func _physics_process(delta):
	#default movement stuff
	speed = WALKSPEED
	
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	# Sprinting
	if Input.is_action_pressed("sprint"):
		speed = RUNSPEED
		
	# Crouching
	if Input.is_action_pressed("crouching"):
		pcol.shape.height -= crouchtransisitionspeed * delta
		speed = CROUCHSPEED
		
	else:
		pcol.shape.height += crouchtransisitionspeed * delta
	pcol.shape.height = clamp(pcol.shape.height, crouchheight, defaultheight)

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (neck.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if is_on_floor() and direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if(canplayfootstepsound):
			canplayfootstepsound = false
			if(footstepsoundtype == 0):
				playrandfootsteps(grasssoundfiles)
			elif(footstepsoundtype == 1):
				playrandfootsteps(concretesoundfiles)
			else: 
				playrandfootsteps(grasssoundfiles)
	elif is_on_floor() and direction == Vector3.ZERO:
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 7.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 7.0)
	else:
		velocity.y -= gravity * delta
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 3.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 3.0)

	t_bob += delta * velocity.length() * float(is_on_floor())
	headbobtoggle(t_bob)
	restartpos(delta)
	move_and_slide()
	
func headbobtoggle(time):
	if(velocity.length() < toggleSpeed or !is_on_floor()):
		return
	playmotion(headbob(time))
	
func headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQUENCY) * BOB_AMP + 1.0
	pos.x = cos(time * BOB_FREQUENCY/2.0) * BOB_AMP * 2.0
	return pos
	
func restartpos(time):
	if(camera.transform.origin == startPos):
		return
	camera.transform.origin = camera.transform.origin.lerp(startPos, 1 * time)
	
func playmotion(motion):
	camera.transform.origin = motion
	
func playrandfootsteps(array):
	if speed == WALKSPEED:
		footsteptimer.wait_time = 1.1
	elif speed == RUNSPEED:
		footsteptimer.wait_time = 0.6
	elif speed == CROUCHSPEED:
		footsteptimer.wait_time = 1.3
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var splayer = AudioStreamPlayer3D.new()
	splayer.bus = "sfx"
	footstepsoundorigin.add_child(splayer)
	
	splayer.stream = (array[rng.randi_range(0,4)])
	footsteptimer.start()
	splayer.play()
	await splayer.finished
	splayer.queue_free()
	await footsteptimer.timeout 
	footsteptimer.stop()
	canplayfootstepsound = true

func playsinglesound(sound, origin):
	var splayer = AudioStreamPlayer3D.new()
	origin.add_child(splayer)
	splayer.bus = "sfx"
	
	splayer.stream = sound
	splayer.play()
	await splayer.finished
	splayer.queue_free()
	
func die():
	get_tree().reload_current_scene()
	
func partscheck():
	if parts == 1:
		message.modulate = Color(1,1,1,1)
		message.text = "[center]2 more parts.[/center]"
		texttimer.start()
		await texttimer.timeout
		texttimer.stop()
		message.modulate = Color(1,1,1,0)
	elif parts == 2:
		message.modulate = Color(1,1,1,1)
		message.text = "[center]1 last part.[/center]"
		texttimer.start()
		await texttimer.timeout
		texttimer.stop()
		message.modulate = Color(1,1,1,0)
	elif parts == 3:
		message.modulate = Color(1,1,1,1)
		message.text = "[center]I need to get to the car.[/center]"
		texttimer.start()
		await texttimer.timeout
		texttimer.stop()
		message.modulate = Color(1,1,1,0)
	
func _on_timer_timeout():
	canplayfootstepsound = true

func _on_area_3d_body_entered(body):
	if "Player" in body.name:
		footstepsoundtype = 1

func _on_area_3d_body_exited(body):
	if "Player" in body.name:
		footstepsoundtype = 0
