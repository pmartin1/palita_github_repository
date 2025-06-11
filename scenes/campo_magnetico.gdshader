shader_type particles;

uniform float major_radius = 100.0;
uniform float tube_radius = 25.0;
uniform float angular_speed = 2.0;
uniform float elevation = 0.5;

float rand_from_id(float id) {
    return fract(sin(id * 91.3458) * 47453.5453);
}

void process() {
    float id = float(INDEX);

    // Generate initial angles using particle ID
    float ring_angle = rand_from_id(id) * TAU;
    float tube_angle = rand_from_id(id + 13.42) * TAU;

    float t = TIME / LIFETIME;

    // Animate both angles
    ring_angle += t * angular_speed;
    tube_angle += t * angular_speed * 1.5;

    float x = (major_radius + tube_radius * cos(tube_angle)) * cos(ring_angle);
    float y = (major_radius + tube_radius * cos(tube_angle)) * sin(ring_angle);
    y += sin(tube_angle) * tube_radius * elevation;

    USERDATA3 = vec4(x, y, 0.0, 0.0);
}