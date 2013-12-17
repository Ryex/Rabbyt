#!/usr/bin/python

# This is just a quick hack because I couldn't find anything I liked.

# [Note for anyone reading this: I wrote this code back in 2007, before
# sphinx was around.]

import os, os.path
import sys
import types

from textwrap import dedent

from django.conf import settings as djangosettings
djangosettings.configure(TEMPLATE_DEBUG=True,
    TEMPLATE_LOADERS = (
            'django.template.loaders.filesystem.load_template_source',),
    TEMPLATE_DIRS = ('templates',))
    #TEMPLATE_DIRS = ('/home/mmarshall/mmorg/templates', 'templates',))

from django.template import Template, Context, add_to_builtins, loader

import re

add_to_builtins('django.contrib.markup.templatetags.markup')


import pygments
from pygments.lexers import get_lexer_by_name
from pygments.formatters import HtmlFormatter
import docutils.parsers.rst.directives as rstdirectives
import docutils.nodes
PYGMENTS_FORMATTER = HtmlFormatter()

def pygments_directive(name, arguments, options, content, lineno,
                        content_offset, block_text, state, state_machine):
    try:
        lexer = get_lexer_by_name(arguments[0])
    except ValueError:
        # no lexer found
        lexer = get_lexer_by_name('text')
    parsed = pygments.highlight(u'\n'.join(content), lexer,
            PYGMENTS_FORMATTER)
    return [docutils.nodes.raw('', parsed, format='html')]
pygments_directive.arguments = (1, 0, 1)
pygments_directive.content = 1
rstdirectives.register_directive('sourcecode', pygments_directive)


modules = []

doc_wrappers = {}

def listify(func):
    def inner(*args, **kwargs):
        return list(func(*args, **kwargs))
    return inner

class Module(object):
    def __init__(self, module, options):
        doc_wrappers[module] = self
        self.module = module
        self.options = options
        self.dir = os.path.join(options.output_dir, *module.__name__.split('.'))

    @property
    @listify
    def all_children(self):
        if not hasattr(self.module, '__docs_all__'):
            print "warning: no __docs_all__ in %r" % self.module
        else:
            for name in self.module.__docs_all__:
                if name.startswith("_"): continue
                obj = getattr(self.module, name)
                yield (name, obj)

    @property
    def name(self):
        return self.module.__name__

    @property
    def doc(self):
        return dedent(self.module.__doc__)

    def get_absolute_url(self):
        return self.options.base_url + \
                '/'.join(self.module.__name__.split('.'))+'/'

    @property
    @listify
    def classes(self):
        for name, obj in self.all_children:
            if isinstance(obj, type):
                if not obj.__doc__:
                    print "Class %s has not docstring" % name
                yield Class(obj, self)

    @property
    @listify
    def modules(self):
        for name, obj in self.all_children:
            if isinstance(obj, types.ModuleType):
                if not obj.__doc__:
                    print "Module %s has not docstring" % name
                yield Module(obj, self.options)

    @property
    @listify
    def functions(self):
        for name, obj in self.all_children:
            if isinstance(obj, (types.FunctionType, types.BuiltinFunctionType)):
                if not obj.__doc__:
                    print "Function %s has not docstring" % name
                yield Function(obj, self, name)

class Class(object):
    def __init__(self, class_, module):
        doc_wrappers[class_] = self
        self.class_ = class_
        self.module = module
        self.options = module.options
        self.dir = os.path.join(self.module.dir, self.name)

    def get_absolute_url(self):
        return self.module.get_absolute_url() + self.name + "/"

    @property
    def doc(self):
        return dedent(self.class_.__doc__)

    @property
    def name(self):
        return self.class_.__name__

    @property
    @listify
    def methods(self):
        for name in dir(self.class_):
            if name.startswith("_"): continue
            obj = getattr(self.class_, name)
            if repr(type(obj)) == "<type 'method_descriptor'>" or \
                    isinstance(obj, types.MethodType):
                if not obj.__doc__:
                    print "Method %s has not docstring; skipping" % name
                    continue
                yield Method(obj, self.options, name)

    @property
    @listify
    def properties(self):
        from rabbyt import anim_slot, swizzle
        for name in dir(self.class_):
            if name.startswith("_"): continue
            obj = getattr(self.class_, name)
            if repr(type(obj)) == "<type 'getset_descriptor'>" or \
                    isinstance(obj, (property, anim_slot, swizzle)):
                if not obj.__doc__:
                    print "Method %s has not docstring; skipping" % name
                    continue
                yield Method(obj, self.options, name)

    @property
    @listify
    def bases(self):
        for base in self.class_.__bases__:
            if base in doc_wrappers:
                yield doc_wrappers[base]

class Function(object):
    def __init__(self, function, options, name):
        doc_wrappers[function] = self
        self.options = options
        self.function = function
        self.name = name

    @property
    def doc(self):
        return dedent(self.function.__doc__)

Method = Function

class Options(object):
    def __init__(self, **kwargs):
        self.__dict__.update(kwargs)

def do_module(module):
    t = loader.get_template("module.html")
    vars = {'module':module}
    vars['relative_base'] = '/'.join(['..']*(len(module.get_absolute_url().split('/'))-2))
    vars.update(module.options.__dict__)
    result = t.render(Context(vars))
    if not os.path.exists(module.dir):
        os.makedirs(module.dir)
    f = open(os.path.join(module.dir, "index.html"), "wt")
    f.write(result)

    for c in module.classes:
        do_class(c)


def do_class(class_):
    t = loader.get_template("class.html")
    vars = {'class':class_}
    vars['relative_base'] = '/'.join(['..']*(len(class_.get_absolute_url().split('/'))-2))
    vars.update(class_.options.__dict__)
    result = t.render(Context(vars))
    if not os.path.exists(class_.dir):
        os.makedirs(class_.dir)
    f = open(os.path.join(class_.dir, "index.html"), "wt")
    f.write(result)

if __name__ == "__main__":
    import rabbyt, rabbyt.anims, rabbyt.sprites, rabbyt.collisions,\
            rabbyt.primitives
    #options = Options(base_url="/projects/rabbyt/docs/",
            #output_dir="/home/mmarshall/export/projects/rabbyt/docs/",
            #use_relative=False)
    options = Options(base_url="/", output_dir="./", use_relative=True)

    for m in (rabbyt, rabbyt.anims, rabbyt.sprites, rabbyt.collisions,
            rabbyt.primitives):
        do_module(Module(m, options))
