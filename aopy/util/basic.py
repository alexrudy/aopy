# -*- coding: utf-8 -*-
# 
#  basic.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-05.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

def istype(instance,ttype):
    """docstring for is_type"""
    try:
        ttype(instance)
    except Exception:
        return False
    else:
        return True

class ConsoleContext(object):
    """Allow a switch between range and progress-bar"""
    def __init__(self):
        super(ConsoleContext, self).__init__()
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
        
    def _pseudoloop(self,iterator):
        """docstring for _pseudoloop"""
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
        