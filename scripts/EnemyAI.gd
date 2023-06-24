extends CharacterBody3D

enum {
	IDLE,
	TARGETFOUND,
	TARGETLOST,
	PURSUING,
	ATTACKING,
	DEAD
}
var state = IDLE
@onready var player = get_parent().get_node("Player")
@onready var nav_agent = $NavigationAgent3D
@onready var animplayer = $shadowzombie/AnimationPlayer
@onready var audioplayer = $AudioStreamPlayer3D
@onready var hitsoundplayer = $hitsounds
@onready var collider = $CollisionShape3D
@onready var timer = $Timer
@onready var attacktimer = $AttackTimer

var chasestartrange = 15
var hp = 3
var speed
const attack_range = 2
var dead = false
var attacking = false
var deathsound
var hitsound

func _ready():
	animplayer.play("Idle")
	deathsound = preload("res://audio/sounds/enemydeathsound.wav")	
	hitsound = preload("res://audio/sounds/hitsound.wav")
	
func _physics_process(delta):
	velocity = Vector3.ZERO
	nav_agent.set_target_position(player.global_transform.origin)
	var next_nav_point = nav_agent.get_next_path_position()
	if hp == 0:
		state = DEAD
	
	if player.hp == 0:
		queue_free()
	match state:
		IDLE:
			animplayer.play("Idle")
			if global_position.distance_to(player.global_position) <= chasestartrange:
				state = TARGETFOUND
				
		TARGETFOUND:
			animplayer.play("Target")
			await animplayer.animation_finished
			state = PURSUING
			
		TARGETLOST:
			animplayer.play_backwards("Target")
			await animplayer.animation_finished
			state = IDLE
		PURSUING:
			if attacking == false:
				animplayer.play("Pursuing")
				speed = 150
			else:
				speed = 125
			velocity = (next_nav_point - global_transform.origin).normalized() * delta * speed
			look_at(Vector3(player.global_position.x, player.global_position.y, player.global_position.z), Vector3.UP)
			move_and_slide()
			if global_position.distance_to(player.global_position) > chasestartrange:
				state = TARGETLOST
			elif global_position.distance_to(player.global_position) < attack_range:
				if attacking == false:
					attacking = true
					timer.start()
					animplayer.stop(true)
					animplayer.play("Attacking")
					do_damage_to_target()
					await timer.timeout
					timer.stop()
					attacking = false
			
		DEAD:
			if dead == false:
				dead = true
				audioplayer.stream = deathsound
				audioplayer.play()
				animplayer.play("Dying")
				await animplayer.animation_finished
				self.visible = false
				collider.disabled = true
				await audioplayer.finished
				queue_free()
			
func enemy_damage_dealt():
	hp = hp - 1

func do_damage_to_target():
	attacktimer.start()
	await attacktimer.timeout
	if global_position.distance_to(player.global_position) < attack_range:
		player.hp -= 1
		hitsoundplayer.stream = hitsound
		hitsoundplayer.play()
		attacktimer.stop()
		return
