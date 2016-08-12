"""
The most interesting part of this module is probably the ``Sprite`` class.

If you need more specialized rendering, try subclassing from ``BaseSprite``.
"""

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

from libc.stdio cimport printf

cdef extern from "include_math.h":
    cdef float fmodf(float x, float y)
    cdef float cosf(float x)
    cdef float sinf(float x)
    cdef float sqrtf(float x)
    cdef float PI, PI_OVER_180

cdef extern from "stdlib.h":
    ctypedef unsigned int size_t
    cdef void *malloc(size_t size)
    cdef void free(void *ptr)
    cdef void *realloc(void *ptr, size_t size)

cdef extern from "include_gl.h":
    ctypedef float GLfloat
    ctypedef float GLclampf
    ctypedef unsigned int GLenum
    ctypedef unsigned int GLbitfield
    ctypedef int GLint
    ctypedef unsigned int GLuint
    ctypedef int GLsizei
    ctypedef double GLdouble
    ctypedef double GLclampd
    ctypedef void GLvoid
    ctypedef unsigned char GLubyte

    cdef int GL_SMOOTH
    cdef int GL_COLOR_BUFFER_BIT
    cdef int GL_BLEND
    cdef int GL_SRC_ALPHA
    cdef int GL_ONE_MINUS_SRC_ALPHA
    cdef int GL_TEXTURE_2D
    cdef int GL_QUADS
    cdef int GL_LINES
    cdef int GL_MODELVIEW
    cdef int GL_RGBA
    cdef int GL_RGB
    cdef int GL_NEAREST
    cdef int GL_LINEAR
    cdef int GL_TEXTURE_MAG_FILTER
    cdef int GL_TEXTURE_MIN_FILTER
    cdef int GL_TEXTURE_ENV
    cdef int GL_TEXTURE_ENV_MODE
    cdef int GL_MODULATE
    cdef int GL_LINEAR_MIPMAP_NEAREST
    cdef int GL_UNSIGNED_BYTE
    cdef int GL_PROJECTION
    cdef int GL_FLAT
    cdef int GL_FLOAT
    cdef int GL_POLYGON_SMOOTH

    cdef int GL_VENDOR, GL_RENDERER, GL_VERSION, GL_EXTENSIONS

    cdef int GL_T2F_C4UB_V3F

    cdef void glTranslatef(GLfloat x, GLfloat y, GLfloat z)
    cdef void glRotatef(GLfloat angle, GLfloat x, GLfloat y, GLfloat z)
    cdef void glScalef(GLfloat x, GLfloat y, GLfloat z)
    cdef void glEnable(GLenum cap)
    cdef void glDisable(GLenum cap)
    cdef void glClear(GLbitfield mask)
    cdef void glShadeModel(GLenum mode)
    cdef void glClearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha)
    cdef void glBlendFunc(GLenum sfactor, GLenum dfactor)
    cdef void glBindTexture(GLenum target, GLuint texture)
    cdef void glColor4f(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha)
    cdef void glColor4fv(GLfloat *v)
    cdef void glBegin(GLenum mode)
    cdef void glTexCoord2f(GLfloat s, GLfloat t)
    cdef void glVertex2f(GLfloat x, GLfloat y)
    cdef void glEnd()
    cdef void glViewport(GLint x, GLint y, GLsizei width, GLsizei height)
    cdef void glOrtho(GLint bottom, GLint left, GLint top, GLint bottom, GLint front, GLint back)
    cdef void glMatrixMode(GLenum mode)
    cdef void glLoadIdentity()
    cdef void glTexParameteri(GLenum target, GLenum pname, GLint param)
    cdef void glTexImage2D(GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, GLvoid *pixels)
    cdef void glGenTextures(GLsizei n, GLuint *textures)
    cdef void glDeleteTextures(GLsizei n, GLuint *textures)
    cdef void glTexEnvf(GLenum target, GLenum pname, GLfloat param)
    cdef void glPushMatrix()
    cdef void glPopMatrix()

    cdef void glLineWidth(GLfloat width)

    cdef int GL_CLIENT_VERTEX_ARRAY_BIT
    cdef void glPushClientAttrib(GLbitfield mask)
    cdef void glPopClientAttrib()
    cdef void glDrawArrays(GLenum mode, GLint first, GLsizei count)
    cdef void glInterleavedArrays( GLenum format, GLsizei stride,
                                           GLvoid *pointer )

    cdef const GLubyte *glGetString(GLenum name)

from primitives cimport Quad, Point2d, float2

from _anims cimport cAnimable, AnimSlot, AnimSlot_s, READ_SLOT

cdef class cBaseSprite(cAnimable):
    #cdef double _bounding_radius
    #cdef AnimSlot_s     _x, _y, _rot
    #cdef AnimSlot_s _red, _green, _blue, _alpha
    #cdef AnimSlot_s _scale_x, _scale_y

    cdef _modify_slots(self):
        cAnimable._modify_slots(self)
        cdef AnimSlot slot

        if (len(self._anim_list) > 0):
            slot = self._anim_list[0]
            slot._slot = &self._x
            slot = self._anim_list[1]
            slot._slot = &self._y

            slot = self._anim_list[2]
            slot._slot = &self._rot

            slot = self._anim_list[3]
            slot._slot = &self._red
            slot = self._anim_list[4]
            slot._slot = &self._green
            slot = self._anim_list[5]
            slot._slot = &self._blue
            slot = self._anim_list[6]
            slot._slot = &self._alpha

            slot = self._anim_list[7]
            slot._slot = &self._scale_x
            slot = self._anim_list[8]
            slot._slot = &self._scale_y

    property bounding_radius:
        """
        bounding_radius

        This should be the distance of the farthest point from the center.  It
        can be used for collision detection.
        """
        def __get__(self):
            return self._bounding_radius
        def __set__(self, v):
            self._bounding_radius = v

    property bounding_radius_squared:
        """
        bounding_radius_squared

        This is just like ``bounding_radius``, only it's squared.  (duh)

        ``bounding_radius`` and ``bounding_radius_squared`` are automatically
        kept in sync with each other.
        """
        def __get__(self):
            return self._bounding_radius * self._bounding_radius
        def __set__(self, float r2):
            self._bounding_radius = sqrtf(r2)

    cdef Point2d _convert_offset(self, float ox, float oy):
        cdef float x, y, sx, sy, r, co, si
        cdef Point2d out
        READ_SLOT(&self._x, &x)
        READ_SLOT(&self._y, &y)
        READ_SLOT(&self._scale_x, &sx)
        READ_SLOT(&self._scale_y, &sy)
        READ_SLOT(&self._rot, &r)

        co = cosf(r*PI_OVER_180)
        si = sinf(r*PI_OVER_180)
        out.x = (ox*sx*co - oy*sy*si) + x
        out.y = (ox*sx*si + oy*sy*co) + y
        return out

    def convert_offset(self, offset):
        """
        ``convert_offset((x, y)) -> (x, y)``

        Converts coordinates relative to this sprite to global coordinates,
        including rotation and scaling.
        """
        cdef Point2d c_offset, out_offset
        c_offset = self._convert_offset(offset[0], offset[1])
        return (c_offset.x, c_offset.y)


    def render(self):
        """
        ``render()``

        Renders the sprite.

        By default, this method will transform the OpenGL modelview matrix
        according to ``x``, ``y``, ``scale``, and ``rot``, and call
        ``render_after_transform()``.

        If you want transformations to be handled for you, leave this method and
        override ``render_after_transform()``.  Otherwise, override
        ``render()``.
        """
        cdef float x, y, sx, sy, r

        READ_SLOT(&self._x, &x)
        READ_SLOT(&self._y, &y)
        READ_SLOT(&self._scale_x, &sx)
        READ_SLOT(&self._scale_y, &sy)
        READ_SLOT(&self._rot, &r)

        if x != 0 or y != 0 or sx != 1 or sy != 1 or r != 0:
            glPushMatrix()
            try:
                glTranslatef(x, y, 0)
                if r != 0:
                    glRotatef(r,0,0,1)
                if sx != 1 or sy != 1:
                    glScalef(sx, sy, 1)
                self.render_after_transform()
            finally:
                glPopMatrix()
        else:
            self.render_after_transform()

    def render_after_transform(self):
        """
        ``render_after_transform()``

        This method is called by ``BaseSprite.render()`` after transformations
        have been applied.

        If you don't want to mess with doing transformations yourself, you can
        override this method instead of ``render()``.
        """
        raise NotImplementedError


cdef class cSprite(cBaseSprite):
    #cdef Quad _shape
    #cdef Quad _tex_shape

    #cdef AnimSlot_s _u, _v

    #cdef int _texture_id
    #cdef int _texture_target

    #cdef int _bounding_radius_is_explicit

    def __init__(self):
        self._texture_target = 0

    def ensure_target(self):
        if not self.texture_target:
            self.texture_target = GL_TEXTURE_2D

    cdef _modify_slots(self):
        cBaseSprite._modify_slots(self)
        cdef AnimSlot slot

        if (len(self._anim_list) > 0):
            slot = self._anim_list[9]
            slot._slot = &self._u
            slot = self._anim_list[10]
            slot._slot = &self._v

    property bounding_radius:
        """
        bounding_radius

        This should be the distance of the farthest point from the center.  It
        can be used for collision detection.

        By default this is calculated from the ``shape`` property, and is
        automatically updated whenever the shape is updated.  However, you can
        set it explicitly yourself.

        After the value is explicitly set it will no longer be updated by
        changes to the shape.  To revert back to the default behavior, delete
        the property using the ``del`` statement::

            del sprite.bounding_radius
        """
        def __get__(self):
            cdef float s, sy
            if self._bounding_radius_is_explicit:
                return self._bounding_radius
            else:
                READ_SLOT(&self._scale_x, &s)
                READ_SLOT(&self._scale_y, &sy)
                if sy > s:
                    s = sy;
                return self._shape.bounding_radius * s
        def __set__(self, v):
            self._bounding_radius = v
            self._bounding_radius_is_explicit = 1
        def __del__(self):
            self._bounding_radius_is_explicit = 0

    property bounding_radius_squared:
        """
        bounding_radius_squared

        This is just like ``bounding_radius``, only it's squared.  (duh)

        ``bounding_radius`` and ``bounding_radius_squared`` are automatically
        kept in sync with each other.
        """
        def __get__(self):
            cdef float s, sy
            if self._bounding_radius_is_explicit:
                return self._bounding_radius * self._bounding_radius
            else:
                READ_SLOT(&self._scale_x, &s)
                READ_SLOT(&self._scale_y, &sy)
                if sy > s:
                    s = sy;
                return self._shape.bounding_radius*self._shape.bounding_radius*s*s
        def __set__(self, float r2):
            self._bounding_radius = sqrtf(r2)
            self._bounding_radius_is_explicit = 1
        def __del__(self):
            self._bounding_radius_is_explicit = 0

    property shape:
        """
        The shape of the sprite.

        This must either be of the form ``[left, top, right, bottom]``, or a
        list of four coordinates, eg. ``[(0,0), (20,0), (20,20), (0,20)]``

        ``[-10, -10, 10, 10]`` is the default.

        When you assign to ``shape``, ``bounding_radius`` is automatically set
        to the distance of the farthest coordinate.
        """
        def __get__(self):
            return self._shape
        def __set__(self, value):
            if isinstance(value, Quad):
                self._shape = value
            else:
                self._shape = Quad(value)
            cdef Quad _shape
            _shape = self._shape

    property tex_shape:
        """
        This defines how a texture is mapped onto the sprite.

        Like ``Sprite.shape``, you can give either
        ``[left, top, right, bottom]`` or a list of coordinates.

        The default is ``[0, 1, 1, 0]``, which uses the entire texture.

        For easy integration with pyglet, a tuple with four items will be
        interpreted as the format used by the ``tex_coords`` attribute
        of pyglet textures.
        """
        def __get__(self):
            return self._tex_shape
        def __set__(self, value):
            if isinstance(value, Quad):
                self._tex_shape = value
            else:
                self._tex_shape = Quad(value)
            self._tex_shape_data_ptr = <unsigned long>self._tex_shape.v

    property texture_id:
        def __get__(self):
            return self._texture_id
        def __set__(self, int value):
            self._texture_id = value

    property texture_target:
        def __get__(self):
            return self._texture_target
        def __set__(self, int value):
            self._texture_target = value

    cdef int _render(self) except -1:
        self.ensure_target()
        if self._texture_id != 0:
            glEnable(self._texture_target)
            glBindTexture(self._texture_target, self._texture_id)
        else:
            glDisable(self._texture_target)

        cdef float color[4]
        READ_SLOT(&self._red, &color[0])
        READ_SLOT(&self._green, &color[1])
        READ_SLOT(&self._blue, &color[2])
        READ_SLOT(&self._alpha, &color[3])
        glColor4fv(color)

        cdef float x, y, u, v, sx, sy, r
        READ_SLOT(&self._x, &x)
        READ_SLOT(&self._y, &y)
        READ_SLOT(&self._u, &u)
        READ_SLOT(&self._v, &v)
        READ_SLOT(&self._scale_x, &sx)
        READ_SLOT(&self._scale_y, &sy)
        READ_SLOT(&self._rot, &r)

        cdef int i
        cdef float vx, vy, co, si

        cdef Point2d * vert, *tex
        vert = self._shape.v
        tex = self._tex_shape.v

        glBegin(GL_QUADS)
        if r == 0:
            glTexCoord2f(tex[0].x+u,tex[0].y+v)
            glVertex2f(vert[0].x*sx+x,vert[0].y*sy+y)
            glTexCoord2f(tex[1].x+u,tex[1].y+v)
            glVertex2f(vert[1].x*sx+x,vert[1].y*sy+y)
            glTexCoord2f(tex[2].x+u,tex[2].y+v)
            glVertex2f(vert[2].x*sx+x,vert[2].y*sy+y)
            glTexCoord2f(tex[3].x+u,tex[3].y+v)
            glVertex2f(vert[3].x*sx+x,vert[3].y*sy+y)
        else:
            r = r * PI_OVER_180
            co = cosf(r)
            si = sinf(r)
            for i from 0 <= i < 4:
                glTexCoord2f(tex[i].x+u,tex[i].y+v)
                vx = vert[i].x*sx
                vy = vert[i].y*sy
                glVertex2f((vx*co - vy*si)+x, (vx*si + vy*co)+y)
        glEnd()

    def render(self):
        """

        """
        self._render()

    cdef float2 _bounds_x(self):
            cdef float2 bounds
            cdef float r, co, si, x, sx, sy
            cdef int i
            READ_SLOT(&self._scale_x, &sx)
            READ_SLOT(&self._scale_y, &sy)
            READ_SLOT(&self._rot, &r)
            r = r * PI_OVER_180
            co = cosf(r)
            si = sinf(r)

            for i from 0 <= i < 4:
                x = (self._shape.v[i].x*sx*co - self._shape.v[i].y*sy*si)
                if i == 0:
                    bounds.a = x
                    bounds.b = x
                else:
                    if bounds.a > x:
                        bounds.a = x
                    if bounds.b < x:
                        bounds.b = x
            return bounds

    cdef float2 _bounds_y(self):
            cdef float2 bounds
            cdef float r, co, si, y, sx, sy
            cdef int i
            READ_SLOT(&self._scale_x, &sx)
            READ_SLOT(&self._scale_y, &sy)
            READ_SLOT(&self._rot, &r)
            r = r * PI_OVER_180
            co = cosf(r)
            si = sinf(r)

            for i from 0 <= i < 4:
                y = (self._shape.v[i].x*sx*si + self._shape.v[i].y*sy*co)
                if i == 0:
                    bounds.a = y
                    bounds.b = y
                else:
                    if bounds.a > y:
                        bounds.a = y
                    if bounds.b < y:
                        bounds.b = y
            return bounds

    property left:
        """ x coordinate of the left side of the sprite """
        def __get__(self):
            cdef float x
            READ_SLOT(&self._x, &x)
            return self._bounds_x().a + x
        def __set__(self, x):
            self.x = x - self._bounds_x().a

    property right:
        """ x coordinate of the right side of the sprite """
        def __get__(self):
            cdef float x
            READ_SLOT(&self._x, &x)
            return self._bounds_x().b + x
        def __set__(self, x):
            self.x = x - self._bounds_x().b

    property bottom:
        """ y coordinate of the bottom of the sprite """
        def __get__(self):
            cdef float y
            READ_SLOT(&self._y, &y)
            return self._bounds_y().a + y
        def __set__(self, y):
            self.y = y - self._bounds_y().a

    property top:
        """ y coordinate of the top of the sprite """
        def __get__(self):
            cdef float y
            READ_SLOT(&self._y, &y)
            return self._bounds_y().b + y
        def __set__(self, y):
            self.y = y - self._bounds_y().b

__docs_all__ = ('Sprite BaseSprite').split()
