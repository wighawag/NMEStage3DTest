const vec2 madd=vec2(0.5,0.5);
attribute vec4 position;
varying vec2 vTexCoord;
void main() {
 gl_Position = position;
 vec2 t = vec2(position.xy  * madd + madd);
 //t.y = 1 -t.y; reverse does not work in glsl
 vTexCoord = t;
}
