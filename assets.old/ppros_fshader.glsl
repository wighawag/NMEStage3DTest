varying vec2 vTexCoord;
uniform sampler2D texture;
void main() {
 vec4 texColor = texture2D(texture, vTexCoord);
 texColor.y = 0.0;
 texColor.z = 0.0;
 gl_FragColor = texColor;
}
