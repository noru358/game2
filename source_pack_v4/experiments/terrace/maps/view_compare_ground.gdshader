shader_type spatial;
uniform sampler2D grass_tex : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D dirt_tex : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D paving_tex : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D masonry_tex : source_color,filter_linear_mipmap,repeat_enable;
varying vec3 p;
varying vec3 n;
void vertex(){p=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;n=(MODEL_MATRIX*vec4(NORMAL,0.0)).xyz;}
void fragment(){
 vec2 q=p.xz-vec2(122.0,0.0);
 vec3 grass=texture(grass_tex,p.xz/7.0).rgb*0.78;
 vec3 dirt=texture(dirt_tex,p.xz/8.0).rgb*0.82;
 vec3 stone=texture(paving_tex,p.xz/7.0).rgb*0.78;
 float clearing=1.0-smoothstep(0.75,1.08,length(q/vec2(11.0,7.0))+sin(q.y*0.5)*0.07);
 float path=1.0-smoothstep(2.0,3.5,abs(q.x-10.0-sin(q.y*0.2)));
 vec3 color=mix(grass,dirt,clearing);
 color=mix(color,stone,path*0.85);
 vec3 face_normal=normalize(cross(dFdx(p),dFdy(p)));
 float steep=1.0-smoothstep(0.65,0.92,abs(face_normal.y));
 vec3 wall=texture(masonry_tex,vec2(p.x*0.28,p.y*0.32)).rgb*0.72;
 ALBEDO=mix(color,wall,steep);ROUGHNESS=0.95;
}
