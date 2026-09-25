shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform sampler2D panorama : source_color, filter_linear_mipmap;
void fragment(){
 vec4 color=texture(panorama,UV);
 ALBEDO=color.rgb;
 // Blend into the midground crowns before terrain occludes the lower card.
 ALPHA=1.0-smoothstep(0.55,0.85,UV.y);
}
