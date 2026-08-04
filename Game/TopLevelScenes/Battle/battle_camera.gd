class_name battle_camera
extends Camera2D

@export var random_strength: float = 30.0
@export var shake_decay: float = 5.0

var trauma: float = 0.0
var noise := FastNoiseLite.new()
var noise_y: int = 0

func _ready() -> void:
    randomize()
    noise.seed = randi()
    noise.frequency = 2.0

func add_shake(amount: float) -> void:
    trauma = min(trauma + amount, 1.0)

func _process(delta: float) -> void:
    if trauma > 0:
        trauma = max(trauma - shake_decay * delta, 0.0)
        offset = get_shake_offset()
    else:
        offset = Vector2.ZERO

func get_shake_offset() -> Vector2:
    var shake := pow(trauma, 2)
    noise_y += 1
    return Vector2(
        noise.get_noise_2d(noise_y, 0) * random_strength * shake,
        noise.get_noise_2d(0, noise_y) * random_strength * shake
    )
