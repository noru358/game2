shader_type spatial;
render_mode cull_disabled;
uniform sampler2D ground_texture : source_color, repeat_enable;
varying vec3 world_position;
void vertex() { world_position = (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz; }
void fragment() {
	float ripple = sin(UV.y * 3.0 + sin(UV.x * 6.0) - TIME * 1.7);
	vec3 stream = mix(vec3(0.08,0.17,0.16),vec3(0.13,0.23,0.19),smoothstep(0.9,1.0,ripple));
	vec3 ground = texture(ground_texture,world_position.xz/10.0).rgb * vec3(0.67,0.73,0.64);
	ALBEDO = mix(ground,stream,smoothstep(0.0,0.15,min(UV.x,1.0-UV.x)));
	ROUGHNESS = 0.3;
}
