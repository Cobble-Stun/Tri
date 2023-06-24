extends Area3D

func _on_body_entered(body):
	if "Player" in body.name:
		queue_free()
		body.playsinglesound(body.pickupsoundfile, body.footstepsoundorigin)
		body.parts += 1
		body.partscheck()
