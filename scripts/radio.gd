extends StaticBody3D

@onready var soundplayer = $AudioStreamPlayer3D
var staticsound
var triggered = false
# Called when the node enters the scene tree for the first time.
func _ready():
	staticsound = preload("res://audio/sounds/radiostatic.wav")

func _on_check_for_player_body_entered(body):
	if "Player" in body.name:
		if triggered == true:
			return
		elif triggered == false:
			triggered = true
			soundplayer.play()
			await soundplayer.finished
			soundplayer.stream = staticsound
			soundplayer.play()
