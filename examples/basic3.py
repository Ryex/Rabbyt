import rabbyt
import pygame

import os.path
rabbyt.data_directory = os.path.dirname(__file__)


pygame.init()
pygame.display.set_mode((640, 480), pygame.OPENGL | pygame.DOUBLEBUF)
rabbyt.set_viewport((640, 480))
rabbyt.set_default_attribs()

car = rabbyt.Sprite("car.png")

# Sprites have various properties you can change.
car.x = 100
car.rot = 45
car.scale = .5
car.rgb = (1,0,0)

# The full list of properties is: x, y, u, v, rot, scale, red, green, blue, and
# alpha
# There all also a few shortcut properties to allow you to set multiple values
# at a time: xy, uv, rgb, and rgba

while not pygame.event.get(pygame.QUIT):
    rabbyt.clear((1,1,1))

    car.render()

    pygame.display.flip()
