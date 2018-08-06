extends Area2D

var feedbackScene = preload("res://ItemFeedback.tscn")

func _on_Gem_body_entered(body):
	if body.name == "Player":
		body.pickup_gem()
		var feedback = feedbackScene.instance()
		feedback.position = position
		get_parent().add_child(feedback)
		queue_free()
	pass # replace with function body
