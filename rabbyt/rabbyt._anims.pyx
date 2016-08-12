"""

This module provides the compiled Anim classes.  Everything is imported into
the rabbyt.anims module, and should be accessed from there.

"""

__credits__ = (
"""
Copyright (C) 2007  Matthew Marshall

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
""")

__author__ = "Matthew Marshall <matthew@matthewmarshall.org>"


cdef extern from "include_math.h":
    cdef float fmodf(float x, float y)
    cdef float cosf(float x)
    cdef float sinf(float x)
    cdef float sqrtf(float x)
    cdef float expf(float x)
    cdef float fabsf(float x)
    cdef float M_PI

cdef extern from "stdlib.h":
    ctypedef unsigned int size_t
    cdef void *malloc(size_t size)
    cdef void free(void *ptr)
    cdef void *realloc(void *ptr, size_t size)

cdef extern from "Python.h":
    cdef int PyNumber_Check(object o)

cdef extern from "anim_sys.h":
    cdef void _set_time(float t)
    cdef void _add_time(float t)
    cdef float _get_time()

    ctypedef struct InterpolateAnim_data:
        AnimSlot_s start, end
        AnimSlot_s t
        int use_global_time
        float start_time, end_time, one_over_dt
        int inter_mode, extend_mode

    cdef AnimFunc interpolate_func

import warnings

def set_time(float t):
    """
    ``set_time(t)``

    Sets the time that ``get_time()`` should return.

    If you are using any time based animations, (such as ``lerp()``,)
    you should call this function every frame.

    For example, if you are using pygame you can do this::

        rabbyt.set_time(pygame.time.get_ticks())

    Using this function should make it easier to implement a pause feature.

    Note that rabbyt makes no assumption about the unit that the time is in.
    You can use milliseconds or seconds or even something else.  It's up to
    you.
    """
    _set_time(t)

def get_time():
    """
    ``get_time()``

    Gets the time that was last set by ``set_time()``
    """
    return _get_time()

def add_time(float t):
    """
    ``add_time(t)``

    Adds ``t`` to the ... time ... (Is it just me or does that sound dorky?)

    This is really just a short cut that does this:

        .. sourcecode:: python

            set_time(get_time() + t)

    The new time is returned.
    """
    _add_time(t)
    return _get_time()

cdef float _on_end_clear(AnimSlot_s * slot, void * data, float end):
    slot.anim = NULL
    slot.type = SLOT_LOCAL
    slot.local = end
    return end

cdef class IncompleteAnimBase:
    """
    This class is only used for introspection.  rabbyt.anims.IncompleteAnim is
    where the implementation is.
    """
    def __add__(self, other):
        return ArithmeticAnim("add", self, other)

    def __sub__(self, other):
        return ArithmeticAnim("sub", self, other)

    def __mul__(self, other):
        return ArithmeticAnim("mul", self, other)

    def __div__(self, other):
        return ArithmeticAnim("div", self, other)

    def __neg__(self):
        return ArithmeticAnim("sub", 0, self)

    def __pos__(self):
        return self

cdef class Anim:
    """
    ``Anim()``

    This is the base class for anims.  It shouldn't be instanced directly.

    Performing arithmetic operations on an anim will result in a new anim that
    will allways be up to date.
    """

    def __init__(self):
        self._anim.on_end = _on_end_clear
        self._anim.on_end_data = NULL
        self.dependencies = []

    def __add__(self, other):
        return ArithmeticAnim("add", self, other)

    def __sub__(self, other):
        return ArithmeticAnim("sub", self, other)

    def __mul__(self, other):
        return ArithmeticAnim("mul", self, other)

    def __div__(self, other):
        return ArithmeticAnim("div", self, other)

    def __neg__(self):
        return ArithmeticAnim("sub", 0, self)

    def __pos__(self):
        return self

    def get_value(self):
        slot = AnimSlot() # TODO cache this!
        slot.anim = self
        return slot.value

    def get(self):
        return self.get_value()

    cdef int add_dependency(self, source, AnimSlot_s * target) except -1:
        cdef AnimSlot slot
        if isinstance(source, IncompleteAnimBase):
            source = source.force_complete()
        if isinstance(source, Anim):
            slot = AnimSlot()
            slot._slot = target
            slot._slot.type = SLOT_LOCAL
            slot.anim = source
            self.dependencies.append(source)
        else:
            target.type = SLOT_LOCAL
            target.local = float(source)

cdef class AnimSlot:
    #cdef AnimSlot_s _internal_slot
    #cdef AnimSlot_s * _slot
    #cdef Anim _py_anim

    def __init__(self):
        self._slot = &self._internal_slot
        self._slot.type = SLOT_LOCAL

    cdef int c_set_anim(self, Anim anim) except -1:
        self._py_anim = anim
        if anim is None:
            self._slot.anim = NULL
            self._slot.type = SLOT_LOCAL
        else:
            self._slot.anim = &self._py_anim._anim
            self._slot.type = SLOT_ANIM
            self._slot.recursion_check = 0

    cdef Anim c_get_anim(self):
        if self._slot.type != SLOT_ANIM:
            self._py_anim = None
        return self._py_anim

    property anim:
        def __get__(self):
            return self.c_get_anim()
        def __set__(self, anim):
            if isinstance(anim, IncompleteAnimBase):
                anim = anim.force_complete()
            self.c_set_anim(anim)

    cdef float c_get_value(self):
        cdef float v
        READ_SLOT(self._slot, &v)
        return v

    cdef int c_set_value(self, float value) except -1:
        if self._slot.type == SLOT_ANIM:
            self._slot.type = SLOT_LOCAL
        if self._slot.type == SLOT_LOCAL:
            self._slot.local = value
        else:
            raise NotImplementedError

    property value:
        def __get__(self):
            return self.c_get_value()
        def __set__(self, float value):
            self.c_set_value(value)

cdef class anim_slot

cdef class cAnimable:
    #cdef object _anim_list
    #cdef int c_slot_count
    #cdef int c_live_slot_count
    #cdef AnimSlot_s ** c_anim_slots
    #cdef AnimSlot_s ** c_live_slots
    def __init__(self, *args, **kwargs):
        cdef AnimSlot slot
        cdef anim_slot desc
        self._anim_list = []
        self.c_slot_count = 0
        if hasattr(self, "_anim_slot_descriptors"):
            self.c_slot_count = len(self._anim_slot_descriptors)
        self.c_anim_slots = <AnimSlot_s**>malloc(
                sizeof(char*)*self.c_slot_count)

        for i in range(self.c_slot_count):
            slot = AnimSlot()
            self._anim_list.append(slot)
        self._modify_slots()

        for i from 0 <= i < self.c_slot_count:
            slot = self._anim_list[i]
            self.c_anim_slots[i] = slot._slot

        self.set_anim_slot_locations()

    cdef _modify_slots(self):
        """
        Called after self._anim_list is populated, be before c_anim_slots.
        """
        pass

    def __dealloc__(self):
        if self.c_anim_slots != NULL:
            free(self.c_anim_slots)
            self.c_anim_slots = NULL

    property anim_slot_list:
        def __get__(self):
            return list(self._anim_list)

    def set_anim_slot_locations(self):
        cdef AnimSlot slot
        for slot in self._anim_list:
            if slot._slot.type >= 0:
                slot._slot.type = SLOT_LOCAL

    def set_anim_slot_locations_in_array(self, attr_names):
        cdef AnimSlot slot
        cdef unsigned long long temp
        for name in attr_names:
            if name in self.__class__.__base__._anim_slot_descriptor_names:
                slot = getattr(self.__class__.__base__, name).get_slot(self)
                array = getattr(self.in_array, name)
                # TODO make sure array type is float.
                slot._slot.type = 0
                slot._slot.offset = (self.in_array.index(self) *
                        array.get_data_stride())
                temp = array.get_data_ptr_addr()
                slot._slot.base = <void **>(temp)

cdef class anim_slot:
    """
    ``anim_slot([default], [doc], [index])``

    ``anim_slot`` is used to create a property that 'understands' anims.  See
    the docs for ``Animable`` for usage.

    ``default`` is the default value for the anim slot.  (It defaults to ``0``.)

    ``index`` is used for optimizing low-level C code.  Only use it if you
    know what you are doing.

    ``anim_slot`` only works in ``Animable`` subclasses.
    """
    cdef public int index
    cdef public float default_value
    cdef public object __doc__
    def __init__(self, default=0, doc="", index=-1):
        self.default_value = default
        self.index = index
        self.__doc__ = doc

    def __get__(self, cAnimable obj, type_):
        if obj is None:
            return self
        if self.index == -1:
            raise RuntimeError
        if obj.c_anim_slots == NULL:
            raise RuntimeError("Animable is not yet initialized.  Call "
                    "Animable.__init__(self) first.  (Or Sprite.__init__)")
        cdef float v
        READ_SLOT(obj.c_anim_slots[self.index], &v)
        return v

    def __set__(self, cAnimable obj not None, value):
        if self.index == -1:
            raise RuntimeError
        if obj.c_anim_slots == NULL:
            raise RuntimeError("Animable is not yet initialized.")
        if PyNumber_Check(value):
            obj.c_anim_slots[self.index].type = SLOT_LOCAL
            obj.c_anim_slots[self.index].local = value
        elif isinstance(value, Anim):
            obj._anim_list[self.index].anim = value
        elif isinstance(value, IncompleteAnimBase):
            value = value.force_complete(start=self.__get__(obj, obj.__class__))
            obj._anim_list[self.index].anim = value
        elif callable(value):
            obj._anim_list[self.index].anim = AnimPyFunc(value)
        else:
            raise ValueError()

    def get_slot(self, cAnimable obj not None):
        return obj._anim_list[self.index]


cdef float _anim_const_func(AnimSlot_s * slot):
    return (<float *>(slot.anim.data))[0]

cdef class AnimConst(Anim):
    """
    ``AnimConst(value)``

    An anim that isn't animated.

    This is mostly here so that constant values can be used with the same
    interface as Anim.  Once upon a time this made sense.
    """
    cdef float v
    def __init__(self, float v):
        self.v = v
        self._anim.data = &self.v
        self._anim.func = <AnimFunc>_anim_const_func


cdef class AnimPointer(Anim):
    """
    ``AnimPointer(pointer, [owner])``

    An anim that reads it's value from a memory address.

    ``pointer`` should either be a ctypes pointer object or the memory address
    as an integer.

    If ``owner`` is given, a reference to it will be held for the lifetime of
    the anim.  Pass the owner of the memory that ``pointer`` points to to
    insure that it won't be deleted before this anim is deleted.  (You risk
    getting a segmentation fault otherwise. Nasty!)

    ``owner`` defaults to be the same as ``pointer``, which is probably what
    you want if ``pointer`` is a ctypes pointer.  But if it's an integer you
    should give ``owner`` explicitly.

    The pointer must point to a C float.  (If it's anything else you'll get
    some crazy results!)
    """
    cdef object _owner
    def __init__(self, pointer, owner=None):
        cdef unsigned long long address
        if owner is None:
            owner = pointer
        if PyNumber_Check(pointer):
            address = pointer
        else:
            import ctypes
            address = ctypes.addressof(pointer.contents)
        self._owner = owner
        self._anim.func = <AnimFunc>_anim_const_func
        self._anim.data = <void *> address

    property owner:
        def __get__(self):
            return self._owner

cdef class InterpolateAnim(Anim):
    cdef InterpolateAnim_data _data
    cdef public object method_name
    def __init__(self, method, start, end, extend, float startt=0, float endt=0,
            t=None):
        Anim.__init__(self)

        self._data.start_time = startt
        self._data.end_time = endt
        #self.extend = extend
        self._data.one_over_dt = 0
        if (endt > startt):
            self._data.one_over_dt = 1/<float>(endt-startt)

        if t is None:
            self._data.use_global_time = True
        else:
            self._data.use_global_time = False
            self.add_dependency(t, &self._data.t)

        self.add_dependency(start, &self._data.start)
        self.add_dependency(end, &self._data.end)

        self._anim.data = &(self._data)

        self._anim.func = interpolate_func

        self._data.inter_mode = {
                "lerp": INTER_LERP,

                "ease_quad": INTER_IN_OUT_QUAD,
                "ease_cubic": INTER_IN_OUT_CUBIC,
                "ease_circ": INTER_IN_OUT_CIRC,
                "ease_back": INTER_IN_OUT_BACK,
                "ease_sine": INTER_IN_OUT_SINE,
                "ease_bounce": INTER_IN_OUT_BOUNCE,

                "ease_in_sine":INTER_IN_SINE,
                "ease_in_quad":INTER_IN_QUAD,
                "ease_in_cubic":INTER_IN_CUBIC,
                "ease_in_exponential":INTER_EXPONENTIAL,
                "ease_in_circ":INTER_IN_CIRC,
                "ease_in_back": INTER_IN_BACK,
                "ease_in_bounce": INTER_IN_BOUNCE,

                "ease_out_quad": INTER_OUT_QUAD,
                "ease_out_cubic": INTER_OUT_CUBIC,
                "ease_out_sine":INTER_OUT_SINE,
                "ease_out_circ": INTER_OUT_CIRC,
                "ease_out_back": INTER_OUT_BACK,
                "ease_out_bounce": INTER_OUT_BOUNCE}[method]

        self._data.extend_mode = {
                "constant":EXTEND_CONSTANT,
                "extrapolate":EXTEND_EXTRAPOLATE,
                "repeat":EXTEND_REPEAT,
                "reverse":EXTEND_REVERSE}[extend]

        self.method_name = method

    property start:
        def __get__(self):
            cdef float x
            READ_SLOT(&self._data.start, &x)
            return x

    property end:
        def __get__(self):
            cdef float x
            READ_SLOT(&self._data.end, &x)
            return x

    property startt:
        def __get__(self):
            return self._data.start_time

    property endt:
        def __get__(self):
            return self._data.end_time

    property dt:
        def __get__(self):
            return self._data.end_time - self._data.start_time

    # TODO provide introspection capabilities for 't' argument?

    def __repr__(self):
        return "<InterpolateAnim %s>" % self.method_name

    property end_time:
        def __get__(self):
            return self._data.end_time

ctypedef struct chain_link_s:
    float end_time
    Anim_s anim

ctypedef struct chain_data_s:
    int link_count
    chain_link_s * links

cdef float _on_end_chain(AnimSlot_s * slot, void * data, float end):
    cdef int i
    cdef float time
    time = _get_time()
    cdef chain_data_s * d
    d = <chain_data_s *> data

    for i from 0 <= i < d.link_count:
        if d.links[i].end_time > time:
            slot.anim.func = d.links[i].anim.func
            slot.anim.data = d.links[i].anim.data
            return slot.anim.func(slot)
    slot.anim.func = d.links[d.link_count-1].anim.func
    slot.anim.data = d.links[d.link_count-1].anim.data
    slot.anim.on_end = _on_end_clear
    slot.anim.on_end_data = NULL
    return slot.anim.func(slot)

cdef class ChainAnim(Anim):
    cdef chain_data_s chain_data
    cdef object _anims

    def __init__(self, anims):
        cdef int i
        cdef Anim anim
        assert len(anims)
        self._anims = list(anims)
        self.chain_data.link_count = len(self._anims)
        self.chain_data.links = <chain_link_s *>malloc(
                sizeof(chain_link_s)*self.chain_data.link_count)

        for i from 0 <= i < self.chain_data.link_count:
            anim = self._anims[i]
            self.chain_data.links[i].anim = anim._anim
            self.chain_data.links[i].end_time = anim.end_time
        self._anim.on_end = _on_end_chain
        self._anim.on_end_data = &self.chain_data

        self._anim.func = self.chain_data.links[0].anim.func
        self._anim.data = self.chain_data.links[0].anim.data

    property anims:
        def __get__(self):
            return list(self._anims)

    def __dealloc___(self):
        if self.chain_data.links != NULL:
            free(self.chain_data.links)
            self.chain_data.links = NULL

# TODO move this to anim_sys.c?
cdef float extend_t(float t, int mode):
    if mode == 1: # constant
        if t < 0:
            t = 0
        elif t > 1:
            t = 1
    elif mode == 2: # extrapolate
        pass
    elif mode == 3: # repeat
        if t > 1.00001:
            t = t - (<int>t)
        elif t < 0:
            t = 1 + t - (<int>t)
    elif mode == 4: # reverse
        if t < 0:
            t = -t
        if (<int>t) % 2 == 1:
            t = 1 - (t - (<int>t))
        else:
            t = t - (<int>t)
    return t

ctypedef struct static_bezier3_data_s:
    int link_count
    float p0
    float startt, endt
    int extend
    float one_over_dt
    float a, b, c
    int use_global_time
    AnimSlot_s t

cdef float _static_bezier3_func(AnimSlot_s * slot):
    cdef float t, t2, t3
    cdef static_bezier3_data_s * d
    d = <static_bezier3_data_s *>(slot.anim.data)
    if d.use_global_time:
        t = extend_t((_get_time()-d.startt)*d.one_over_dt, d.extend)
    else:
        READ_SLOT(&d.t, &t)
    t2 = t * t
    t3 = t2 * t
    return d.a*t3 + d.b*t2 + d.c*t + d.p0

cdef class AnimStaticCubicBezier(Anim):
    cdef static_bezier3_data_s _data

    def __init__(self, float p0, float p1, float p2, float p3, float startt,
            float endt, t, int extend):
        self._data.p0 = p0
        self._data.startt = startt
        self._data.endt = endt
        self._data.extend = extend
        if t is None:
            self._data.use_global_time = True
            self._data.one_over_dt = 1/<float>(endt-startt)
        else:
            self._data.use_global_time = False
            self._data.one_over_dt = 1
            self.add_dependency(t, &self._data.t)
        self._data.c = 3.0 * (p1 - p0)
        self._data.b = 3.0 * (p2 - p1) - self._data.c
        self._data.a = p3 - p0 - self._data.c - self._data.b
        self._anim.func = <AnimFunc>_static_bezier3_func
        self._anim.data = &self._data

    cdef float g(self):
        cdef float t, t2, t3
        t = extend_t((_get_time()-self.startt)*self.one_over_dt, self.extend)
        t2 = t * t
        t3 = t2 * t
        return self.a*t3 + self.b*t2 + self.c*t + self.p0

cdef float _slot_reader_func(AnimSlot_s * slot):
    cdef float v
    READ_SLOT((<AnimSlot_s **>slot.anim.data)[0], &v)
    return v

cdef class AnimSlotReader(Anim):
    cdef AnimSlot read_slot
    def __init__(self, AnimSlot read_slot not None):
        self.read_slot = read_slot
        cdef AnimSlot_s ** _slot
        _slot = &self.read_slot._slot
        self._anim.data = _slot
        self._anim.func = <AnimFunc>_slot_reader_func


cdef struct wrap_data:
    float a, b
    AnimSlot_s input

cdef class AnimWrap(Anim):
    """
    ``AnimWrap(bounds, parent, static=True)``

    An anim that returns another anim wrapped within two bounds.

    You might want to use ``rabbyt.wrap()`` instead.

   ``bounds`` is the bounds that the value should be wrapped within.  It can
    be anything supporting item access with a length of at least two.

    ``parent`` is the ``Anim`` that is being wrapped.

    If static is ``True``, ``bounds[0]`` and ``bounds[1]`` are read only once
    and stored as variables in c.  This is much faster, but doesn't work if
    ``bounds`` is an object you wish to mutate.
    """
    cdef wrap_data _data
    cdef AnimSlot input_slot


    def __init__(self, bounds, parent, static=True):
        Anim.__init__(self)
        self.input_slot = AnimSlot()
        self.input_slot._slot = &self._data.input

        self.input_slot.anim = parent

        self._anim.data = &(self._data)
        if static:
            self._data.a = bounds[0]
            self._data.b = bounds[1]
        else:
            raise NotImplementedError
        self.add_dependency(parent, &self._data.input)
        self._anim.func = <AnimFunc>_wrap_func

cdef float _wrap_func(AnimSlot_s * slot):
    cdef wrap_data * data
    data = <wrap_data *>(slot.anim.data)
    cdef float b1, b2, d
    b1 = data.a
    b2 = data.b
    cdef float p
    READ_SLOT(&data.input, &p)

    d = b2 - b1

    p = fmodf(p-fmodf(b1,d), d)
    if p < 0:
        p = p + d

    return p + b1


cdef struct op_data:
    AnimSlot_s a, b

cdef float _add_func(AnimSlot_s * slot):
    cdef float a, b
    cdef op_data * data
    data = <op_data *>(slot.anim.data)
    READ_SLOT(&data.a, &a)
    READ_SLOT(&data.b, &b)
    return a + b

cdef float _sub_func(AnimSlot_s * slot):
    cdef float a, b
    cdef op_data * data
    data = <op_data *>(slot.anim.data)
    READ_SLOT(&data.a, &a)
    READ_SLOT(&data.b, &b)
    return a - b

cdef float _mul_func(AnimSlot_s * slot):
    cdef float a, b
    cdef op_data * data
    data = <op_data *>(slot.anim.data)
    READ_SLOT(&data.a, &a)
    READ_SLOT(&data.b, &b)
    return a * b

cdef float _div_func(AnimSlot_s * slot):
    cdef float a, b
    cdef op_data * data
    data = <op_data *>(slot.anim.data)
    READ_SLOT(&data.a, &a)
    READ_SLOT(&data.b, &b)
    return a / b


cdef class ArithmeticAnim(Anim):
    cdef op_data _data
    cdef public object operation_name
    def __init__(self, operation, a, b):
        Anim.__init__(self)
        self.add_dependency(a, &self._data.a)
        self.add_dependency(b, &self._data.b)

        self._anim.data = &(self._data)

        if operation == "add":
            self._anim.func = <AnimFunc>_add_func
        elif operation == "sub":
            self._anim.func = <AnimFunc>_sub_func
        elif operation == "mul":
            self._anim.func = <AnimFunc>_mul_func
        elif operation == "div":
            self._anim.func = <AnimFunc>_div_func
        else:
            raise ValueError("Unknown arithmetic operation")

        self.operation_name = operation

    def __repr__(self):
        return "<ArithmeticAnim %s>" % self.operation_name

cdef struct _py_func_data:
    void * function
    float cache, cache_time
    int do_cache

cdef float _py_func_func(AnimSlot_s * slot):
    cdef object function
    cdef _py_func_data * d
    cdef float v
    d = <_py_func_data *>(slot.anim.data)
    function = <object>d.function
    # TODO caching
    v = function()
    return v

cdef class AnimPyFunc(Anim):
    """
    ``AnimPyFunc(function, cache=False)``

    An anim that calls a python function, using the returned value.

    function is the callback called to retrieve the value.  It should
    return a float.

    If ``cache`` is ``True``, the result returned by function will be
    cached for as long as the time (as set by ``rabbyt.set_time()``) doesn't
    change. This could provide good speedup if the value is read multiple
    times per frame.
    """
    cdef object function
    cdef _py_func_data _data
    def __init__(self, function, cache=False):
        self.function = function
        self._anim.data = &(self._data)

        # We're storing the function in two places, but only INCREF'ing once.
        self._data.function = <void *>function

        self._data.do_cache = cache
        self._data.cache_time = -1
        self._anim.func = <AnimFunc>_py_func_func


cdef class AnimProxy(AnimSlotReader):
    """
    ``AnimProxy(value, cache=False)``

    An anim that simply returns the value of another anim.

    ``value`` is the value that can be returned.  It can be a number, a
    function, or another anim.

    If ``cache`` is True, a cached value will be called when the anim is
    accessed a second time without the global time changing.
    """
    cdef int cache_output
    cdef float cache
    cdef float cache_time
    def __init__(self, value, cache=False):
        AnimSlotReader.__init__(self, AnimSlot())
        if cache == True:
            warnings.warn("AnimProxy currently doesn't support caching.",
                    stacklevel=2)
        self.cache_output = cache
        self.value = value

    property value:
        """
        The value that this anim will return.

        You can assign another anim here, and it's value will be returned.
        """
        def __get__(self):
            return self.read_slot.value
        def __set__(self, value):
            if PyNumber_Check(value):
                self.read_slot._slot.type = SLOT_LOCAL
                self.read_slot._slot.local = value
            elif isinstance(value, (Anim, IncompleteAnimBase)):
                self.read_slot.anim = value
            elif callable(value):
                self.read_slot.anim = AnimPyFunc(value)
            else:
                raise ValueError()
            self.cache_time = 0

cdef struct rate_data:
    AnimSlot_s target
    float last, last_time, last_rate

cdef float _rate_func(AnimSlot_s * slot):
    cdef rate_data * d
    d = <rate_data *>(slot.anim.data)
    cdef float v, t, dt
    t = _get_time()
    if t == d.last_time:
        return d.last_rate
    else:
        READ_SLOT(&(d.target), &v)
        dt = t-d.last_time
        d.last_rate = (v-d.last)/dt
        d.last = v
        d.last_time = t
        return d.last_rate

cdef class AnimRate(Anim):
    cdef rate_data _data
    def __init__(self, target):
        Anim.__init__(self)
        self.add_dependency(target, &self._data.target)
        READ_SLOT(&self._data.target, &self._data.last)
        self._data.last_time = _get_time()
        self._data.last_rate = 0
        self._anim.func = <AnimFunc>_rate_func
        self._anim.data = <void*>&self._data


def to_Anim(v):
    """
    ``to_Anim(value) -> Anim subclass instance``

    *This function is deprecated, and will eventually be removed.*

    This is a convenience function to get ``Anim`` for a value.

    If ``value`` is already an ``Anim``, it is returned directly.

    If ``value`` is callable, it is wrapped in an ``AnimPyFunc``.

    Otherwise, ``value`` is wrapped in an ``AnimConst``.
    """
    warnings.warn("to_Anim() is deprecated", stacklevel=2)
    cdef Anim dv
    if isinstance(v, Anim):
        dv = v
    elif callable(v):
        dv = AnimPyFunc(v)
    else:
        dv = AnimConst(v)
    return dv
