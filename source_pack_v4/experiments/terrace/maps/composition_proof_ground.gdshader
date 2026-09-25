shader_type spatial;
render_mode diffuse_burley,cull_disabled;
uniform sampler2D grass_tex : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D dirt_tex : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D paving_tex : source_color,filter_linear_mipmap,repeat_enable;
uniform sampler2D masonry_tex : source_color,filter_linear_mipmap,repeat_enable;
uniform int surface_kind = 0;
varying vec3 world_pos;

void vertex(){
 world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
}

float segment_distance(vec2 p,vec2 a,vec2 b){
 vec2 ab=b-a;
 return length(p-a-ab*clamp(dot(p-a,ab)/max(dot(ab,ab),0.001),0.0,1.0));
}

void fragment(){
 vec2 p=world_pos.xz;
 vec3 grass=texture(grass_tex,p/7.5).rgb*0.78;
 vec3 dirt=texture(dirt_tex,p/7.0).rgb*0.80;
 vec3 stone=texture(paving_tex,p/6.2).rgb*0.74;
 vec3 color=grass;

 if(surface_kind==0){
  vec2 q=p-vec2(123.5,5.5);
  float quiet_box=max(abs(q.x)/13.0,abs(q.y)/8.2);
  float clearing=1.0-smoothstep(0.74,1.04,quiet_box);
  float approach=min(segment_distance(p,vec2(107.0,16.0),vec2(120.0,9.0)),segment_distance(p,vec2(120.0,9.0),vec2(128.0,-5.5)));
  color=mix(grass,dirt,max(clearing,1.0-smoothstep(1.8,3.1,approach)));
  color=mix(color,stone,(1.0-smoothstep(1.0,1.8,approach))*0.66);
 }else if(surface_kind==1){
  vec2 q=p-vec2(131.0,-20.0);
  float court=max(abs(q.x)/9.5,abs(q.y)/6.0);
  color=mix(grass,stone,1.0-smoothstep(0.68,1.05,court));
 }else if(surface_kind==2){
  float entry=segment_distance(p,vec2(94.0,23.0),vec2(102.0,18.5));
  color=mix(grass,dirt,1.0-smoothstep(1.6,3.0,entry));
 }else{
  color=stone;
  float tread_phase=fract((p.y+14.5)*2.0);
  float tread=1.0-smoothstep(0.035,0.11,abs(tread_phase-0.08));
  color*=mix(1.0,0.66,tread);
 }

 vec3 face_normal=normalize(cross(dFdx(world_pos),dFdy(world_pos)));
 float steep=1.0-smoothstep(0.58,0.90,abs(face_normal.y));
 vec2 wall_uv=abs(face_normal.x)>abs(face_normal.z) ? vec2(world_pos.z,world_pos.y)/3.2 : vec2(world_pos.x,world_pos.y)/3.2;
 vec3 wall=texture(masonry_tex,wall_uv).rgb*0.66;
 ALBEDO=mix(color,wall,steep);
 ROUGHNESS=0.94;
 SPECULAR=0.16;
}
