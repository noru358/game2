shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, fog_disabled;
uniform float phase = 0.0;
uniform bool solid_lens = false;
uniform bool dense_strike = false;
varying vec4 energy_color;
varying float lens;
uniform float depth_lift = 0.0;
void vertex() {
 energy_color = COLOR; lens = UV2.x;
 vec4 view_vertex=MODELVIEW_MATRIX*vec4(VERTEX,1.0);
 view_vertex.z+=depth_lift;
 POSITION=PROJECTION_MATRIX*view_vertex;
}
void fragment() {
    float across = abs(UV.y * 2.0 - 1.0);
    float envelope = pow(max(sin(UV.x * 3.14159265), 0.0), 0.55);
    float flow = 0.76 + 0.14 * sin(UV.x * 41.0 - phase * 15.0 + UV.y * 8.0)
                      + 0.10 * sin(UV.x * 93.0 + phase * 9.0);
    float veil = exp(-across * across * 5.0) * 0.40;
    float thread = exp(-across * across * 32.0) * 0.70;
    float edge = 1.0 - smoothstep(0.65, 1.0, across);
    if (lens > 0.5) {
        vec2 p = UV * 2.0 - 1.0;
        if (solid_lens) { p.x *= 1.15 + 0.35 * p.y; }
        float d = length(p);
        veil = exp(-d * d * 5.0) * 0.48;
        thread = exp(-d * d * 40.0) * 0.65;
        envelope = 1.0 - smoothstep(0.6, 1.0, d);
        edge = 1.0;
        flow = 1.0;
        if (solid_lens) { veil = 1.0 - smoothstep(0.38, 0.88, d); thread = 0.0; envelope = 1.0; }
    }
    if (dense_strike && lens < 0.5) {
        veil = 1.0 - smoothstep(0.64, 0.90, across);
        thread = 0.0;
        envelope = 1.0;
        flow = 1.0;
        edge = 1.0;
    }
    ALBEDO = energy_color.rgb * 1.1;
    ALPHA = clamp((veil + thread) * envelope * flow * edge * energy_color.a, 0.0, 1.0);
}
