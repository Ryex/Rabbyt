from rabbyt._sprites import cBaseSprite, cSprite
from rabbyt.anims import anim_slot, swizzle, Animable
from rabbyt.primitives import Quad

class BaseSprite(cBaseSprite, Animable):
    """
    ``BaseSprite(...)``

    This class provides some basic functionality for sprites:

    * transformations (x, y, rot, scale)
    * color (red, green, blue, alpha)
    * bounding_radius (for collision detection)

    ``BaseSprite`` doesn't render anything itself  You'll want to subclass it
    and override either ``render()`` or ``render_after_transform()``.

    You can pass any of the ``BaseSprite`` properties as keyword arguments.
    (``x``, ``y``, ``xy``, etc.)
    """
    x = anim_slot(default=0, index=0, doc="x coordinate of the sprite")
    y = anim_slot(default=0, index=1, doc="y coordinate of the sprite")
    rot = anim_slot(default=0, index=2, doc="rotation angle in degrees.")
    red = anim_slot(default=1, index=3, doc="red color component")
    green = anim_slot(default=1, index=4, doc="green color component")
    blue = anim_slot(default=1, index=5, doc="blue color component")
    alpha = anim_slot(default=1, index=6, doc="alpha color component")
    scale_x = anim_slot(default=1, index=7, doc="x component of ``scale``")
    scale_y = anim_slot(default=1, index=8, doc="y component of ``scale``")

    xy = swizzle("x", "y")
    rgb = swizzle("red", "green", "blue")
    rgba = swizzle("red", "green", "blue", "alpha")

    def _get_scale(self):
        if self.scale_x == self.scale_y:
            return self.scale_x
        else:
            return (self.scale_x, self.scale_y)
    def _set_scale(self, s):
        if hasattr(s, "__len__"):
            self.scale_x, self.scale_y = s
        else:
            self.scale_x = self.scale_y = s
    scale = property(_get_scale, _set_scale, doc=
        """
        scale

        ``1.0`` is normal size; ``0.5`` is half size, ``2.0`` is double
        size... you get the point.

        You can scale the x and y axes independently by assigning a tuple with
        a length of two.
        """)

class Sprite(cSprite, BaseSprite):
    """
    ``Sprite(texture=None, shape=None, tex_shape=(0,1,1,0), ...)``

    This class provides a basic, four point, textured sprite.

    All arguments are optional.

    ``texture`` should be an image filename, a pyglet texture object, or
    an OpenGL texture id.  (See ``Sprite.texture`` for more information.)

    If ``shape`` is not given it will default to the dimensions of the
    texture if they are available.  For more information on ``shape`` and
    ``tex_shape`` read the docstrings for ``Sprite.shape`` and
    ``Sprite.tex_shape``

    Additionally, you can pass values for most of the properties as keyword
    arguments.  (``x``, ``y``, ``xy``, ``u``, ``v``, ``uv``, etc...)
    """
    u = anim_slot(default=0, index=9, doc="texture offset")
    v = anim_slot(default=0, index=10, doc="texture offset")

    uv = swizzle("u", "v")

    def __init__(self, texture=None, shape=None, tex_shape=None,
            **kwargs):
        BaseSprite.__init__(self)

        self.red = self.green = self.blue = self.alpha = 1
        self.x = self.y = 0
        self.scale = 1
        self.rot = 0
        self.texture_id = -1

        # If no shape or tex_shape was given, we want to have useful defaults
        # in case the texture doesn't set them.
        if shape is None:
            s = 10.
            self.shape = [s, s, -s, -s]
        if tex_shape is None:
            self.tex_shape = (0,1,1,0)

        self.texture = texture

        # If shape or tex_shape were given, we want them to override the
        # values set when we set the texture.
        if shape is not None:
            self.shape = shape
        if tex_shape is not None:
            self.tex_shape = tex_shape

        for name, value in kwargs.items():
            if hasattr(self.__class__, name) and isinstance(
                    getattr(self.__class__, name),
                    (swizzle, anim_slot, property)):
                 setattr(self, name, value)
            else:
                raise ValueError("unexpected keyword argument %r" % name)

    def _get_texture(self):
        return self._tex_obj
    def _set_texture(self, texture):
        self._tex_obj = texture
        tex_size = None
        if isinstance(texture, basestring):
            from rabbyt._rabbyt import load_texture_file_hook
            res = load_texture_file_hook(texture)
            if isinstance(res, tuple) and len(res) == 2:
                self.texture_id, tex_size = res
            else:
                self.texture = res # Recursive
        elif isinstance(texture, (int, long)):
            self.texture_id = texture
        elif hasattr(texture, "id"):
            self.texture_id = texture.id
            if hasattr(texture, "tex_coords"):
                self.tex_shape = texture.tex_coords
                self.uv = 0,0
            elif hasattr(texture, "tex_shape"):
                self.tex_shape = texture.tex_shape
            if hasattr(texture, "width") and hasattr(texture, "height"):
                tex_size = (texture.width, texture.height)
        elif texture is None:
            self.texture_id = 0
        else:
            raise ValueError("texture should be either an int or str.")

        if tex_size:
            w, h = tex_size
            self.shape = [-w/2, h/2, w/2, -h/2]
    texture = property(_get_texture, _set_texture, doc=
        """
        ``Sprite.texture``

        The texture used for this sprite.

        The value can be in a variety of formats:

            If it's a string, it will be used as a filename to load the
            texture.

            If it's an integer, it will be used as an OpenGL texture id.

            If it's an object with an ``id`` attribute, it will be treated
            as a pyglet texture object.  (The ``width``, ``height``, and
            ``tex_coords`` attributes will set the sprite's ``shape`` and
            ``tex_shape`` properties.)
        """)

__docs_all__ = ["BaseSprite", "Sprite"]
