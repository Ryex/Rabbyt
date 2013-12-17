cdef extern from "anim_sys.h":
    ctypedef float (*AnimFunc)(void * slot)
    ctypedef struct AnimSlot_s
    ctypedef struct Anim_s:
        AnimFunc func
        void * data
        float (*on_end)(AnimSlot_s * slot, void * data, float end)
        void * on_end_data

    ctypedef struct AnimSlot_s:
        #union {
        int type
        int offset
        #};
        #union {
        void ** base      # if type is 0 or greater
        Anim_s *anim     # if type is SLOT_ANIM
        float local        # if type is SLOT_LOCAL
        #};
        int recursion_check

    cdef int SLOT_ANIM, SLOT_LOCAL
    cdef int EXTEND_CONSTANT, EXTEND_EXTRAPOLATE, EXTEND_REPEAT, EXTEND_REVERSE
    cdef int INTER_LERP, INTER_COSINE, INTER_SINE, INTER_EXPONENTIAL
    cdef int INTER_IN_CIRC, INTER_OUT_CIRC, INTER_IN_OUT_CIRC
    cdef int INTER_IN_BACK, INTER_OUT_BACK, INTER_IN_OUT_BACK
    cdef int INTER_IN_BOUNCE, INTER_OUT_BOUNCE, INTER_IN_OUT_BOUNCE
    cdef int INTER_IN_QUAD, INTER_OUT_QUAD, INTER_IN_OUT_QUAD
    cdef int INTER_IN_CUBIC, INTER_OUT_CUBIC, INTER_IN_OUT_CUBIC
    cdef int INTER_IN_SINE, INTER_OUT_SINE, INTER_IN_OUT_SINE

    cdef void READ_SLOT(AnimSlot_s * slot, float * out)

cdef class cAnimable:
    cdef object _anim_list
    cdef int c_slot_count
    cdef AnimSlot_s ** c_anim_slots
    cdef _modify_slots(self)

cdef class Anim

cdef class AnimSlot:
    cdef AnimSlot_s _internal_slot
    cdef AnimSlot_s * _slot
    cdef Anim _py_anim
    cdef int c_set_anim(self, Anim anim) except -1
    cdef Anim c_get_anim(self)
    cdef float c_get_value(self)
    cdef int c_set_value(self, float value) except -1
