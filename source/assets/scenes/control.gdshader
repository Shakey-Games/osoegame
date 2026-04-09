shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;

// Pixel controls
uniform float pixel_size : hint_range(1.0, 6.0) = 2.0;
uniform float color_levels : hint_range(4.0, 32.0) = 16.0;
uniform float dither_strength : hint_range(0.0, 1.0) = 0.4;

// Curvature
uniform float curvature : hint_range(0.0, 0.3) = 0.12;


// Bayer dithering
float bayer4x4(vec2 coord) {

    int x = int(mod(coord.x, 4.0));
    int y = int(mod(coord.y, 4.0));

    int index = x + y * 4;

    float[16] pattern = float[](
        0.0,  8.0,  2.0, 10.0,
        12.0, 4.0, 14.0, 6.0,
        3.0, 11.0,  1.0,  9.0,
        15.0, 7.0, 13.0, 5.0
    );

    return pattern[index] / 16.0;
}

void fragment() {

    vec2 uv = SCREEN_UV;

    // --- REAL CURVATURE ---

    vec2 centered = uv * 2.0 - 1.0;

    float r2 = dot(centered, centered);

    centered *= 1.0 + curvature * r2;

    uv = centered * 0.5 + 0.5;

    // Shrink slightly to avoid edge artifacts
    uv = mix(vec2(0.02), vec2(0.98), uv);

    vec2 resolution =
        vec2(textureSize(screen_texture, 0));

    // --- PIXELATION ---

    vec2 pixel_uv =
        floor(uv * resolution / pixel_size)
        * pixel_size / resolution;

    vec3 color =
        texture(screen_texture, pixel_uv).rgb;

    // --- DITHERING ---

    float dither =
        bayer4x4(pixel_uv * resolution);

    color += (dither - 0.5)
            * dither_strength
            / color_levels;

    // --- COLOR REDUCTION ---

    color =
        floor(color * color_levels)
        / color_levels;

    COLOR = vec4(color, 1.0);
}