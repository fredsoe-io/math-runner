class_name ParticleSpawner
extends RefCounted
## Spawns a one-shot burst of particles and frees it afterwards.
## Ported from Jumpy Boi (common/ParticleSpawner.cs). The differences:
## - The burst is added to `parent` and follows it, instead of staying behind in the
##   world. The runner never stands still, so a burst left in the world would
##   slide off the screen before you see it.
## - The particles fly out all the way round (360°), not only upwards.
## - The particles fade out instead of vanishing all at once.
## - `size` is a parameter, because this game is not pixel-art sized.
## - `delay` waits before the pop, so several bursts can be staggered.

static func spawn_burst(parent: Node, pos: Vector2, color: Color = Color.WHITE, amount: int = 12, speed: float = 110.0, size: float = 2.0, delay: float = 0.0) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false # a new CPUParticles2D emits by default, wait for the delay
	p.z_index = 10
	p.local_coords = true # the particles move along with the parent
	p.explosiveness = 0.9 # release them all at once = a pop
	p.amount = amount
	p.spread = 180.0 # ±180° around direction = all the way round
	p.direction = Vector2.UP
	p.gravity = Vector2(0, 250)
	p.scale_amount_min = size
	p.scale_amount_max = size * 1.5
	p.lifetime = 0.5
	p.color = color
	p.color_ramp = _make_fade()
	p.initial_velocity_min = speed
	p.initial_velocity_max = speed

	parent.add_child(p)
	p.process_mode = Node.PROCESS_MODE_ALWAYS
	p.global_position = pos

	if delay > 0.0:
		parent.get_tree().create_timer(delay).timeout.connect(p.set_emitting.bind(true))
	else:
		p.emitting = true

	parent.get_tree().create_timer(delay + 1.2).timeout.connect(p.queue_free)

# Each particle goes from fully visible to see-through over its lifetime
static func _make_fade() -> Gradient:
	var fade := Gradient.new()
	fade.set_color(0, Color.WHITE)
	fade.set_color(1, Color(1, 1, 1, 0))
	return fade
