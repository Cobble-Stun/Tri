extends Area3D

func _on_body_entered(body):
	if "Player" in body.name:
		body.playsinglesound(body.pickupsoundfile, body.footstepsoundorigin)
		queue_free()
		body.reserveammo += 3
		body.reservetext.text = str(body.reserveammo)
