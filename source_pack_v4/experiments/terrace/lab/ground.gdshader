shader_type spatial;
render_mode diffuse_burley;
uniform int region = -1;
varying vec3 ground_pos;
varying float steepness;
varying vec3 ground_normal;
uniform sampler2D soil_texture : source_color, filter_linear_mipmap;
uniform sampler2D stone_texture : source_color, filter_linear_mipmap;
void vertex(){ground_pos=VERTEX;ground_normal=NORMAL;steepness=1.0-abs(NORMAL.y);}
void fragment(){
 vec2 p=ground_pos.xz;
 float x=p.x-120.0;
 float river=(1.0-smoothstep(1.3,1.65,abs(x-sin(p.y*0.14)*0.65)))*smoothstep(-27.0,-22.5,p.y);
 if(region==0){float basin=(1.0-smoothstep(4.9,5.2,abs(p.x-123.0)))*(1.0-smoothstep(7.9,8.2,abs(p.y+6.0)));river=max(river,basin);}
 float left_road=1.0-smoothstep(2.2,2.6,abs(x+10.0-sin(p.y*0.14)*1.3));
 float right_road=1.0-smoothstep(1.5,1.9,abs(x-10.0-sin(p.y*0.18)*1.2));
 float road=max(left_road,right_road);
 float crossroad=1.0-smoothstep(2.0,2.5,abs(p.y+19.0));
 if(region==1){
   float lower=left_road*(1.0-smoothstep(-14.0,-11.0,p.y));
   float upper=right_road*smoothstep(-15.0,-12.0,p.y);
   road=max(lower,upper);
   crossroad=1.0-smoothstep(1.1,1.8,abs(p.y+13.0));
   river=0.0;
 }
 vec3 soil=texture(soil_texture,p/16.0).rgb*vec3(0.26,0.36,0.29);
 vec3 stone=mix(vec3(0.32,0.34,0.25),texture(stone_texture,p/14.0).rgb*0.5,0.28);
 ALBEDO=mix(soil,stone,max(road,crossroad));
 ALBEDO=mix(ALBEDO,vec3(0.045,0.135,0.12)+sin(p.y*3.0+TIME*1.2)*0.005,river*(1.0-crossroad));
 vec3 weights=pow(abs(ground_normal),vec3(4.0));weights/=max(dot(weights,vec3(1.0)),0.001);
 vec3 rock_x=texture(stone_texture,ground_pos.zy/5.0).rgb;
 vec3 rock_z=texture(stone_texture,ground_pos.xy/5.0).rgb;
 vec3 rock_y=texture(stone_texture,ground_pos.xz/5.0).rgb;
 vec3 cliff=(rock_x*weights.x+rock_y*weights.y+rock_z*weights.z)*vec3(0.50,0.52,0.40);
 float course=1.0-smoothstep(0.025,0.09,abs(fract(ground_pos.y*1.6)-0.5));
 cliff*=1.0-course*0.3;
 ALBEDO=mix(ALBEDO,cliff,smoothstep(0.12,0.30,steepness));
 ROUGHNESS=0.95;
}
