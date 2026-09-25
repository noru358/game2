shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform vec4 tint : source_color = vec4(0.03,0.07,0.06,0.36);
void fragment() {
	float d = length((UV-vec2(0.5))*2.0);
	ALBEDO = tint.rgb;
	ALPHA = (1.0-smoothstep(0.25,1.0,d))*tint.a;
}
