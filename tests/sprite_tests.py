from __future__ import division

import unittest

from rabbyt.sprites import *
from math import *


class TestSprite(unittest.TestCase):
    pass


class TestBoundingRadius(unittest.TestCase):
    def test_bounding_radius_from_shape(self):
        s = Sprite()
        self.assertEqual(s.bounding_radius, s.shape.bounding_radius)
        s.shape.width = 100
        self.assertEqual(s.bounding_radius, s.shape.bounding_radius)

    def test_bounding_radius_explicit(self):
        s = Sprite()
        original_shape_radius = s.shape.bounding_radius
        s.bounding_radius = 5
        self.assertEqual(s.bounding_radius, 5)
        self.assertEqual(s.shape.bounding_radius, original_shape_radius)
        s.shape.width = 100
        self.assertEqual(s.bounding_radius, 5)
        del s.bounding_radius
        self.assertEqual(s.bounding_radius, s.shape.bounding_radius)

    def test_bounding_radius_squared(self):
        s = Sprite()
        self.assertEqual(s.bounding_radius_squared, s.bounding_radius**2)
        s.bounding_radius = 10
        self.assertEqual(s.bounding_radius_squared, 100)

    def test_bounding_radius_scale(self):
        s = Sprite()
        s.scale=3
        self.assertAlmostEqual(s.bounding_radius, s.shape.bounding_radius * 3)

    def test_bounding_radius_scale_x(self):
        s = Sprite()
        s.scale_x=3
        self.assertAlmostEqual(s.bounding_radius, s.shape.bounding_radius * 3)

    def test_bounding_radius_scale_y(self):
        s = Sprite()
        s.scale_y=3
        self.assertAlmostEqual(s.bounding_radius, s.shape.bounding_radius * 3)
        
    def test_bounding_radius_squared_scale(self):
        s = Sprite()
        s.scale=3
        self.assertAlmostEqual(s.bounding_radius_squared, s.shape.bounding_radius**2*9)
        
        

class TestSpriteSides(unittest.TestCase):
    def setUp(self):
        self.s = Sprite(shape=(1,20,2,10))

    def testLeft(self):
        self.assertEqual(self.s.left, 1)

    def testTop(self):
        self.assertEqual(self.s.top, 20)

    def testRight(self):
        self.assertEqual(self.s.right, 2)

    def testBottom(self):
        self.assertEqual(self.s.bottom, 10)

    def test_scale_x(self):
        self.s.scale_x = 2
        self.assertEqual(self.s.left, 2)
        self.assertEqual(self.s.right, 4)

    def test_scale_y(self):
        self.s.scale_y = 2
        self.assertEqual(self.s.top, 40)
        self.assertEqual(self.s.bottom, 20)

    def test_absolute_left(self):
        self.s.x = 10
        self.assertEqual(self.s.left, 11)

def rotate(x,y, angle):
    co = cos(radians(angle))
    si = sin(radians(angle))
    return x*co - y*si, x*si + y*co

class TestSpriteSidesRot(unittest.TestCase):
    def setUp(self):
        self.s = Sprite(shape=(-10,10,10,-10), rot=45)
    def test_simple(self):
        self.assertAlmostEqual(self.s.right, hypot(10,10))
        self.assertAlmostEqual(self.s.top, hypot(10,10))
        self.assertAlmostEqual(self.s.top, rotate(10,10, 45)[1])
        self.assertAlmostEqual(self.s.left, -hypot(10,10))
        self.assertAlmostEqual(self.s.bottom, -hypot(10,10))

    def test_scale_x(self):
        self.s.rot=30
        self.s.scale_x = 2
        self.assertAlmostEqual(self.s.right, rotate(20, -10, 30)[0], places=4)
        self.assertAlmostEqual(self.s.top, rotate(20, 10, 30)[1], places=4)

    def test_scale_y(self):
        self.s.rot=30
        self.s.scale_y = 2
        self.assertAlmostEqual(self.s.right, rotate(10, -20, 30)[0], places=4)
        self.assertAlmostEqual(self.s.top, rotate(10, 20, 30)[1], places=4)



if __name__ == '__main__':
    unittest.main()
