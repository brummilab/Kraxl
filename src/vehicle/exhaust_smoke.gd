class_name ExhaustSmoke
extends GPUParticles3D
## Auspuffrauch: kleine graue Wölkchen, die aufsteigen, wachsen und verblassen. Im Leerlauf
## pafft es leise, mit Gas qualmt es kräftiger (amount_ratio). Reine Optik – keine Physik-Werte.

const IDLE_RATIO := 0.25
const PUFF_SPEED := 0.6  # m/s Austrittsgeschwindigkeit im Leerlauf
const SMOOTHING := 5.0  # 1/s, wie schnell die Rauchmenge dem Gas folgt

var vehicle: KraxlVehicle

static var _mesh: SphereMesh
static var _motion: ParticleProcessMaterial


## `exhaust`: Lage der Auspufföffnung im Fahrzeug, -Z der Basis zeigt in Austrittsrichtung.
func _init(owner_vehicle: KraxlVehicle, exhaust: Transform3D) -> void:
	vehicle = owner_vehicle
	name = "Auspuffrauch"
	transform = exhaust
	if _mesh == null:
		_build_shared()
	draw_pass_1 = _mesh
	process_material = _motion
	amount = 24
	lifetime = 1.4
	local_coords = false  # Wölkchen bleiben in der Welt stehen, wenn der Crawler wegfährt
	visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 5, 6))
	amount_ratio = IDLE_RATIO


func _process(delta: float) -> void:
	var throttle := absf(vehicle.input.throttle)
	var blend := 1.0 - exp(-SMOOTHING * delta)
	amount_ratio = lerpf(amount_ratio, lerpf(IDLE_RATIO, 1.0, throttle), blend)
	speed_scale = lerpf(1.0, 1.6, throttle)


static func _build_shared() -> void:
	_mesh = SphereMesh.new()
	_mesh.radius = 0.16
	_mesh.height = 0.32
	_mesh.radial_segments = 8
	_mesh.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	_mesh.material = material

	_motion = ParticleProcessMaterial.new()
	_motion.direction = Vector3.FORWARD
	_motion.spread = 12.0
	_motion.initial_velocity_min = PUFF_SPEED * 0.7
	_motion.initial_velocity_max = PUFF_SPEED
	_motion.gravity = Vector3(0, 0.5, 0)  # warmer Rauch steigt auf
	_motion.damping_min = 0.6
	_motion.damping_max = 1.0
	_motion.scale_min = 0.6
	_motion.scale_max = 1.0
	var grow := Curve.new()
	grow.max_value = 3.0
	grow.add_point(Vector2(0.0, 0.5))
	grow.add_point(Vector2(1.0, 2.6))
	var grow_texture := CurveTexture.new()
	grow_texture.curve = grow
	_motion.scale_curve = grow_texture
	var fade := Gradient.new()
	fade.set_color(0, Color(0.55, 0.55, 0.58, 0.8))
	fade.set_color(1, Color(0.85, 0.85, 0.88, 0.0))
	var fade_texture := GradientTexture1D.new()
	fade_texture.gradient = fade
	_motion.color_ramp = fade_texture
