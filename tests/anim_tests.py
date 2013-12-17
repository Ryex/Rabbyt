import unittest
import rabbyt.anims
from rabbyt.anims import *
import weakref
import ctypes
import warnings
warnings.defaultaction = "error"

def almostEqualTuples(self, t1, t2, places=5):
    self.assertEqual(len(t1), len(t2))
    for a, b in zip(t1, t2):
        self.assertAlmostEqual(a,b, places)

class TestTime(unittest.TestCase):
    def test_set_time(self):
        set_time(100)
        self.assertEqual(get_time(), 100)

    def test_add_time(self):
        set_time(100)
        add_time(10)
        self.assertEqual(get_time(), 110)

class TestAnimSlot(unittest.TestCase):
    def setUp(self):
        self.slot = AnimSlot()

    def test_set_anim(self):
        l = lerp(0,1, startt=get_time(), dt=1)
        self.slot.anim = l
        self.assertEqual(self.slot.anim, l)

    def test_get_value_set(self):
        self.slot.value = 10
        self.assertEqual(self.slot.value, 10)

    def test_get_value_anim(self):
        self.slot.anim = lerp(10,0,dt=1)
        self.assertEqual(self.slot.value, 10)

    def test_set_value_replace_anim(self):
        self.slot.anim = lerp(10,0,dt=1)
        self.assertEqual(self.slot.value, 10)
        self.slot.value = 20
        self.assertEqual(self.slot.anim, None)
        self.assertEqual(self.slot.value, 20)

class TestAnimPyFunc(unittest.TestCase):
    def test_read(self):
        a = AnimPyFunc(lambda: 4)
        self.assertEqual(a.get_value(), 4)

class TestLerp(unittest.TestCase):
    def test_lerp(self):
        l = lerp(10, 100, startt=get_time(), dt=1)
        self.assertEqual(l.get_value(), 10)
        add_time(.5)
        self.assertEqual(l.get_value(), 55)
        add_time(.5)
        self.assertEqual(l.get_value(), 100)

    def test_expire(self):
        set_time(1)
        slot = AnimSlot()
        slot.anim = lerp(0,1, dt=1)
        self.assertEqual(slot.value, 0)
        set_time(3)
        self.assertEqual(slot.value, 1)
        self.assertEqual(slot.anim, None)
        set_time(4)
        self.assertEqual(slot.value, 1)

    def test_anim_input(self):
        set_time(0)
        l1 = lerp(1,2, startt=0, dt=1)
        l2 = lerp(0,l1, startt=0, dt=1)
        self.assertEqual(l2.get_value(), 0)
        set_time(.5)
        self.assertEqual(l2.get_value(), 0.75)
        set_time(1)
        self.assertEqual(l2.get_value(), 2)

    def test_constant_t(self):
        l = lerp(0,10, t=.5)
        self.assertEqual(l.get(), 5)
        add_time(100)
        self.assertEqual(l.get(), 5)

    def test_dynamic_t(self):
        l = lerp(0,10, t=lerp(0,1,dt=2))
        self.assertEqual(l.get(), 0)
        rabbyt.add_time(1)
        self.assertEqual(l.get(), 5)
        rabbyt.add_time(1)
        self.assertEqual(l.get(), 10)

    def test_dynamic_t_incomplete(self):
        l = lerp(0,10, t=lerp(dt=2))
        self.assertEqual(l.get(), 0)
        rabbyt.add_time(1)
        self.assertEqual(l.get(), 5)
        rabbyt.add_time(1)
        self.assertEqual(l.get(), 10)

    # TODO test using multiple dimensions.

class TestMultidimensional(unittest.TestCase, Animable):
    x = anim_slot()
    y = anim_slot()
    xy = swizzle('x', 'y')

    def __init__(self, *pargs, **kwargs):
        Animable.__init__(self)
        unittest.TestCase.__init__(self, *pargs, **kwargs)

    def test_incomplete_start(self):
        self.xy = 10,20
        self.xy = lerp(end=(20,30), dt=10)
        add_time(5)
        almostEqualTuples(self, self.xy, (15, 25))

class TestArithmeticAnim(unittest.TestCase):
    def test_add(self):
        self.assertEqual(ArithmeticAnim("add", 1, 4.5).get_value(), 5.5)
    def test_sub(self):
        self.assertEqual(ArithmeticAnim("sub", 1, 4.5).get_value(), -3.5)
    def test_mul(self):
        self.assertEqual(ArithmeticAnim("mul", 2, 4.5).get_value(), 9)
    def test_div(self):
        self.assertEqual(ArithmeticAnim("div", 6, 3).get_value(), 2)

    def test_neg_complete(self):
        set_time(1)
        self.assertEqual((-lerp(5,6,1,2)).get_value(), -5)

    def test_neg_incomplete(self):
        set_time(1)
        self.assertEqual((-lerp(5,6,dt=1)).get_value(), -5)

    def test_anim_dep(self):
        a = ArithmeticAnim("add", 1, lerp(10,20, dt=1))
        self.assertEqual(a.get_value(), 11)
        add_time(1)
        self.assertEqual(a.get_value(), 21)

    def test_incomplete_add(self):
        a = lerp(10,20,dt=1) + 1
        self.assertEqual(a.get_value(), 11)
        add_time(1)
        self.assertEqual(a.get_value(), 21)


class TestAnimable(unittest.TestCase):
    def setUp(self):
        class Sprite(Animable):
            x = anim_slot()
            y = anim_slot()
            xy = swizzle("x", "y")
        self.Sprite_class = Sprite
        self.sprite = Sprite()

    def test_access(self):
        self.sprite.x = 1
        self.sprite.y = 5
        self.assertEqual(self.sprite.x, 1)
        self.assertEqual(self.sprite.y, 5)

    def test_swizzle_read(self):
        self.sprite.x = 1
        self.sprite.y = 2
        self.assertEqual(self.sprite.xy, (1,2))

    def test_swizzle_write(self):
        self.sprite.xy = 3,4
        self.assertEqual(self.sprite.x, 3)
        self.assertEqual(self.sprite.y, 4)

    def test_kwargs(self):
        sprite = self.Sprite_class(x=1, y=2)
        self.assertEqual(sprite.x, 1)
        self.assertEqual(sprite.y, 2)

    def test_kwargs_swizzle(self):
        sprite = self.Sprite_class(xy=(1,2))
        self.assertEqual(sprite.x, 1)
        self.assertEqual(sprite.y, 2)

    def test_complete_anim(self):
        set_time(1)
        self.sprite.x = lerp(2,3, 1,2)
        self.assertEqual(self.sprite.x, 2)
        set_time(2)
        self.assertEqual(self.sprite.x, 3)

    def test_incomplete_start(self):
        set_time(1)
        self.sprite.x = 2
        self.sprite.x = lerp(end=3, dt=1)
        self.assertEqual(self.sprite.x, 2)
        set_time(2)
        self.assertEqual(self.sprite.x, 3)

    def test_single_slot(self):
        # At one time, a single slot would fail
        class Test(Animable):
            x = anim_slot()
        t = Test(x=1)
        self.assertEqual(t.x, 1)

    def test_circular(self):
        self.sprite.x = 5
        self.sprite.x = self.sprite.attrgetter("x")
        #self.assertRaises(RuntimeError, lambda:self.sprite.x)
        self.assertEqual(0, self.sprite.x)

class TestAnimConst(unittest.TestCase):
    def test(self):
        a = AnimConst(6)
        self.assertAlmostEqual(a.get(), 6)

class TestAnimProxy(unittest.TestCase):
    def setUp(self):
        self.a = AnimProxy(0)

    def test_number(self):
        self.a.value = 10.5
        self.assertAlmostEqual(self.a.get(), 10.5)
        self.a.value = -20.5
        self.assertAlmostEqual(self.a.get(), -20.5)

    def test_function(self):
        self.a.value = lambda: 3
        self.assertAlmostEqual(self.a.get(), 3)

    def test_anim(self):
        set_time(10)
        self.a.value = lerp(1,2, startt=get_time(), dt=10)
        self.assertAlmostEqual(self.a.get(), 1)
        add_time(5)
        self.assertAlmostEqual(self.a.get(), 1.5)

    def test_incomplete_anim(self):
        set_time(10)
        self.a.value = lerp(1,2, dt=10)
        self.assertAlmostEqual(self.a.get(), 1)
        add_time(5)
        self.assertAlmostEqual(self.a.get(), 1.5)


class TestAnimPointer(unittest.TestCase):
    def test_ctypes_pointer(self):
        f = ctypes.c_float(20)
        p = ctypes.pointer(f)
        a = AnimPointer(p)
        self.assertEqual(a.owner, p)
        self.assertEqual(a.get(), 20)
        f.value = 30
        self.assertEqual(a.get(), 30)

    def test_integer_pointer(self):
        f = ctypes.c_float(20)
        a = AnimPointer(ctypes.addressof(f), owner=f)
        self.assertEqual(a.owner, f)
        self.assertEqual(a.get(), 20)
        f.value = 30
        self.assertEqual(a.get(), 30)


class TestChain(unittest.TestCase):
    def test_verbose(self):
        c = chain(
                lerp(0, 10, 0, 1),
                lerp(10, 30, 1, 2))
        set_time(0)
        self.assertEqual(c.get(), 0)
        set_time(.5)
        self.assertEqual(c.get(), 5)
        set_time(1)
        self.assertEqual(c.get(), 10)
        set_time(1.5)
        self.assertEqual(c.get(), 20)
        set_time(2)
        self.assertEqual(c.get(), 30)
        set_time(3)
        self.assertEqual(c.get(), 30)

    def test_from_incomplete(self):
        set_time(0)
        c = chain(
                lerp(0, 10, 0, dt=1),
                lerp(end=30, dt=1))
        self.assertEqual(c.anims[1].start, 10)
        self.assertEqual(c.anims[1].startt, 1)
        self.assertEqual(c.get(), 0)
        set_time(.5)
        self.assertEqual(c.get(), 5)
        set_time(1)
        self.assertEqual(c.get(), 10)
        set_time(1.5)
        self.assertEqual(c.get(), 20)
        set_time(2)
        self.assertEqual(c.get(), 30)
        set_time(3)
        self.assertEqual(c.get(), 30)

    def test_incomplete(self):
        class Test(Animable):
            x = anim_slot()
        t = Test()
        t.x = 100
        set_time(0)
        c = chain(
                lerp(end=10, dt=1),
                lerp(end=30, dt=1))
        set_time(10)
        t.x = c
        self.assertEqual(t.x, 100)
        set_time(10.5)
        self.assertEqual(t.x, 55)
        set_time(11)
        self.assertEqual(t.x, 10)
        set_time(11.5)
        self.assertEqual(t.x, 20)
        set_time(12)
        self.assertEqual(t.x, 30)
        set_time(13)
        self.assertEqual(t.x, 30)

    def test_tupled_chain(self):
        class Test(Animable):
            x = anim_slot()
            y = anim_slot()
            xy = swizzle('x','y')
        set_time(0)
        t = Test()
        now = 0
        t.xy = chain(
                lerp(( 0, 0), (10, 0),    now, now+10),
                lerp((10, 0), (10,10), now+10, now+20),
                lerp((10,10), ( 0,10), now+20, now+30),
                lerp(( 0,10), ( 0, 0), now+30, now+40))

        self.assertEqual(t.xy, (0,0))
        set_time(15)
        almostEqualTuples(self, t.xy, (10,5))
        set_time(35)
        almostEqualTuples(self, t.xy, (0,5))

    def test_tupled_chain_incomplete(self):
        class Test(Animable):
            x = anim_slot()
            y = anim_slot()
            xy = swizzle('x','y')
        set_time(0)
        t = Test()
        t.xy = chain(
                lerp(end=(10, 0), dt=10),
                lerp(end=(10,10), dt=10),
                lerp(end=( 0,10), dt=10),
                lerp(end=( 0, 0), dt=10))

        self.assertEqual(t.xy, (0,0))
        set_time(15)
        almostEqualTuples(self, t.xy, (10,5))
        set_time(35)
        almostEqualTuples(self, t.xy, (0,5))

    # TODO test anims using t argument in a chain.

class Test_rate(unittest.TestCase):
    def setUp(self):
        set_time(1)
        self.r = rate(lerp(0,8,dt=1))
    def test_starting_value(self):
        self.assertEqual(self.r.get(), 0)
    def test_change(self):
        add_time(.5)
        self.assertEqual(self.r.get(), 8)
        self.assertEqual(self.r.get(), 8) # reading twice shouldn't change it.
        add_time(1)
        # half rate, because it stopped halfway through:
        self.assertEqual(self.r.get(), 4)
        add_time(100)
        self.assertEqual(self.r.get(), 0)

class Test_extend(unittest.TestCase):
    def test_constant(self):
        set_time(0)
        l = lerp(0,1,startt=10, endt=20, extend="constant")
        for t, v in [(0,0),(5,0),(10,0),(14,.4),(20,1),(25,1)]:
            set_time(t)
            self.assertAlmostEqual(l.get(), v,
                    msg="Expected %f not %f (time %f)" % (v, l.get(), t))

    def test_extrapolate(self):
        set_time(0)
        l = lerp(0,1,startt=10, endt=20, extend="extrapolate")
        for t, v in [(0,-1),(6,-.4),(10,0),(14,.4),(20,1),(26,1.6)]:
            set_time(t)
            self.assertAlmostEqual(l.get(), v,
                    msg="Expected %f not %f (time %f)" % (v, l.get(), t))

    def test_repeat(self):
        set_time(0)
        l = lerp(0,1,startt=10, endt=20, extend="repeat")
        for t, v in [(0,1),(5,.5),(9,.9),(10,0),(14,.4),(20,1),(26,.6)]:
            set_time(t)
            self.assertAlmostEqual(l.get(), v,
                    msg="Expected %f not %f (time %f)" % (v, l.get(), t))

    def test_reverse(self):
        set_time(0)
        l = lerp(0,1,startt=10, endt=20, extend="reverse")
        for t, v in [(0,1),(5,.5),(9, .1),(10,0),(15,.5),(20,1),(26,.4)]:
            set_time(t)
            self.assertAlmostEqual(l.get(), v,
                    msg="Expected %f not %f (time %f)" % (v, l.get(), t))


if __name__ == '__main__':
    unittest.main()
