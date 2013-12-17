from __future__ import division

import random

import rabbyt, rabbyt.collisions
from rabbyt import lerp, wrap

import pygame

pygame.init()
pygame.display.set_mode((800,600), pygame.OPENGL | pygame.DOUBLEBUF)
rabbyt.set_viewport((800, 600))
rabbyt.set_default_attribs()


sprites = []

r = lambda: random.random()-.5

for i in range(400):
    s = rabbyt.Sprite(shape=(-2,2,2,-2))

    s.x = wrap([-400,400], lerp(r()*800, r()*800, dt=4, extend="extrapolate"))
    s.y = wrap([-300,300], lerp(r()*600, r()*600, dt=4, extend="extrapolate"))

    sprites.append(s)

collision_times = []
c = pygame.time.Clock()
last_fps = 0
while not pygame.event.get(pygame.QUIT):
    c.tick()
    if pygame.time.get_ticks() - last_fps > 1000:
        print "FPS: ", c.get_fps()
        last_fps = pygame.time.get_ticks()
        if collision_times:
            average = sum(collision_times)/len(collision_times)
            print "Average ms to find collisions:", average
        collision_times = []
    rabbyt.clear()
    rabbyt.set_time(pygame.time.get_ticks()/1000.0)

    start = pygame.time.get_ticks()

    collisions = rabbyt.collisions.aabb_collide(sprites)
    collision_times.append(pygame.time.get_ticks()-start)

    for group in collisions:
        for s in group:
            s.rgb = lerp((1,0,0),(1,1,1), dt=.4)
        #s2.rgb = lerp((1,0,0),(1,1,1), dt=.4)

    rabbyt.render_unsorted(sprites)
    pygame.display.flip()
