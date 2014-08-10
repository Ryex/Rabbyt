#include "anim_sys.h"

#include "stdlib.h"
#include "stdio.h"
#include "include_math.h"

int system_step=1;
float system_time;
int exception_state;

void _set_time(float t){
    system_time = t;
    system_step += 1;
}

void _add_time(float t){
    system_time += t;
    system_step += 1;
}

float _get_time(void){
    return system_time;
}

void _invalidate_caches(void){
    system_step += 1;
}

float _out_bounce(float t){
    float x;
    if (t < 1./2.75) x = 7.5625*t*t;
    else if (t < 2/2.75) { t -= 1.5/2.75; x = 7.5625*t*t + .75; }
    else if (t < 2.5/2.75) { t -= 2.25/2.75; x = 7.5625*t*t + .9375; }
    else { t -= 2.625/2.75; x = 7.5625*t*t + .984375; }
    return x;
}


float interpolate_func(AnimSlot_s * slot){
    float t;
    float start, end;
    float x;
    float s;
    InterpolateAnim_data * d;
    d = (InterpolateAnim_data *)(slot->anim->data);
    

    if (d->use_global_time){
        t = (system_time - d->start_time)*d->one_over_dt;
    } else {
        READ_SLOT(&(d->t), &t);
    }

    
    READ_SLOT(&(d->start), &start);
    READ_SLOT(&(d->end), &end);

    switch (d->extend_mode){
        case (EXTEND_CONSTANT):
            if (t < 0){
                return start;
            } else if (t > 1){
                if (slot->anim->on_end != 0){
                    return slot->anim->on_end(slot, slot->anim->on_end_data,
                            end);
                } else {
                    return end;
                }
            }
            break;
        case (EXTEND_EXTRAPOLATE):
            break;
        case (EXTEND_REPEAT):
            if (t > 1.0001){
                t = t - ((int)t);
            } else if (t < 0) {
                t = 1 + t - ((int)t);
            }
            break;
        case (EXTEND_REVERSE):
            if (t < 0){
                t = -t;
            }
            if ((int)t & 1) {
                t = 1 - (t - ((int)t));
            } else {
                t = t - ((int)t);
            }
            break;
        default:
            break;
    }

    

    switch (d->inter_mode) {
        case (INTER_LERP):
        default:
            x = t;
            break;
        case (INTER_COSINE):
        case (INTER_IN_SINE):
            x = (1 - cosf(t * M_PI*.5));
            break;
        case (INTER_SINE):
        case (INTER_OUT_SINE):
            x = (sinf(t * M_PI*.5));
            break;
        case (INTER_IN_OUT_SINE):
            x = -cosf(t * M_PI)*.5 + .5;
            break;
        case (INTER_EXPONENTIAL):
            x = ((expf(t)-1) / (expf(1)-1));
            break;
        case (INTER_IN_QUAD):
            x = t*t;
            break;
        case (INTER_OUT_QUAD):
            x = -t*t + 2*t;
            break;
        case (INTER_IN_OUT_QUAD):
            if (t < .5) {
                x = t*t*2;
            } else {
                x = -2*t*t + 4*t - 1;
            }
            break;
        case (INTER_IN_CUBIC):
            x = t*t*t;
            break;
        case (INTER_OUT_CUBIC):
            x = pow(t-1, 3) + 1;
            break;
        case (INTER_IN_OUT_CUBIC):
            t *= 2;
            if (t < 1.0) x = 0.5*pow(t,3);
            else { t-=2; x = 0.5*pow(t,3)+1; }
            break;
        case (INTER_IN_CIRC):
            x = 1 - sqrt(1 - t*t);
            break;
        case (INTER_OUT_CIRC):
            t -= 1;
            x = sqrt(1 - t*t);
            break;
        case (INTER_IN_OUT_CIRC):
            t *= 2;
            if (t < 1.0) x = 0.5*(1-sqrt(1-t*t));
            else { t-= 2; x = 0.5*(sqrt(1 - t*t) + 1); }
            break;
        case (INTER_IN_BACK):
            s = 1.70158;
            x = t*t*((s+1)*t - s);
            break;
        case (INTER_OUT_BACK):
            s = 1.70158;
            t -= 1;
            x = t*t*((s+1)*t+s)+1;
            break;
        case (INTER_IN_OUT_BACK):
            s = 1.70158;
            t *= 2;
            s *= 1.525;
            if (t < 1.0) x = 0.5*(t*t*((s+1)*t - s));
            else { t -= 2; x = 0.5*(t*t*((s+1)*t+s)+2); }
            break;
        case (INTER_IN_BOUNCE):
            x = 1 - _out_bounce(1-t);
            break;
        case (INTER_OUT_BOUNCE):
            x = _out_bounce(t);
            break;
        case (INTER_IN_OUT_BOUNCE):
            if (t < .5) {
                x = .5 - _out_bounce(1-t*2)*.5;
            } else {
                x = _out_bounce(t*2-1)*.5 + .5;
            }
            break;
    }
    return (end - start) * x + start;
}
