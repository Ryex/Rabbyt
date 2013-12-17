import rabbyt
import pygame

pygame.init()
pygame.display.set_mode((640, 480), pygame.OPENGL | pygame.DOUBLEBUF)
rabbyt.set_viewport((640, 480))
rabbyt.set_default_attribs()


sprites = [rabbyt.Sprite(x=x) for x in range(-100, 100, 50)]

# Constant is the default extend mode.  It will not go beyond start or end.
sprites[0].y = rabbyt.lerp(-100, 100, 1, 3, extend="constant")

# With extrapolate, it just keeps going.
sprites[1].y = rabbyt.lerp(-100, 100, 1, 3, extend="extrapolate")

# With repeat, it starts at start again after reaching end.
sprites[2].y = rabbyt.lerp(-100, 100, 1, 3, extend="repeat")

# Reverse is like repeat, only every other time it moves from end to start.
sprites[3].y = rabbyt.lerp(-100, 100, 1, 3, extend="reverse")

while not pygame.event.get(pygame.QUIT):
    rabbyt.clear()
    rabbyt.set_time(pygame.time.get_ticks()/1000.0)

    rabbyt.render_unsorted(sprites)

    pygame.display.flip()
