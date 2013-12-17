import rabbyt
from pyglet.window import Window
from pyglet import clock
from pyglet import image
import os.path
rabbyt.data_directory = os.path.dirname(__file__)

# This will cause pyglet to call rabbyt.add_time(dt) when we call clock.tick()
# But note that all times will be in *seconds*, not milliseconds like when we
# use pygame.time.get_ticks().
clock.schedule(rabbyt.add_time)

window = Window(width=640, height=480)
rabbyt.set_default_attribs()

car = rabbyt.Sprite("car.png")

# Rabbyt automatically detected that we are using pyglet, and used pyglet
# to load the texture.
assert isinstance(car.texture, image.Texture)

car.xy = (320, 240)

# Fade the car in after one second.
car.alpha = rabbyt.lerp(0.0, 1.0, startt=1, endt=2)

# Rotate the car from 0 to 360 over three seconds, then repeat.
car.rot = rabbyt.lerp(0, 360, dt=3, extend="repeat")

while not window.has_exit:
    clock.tick()
    window.dispatch_events()
  
    rabbyt.clear((1,1,1))

    car.render()

    window.flip()
