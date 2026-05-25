shader_type canvas_item;

void fragment() {
    vec2 uv = UV - vec2(0.5);
    float dist = length(uv);
    
    float inner = step(dist, 0.38);
    float border = step(dist, 0.44) - inner;
    float outer = step(dist, 0.5) - step(dist, 0.44);
    
    vec4 red = vec4(0.55, 0.0, 0.0, 1.0);
    vec4 white = vec4(1.0, 1.0, 1.0, 1.0);
    
    COLOR = mix(vec4(0.0), white, outer);
    COLOR = mix(COLOR, red, border + inner);
    COLOR.a = step(dist, 0.5);
}