shader_type spatial;
uniform vec4 stone_color : source_color = vec4(0.45,0.40,0.31,1.0);
uniform sampler2D grain_texture : source_color, repeat_enable, filter_linear_mipmap;
uniform bool follow_object = false;
varying vec3 position_world;
varying vec3 normal_world;
void vertex(){
 position_world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 normal_world=normalize(MODEL_NORMAL_MATRIX*NORMAL);
 if(follow_object){position_world=VERTEX;normal_world=NORMAL;}
}
void fragment(){
 vec3 n=abs(normal_world);
 vec2 p=n.y>0.7 ? position_world.xz : (n.z>n.x ? position_world.xy : position_world.zy);
 vec3 painted=texture(grain_texture,p/7.0,1.0).rgb;
 painted=mix(vec3(dot(painted,vec3(0.2126,0.7152,0.0722))),painted,0.55);
 // World-space projection keeps adjacent masonry pieces at a consistent scale.
 vec3 tint=stone_color.rgb/vec3(0.46,0.40,0.31);
 ALBEDO=painted*mix(vec3(1.0),tint,0.45)*0.72;
 ROUGHNESS=1.0;
 SPECULAR=0.0;
}
