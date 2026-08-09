shader_type sky;
// No render_mode: sky shaders only accept use_half_res_pass /
// use_quarter_res_pass / disable_fog, and this needs full resolution and
// the scene's fog.

// Photoreal sky for DayNightSky. Two equirectangular HDRI panoramas (a day
// plate and a night plate) cross-faded by the sun's elevation, then
// multiplied by the viewer's frame tint.
//
// The tint is the point: a bare PanoramaSkyMaterial would show every player
// the same photograph and quietly break the "no two players see the same
// game" invariant that IdentityLens enforces everywhere else. Sampling the
// panorama ourselves keeps the frame's sensorium authority over the sky.

uniform sampler2D day_panorama : source_color, filter_linear;
uniform sampler2D night_panorama : source_color, filter_linear;

// 1.0 at noon, 0.0 at night — DayNightSky drives this from sun elevation.
uniform float daylight : hint_range(0.0, 1.0) = 1.0;
// Warm/cool shift through dusk and dawn, applied on top of the blend.
uniform vec3 dusk_tint = vec3(1.0);
uniform float duskness : hint_range(0.0, 1.0) = 0.0;
// IdentityLens frame tint + exposure.
uniform vec3 frame_tint = vec3(1.0);
uniform float energy : hint_range(0.0, 4.0) = 1.0;

void sky() {
	vec3 day = texture(day_panorama, SKY_COORDS).rgb;
	vec3 night = texture(night_panorama, SKY_COORDS).rgb;
	vec3 col = mix(night, day, daylight);
	col = mix(col, col * dusk_tint, duskness);
	COLOR = col * frame_tint * energy;
}
