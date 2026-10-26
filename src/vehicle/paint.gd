class_name Paint
## Lack für gezeichnete Teile: einfarbig oder Regenbogen. Der Regenbogen hängt an der Weltposition,
## deshalb wandern die Farben beim Fahren über den Crawler (gewollt: „Zauberlack“).
## Die Kenney-Modelle nutzen dieselbe Regenbogen-Funktion in ihrem Palettenshader (KenneyModels).

## GLSL-Bausteine, die beide Shader einbinden.
const RAINBOW_GLSL := """
varying vec3 world_pos;
vec3 rainbow_at(vec3 p) {
	float h = fract(dot(p, vec3(0.23, 0.31, 0.17)));
	vec3 c = clamp(abs(mod(h * 6.0 + vec3(0.0, 4.0, 2.0), 6.0) - 3.0) - 1.0, 0.0, 1.0);
	return mix(vec3(1.0), c, 0.85);
}
"""
const WORLD_POS_VERTEX := """
void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
"""
const RAINBOW_SHADER := "shader_type spatial;\n" + RAINBOW_GLSL + WORLD_POS_VERTEX + """
void fragment() {
	ALBEDO = rainbow_at(world_pos);
	ROUGHNESS = 0.5;
}
"""

static var _rainbow: ShaderMaterial


## Material für eine lackierte Fläche. Regenbogen-Material wird geteilt (ein Shader für alle).
static func solid(color: Color, rainbow := false) -> Material:
	if rainbow:
		if _rainbow == null:
			var shader := Shader.new()
			shader.code = RAINBOW_SHADER
			_rainbow = ShaderMaterial.new()
			_rainbow.shader = shader
		return _rainbow
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.6
	return m
