// Procedural ripple + plasma pattern. Computes the entire image from
// `gl_FragCoord` and three uniforms — no input texture is sampled.
// Loaded by examples/22_shader_wave/shader_wave.rb via SFML::Shader.from_file.

uniform float time;
uniform vec2  resolution;
uniform vec2  mouse;

void main() {
    vec2 uv = gl_FragCoord.xy / resolution;
    vec2 m  = mouse / resolution;

    // Concentric ripple radiating from the cursor.
    float d      = length(uv - m);
    float ripple = sin(d * 60.0 - time * 5.0);

    // Diagonal plasma drifting with time.
    float plasma = sin(uv.x * 6.0 + time)
                 + sin(uv.y * 7.0 - time * 1.3);

    float v = ripple * 0.4 + plasma * 0.3;

    // RGB channels offset around the same value → smooth hue cycle.
    gl_FragColor = vec4(
        0.5 + 0.5 * sin(v + time),
        0.5 + 0.5 * sin(v + time + 2.094),
        0.5 + 0.5 * sin(v + time + 4.188),
        1.0
    );
}
