extends Area3D

func _on_body_entered(body):
	if "Player" in body.name:
		queue_free()
		body.hands.visible = true
		print("Hello")
		body.playsinglesound(body.pickupsoundfile, body.footstepsoundorigin)
		body.ammotext.text = str(body.ammo)
		body.reservetext.text = str(body.reserveammo)
		body.handsanimplayer.play("Idle")
		body.gunanimplayer.play("Idle")
