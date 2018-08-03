extends AnimatedSprite

func _ready():
	playing = true

func _on_AnimatedSprite_animation_finished():
	queue_free()
