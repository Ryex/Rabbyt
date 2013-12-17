"""
This module provides some functions for collision detection.
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

cdef extern from "stdlib.h":
    ctypedef unsigned int size_t
    cdef void *malloc(size_t size)
    cdef void free(void *ptr)
    cdef void *realloc(void *ptr, size_t size)

    ctypedef int(*compar_func)(void *, void *)
    cdef void qsort(void *base, size_t nmemb, size_t size, compar_func compar)

from primitives cimport float2
from _anims cimport READ_SLOT
from _sprites cimport cSprite

def _get_object_data(obj):
    cdef float x,y,brs
    if hasattr(obj, 'x') and hasattr(obj, 'y'):
        x,y = obj.x, obj.y
        if hasattr(obj, "bounding_radius"):
            brs = obj.bounding_radius**2
        else:
            brs = 0
    else:
        x = obj[0]
        y = obj[1]
        if len(obj) > 2:
            brs = obj[2] ** 2
        else:
            brs = 0
    return (x,y,brs)

def collide(objects):
    """
    ``collide(objects) -> list of collisions``

    Collides ``objects``, first using ``rdc()`` and then using
    ``brute_force()``.

    Each object should have the attributes ``x``, ``y``, ``bounding_radius``,
    and ``bounding_radius_squared``.
    """
    collisions = []
    for group in rdc(objects, min_split=10):
        if len(group) > 1:
            collisions.extend(brute_force(group))
    return collisions


def collide_single(single, objects):
    """
    ``collide_single(single, objects)``

    Finds collisions between a single object and a list of objects.

    ``single`` can either be an object with ``x``, ``y``, and
    ``bounding_radius`` attributes, or a tuple of ``(x,y, bounding_radius)``
    (In both cases, ``bounding_radius`` is optional and defaults to ``0``.)
    """
    cdef object o
    cdef float x,y,brs, dx,dy, ox, oy, obrs

    x,y,brs = _get_object_data(single)

    collisions = []
    for o in objects:
        ox, oy, obrs = _get_object_data(o)
        dx = x - ox
        dy = y - oy
        if dx*dx + dy*dy < obrs + brs:
            collisions.append(o)
    return collisions


cdef enum _Side:
    LEFT=1
    RIGHT=2

cdef enum _Axis:
    X=1
    Y=2

cdef struct side_s:
    float x,y
    _Side side
    side_s * other_side
    int index

cdef int _compar_sides_x(void *p1, void *p2):
    cdef float x1, x2
    x1 = (<side_s**>p1)[0][0].x
    x2 = (<side_s**>p2)[0][0].x
    if x1 < x2:
        return -1
    elif x1 > x2:
        return 1
    else:
        return 0

cdef int _compar_sides_y(void *p1, void *p2):
    cdef float y1, y2
    y1 = (<side_s**>p1)[0][0].y
    y2 = (<side_s**>p2)[0][0].y
    if y1 < y2:
        return -1
    elif y1 > y2:
        return 1
    else:
        return 0

def rdc(objects, int min_split=1, int max_depth=0):
    """
    ``rdc(objects, [max_depth,] [min_split]) -> list of collision groups``

    Uses the Recursive Dimensional Clustering algorithm to find groups of
    colliding objects.

    ``objects`` should be a list of objects.  Each object should have the
    attributes ``x``, ``y``, and ``bounding_radius``.

    If the number of objects in a collision group is less than ``min_split``,
    recursion will stop.  This defaults to ``1``, but in practice, it is
    usually faster to just use a brute force method once a group gets down
    to ``10`` objects.

    ``max_depth`` is the maximum number of recursions to make.  It defaults to
    ``0``, which is infinite.

    Instead of returning individual collisions, ``rdc()`` returns groups
    (lists) of colliding objects.  For example, if ``A`` collides with ``B``
    and ``B`` collides with ``C``, one of the groups will be ``[A, B, C]``,
    even though ``A`` and ``C`` don't directly collide.

    Also, each object is returned at most once.  If it is in one group, it won't
    be in any other.  An object without any collisions isn't returned at all.
    """

    cdef side_s * side_list
    cdef side_s ** side_p_list
    cdef int length, i, d, group_start
    cdef float r, x, y
    length = len(objects)*2

    side_list = <side_s*>malloc(sizeof(side_s)*length)
    side_p_list = <side_s**>malloc(sizeof(side_s*)*length)
    try:
        for i from 0 <= i < length/2:
            o = objects[i]
            r = o.bounding_radius
            x = o.x
            y = o.y
            side_list[i*2].x = x-r
            side_list[i*2].y = y-r
            side_list[i*2].side = LEFT
            side_list[i*2].index = i
            side_list[i*2+1].x = x+r
            side_list[i*2+1].y = y+r
            side_list[i*2+1].side = RIGHT
            side_list[i*2+1].index = i

            side_p_list[i*2] = &side_list[i*2]
            side_p_list[i*2+1] = &side_list[i*2+1]

        _rdc(side_p_list, length, X, 0, min_split, max_depth)

        groups = []
        current_group = []
        d = 0
        for i from 0 <= i < length:
            if side_p_list[i][0].side == LEFT:
                if d == 0:
                    # Check to see if we are a single object without any
                    # collisions.  If so, we shouldn't be added as a group.
                    # (Doing this can cut running time in half.)
                    if side_p_list[i][0].index == side_p_list[i+1][0].index:
                        # The next item will be the right side of the same
                        # object; we can safely skip it.
                        i = i + 1
                        continue
                d = d + 1
                current_group.append(objects[side_p_list[i][0].index])
            else:
                d = d - 1
                if d == 0:
                    groups.append(current_group)
                    current_group = []
        return groups
    finally:
        free(side_list)
        free(side_p_list)

cdef void _rdc(side_s ** side_p_list, int length, _Axis axis, int depth,
        int min_split, int max_depth):
    cdef int i
    if length <= min_split*2:
        return
    if max_depth > 0 and depth >= max_depth:
        return

    cdef _Axis next_axis

    if axis == X:
        qsort(side_p_list, length, sizeof(side_s*), _compar_sides_x)
        next_axis = Y
    else:
        qsort(side_p_list, length, sizeof(side_s*), _compar_sides_y)
        next_axis = X

    cdef int group_start, d

    group_start = 0
    d = 0
    for i from 0 <= i < length:
        if group_start == 0 and i == length-1:
            # We only have one group. If we are the first call, go ahead and try
            # the Y access.  Otherwise, let's just bail out now.
            if depth == 0:
                _rdc(side_p_list, length, Y, 1, min_split, max_depth)
            return

        if side_p_list[i][0].side == LEFT:
            d = d + 1
        else:
            d = d - 1
            if d == 0:
                # If we have come to as many right sides as left sides we have
                # found the end of a group.  HOWEVER, if the next left side is
                # exactly overlapping this side, we still want it to count as
                # a collision, hence this crazy looking if:
                if i == length-1 or \
                        (axis==X and 
                                side_p_list[i+1][0].x != side_p_list[i][0].x)\
                        or (axis==Y and 
                                side_p_list[i+1][0].y != side_p_list[i][0].y):
                    
                    _rdc(&side_p_list[group_start], i-group_start+1, next_axis,
                            depth+1, min_split, max_depth)
                    group_start = i + 1



cdef struct collision_object_s:
    float x, y, brs

cdef _brute_force(collision_object_s * objs, int length, objects):
    cdef float dx, dy
    cdef int i, j
    collisions = []
    for i from 0 <= i < length-1:
        for j from i < j < length:
            dx = objs[i].x - objs[j].x
            dy = objs[i].y - objs[j].y
            if dx*dx + dy*dy < objs[i].brs + objs[j].brs:
                collisions.append((objects[i],
                        objects[j]))
    return collisions

def brute_force(objects):
    """
    ``brute_force(objects) -> list of collisions``

    Finds collisions between ``objects`` using a brute force algorithm.

    ``objects`` should be a list of objects, each of which have the attributes
    ``x``, ``y``, and ``bounding_radius_squared``.  Each object is checked
    against every other object.

    For example, if ``A`` collides with ``B``, ``B`` collides with ``C``, and
    ``D`` doesn't collide with anything, the result will be:
    ``[(A, B), (B, C)]``.
    """
    cdef collision_object_s * objs
    cdef int i, length

    length = len(objects)
    objs = <collision_object_s*>malloc(sizeof(collision_object_s)*length)
    try:
        # First we move the data from the python objects into c structures.
        # This is especially important as most of the objects will be sprites,
        # and accessing their positions could set off a long chain of
        # calculations.  We only want to do that once.
        for i from 0 <= i < length:
            o = objects[i]
            objs[i].x = o.x
            objs[i].y = o.y
            objs[i].brs = o.bounding_radius_squared
        # Do the actual work:
        return _brute_force(objs, length, objects)
    finally:
        free(objs)


def collide_groups(group_a, group_b):
    """
    ``collide_groups(group_a, group_b)``

    Returns a list of collisions between objects in ``group_a`` with objects
    in ``group_b``.

    All objects must either have ``x``, ``y``, and (optionally)
    ``bounding_radius`` attributes *or* behave like a tuple with the form
    ``(x, y, bounding_radius)`` or ``(x, y)``.

    If ``bounding_radius`` is missing it will default to ``0``.
    """
    cdef collision_object_s * c_group_b
    cdef int i, length
    cdef collision_object_s obj
    cdef object o
    cdef float dx, dy

    group_b = list(group_b)
    length = len(group_b)

    c_group_b = <collision_object_s*>malloc(sizeof(collision_object_s)*length)
    try:
        i = 0
        for o in group_b:
            c_group_b[i].x, c_group_b[i].y, c_group_b[i].brs = _get_object_data(o)
            i = i + 1

        collisions = []
        for o in group_a:
            obj.x, obj.y, obj.brs = _get_object_data(o)
            for i from 0 <= i < length:
                dx = c_group_b[i].x - obj.x
                dy = c_group_b[i].y - obj.y
                if dx*dx + dy*dy < c_group_b[i].brs + obj.brs:
                    collisions.append((o, group_b[i]))
    finally:
        free(c_group_b)

    return collisions


cdef struct rect_s:
    float l, r, t, b

cdef int _read_rect(object obj, rect_s * rect) except -1:
    cdef float x, y
    cdef cSprite sprite
    cdef float2 temp_float2
    if isinstance(obj, cSprite):
        sprite = obj
        READ_SLOT(&sprite._x, &x)
        READ_SLOT(&sprite._y, &y)
        temp_float2 = sprite._bounds_x()
        rect.l = temp_float2.a + x
        rect.r = temp_float2.b + x
        temp_float2= sprite._bounds_y()
        rect.b = temp_float2.a + y
        rect.t = temp_float2.b + y
    else:
        rect.l = obj.left
        rect.r = obj.right
        rect.t = obj.top
        rect.b = obj.bottom
    if rect.r < rect.l:
        # TODO check to make sure that pyrex isn't using tuples for this...
        rect.l, rect.r = rect.r, rect.l
    if rect.t < rect.b:
        rect.b, rect.t = rect.t, rect.b
    return 1

cdef int _collide_rect(rect_s * a, rect_s * b):
    if a.l <= b.r and a.r >= b.l and a.b <= b.t and a.t >= b.b:
        return 1
    return 0

def aabb_collide(objects):
    """
    ``aabb_collide(objects)``

    ``aabb_collide`` works similar to ``collide``,  but instead of using
    bounding radius it uses axis aligned bounding boxes [AABB].

    All objects must have ``left``, ``top``, ``right``, and ``bottom``
    attributes.
    """
    cdef side_s * side_list
    cdef side_s ** side_p_list
    cdef side_s * temp_side
    cdef int length, i, j, d, group_start, index
    cdef float2 temp_float2
    cdef float l,t,r,b
    cdef rect_s rect
    cdef float x,y
    cdef cSprite sprite
    length = len(objects)*2

    side_list = <side_s*>malloc(sizeof(side_s)*length)
    side_p_list = <side_s**>malloc(sizeof(side_s*)*length)
    try:
        i = 0
        for o in objects:
            _read_rect(o, &rect)
            side_list[i].x = rect.l
            side_list[i].y = rect.b
            side_list[i].side = LEFT
            side_list[i].other_side = &side_list[i+1]
            side_list[i].index = i/2
            side_p_list[i] = &side_list[i]
            i = i + 1
            side_list[i].x = rect.r
            side_list[i].y = rect.t
            side_list[i].side = RIGHT
            side_list[i].other_side = &side_list[i-1]
            side_list[i].index = i/2
            side_p_list[i] = &side_list[i]
            i = i + 1

        _rdc(side_p_list, length, X, 0, 1, 0)

        collisions = []
        for i from 0 <= i < length:
            if side_p_list[i][0].side == LEFT:
                index = side_p_list[i][0].index
                temp_side = side_p_list[i]
                l = temp_side.x
                r = temp_side.other_side[0].x
                b = temp_side[0].y
                t = temp_side[0].other_side[0].y
                j = i + 1
                temp_side = side_p_list[j]
                while temp_side.index != index:
                    if temp_side.side == LEFT:
                        if l <= temp_side.other_side[0].x and \
                                r >= temp_side.x and\
                                b <= temp_side.other_side[0].y and \
                                t >= temp_side.y:
                            collisions.append((objects[index],
                                    objects[side_p_list[j][0].index]))
                    j = j + 1
                    temp_side = side_p_list[j]

        # TODO keyword argument to return the group instead?

        return collisions
    finally:
        free(side_list)
        free(side_p_list)

def aabb_collide_single(single, objects):
    """
    ``aabb_collide_single(single, objects)``

    Finds all objects in ``objects`` that collide with ``single``, (using
    bounding boxes.)

    All objects must have ``left``, ``top``, ``right``, and ``bottom``
    attributes.

    A list of all objects from ``objects`` that collide with ``single`` is
    returned.
    """
    cdef rect_s r_a, r_b
    cdef object o, collisions

    _read_rect(single, &r_a)

    collisions = []
    for o in objects:
        _read_rect(o, &r_b)
        if _collide_rect(&r_a, &r_b):
            collisions.append(o)
    return collisions

def aabb_collide_groups(group_a, group_b):
    """
    ``aabb_collide_groups(group_a, group_b)``

    Returns a list of collisions between objects in ``group_a`` with objects
    in ``group_b``.

    All objects must have ``left``, ``top``, ``right``, and ``bottom``
    attributes.
    """
    cdef rect_s * c_group_b
    cdef rect_s a
    cdef int i, length
    cdef object o
    if not isinstance(group_b, list):
        group_b = list(group_b)

    length = len(group_b)
    c_group_b = <rect_s*>malloc(sizeof(rect_s)*length)

    try:
        i = 0
        for o in group_b:
            _read_rect(o, &c_group_b[i])
            i = i + 1

        collisions = []
        for o in group_a:
            _read_rect(o, &a)
            for i from 0 <= i < length:
                if _collide_rect(&a, &c_group_b[i]):
                    collisions.append((o, group_b[i]))
    finally:
        free(c_group_b)
    return collisions

__docs_all__ = ('collide', 'collide_single', 'collide_groups',
        'aabb_collide', 'aabb_collide_single', 'aabb_collide_groups',
        'rdc', 'brute_force')
