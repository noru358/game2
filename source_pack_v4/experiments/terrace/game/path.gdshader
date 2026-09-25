shader_type spatial;
render_mode cull_disabled;
uniform sampler2D ground_texture : source_color, repeat_enable;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float grain = sin(UV.y * 2.1 + sin(UV.x * 15.0)) * 0.025;
	float edge = min(UV.x,1.0-UV.x);
	vec3 ground = texture(ground_texture,world_position.xz/10.0).rgb * vec3(0.67,0.73,0.64);
	ALBEDO = mix(ground,vec3(0.30,0.25,0.16)+grain,smoothstep(0.0,0.2,edge)*0.75);
	ROUGHNESS = 1.0;
}
