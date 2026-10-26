class_name SpikeTerrain
extends RefCounted
## Erzeugt das Terrain3D für den Spike-Tag per Code: genau 1 Region (256 m × 256 m),
## 2 Boden-Texturen (≤ 1024², ADR 0004) und volle Kollision.
##
## Höhenprofil (lokale Region-Koordinaten in m, Region liegt bei x/z 0..256):
## - Mitte: flache Spielwiese um (128, 128)
## - Osten: gerader 35°-Hang ab x = 170 bis zu einem Plateau
## - Westen und Norden: sanfte Hügel

const REGION_SIZE := 256
const ORIGIN := Vector3(0, 0, 0)
const CENTER := Vector3(128, 0, 128)
const SLOPE_START_X := 170.0
const SLOPE_END_X := 200.0
const TEXTURE_SIZE := 512


## Baut das Terrain als Kind von `parent`. Muss im Baum aufgerufen werden (nach _ready).
static func create(parent: Node, camera: Camera3D = null) -> Terrain3D:
	var terrain := Terrain3D.new()
	terrain.name = "Terrain3D"
	terrain.region_size = REGION_SIZE
	parent.add_child(terrain, true)
	if camera:
		terrain.set_camera(camera)

	terrain.material.world_background = Terrain3DMaterial.FLAT  # Wiese bis zum Horizont statt Leere
	terrain.material.auto_shader = true
	terrain.material.set_shader_param("auto_slope", 10)
	terrain.assets = Terrain3DAssets.new()
	# Auto-Shader: Textur 1 auf flachem Boden, Textur 0 an steilen Hängen.
	terrain.assets.set_texture(0, _texture_asset("Erde", Color.from_hsv(0.07, 0.55, 0.55)))
	terrain.assets.set_texture(1, _texture_asset("Wiese", Color.from_hsv(0.29, 0.58, 0.54)))

	terrain.data.import_images([_height_map(), null, null], ORIGIN, 0.0, 1.0)
	terrain.set_collision_mode(Terrain3DCollision.FULL_GAME)
	return terrain


static func height_at(x: float, z: float) -> float:
	var slope := tan(deg_to_rad(VehicleConstants.TARGET_HILL_ANGLE_DEG))
	if x >= SLOPE_START_X:
		return (minf(x, SLOPE_END_X) - SLOPE_START_X) * slope
	var hills := 0.0
	if x < 90.0 or z < 70.0:
		var fade := clampf(maxf(90.0 - x, 70.0 - z) / 30.0, 0.0, 1.0)
		fade *= clampf((140.0 - x) / 20.0, 0.0, 1.0)  # Abstand zum Hang halten
		hills = (sin(x * 0.08) * cos(z * 0.06) + 1.0) * 2.5 * fade
	return hills


static func _height_map() -> Image:
	var img := Image.create_empty(REGION_SIZE, REGION_SIZE, false, Image.FORMAT_RF)
	for z in REGION_SIZE:
		for x in REGION_SIZE:
			img.set_pixel(x, z, Color(height_at(x, z), 0, 0))
	return img


## Einfarbige Textur mit leichtem Rauschen; ersetzt später echte Blender/PNG-Texturen.
static func _texture_asset(asset_name: String, base: Color) -> Terrain3DTextureAsset:
	var noise := FastNoiseLite.new()
	noise.frequency = 0.02
	var albedo := Image.create_empty(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	var normal := Image.create_empty(TEXTURE_SIZE, TEXTURE_SIZE, false, Image.FORMAT_RGBA8)
	for y in TEXTURE_SIZE:
		for x in TEXTURE_SIZE:
			var n := noise.get_noise_2d(x, y) * 0.5 + 0.5
			var c := base.darkened(0.25 - n * 0.25)
			c.a = n  # Höhe im Alpha-Kanal
			albedo.set_pixel(x, y, c)
			normal.set_pixel(x, y, Color(0.5, 0.5, 1.0, 0.85))  # flach, Rauheit 0,85
	albedo.generate_mipmaps()
	normal.generate_mipmaps()
	var asset := Terrain3DTextureAsset.new()
	asset.name = asset_name
	asset.albedo_texture = ImageTexture.create_from_image(albedo)
	asset.normal_texture = ImageTexture.create_from_image(normal)
	asset.uv_scale = 0.1
	return asset
