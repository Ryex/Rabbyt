#include <Python.h>

#define ALLWAYS_UP_TO_DATE 0x7fffffff

extern int system_step;
extern float system_time;
extern int exception_state;


#define SLOT_ANIM -1
#define SLOT_LOCAL -2

#define EXTEND_CONSTANT 1
#define EXTEND_EXTRAPOLATE 2
#define EXTEND_REPEAT 3
#define EXTEND_REVERSE 4


enum {
  INTER_LERP=1,
  INTER_COSINE,
  INTER_SINE,
  INTER_EXPONENTIAL,
  INTER_IN_CIRC,
  INTER_OUT_CIRC,
  INTER_IN_OUT_CIRC,
  INTER_IN_BACK,
  INTER_OUT_BACK,
  INTER_IN_OUT_BACK,

  INTER_IN_BOUNCE,
  INTER_OUT_BOUNCE,
  INTER_IN_OUT_BOUNCE,

  INTER_IN_SINE,
  INTER_OUT_SINE,
  INTER_IN_OUT_SINE,

  INTER_IN_QUAD,
  INTER_OUT_QUAD,
  INTER_IN_OUT_QUAD,

  INTER_IN_CUBIC,
  INTER_OUT_CUBIC,
  INTER_IN_OUT_CUBIC
};

#define READ_SLOT(slot, out) do {\
    switch ((slot)->type){\
        case (SLOT_ANIM):\
            if ((slot)->recursion_check == 0) {\
                (slot)->recursion_check = 1;\
                (out)[0] = (slot)->anim->func((slot));\
            } else {\
                (out)[0] = 0;\
                /*PyErr_SetString(PyExc_RuntimeError, "Circular anims detected");*/\
                PyErr_Warn(NULL, "Circular anims detected");\
            }\
            (slot)->recursion_check = 0;\
            break;\
        case (SLOT_LOCAL):\
            (out)[0] = (slot)->local;\
            break;\
        default:\
            (out)[0] = ((float*)((slot)->base[0] + (slot)->offset))[0];\
            break;\
    }}while(0)

struct s_AnimSlot_s;

typedef float (*AnimFunc)(struct s_AnimSlot_s * slot);

typedef struct {
    AnimFunc func;
    void * data;
    float (*on_end)(struct s_AnimSlot_s * slot, void * data, float end);
    void * on_end_data;
} Anim_s;

typedef struct s_AnimSlot_s {
    union {
        int type;
        int offset;
    };
    union {
        void ** base;      // if type/offset is 0 or greater
        Anim_s *anim;     // if type is SLOT_ANIM
        float local;        // if type is SLOT_LOCAL
    };
    int recursion_check;
} AnimSlot_s;

typedef struct {
    AnimSlot_s start, end;
    AnimSlot_s t;
    int use_global_time;  // If True, _get_time() is used.
    float start_time, end_time, one_over_dt;
    int inter_mode, extend_mode;
} InterpolateAnim_data;

float interpolate_func(AnimSlot_s * slot);

void _set_time(float t);
void _add_time(float t);
float _get_time(void);

