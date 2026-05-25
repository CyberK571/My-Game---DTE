shader_type canvas_item;

uniform float speed = 0.5;
uniform float strength = 0.03;

void fragment() {
    vec2 uv = UV;
    uv.x += sin(uv.y * 10.0 + TIME * speed) * strength;
    uv.y += cos(uv.x * 10.0 + TIME * speed) * strength;
    COLOR = texture(TEXTURE, uv);
}