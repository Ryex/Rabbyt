import rabbyt
from pyglet.window import Window

from pyglet import font
from pyglet import clock
clock.schedule(rabbyt.add_time)

window = Window(width=640, height=480)
rabbyt.set_default_attribs()

class SpriteText(rabbyt.BaseSprite):
    def __init__(self, ft, text="", *args, **kwargs):
        rabbyt.BaseSprite.__init__(self, *args, **kwargs)
        self._text = font.Text(ft, text)

    def set_text(self, text):
        self._text.text = text

    def render_after_transform(self):
        self._text.color = self.rgba
        self._text.draw()

ft = font.load('Arial', 24)
sprite = SpriteText(ft, "Hello World", xy=(320,240))

sprite.rot = rabbyt.lerp(0,360, dt=5, extend="extrapolate")
sprite.rgb = rabbyt.lerp((1,0,0), (0,1,0), dt=2, extend="reverse")

while not window.has_exit:
    clock.tick()
    window.dispatch_events()
    rabbyt.clear()

    sprite.render()

    window.flip()
