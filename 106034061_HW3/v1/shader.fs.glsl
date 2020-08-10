#version 330
in vec2 texCoord;
out vec4 fragColor;

// [TODO] passing texture from main.cpp
// Hint: sampler2D
uniform sampler2D tex;                // texture uniform

void main() {

	// [TODO] sampleing from texture
	// Hint: texture
    vec4 texColor = vec4(texture(tex, texCoord).rgb, 1.0);
//    fragColor = fragColor * texColor;
    fragColor = texColor;

//    fragColor = vec4(texCoord.xy, 0, 1);

}
