from __future__ import division

import pygame
import rabbyt

from math import cos, sin, radians
import random
import os.path

rabbyt.data_directory = os.path.dirname(__file__)


class Car(rabbyt.Sprite):
    boost_particles = set()
    dust_particles = set()
    def __init__(self, name):
        rabbyt.Sprite.__init__(self, name+'.png', (-30, -20, 50, 20))

        self.shadow = rabbyt.Sprite(name+"shadow.png", self.shape)
        self.shadow.alpha = .5

        # These three lines make use of a rather experimental feature of rabbyt.
        # At the end of update() I have left commented out a more traditional
        # method of doing the same thing.
        self.shadow.rot = lambda: self.rot
        self.shadow.x = lambda: self.x - 4
        self.shadow.y = lambda: self.y - 5
        # Here is another method with identical results (only faster):
        #self.shadow.rot = self.attrgetter('rot')
        #self.shadow.x = self.attrgetter('x') - 4
        #self.shadow.y = self.attrgetter('y') - 5

        self.dust_r = (-15, 10)
        self.dust_l = (-15,-10)

        self.accelerating = False
        self.turning_right = False
        self.turning_left = False

        self.boost_endtime = 0
        self.boost_rot = 0

        self.boost_length = 1

        self.xy = [0,0]
        self.velocity = [0,0]
        self.rot = 0

    def boost(self):
        if self.boost_endtime > rabbyt.get_time():
            return
        self.boost_rot = self.rot
        self.boost_endtime = rabbyt.get_time() + self.boost_length

    def update(self):
        if self.turning_right:
            self.rot -= 5
        if self.turning_left:
            self.rot += 5

        a = [0.0,0.0]
        if self.boost_endtime > rabbyt.get_time():
            f = 3*(self.boost_endtime - rabbyt.get_time())/self.boost_length
            a[0] += cos(radians(self.boost_rot))*f
            a[1] += sin(radians(self.boost_rot))*f
            self.create_boost_particle()

        if self.accelerating:
            a[0] += cos(radians(self.rot))*.9
            a[1] += sin(radians(self.rot))*.9
            self.create_dust_particle(self.dust_r)
            self.create_dust_particle(self.dust_l)

        ff = .9 # Friction Factor

        self.velocity[0] *= ff
        self.velocity[1] *= ff

        self.velocity[0] += a[0]
        self.velocity[1] += a[1]

        self.x += self.velocity[0]
        self.y += self.velocity[1]

        #self.shadow.x = self.x - 4
        #self.shadow.y = self.y - 5
        #self.shadow.rot = self.rot


    def create_boost_particle(self):
        s = rabbyt.Sprite(self.texture_id, self.shape)

        lifetime = .5

        s.xy = self.xy
        s.rot = self.rot
        s.scale = rabbyt.lerp(1, 2, dt=lifetime)
        s.alpha = rabbyt.lerp(.8, 0, dt=lifetime)

        Car.boost_particles.add(s)
        rabbyt.scheduler.add(rabbyt.get_time()+lifetime,
                lambda:Car.boost_particles.remove(s))

        lt = .8
        star = rabbyt.Sprite("star2.png")
        x = random.random()*80-40
        y = random.random()*80-40
        star.x = rabbyt.lerp(self.x+x, self.convert_offset((-20,0))[0]+x, dt=lt)
        star.y = rabbyt.lerp(self.y+y, self.convert_offset((-20,0))[1]+y, dt=lt)
        star.rot = rabbyt.lerp(0, 190*random.choice([-2,-1,1,2]), dt=5, extend="extrapolate")
        star.scale = rabbyt.lerp(random.random()+.2,0, rabbyt.get_time()+lt/2, dt=lt/2)
        star.rgb = 0, .5, .9
        Car.boost_particles.add(star)
        rabbyt.scheduler.add(rabbyt.get_time()+lt,
            lambda:Car.boost_particles.remove(star))


    def create_dust_particle(self, offset):
        s = rabbyt.Sprite("star.png")

        lifetime = 4

        x, y = self.convert_offset(offset)

        r = random.random  # (shortcut)
        s.x = rabbyt.lerp(x+r()*10-5, x+r()*60-30, dt=lifetime)
        s.y = rabbyt.lerp(y+r()*10-5, y+r()*60-30, dt=lifetime)

        s.rot = rabbyt.lerp(0, 90*random.choice(range(-2,3)), dt=6)

        s.scale = rabbyt.lerp(1, 4, dt=lifetime)

        now = rabbyt.get_time()
        s.rgba = .7, .5, 0, rabbyt.lerp(.1, 0, now+lifetime/2, now+lifetime)

        Car.dust_particles.add(s)
        rabbyt.scheduler.add(rabbyt.get_time()+lifetime,
                lambda:Car.dust_particles.remove(s))

    def render(self):
        self.shadow.render()
        rabbyt.Sprite.render(self)



if __name__ == "__main__":
    pygame.init()
    pygame.display.set_mode((800,600), pygame.OPENGL | pygame.DOUBLEBUF)
    rabbyt.set_viewport((800, 600))
    rabbyt.set_default_attribs()

    print """
    This is a simple example for using rabbyt.

    Use the arrow keys to steer.  Press SPACE to boost.
    """

    car1 = Car("car")

    cars = [car1]

    clock = pygame.time.Clock()
    while True:
        clock.tick(40)

        for event in pygame.event.get():
            if event.type ==  pygame.QUIT:
                import sys; sys.exit(0)
            elif event.type == pygame.KEYDOWN:
                if event.key in (pygame.K_ESCAPE, pygame.K_q):
                    import sys
                    sys.exit(0)
                elif event.key == pygame.K_SPACE:
                    car1.boost()

        pressed = pygame.key.get_pressed()
        car1.accelerating = pressed[pygame.K_UP]
        car1.turning_right = pressed[pygame.K_RIGHT]
        car1.turning_left = pressed[pygame.K_LEFT]

        rabbyt.set_time(pygame.time.get_ticks()/1000.0)

        for c in cars:
            c.update()

        rabbyt.scheduler.pump()


        rabbyt.clear((.56, .3, 0, 1))

        for c in cars:
            c.render()

        rabbyt.render_unsorted(Car.dust_particles)

        rabbyt.render_unsorted(Car.boost_particles)

        pygame.display.flip()

