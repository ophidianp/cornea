#if !defined SPACE_GLSL
#define SPACE_GLSL

// Spaces: screen (uv, depth) -> view -> scene (camera-relative world) -> world

vec3 projectAndDivide(mat4 m, vec3 p) {
    vec4 h = m * vec4(p, 1.0);
    return h.xyz / h.w;
}

vec3 screenToView(vec3 screenPos) {
    vec3 ndc = screenPos * 2.0 - 1.0;
    return projectAndDivide(gbufferProjectionInverse, ndc);
}
vec3 viewToScreen(vec3 viewPos) {
    return projectAndDivide(gbufferProjection, viewPos) * 0.5 + 0.5;
}
vec3 viewToScene(vec3 viewPos) {
    return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz;
}
vec3 sceneToView(vec3 scenePos) {
    return mat3(gbufferModelView) * (scenePos - gbufferModelViewInverse[3].xyz);
}

// Positive view-space distance along -z
float linearDepth(float depth) {
    float ndc = depth * 2.0 - 1.0;
    return gbufferProjection[3][2] / (ndc + gbufferProjection[2][2]);
}

// Scene-space position (current frame) to last frame's screen position.
// Sky positions are directions and ignore camera translation.
vec3 reprojectScene(vec3 scenePos, bool isSky) {
    vec3 prevView = isSky
        ? mat3(gbufferPreviousModelView) * scenePos
        : (gbufferPreviousModelView * vec4(scenePos + cameraPosition - previousCameraPosition, 1.0)).xyz;
    vec4 prevClip = gbufferPreviousProjection * vec4(prevView, 1.0);
    return (prevClip.xyz / prevClip.w) * 0.5 + 0.5;
}

#endif
