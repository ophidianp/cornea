// Vanilla sky, sun/moon and clouds are replaced by our own; draw nothing.

#if defined VERTEX_SHADER
void main() {
    gl_Position = vec4(-10.0, -10.0, -10.0, 1.0);
}
#else
/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 outColor;
void main() {
    discard;
}
#endif
