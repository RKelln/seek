shader_type canvas_item;

uniform float amount : hint_range(0, 1);

void fragment() {
    // Convert the pixel position to polar coordinates, with the center of the image as the origin
    vec2 pos = UV - vec2(0.5, 0.5);
    float angle = atan(pos.y, pos.x);

    // Normalize the angle to the range 0 to 1
    if (angle < 0.0) {
        angle = (angle + 2.0 * PI) / (2.0 * PI);
    } else {
        angle /= 2.0 * PI;
    }

    // Determine the alpha value for the pixel
    // If the angle is less than the time uniform, the pixel is transparent. Otherwise, it's opaque.
    float alpha = angle < amount ? 0.0 : 1.0;

    // Apply the alpha value to the pixel
    COLOR.a *= alpha;
}
