cdef struct Point2d:
    float x,y

cdef struct float2:
    float a, b

cdef class Quad:
    cdef Point2d v[4]
    cdef public double bounding_radius
    cdef void _shift_x(self, float x)
    cdef void _shift_y(self, float y)
    cdef float2 _bounds_x(self)
    cdef float2 _bounds_y(self)
    cdef void _update_bounding_radius(self)
