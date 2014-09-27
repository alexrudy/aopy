# -*- coding: utf-8 -*-
# 
#  basic.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-05.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:mod:`~aopy.util.basic` – Utiltiy Functions
-------------------------------------------

"""


from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import collections

__all__ = ['istype', 'resolve', 'configure_class', 'ConsoleContext', '_ConsoleContext']

def is_type_factory(ttype):
    """Return a function which checks if an object can be cast as a given 
    type. Basic usage allows for checking string-casting to a specific type.
    
    :param ttype: Usually a ``type`` but really, any function which takes one
        argument and which will raise a :exc:`ValueError` if that one argument can't be 
        cast correctly.
        
    """
    def is_type(obj): # pylint: disable = missing-docstring
        try:
            ttype(obj)
        except ValueError:
            return False
        else:
            return True
    is_type.__doc__ = "Checks if obj can be *cast* as {!r}.".format(ttype)
    is_type.__hlp__ = "Input must be an {!s}".format(ttype)
    return is_type

def is_type(instance, ttype):
    """Tests whether an instance is of a current type."""
    return is_type_factory(ttype)(instance)
        
def resolve(name):
    """Resolve a dotted name to a global object."""
    name = name.split('.')
    used = name.pop(0)
    found = __import__(used)
    reload(found)
    for n in name:
        used = used + '.' + n
        try:
            found = getattr(found, n)
        except AttributeError:
            module = __import__(used)
            reload(module)
            found = getattr(found, n)
    return found
    
def configure_class(configuration):
    """Resolve and configure a class."""
    if isinstance(configuration, basestring):
        class_obj = resolve(configuration)()
    elif isinstance(configuration, collections.MutableMapping):
        if "()" in configuration:
            class_type = resolve(configuration.pop("()"))
            class_obj = class_type(**configuration)
        else:
            raise ValueError("Must provide class name in key '()'")
    else:
        raise ValueError("Can't understand {}".format(configuration))
    return class_obj

class _ConsoleContext(object):
    """Allow a switch between range and progress-bar"""
    _console = False
    _looper = None
    
    def __init__(self, *args, **kwargs):
        super(_ConsoleContext, self).__init__(*args, **kwargs)
        self._looper = self._pseudoloop
        self.console = True
    
    @property
    def looper(self):
        """The range function"""
        if self._looper is None:
            return self._pseudoloop
        return self._looper
    
    @property
    def console(self):
        """Whether to use the builtin range or a progressbar"""
        return self._console
        
    def _pseudoloop(self,total_or_items):
        """docstring for _pseudoloop"""
        from astropy.utils.misc import isiterable
        if isiterable(total_or_items):
            iterator = iter(total_or_items)
        else:
            try:
                total = int(total_or_items)
            except TypeError:
                raise TypeError("Argument must be int or sequence")
            else:
                iterator = iter(xrange(total))
        return iterator
        
        
    @console.setter
    def console(self,value):
        """docstring for console"""
        if value:
            from astropy.utils.console import ProgressBar
            self._looper = ProgressBar
        else:
            self._looper = self._pseudoloop
        self._console = value
        
ConsoleContext = _ConsoleContext