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



cdef extern from "include_math.h":
    cdef float fmodf(float x, float y)
    cdef float cosf(float x)
    cdef float sinf(float x)
    cdef float sqrtf(float x)

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

    cdef void glTranslatef(GLfloat x, GLfloat y, GLfloat z)
    cdef void glEnable(GLenum cap)
    cdef void glDisable(GLenum cap)
    cdef void glClear(GLbitfield mask)
    cdef void glShadeModel(GLenum mode)
    cdef void glClearColor(GLclampf red, GLclampf green, GLclampf blue, GLclampf alpha)
    cdef void glBlendFunc(GLenum sfactor, GLenum dfactor)
    cdef void glBindTexture(GLenum target, GLuint texture)
    cdef void glColor4f(GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha)
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

    cdef GLubyte *glGetString(GLenum name)

    cdef GLint gluBuild2DMipmaps( GLenum target, GLint internalFormat, GLsizei width, GLsizei height, GLenum format, GLenum type, void *data)

from warnings import warn

load_texture_file_hook = None
def set_load_texture_file_hook(callback):
    """
    ``set_load_texture_file_hook(callback)``

    This sets the ``callback`` that is used to load a texture from a file.
    (It is called when you give a string for the first argument of
    ``Sprite``.)

    The default is ``rabbyt.autodetect_load_texture``, which will smartly
    choose between using pyglet of pygame to load the file.

    The ``callback`` should take the filename as a single argument, and return
    either a tuple of the form ``(texture_id, (width, height))`` or any value
    suitable for assiging to ``Sprite.texture``.
    """
    global load_texture_file_hook
    load_texture_file_hook = callback



def render_unsorted(sprites):
    """
    ``render_unsorted(sprites)``

    Renders a list of sprites.

    Since this function is implemented in Pyrex, it should be a little faster
    than looping through the sprites in Python.
    """
    for s in sprites:
        s.render()


def render_sorted(sprites):
    ss = list(sprites)
    ss.sort()
    render_unsorted(ss)


def set_viewport(viewport, projection=None):
    """
    ``set_viewport(viewport, [projection])``

    Sets how coordinates map to the screen.

    ``viewport`` gives the screen coordinates that will be drawn to.  It
    should be in either the form ``(width, height)`` or
    ``(left, top, right, bottom)``

    ``projection`` gives the sprite coordinates that will be mapped to the
    screen coordinates given by ``viewport``.  It too should be in one of the
    two forms accepted by ``viewport``.  If ``projection`` is not given, it
    will default to the width and height of ``viewport``.  If only the width
    and height are given, ``(0, 0)`` will be the center point.
    """
    glMatrixMode(GL_PROJECTION)
    glLoadIdentity()
    if len(viewport) == 4:
        l, t, r, b = viewport
    else:
        l, t = 0, 0
        r, b = viewport
    for i in (l,t,r,b):
        if i < 0:
            raise ValueError("Viewport values cannot be negative")
    glViewport(l, t, r-l, b-t)

    if projection is not None:
        if len(projection) == 4:
            l, t, r, b = projection
        else:
            w,h = projection
            l, r, t, b = -w/2, w/2, -h/2, h/2
    else:
        w,h = r-l, b-t
        l, r, b, t = -w/2, w/2, -h/2, h/2
    glOrtho(l, r, b, t, -1, 1)
    glMatrixMode(GL_MODELVIEW)
    glLoadIdentity()

def set_default_attribs():
    """
    ``set_default_attribs()``

    Sets a few of the OpenGL attributes that sprites expect.

    Unless you know what you are doing, you should call this at least once
    before rendering any sprites.  (It is called automatically in
    ``rabbyt.init_display()``)
    """
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)
    glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE)
    glEnable(GL_BLEND)
    #glEnable(GL_POLYGON_SMOOTH)


def set_gl_color(rgba):
    """
    ``set_gl_color(rgba)``

    This is a thin wrapper around ``glColor4f()``.
    """
    warn("set_gl_color is deprecated.  Use glColor4f instead.",
            stacklevel=2)
    cdef float r,g,b,a
    r, g, b, a = rgba
    glColor4f(r,g,b,a)

def get_gl_vendor():
    """
    ``gl_get_vendor()``

    Returns the OpenGL vendor string.  Returns None if there is no context.
    """
    cdef char * string
    string = <char*>glGetString(GL_VENDOR)
    if string == NULL:
        return None
    else:
        return string


# The following functions were ripped from Simmon Wittber's GFX library:

def load_texture(byte_string, size, type_='RGBA', filter=True, mipmap=True):
    """
    ``load_texture(byte_string, size, type_='RGBA', filter=True, mipmap=True)``

    Load a texture and return it.
    """
    cdef GLuint textures[1]
    cdef GLuint id
    glGenTextures(1, textures)
    id = textures[0]
    update_texture(id, byte_string, size, type_, filter, mipmap)
    return id

def update_texture(texture_id, byte_string, size, type_='RGBA', filter=True,
        mipmap=True):
    """
    ``update_texture(texture_id, byte_string, size, type_='RGBA', filter=True,
    mipmap=True)``

    Update a texture with a different byte_string.
    """

    if not get_gl_vendor():
        raise RuntimeError("Trying to load a texture without an OpenGL context")

    cdef char *data
    data = byte_string
    if type_ == 'RGBA':
        ptype = GL_RGBA
        channels = 4
    elif type_ == 'RGB':
        ptype = GL_RGB
        channels = 3
    else:
        raise ValueError('type_ must be "RGBA" or "RGB"')

    if size[0]*size[1]*channels != len(byte_string):
        raise ValueError('byte_string is an unexpected size.')

    filter_type = GL_NEAREST
    if filter: filter_type = GL_LINEAR
    glBindTexture(GL_TEXTURE_2D, texture_id)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter_type)
    if mipmap:
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST)
        gluBuild2DMipmaps(GL_TEXTURE_2D, channels, size[0], size[1], ptype, GL_UNSIGNED_BYTE, data)
    else:
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter_type)
        glTexImage2D(GL_TEXTURE_2D, 0, ptype, size[0], size[1], 0, ptype, GL_UNSIGNED_BYTE, data)

def unload_texture(texture_id):
    """
    ``unload_texture(texture_id)``

    Unload a texture from memory.
    """
    cdef GLuint textures[1]
    textures[0] = texture_id
    glDeleteTextures(1, textures)

def clear(rgba=(0.0,0.0,0.0,1.0)):
    """
    ``clear(rgba=(0.0,0.0,0.0,1.0))``

    Clear the screen to a background color.
    """
    if len(rgba) == 3:
        rgba = tuple(rgba) + (1.0,)
    glClearColor(rgba[0], rgba[1], rgba[2], rgba[3])
    glClear(GL_COLOR_BUFFER_BIT)
