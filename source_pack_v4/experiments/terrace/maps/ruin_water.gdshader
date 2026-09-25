shader_type spatial;
uniform sampler2D water_tex:source_color,filter_linear_mipmap,repeat_enable;
uniform bool plain=false;
varying vec3 wp;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
 vec3 c=texture(water_tex,wp.xz/15.0+vec2(TIME*0.002,TIME*0.006)).rgb;
 ALBEDO=plain?vec3(0.17,0.23,0.25):mix(vec3(0.055,0.30,0.32),c*vec3(0.48,0.70,0.65),0.6);
 ROUGHNESS=0.6;SPECULAR=0.15;
}
