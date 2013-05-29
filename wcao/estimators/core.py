# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-04-29.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
WCAO Estimator Template Classes
===============================


:class:`BaseEstimator` – Template Class
---------------------------------------

.. autoclass::
    BaseEstimator
    :members:

"""
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import abc

import pyshell.loggers

from aopy.util.basic import ConsoleContext

class Base(ConsoleContext):
    """A common base for WCAO objects"""
    def __init__(self):
        super(Base, self).__init__()
        self.log = pyshell.loggers.getLogger(".".join((__name__,self.__class__.__name__)))
        
    
class BaseEstimator(Base):
    """A base estimator class. This class should be subclassed"""
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self):
        super(BaseEstimator, self).__init__()
        
    
    @abc.abstractmethod
    def setup(self,data):
        """Setup from data"""
        pass
    
    @abc.abstractmethod
    def estimate(self):
        """Do the estimation."""
        pass
        
    @abc.abstractmethod
    def finish(self):
        """Finish of the estimation"""
        pass
