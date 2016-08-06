import rabbyt
import pygame

import os.path
# We do this so that you don't have to be in the same directory as the script
# to use it.
rabbyt.data_directory = os.path.dirname(__file__)

pygame.init()

# Make sure that you allways have an OpenGL window created before loading
# textures:
pygame.display.set_mode((640, 480), pygame.OPENGL | pygame.DOUBLEBUF)

rabbyt.set_viewport((640, 480))
rabbyt.set_default_attribs()

# Creating a sprite is easy.  Just give it an image filename.
car = rabbyt.Sprite("car.png")

while not pygame.event.get(pygame.QUIT):
    rabbyt.clear((1,1,1))

    car.render()

    pygame.display.flip()
