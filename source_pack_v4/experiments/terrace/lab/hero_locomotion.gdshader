shader_type spatial;
render_mode unshaded, cull_disabled, depth_prepass_alpha;
uniform sampler2D artwork : source_color, filter_linear;
uniform sampler2D artwork_soft : source_color, filter_linear_mipmap;
uniform bool soft_filter = false;
uniform vec4 region;
uniform float root_u;
uniform float foot_v;
uniform float phase = 0.0;
uniform float amount = 0.0;
uniform float lateral = 1.0;
uniform float dash = 0.0;
uniform float run_blend = 0.0;
void vertex() {
    vec2 p = (UV-region.xy)/region.zw;
    float lower = smoothstep(foot_v-0.20,foot_v-0.025,p.y);
    float body = 1.0-smoothstep(foot_v-0.24,foot_v-0.06,p.y);
    float side = smoothstep(root_u-0.035,root_u+0.035,p.x)*2.0-1.0;
    float leg = sin(phase)*mix(side,1.0,abs(lateral));
    VERTEX.x += amount*lower*leg*mix(0.035,0.13,abs(lateral))*mix(0.75,1.35,run_blend);
    VERTEX.y += amount*(lower*max(0.0,leg)*mix(0.06,0.14,run_blend) + body*(1.0-cos(phase*2.0))*mix(0.012,0.04,run_blend));
    float robe = smoothstep(foot_v-0.50,foot_v-0.30,p.y)*(1.0-lower);
    VERTEX.x += amount*robe*sin(phase+0.6)*mix(0.015,0.035,run_blend);
    VERTEX.x += amount*run_blend*lateral*body*0.055;
    VERTEX.x += dash*lateral*body*0.12;
}
void fragment() {
    vec4 texel = soft_filter ? texture(artwork_soft,UV) : texture(artwork,UV);
    ALBEDO = texel.rgb;
    ALPHA = texel.a;
}
