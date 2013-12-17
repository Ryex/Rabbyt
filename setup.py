from setuptools import setup, find_packages
from setuptools.extension import Extension as BaseExtension
import re

import sys, os
from Cython.Distutils import build_ext


def replace_suffix(path, new_suffix):
    return os.path.splitext(path)[0] + new_suffix



# Setuptools doesn't pass the extension to swig_sources, so until it is
# fixed we need to do a little hack.

_old_swig_sources = build_ext.swig_sources
def swig_sources(self, sources, extension=None):
    # swig_sources only uses the extension for looking up the swig_options,
    # so we're fine with passing it a dummy.
    if extension is None:  extension = Extension("dummy", [])
    return _old_swig_sources(self, sources, extension)
build_ext.swig_sources = swig_sources

class Extension(BaseExtension):
    def __init__(self, name, sources, libraries=()):

        transform = {}
        exclude = []
        compile_args = ["-O3"]
        link_args = []
        if sys.platform == "win32":
            transform = {'GL':'opengl32', 'GLU':'glu32'}
            exclude = ['m']
            compile_args.append("-fno-strict-aliasing")

        libraries = [transform.get(l,l) for l in libraries if l not in exclude]


        if sys.platform == "darwin" and "GL" in libraries:
            compile_args.extend(['-fno-common', '-I',
                    '/System/Library/Frameworks/OpenGL.framework/Headers'])
            link_args.extend(['-dynamic',
            '-L/System/Library/Frameworks/OpenGL.framework/Libraries'])

        BaseExtension.__init__(self, name, sources, libraries=libraries,
                extra_compile_args=compile_args, extra_link_args=link_args)


version = re.search(r'__version__ = "([0-9\.a-z\-]+)"',
        open("rabbyt/__init__.py").read()).groups()[0]

changelog = open("CHANGELOG").read()
split = re.compile("^Version", re.M).split(changelog)
changes = '\n'.join(split[1].split("\n")[2:])
last_version = split[2].split("\n",1)[0].strip()

long_description = open("README").read() + ("""

Changes from Version %s to Version %s
===============================================================

%s

""" % (last_version, version, changes))

setup(
    name = 'Rabbyt',
    version = version,
    author = "Matthew Marshall",
    author_email = "matthew@matthewmarshall.org",
    description = "A fast 2D sprite engine using OpenGL",
    license = "MIT",
    url="http://matthewmarshall.org/projects/rabbyt/",
    long_description=long_description,

    packages = find_packages(),
    include_package_data = True,
    exclude_package_data = {'':['README', 'examples', 'docs'],
            'rabbyt':['*.c', '*.h',  '*.pyx', '*.pxd']},

    ext_modules=[
        Extension("rabbyt._rabbyt", ["rabbyt/rabbyt._rabbyt.pyx"],
            libraries=['GL', 'GLU', 'm']),
        Extension("rabbyt._anims", ["rabbyt/rabbyt._anims.pyx",
                "rabbyt/anim_sys.c"],
            libraries=['GL', 'GLU', 'm']),
        Extension("rabbyt._sprites", ["rabbyt/rabbyt._sprites.pyx"],
            libraries=['GL', 'm']),
        Extension("rabbyt.collisions", ["rabbyt/rabbyt.collisions.pyx"],
            libraries=['m']),
        Extension("rabbyt.primitives", ["rabbyt/rabbyt.primitives.pyx"],
            libraries=['GL', 'm']),
    ],

    classifiers = [
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'License :: OSI Approved :: MIT License',
        'Programming Language :: Python',
        'Topic :: Multimedia :: Graphics',
        'Topic :: Software Development :: Libraries :: Python Modules',
    ],

    cmdclass={'build_ext': build_ext}
)
