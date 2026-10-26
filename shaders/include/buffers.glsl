#if !defined BUFFERS_GLSL
#define BUFFERS_GLSL

/*
Buffer layout (sizes are set in shaders.properties)
  colortex0  scene HDR                     full   R11F_G11F_B10F
  colortex1  gbuffer (packed)              full   RGBA16
  colortex2  translucent colour (premult)  full   RGBA16F
  colortex3  translucent data              full   RGBA8
  colortex4  sky LUT + light colours       193x108 RGBA16F
  colortex5  clouds, current frame         1/2    RGBA16F
  colortex6  clouds, accumulated           1/2    RGBA16F (persistent)
  colortex7  volumetric light              1/2    R11F_G11F_B10F
  colortex8  TAA history / resolved        full   RGBA16F (persistent)
  colortex9  bloom tiles + exposure        1/2    RGBA16F (persistent)
  colortex10 SSAO                          1/2    R8

const int colortex0Format = R11F_G11F_B10F;
const int colortex1Format = RGBA16;
const int colortex2Format = RGBA16F;
const int colortex3Format = RGBA8;
const int colortex4Format = RGBA16F;
const int colortex5Format = RGBA16F;
const int colortex6Format = RGBA16F;
const int colortex7Format = R11F_G11F_B10F;
const int colortex8Format = RGBA16F;
const int colortex9Format = RGBA16F;
const int colortex10Format = R8;

const bool colortex4Clear = false;
const bool colortex6Clear = false;
const bool colortex8Clear = false;
const bool colortex9Clear = false;

const vec4 colortex0ClearColor = vec4(0.0, 0.0, 0.0, 1.0);
const vec4 colortex1ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex2ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 colortex3ClearColor = vec4(0.0, 0.0, 0.0, 0.0);
const vec4 shadowcolor0ClearColor = vec4(1.0, 1.0, 1.0, 1.0);
*/

#endif
