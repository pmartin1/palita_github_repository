shader_type particles;

uniform float major_radius = 00.0;     // Orbit radius around the planet
uniform float tube_radius = 500.0;       // Field line spread (distance from center path)
uniform float angular_speed = 4.0;      // How fast the particle loops
uniform float elevation = 3;          // Curve "thickness" in vertical
uniform float fade_in = 100;            // Fade in percentage of lifetime
uniform float fade_out = 0;           // Fade out percentage of lifetime

float rand_from_id(float id) {
    return fract(sin(id * 91.3458) * 47453.5453);
}

void start(){
	float origin_time = TIME;
	USERDATA1.x = 0.0;
}

void process() {
    float id = float(INDEX);
	

    // Initial random seed angles
    float ring_angle = rand_from_id(id) * TAU;
    float tube_angle = rand_from_id(id + 13.42) * TAU;

    // Normalized lifetime (0.0 - 1.0)
	
	//USERDATA1.x = min(1.1, USERDATA1.x + DELTA / LIFETIME);
    //float t = USERDATA1.x;
	float t = TIME / LIFETIME;

    // Animate angles over time
    ring_angle += t * angular_speed;
    tube_angle += t * angular_speed * 1.5;

    // Torus formula (flattened to 2D)
    float x = (major_radius + tube_radius * cos(tube_angle)) * cos(ring_angle);
    float y = (major_radius + tube_radius * cos(tube_angle)) * sin(ring_angle);
    y += sin(tube_angle) * tube_radius * elevation;

    VELOCITY.xy = vec2(x, y);

     //Alpha fade in/out
    //float alpha = t;
    //if (t < fade_in) {
        //alpha = t / fade_in;
    //} else if (t > 1.0 - fade_out) {
        //alpha = (1.0 - t) / fade_out;
    //}

    //COLOR.a *= alpha;
	//if(t==1.0){
		//ACTIVE=false;
	//}
}
