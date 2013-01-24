attribute vec3 position;
attribute vec2 uv;
uniform mat4 proj;
varying vec2 vTexCoord;
void main() {
 gl_Position = proj * vec4(position, 1.0);
 vTexCoord = uv;
}