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

from pyshell.util import is_type_factory

__all__ = ['istype', 'resolve', 'configure_class', 'ConsoleContext', '_ConsoleContext']

def istype(instance, ttype):
    """Tests whether an instance is of a current type."""
    return is_type_factory(ttype)(instance)
        
def resolve(name):
    """Resolve a dotted name to a global object."""
    name = name.split('.')
    used = name.pop(0)
    found = __import__(used)
    for n in name:
        used = used + '.' + n
        try:
            found = getattr(found, n)
        except AttributeError:
            __import__(used)
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
    
    def __init__(self):
        super(_ConsoleContext, self).__init__()
        self._looper = self._pseudoloop
        self.console = True
    
    @property
    def looper(self):
        """The range function"""
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
            total = len(total_or_items)
        else:
            try:
                total = int(total_or_items)
            except TypeError:
                raise TypeError("Argument must be int or sequence")
            else:
                iterator = iter(xrange(self._total))
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