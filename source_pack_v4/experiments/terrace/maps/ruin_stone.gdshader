shader_type spatial;
uniform sampler2D grain : source_color,filter_linear_mipmap,repeat_enable;
uniform bool wall=false;
uniform bool plain=false;
uniform bool stair=false;
uniform bool entry_palette=false;
varying vec3 wp;
varying vec3 wn;
void vertex(){wp=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;wn=(MODEL_MATRIX*vec4(NORMAL,0.0)).xyz;}
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
 vec2 p=wp.xz;
 if(wall){p=abs(wn.x)>0.5?vec2(wp.z,wp.y):vec2(wp.x,wp.y);}
 vec2 uv=p/(wall?vec2(1.5,0.65):vec2(1.9,1.25));
 if(entry_palette&&!wall&&!stair)uv=p/vec2(1.2,0.8);
 uv.x+=mod(floor(uv.y),2.0)*0.5;
 vec2 f=fract(uv);vec2 edge=min(f,1.0-f);
 float seam=1.0-smoothstep(0.014,0.033,min(edge.x,edge.y));
 float variation=hash(floor(uv));
 vec3 base=wall?vec3(0.43,0.45,0.35):vec3(0.66,0.60,0.43);
 if(entry_palette)base=wall?vec3(0.38,0.40,0.33):vec3(0.59,0.56,0.44);
 vec3 detail=texture(grain,p/5.0).rgb;
 vec3 col=base*(0.90+variation*0.16);
 col=mix(col,col*(0.75+detail*0.42),0.36);
 col=mix(col,col*0.60,seam*0.7);
 float moss=smoothstep(0.73,0.88,sin(wp.x*0.47)*sin(wp.z*0.57)+sin(wp.x*0.19+wp.z*0.31)*0.23);
 if(!wall)col=mix(col,vec3(0.35,0.43,0.20),moss*0.55);
 if(entry_palette&&!wall){
   col=mix(base*(0.94+variation*0.10),base*0.69,seam*0.55);
   float grass=0.0;
   if(!stair){grass=max(smoothstep(18.0,23.0,wp.x),1.0-smoothstep(-19.0,-14.0,wp.x));
     if(wp.x<-8.0)grass=max(grass,1.0-smoothstep(0.0,2.0,min(abs(wp.z-8.0),abs(wp.z-18.0))));
     if(wp.x<-8.0&&(wp.z<8.0||wp.z>18.0))grass=1.0;
   }
   col=mix(col,vec3(0.27,0.35,0.18)*(0.97+texture(grain,wp.xz/7.0).g*0.12),grass);
 }
 if(stair){float tread=fract(wp.z*2.0);col=base*mix(0.72,1.06,smoothstep(0.0,0.09,tread));col*=mix(0.76,1.0,abs(wn.y));}
 ALBEDO=plain?(wall?vec3(0.34):vec3(0.65)):col;ROUGHNESS=1.0;SPECULAR=0.05;
}
