import unittest

import rabbyt.collisions

class Rect(object):
    def __init__(self, l, t, r, b):
        self.left = l
        self.top = t
        self.right = r
        self.bottom = b

    def __eq__(self, other):
        return (self.left == other.left and self.top == other.top and
                self.right == other.right and self.bottom == other.bottom)

class Test_aabb_collide(unittest.TestCase):
    def test_swapped_sides(self):
        rects = [Rect(10,0,0,10), Rect(100,90,90,100)]
        self.assertEqual([], rabbyt.collisions.aabb_collide(rects))

    def test_zero_size(self):
        rects = [Rect(0,0,0,0), Rect(90,90,90,90)]
        self.assertEqual([], rabbyt.collisions.aabb_collide(rects))

class Test_collide_groups(unittest.TestCase):
    def test_collide_groups(self):
        group_a = [(5,5,2), (5,6,3), (10,10,1)]
        group_b = [(6,6,2), (7,7,1), (90,90,1)]
        collisions = rabbyt.collisions.collide_groups(group_a, group_b)
        collisions.sort()
        self.assertEqual(collisions, [
                ((5,5,2), (6,6,2)),
                ((5,6,3), (6,6,2)),
                ((5,6,3), (7,7,1))])

class Test_aabb_collide_single(unittest.TestCase):
    def test_aabb_collide_single(self):
        objects = [Rect(10, 10, 20, 0), Rect(20, 20, 30, 10),
                Rect(100, 110, 110, 100)]
        single = Rect(15, 15, 25, 5)
        collisions = rabbyt.collisions.aabb_collide_single(single, objects)

        self.assertTrue(objects[0] in collisions)
        self.assertTrue(objects[1] in collisions)
        self.assertFalse(objects[2] in collisions)

class Test_aabb_collide_groups(unittest.TestCase):
    def test_aabb_collide_groups(self):
        a = [Rect(5,5,10,0), Rect(5,7,12,1), Rect(10,20,20,10)]
        b = [Rect(6,6,11,1), Rect(11,7,12,6), Rect(90,90,100,80)]
        collisions = rabbyt.collisions.aabb_collide_groups(a, b)
        self.assertEqual(len(collisions), 3)
        self.assertTrue((a[0], b[0]) in collisions)
        self.assertTrue((a[1], b[0]) in collisions)
        self.assertTrue((a[1], b[1]) in collisions)

if __name__=="__main__":
    unittest.main()
