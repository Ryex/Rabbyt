import random

import rabbyt
from rabbyt import lerp, wrap
import pygame
import os.path
rabbyt.data_directory = os.path.dirname(__file__)

pygame.init()
pygame.display.set_mode((640, 480), pygame.OPENGL | pygame.DOUBLEBUF)
rabbyt.set_viewport((640, 480))
rabbyt.set_default_attribs()


sprites = []

r = lambda: random.random()-.5

for i in range(2400):
    s = rabbyt.Sprite("rounded_square.png")
    s.rgba = lerp((.5,.2,1,.2), (0,.8,0,.6), dt=3*r()+2, extend="reverse")

    s.x = wrap([-320,320], lerp(r()*640, r()*640, dt=2, extend="extrapolate"))
    s.y = wrap([-240,240], lerp(r()*480, r()*480, dt=2, extend="extrapolate"))

    s.scale = lerp(.1, 1, dt=r()+.75, extend="reverse")

    s.rot = lerp(0, 360, dt=2, extend="extrapolate")

    sprites.append(s)

print "Drawing 2400 sprites..."

c = pygame.time.Clock()
last_fps = 0
while not pygame.event.get(pygame.QUIT):
    c.tick()
    if pygame.time.get_ticks() - last_fps > 1000:
        print "FPS: ", c.get_fps()
        last_fps = pygame.time.get_ticks()
    rabbyt.clear()
    rabbyt.set_time(pygame.time.get_ticks()/1000.0)
    rabbyt.render_unsorted(sprites)
    pygame.display.flip()
