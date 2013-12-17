import random

import rabbyt
from rabbyt.fonts import Font, FontSprite
import pygame
import os.path
rabbyt.data_directory = os.path.dirname(__file__)

pygame.init()
pygame.display.set_mode((800, 480), pygame.OPENGL | pygame.DOUBLEBUF)
rabbyt.set_viewport((800, 480))
rabbyt.set_default_attribs()

font = Font(pygame.font.Font(pygame.font.get_default_font(), 20))

sprites = []

sprites.append(FontSprite(font, "lerp", x=-275, y=480/2-10))
sprites.append(rabbyt.Sprite(x=-275, y=480/2-50))
sprites.append(rabbyt.Sprite(x=-125, y=480/2-50))
s = rabbyt.Sprite()
s.x = rabbyt.lerp(-275, -125, dt=3, extend="repeat")
s.y = 480/2-50
sprites.append(s)


sprites.append(FontSprite(font, "ease", x=-275, y=480/2-70))
sprites.append(FontSprite(font, "ease_out", x=-20, y=480/2-70))
sprites.append(FontSprite(font, "ease_in", x=235, y=480/2-70))

methods = ["sine", "quad", "cubic", "circ", "back", "bounce"]
ypos = 480/2-100
for method in methods:
    sprites.append(FontSprite(font, method, x=-390, y=ypos))
    for func, start, end in [(rabbyt.ease, -275, -125),
                            (rabbyt.ease_out, -20, 130),
                            (rabbyt.ease_in, 235, 385)]:
        sprites.append(rabbyt.Sprite(x=start, y=ypos-10))
        sprites.append(rabbyt.Sprite(x=end, y=ypos-10))
        s = rabbyt.Sprite()
        s.x = func(start, end, dt=3, extend="repeat", method=method)
        s.y = ypos-10
        sprites.append(s)
    ypos -= 30

c = pygame.time.Clock()
while not pygame.event.get(pygame.QUIT):
    rabbyt.add_time(c.tick(40)/1000.0)
    rabbyt.clear()
    rabbyt.render_unsorted(sprites)
    pygame.display.flip()
