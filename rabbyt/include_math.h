#include "math.h"

#ifndef M_PI
const double M_PI = 3.1415926535897931;
#endif

#define PI M_PI
#define PI_OVER_180  (PI/180.0)

#ifdef _WIN32
  #define cosf cos
  #define sinf sin
  #define fmodf fmod
  #define expf exp
  #define sqrtf sqrt
#endif
