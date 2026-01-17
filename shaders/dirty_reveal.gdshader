shader_type canvas_item;

uniform sampler2D clean_tex;
uniform sampler2D mask_tex;

void fragment() {
	vec4 dirty_col = texture(TEXTURE, UV);
	vec4 clean_col = texture(clean_tex, UV);
	float a = texture(mask_tex, UV).r;
	COLOR = mix(dirty_col, clean_col, a);
}

