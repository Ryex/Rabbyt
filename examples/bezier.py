from math import hypot

import pygame
import rabbyt

rabbyt.init_display((640,480))
rabbyt.set_viewport((640,480), projection=(0,0,640,480))

control_points = [rabbyt.Sprite(xy=xy) for xy in
        [(100,100),(200,50),(300,150),(400,100)]]
grabbed_point = None

path_followers = []
def generate_followers():
    global path_followers
    p = [c.xy for c in control_points]
    path_followers = [rabbyt.Sprite(xy=rabbyt.bezier3(p[0], p[1], p[2], p[3],
            i*200, i*200 + 2000, extend="repeat")) for i in range(10)]

generate_followers()

print "Click and drag the control points."

clock = pygame.time.Clock()
running=True
while running:
    clock.tick(40)

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running=False
        elif event.type == pygame.KEYDOWN:
            if event.key in (pygame.K_ESCAPE, pygame.K_q):
                running=False
        elif event.type == pygame.MOUSEBUTTONDOWN:
            for c in control_points:
                if hypot(c.x-event.pos[0], c.y-event.pos[1]) < 20:
                    grabbed_point = c
                    break
        elif event.type == pygame.MOUSEMOTION:
            if grabbed_point:
                grabbed_point.xy = event.pos
                generate_followers()
        elif event.type == pygame.MOUSEBUTTONUP:
            grabbed_point = None

    rabbyt.set_time(pygame.time.get_ticks())
    rabbyt.clear()
    rabbyt.render_unsorted(control_points)
    rabbyt.render_unsorted(path_followers)
    pygame.display.flip()
