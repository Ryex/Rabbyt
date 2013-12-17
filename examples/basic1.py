import rabbyt
import pygame

# This is pretty much the bare minimum.

pygame.init()
pygame.display.set_mode((640, 480), pygame.OPENGL | pygame.DOUBLEBUF)
rabbyt.set_viewport((640, 480))
rabbyt.set_default_attribs()

while not pygame.event.get(pygame.QUIT):
    # Clear the screen to white.  (Colors in rabbyt are the same as in OpenGL,
    # from 0.0 to 1.0.)
    rabbyt.clear((1.0,1.0,1.0))

    pygame.display.flip()
