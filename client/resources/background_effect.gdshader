shader_type canvas_item;

// --- Uniforms --- //
uniform vec2 amplitutde = vec2(1.0, 0.0);
uniform vec2 speed = vec2(1.0, 0.0);

// --- Functions --- //
void fragment() {
	vec2 pos = mod((UV - amplitutde * sin(TIME + vec2(UV.y, UV.x) * speed)) / TEXTURE_PIXEL_SIZE,
			1.0 / TEXTURE_PIXEL_SIZE) * TEXTURE_PIXEL_SIZE;
	COLOR = texture(TEXTURE, pos);
}