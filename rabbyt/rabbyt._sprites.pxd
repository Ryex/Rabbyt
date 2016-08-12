from primitives cimport Quad, Point2d, float2

from _anims cimport cAnimable, AnimSlot, AnimSlot_s, READ_SLOT

cdef class cBaseSprite(cAnimable):
    cdef double _bounding_radius
    cdef AnimSlot_s     _x, _y, _rot
    cdef AnimSlot_s _red, _green, _blue, _alpha
    cdef AnimSlot_s _scale_x, _scale_y
    cdef _modify_slots(self)
    cdef Point2d _convert_offset(self, float ox, float oy)



cdef class cSprite(cBaseSprite):
    cdef Quad _shape
    cdef Quad _tex_shape

    cdef AnimSlot_s _u, _v

    cdef int _texture_id
    cdef int _texture_target

    cdef int _bounding_radius_is_explicit

    cdef _modify_slots(self)
    cdef int _render(self) except -1

    cdef float2 _bounds_x(self)
    cdef float2 _bounds_y(self)
