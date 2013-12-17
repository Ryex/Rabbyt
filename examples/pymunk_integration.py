from __future__ import division

import ctypes as ct
import pymunk._chipmunk as cp
from pymunk.vec2d import vec2d

import pygame
import rabbyt

from math import cos, sin, radians, degrees, pi
import random
import os.path

rabbyt.data_directory = os.path.dirname(__file__)

def chipmunk_body_anims(body):
    x = rabbyt.AnimPointer(ct.addressof(body.contents.p)+vec2d.x.offset, body)
    y = rabbyt.AnimPointer(ct.addressof(body.contents.p)+vec2d.y.offset, body)
    a = rabbyt.AnimPointer(ct.addressof(body.contents)+cp.cpBody.a.offset, body)
    return x, y, a*(180/pi)

COLLTYPE_DEFAULT = 0

def create_cube(space, mass = 5.0, xy = (0,0)):
    p_num = 4
    P_ARR = vec2d * p_num
    p_arr = P_ARR(vec2d(0,0))
    
    s = 5
    sprite = rabbyt.Sprite(shape=(-s,s,s,-s), xy=xy)
    for i, p in enumerate(sprite.shape):
        p_arr[i].x, p_arr[i].y = p

    moment = 500
    body = cp.cpBodyNew(mass, moment)
    body.contents.p = vec2d(*xy)
    cp.cpSpaceAddBody(space, body)
    
    shape = cp.cpPolyShapeNew(body, p_num, p_arr, vec2d(0,0))
    shape.contents.u = 0.5
    shape.contents.collision_type = COLLTYPE_DEFAULT
    cp.cpSpaceAddShape(space, shape)

    anims = chipmunk_body_anims(body)
    sprite.x, sprite.y, sprite.rot = anims

    return shape, sprite

if __name__ == "__main__":
    pygame.init()
    pygame.display.set_mode((800,600), pygame.OPENGL | pygame.DOUBLEBUF)
    rabbyt.set_viewport((800, 600))
    rabbyt.set_default_attribs()

    ### Physics stuff
    cp.cpInitChipmunk()
    space = cp.cpSpaceNew()
    space.contents.gravity = vec2d(0.0, -900.0)
    
    cp.cpSpaceResizeStaticHash(space, 50.0, 2000)
    cp.cpSpaceResizeActiveHash(space, 50.0, 100)

    wallBody = cp.cpBodyNew(1e100, 1e100)
    wallShape = cp.cpSegmentShapeNew(wallBody, vec2d(-300, -300),
            vec2d(300, -300), 0.0)
    wallShape.contents.u = 1.0
    wallShape.contents.collision_type = COLLTYPE_DEFAULT
    cp.cpSpaceAddStaticShape(space, wallShape)


    shapes = []
    sprites = []

    for x in range(-200, 200, 15):
        for y in range(-200, 400, 15):
            shape, sprite = create_cube(space, xy = (x+random.random()*10,y))
            shapes.append(shape)
            sprites.append(sprite)


    clock = pygame.time.Clock()
    running = True
    while running:
        clock.tick(40)

        for event in pygame.event.get():
            if event.type ==  pygame.QUIT:
                running = False

        rabbyt.set_time(pygame.time.get_ticks())

        rabbyt.scheduler.pump()

        dt = 1/60/2
        # This is the only call in the loop with ctypes overhead :)

        cp.cpSpaceStep(space, dt)
        cp.cpSpaceStep(space, dt)

        rabbyt.clear()

        rabbyt.render_unsorted(sprites)

        pygame.display.flip()

