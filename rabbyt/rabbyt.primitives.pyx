__credits__ = (
"""
Copyright (C) 2007  Matthew Marshall

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
""")

__author__ = "Matthew Marshall <matthew@matthewmarshall.org>"

cdef extern from "Python.h":
    cdef int PyNumber_Check(object o)

cdef extern from "include_math.h":
    cdef float fmodf(float x, float y)
    cdef float cosf(float x)
    cdef float sinf(float x)
    cdef float sqrtf(float x)
    cdef float expf(float x)
    cdef float fabsf(float x)
    cdef float M_PI

cdef class Quad:
    """
    ``Quad(definition)``

    ``Quad`` provides a convenient representation of a quadrilateral.
    This is useful for specifying ``Sprite.shape`` and ``Sprite.tex_shape``.

    ``definition`` can be in a number of forms:

       * A tuple with four vertexes.
            For example: ``((0,1), (1,1), (1,0), (0,0))``.

       * A tuple with the format ``(left, top, right, bottom)``.
            For example: ``(0, 1, 1, 0)``. You can also think of this as
            ``(x1, y1, x2, y2)``, giving the top-left and bottom-right corners
            of a rectangle.

       * A tuple in the format of pyglet's ``Texture.tex_coords`` attribute.
            (This, is a flattened tuple giving each vertex in three
            dimensions.  The third dimension will be discarded.)

    ``Quad`` has a number of properties to make modifying it easier.  The
    ``width`` and ``height`` properties will scale the vertexes from the
    center, but all other properties will move *all* vertexes the same amount.
    (e.g., assigning to ``left`` will move the right side as well: the width
    says the same.)
    """
    # v defined in the pxd

    def __init__(self, definition):
        try:
            definition[0][0]
        except TypeError:
            if len(definition) == 2:
                l = -definition[0]/2
                r =  definition[0]/2
                b = -definition[1]/2
                t =  definition[1]/2
                definition = [(l, t), (r, t), (r, b), (l, b)]
            elif len(definition) == 4:
                l, t, r, b = definition
                definition = [(l, t), (r, t), (r, b), (l, b)]
            elif len(definition) == 12:
                # Assume this is in the format of pyglet's tex_coords.
                d = definition
                definition = [
                        (d[9],d[10]), # l t
                        (d[6],d[7]), # r t
                        (d[3],d[4]), # r b
                        (d[0],d[1])] # l b
            else:
                raise ValueError("Don't know what to do with %r" % definition)
        assert len(definition) == 4
        cdef int i
        for i, v in enumerate(definition):
            self.__setitem__(i, v)
        self._update_bounding_radius()

    def __getitem__(self, int i):
        if i < 0:
            i = 4 + i
        if i < 0 or i >= 4:
            raise IndexError(i)
        return self.v[i].x, self.v[i].y
    def __setitem__(self, int i, value):
        if i < 0:
            i = 4 + i
        if i < 0 or i >= 4:
            raise IndexError(i)
        self.v[i].x = value[0]
        self.v[i].y = value[1]

    def __len__(self):
        return 4

    cdef void _shift_x(self, float offset):
        for i from 0 <= i < 4:
            self.v[i].x = self.v[i].x + offset

    cdef void _shift_y(self, float offset):
        for i from 0 <= i < 4:
            self.v[i].y = self.v[i].y + offset

    property width:
        """
        The width between the left-most and right-most vertexes.

        Assigning to this property will scale all vertexes from the center.  So
        the ``x`` property will remain the same, but ``left`` and ``right``
        properties will change.
        """
        def __get__(self):
            cdef float2 b
            b = self._bounds_x()
            return b.b - b.a
        def __set__(self, float value):
            cdef float scale, center
            cdef float2 bounds
            cdef int i
            bounds = self._bounds_x()
            center = (bounds.a + bounds.b)/2
            if bounds.a == bounds.b:
                self.v[0].x = self.v[3].x = center-value/2
                self.v[1].x = self.v[2].x = center+value/2
            else:
                scale = value/(bounds.b - bounds.a)
                for i from 0 <= i < 4:
                    self.v[i].x = (self.v[i].x - center) * scale + center
            self._update_bounding_radius()

    property height:
        """
        The height between the top-most and bottom-most vertexes.

        Assigning to this property will scale all vertexes from the center.  So
        the ``y`` property will remain the same, but ``top`` and ``bottom``
        properties will change.
        """
        def __get__(self):
            cdef float2 b
            b = self._bounds_y()
            return b.b - b.a
        def __set__(self, float value):
            cdef float scale, center
            cdef float2 bounds
            cdef int i
            bounds = self._bounds_y()
            center = (bounds.a + bounds.b)/2
            if bounds.a == bounds.b:
                self.v[0].y = self.v[1].y = center+value/2
                self.v[2].y = self.v[3].y = center-value/2
            else:
                scale = value/(bounds.b - bounds.a)
                for i from 0 <= i < 4:
                    self.v[i].y = (self.v[i].y - center) * scale + center
            self._update_bounding_radius()

    property x:
        """
        Halfway between ``left`` and ``right``.
        """
        def __get__(self):
            cdef float2 b
            b = self._bounds_x()
            return (b.a + b.b)/2
        def __set__(self, float value):
            cdef float2 current
            current = self._bounds_x()
            self._shift_x(value - (current.a + current.b)/2)

    property y:
        """
        Halfway between ``top`` and ``bottom``.
        """
        def __get__(self):
            cdef float2 b
            b = self._bounds_y()
            return (b.a + b.b)/2
        def __set__(self, value):
            cdef float2 current
            current = self._bounds_y()
            self._shift_y(value - (current.a + current.b)/2)

    property xy:
        """
        The coordinates of the center of the Quad.
        """
        def __get__(self):
            return (self.x, self.y)
        def __set__(self, value):
            self.x, self.y = value

    cdef float2 _bounds_x(self):
            cdef float2 bounds
            cdef float x
            cdef int i
            bounds.a = bounds.b = self.v[0].x
            for i from 1 <= i < 4:
                x = self.v[i].x
                if bounds.a > x:
                    bounds.a = x
                if bounds.b < x:
                    bounds.b = x
            return bounds

    cdef float2 _bounds_y(self):
            cdef float2 bounds
            cdef float y
            cdef int i
            bounds.a = bounds.b = self.v[0].y
            for i from 1 <= i < 4:
                y = self.v[i].y
                if bounds.a > y:
                    bounds.a = y
                if bounds.b < y:
                    bounds.b = y
            return bounds

    property left:
        """ The x coordinate of the left-most point. """
        def __get__(self):
            return self._bounds_x().a
        def __set__(self, float v):
            self._shift_x(v - self._bounds_x().a)
            self._update_bounding_radius()

    property right:
        """ The x coordinate of the right-most point. """
        def __get__(self):
            return self._bounds_x().b
        def __set__(self, float v):
            self._shift_x(v - self._bounds_x().b)
            self._update_bounding_radius()

    property bottom:
        """ The y coordinate of the bottom-most point. """
        def __get__(self):
            return self._bounds_y().a
        def __set__(self, float v):
            self._shift_y(v - self._bounds_y().a)
            self._update_bounding_radius()

    property top:
        """ The y coordinate of the top-most point. """
        def __get__(self):
            return self._bounds_y().b
        def __set__(self, float v):
            self._shift_y(v - self._bounds_y().b)
            self._update_bounding_radius()


    cdef void _update_bounding_radius(self):
        self.bounding_radius = 0
        cdef double brs
        brs = 0
        for i from 0 <= i < 4:
            d = self.v[i].x**2 + self.v[i].y**2
            if d > brs:
                brs = d
        self.bounding_radius = brs**.5

    def __repr__(self):
        return "Quad((%r, %r, %r, %r))" % (self[0], self[1], self[2], self[3])

__docs_all__ = ['Quad']
