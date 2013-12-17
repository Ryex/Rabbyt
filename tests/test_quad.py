from __future__ import division

import unittest

from rabbyt.primitives import Quad

class TestQuadAsRect(unittest.TestCase):
    def setUp(self):
        self.quad = Quad((-11, 12, 13, -14))

    def test_as_list(self):
        self.assertEqual(list(self.quad),
            [(-11,12), (13,12), (13,-14), (-11,-14)])

    def test_read_left(self):
        self.assertEqual(self.quad.left, -11)

    def test_write_left(self):
        self.quad.left = 1
        self.assertEqual(list(self.quad), [(1,12), (25,12), (25,-14), (1,-14)])

    def test_read_top(self):
        self.assertEqual(self.quad.top, 12)

    def test_write_top(self):
        self.quad.top = 1
        self.assertEqual(list(self.quad),
                [(-11,1), (13,1), (13,-25), (-11,-25)])

    def test_read_right(self):
        self.assertEqual(self.quad.right, 13)

    def test_write_right(self):
        self.quad.right = -1
        self.assertEqual(list(self.quad),
                [(-25,12), (-1,12), (-1,-14), (-25,-14)])

    def test_read_bottom(self):
        self.assertEqual(self.quad.bottom, -14)

    def test_write_bottom(self):
        self.quad.bottom = 1
        self.assertEqual(list(self.quad),
                [(-11,27), (13,27), (13,1), (-11,1)])

    def test_read_y(self):
        self.assertEqual(self.quad.y, -1)

    def test_write_y(self):
        self.quad.y += 5
        self.assertEqual(list(self.quad),
            [(-11,12+5), (13,12+5), (13,-14+5), (-11,-14+5)])

    def test_read_x(self):
        self.assertEqual(self.quad.x, 1)

    def test_write_x(self):
        self.quad.x += 5
        self.assertEqual(list(self.quad),
            [(-11+5,12), (13+5,12), (13+5,-14), (-11+5,-14)])

    def test_read_width(self):
        self.assertEqual(self.quad.width, 24)

    def test_write_width(self):
        self.quad.width = 12
        self.assertEqual(list(self.quad),
            [(-5,12), (7,12), (7,-14), (-5,-14)])

    def test_read_height(self):
        self.assertEqual(self.quad.height, 26)

    def test_write_height(self):
        self.quad.height = 13
        self.assertEqual(list(self.quad),
            [(-11,5.5), (13,5.5), (13,-7.5), (-11,-7.5)])

class TestGetSetItem(unittest.TestCase):
    def setUp(self):
        self.quad = Quad((-11, 12, 13, -14))

    def test_getitem(self):
        self.assertEqual(self.quad[0], (-11,12))
        self.assertEqual(self.quad[1], (13,12))
        self.assertEqual(self.quad[2], (13,-14))
        self.assertEqual(self.quad[3], (-11,-14))
        self.assertEqual(self.quad[-4], (-11,12))
        self.assertEqual(self.quad[-3], (13,12))
        self.assertEqual(self.quad[-2], (13,-14))
        self.assertEqual(self.quad[-1], (-11,-14))

    def test_getitem_index_error(self):
        self.assertRaises(IndexError, lambda:self.quad[-5])
        self.assertRaises(IndexError, lambda:self.quad[4])

    def test_setitem_index_error(self):
        def setitem():
            self.quad[-5] = (0,0)
            self.quad[4] = (0,0)
        self.assertRaises(IndexError, setitem)

if __name__ == '__main__':
    unittest.main()
