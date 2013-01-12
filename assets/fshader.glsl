varying vec2 vTexCoord;
uniform sampler2D texture;
void main() {
 vec4 texColor = texture2D(texture, vTexCoord);
 gl_FragColor = texColor;
}