# -*- coding: utf-8 -*-
# 
#  core.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-04-29.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
:class:`BaseEstimator` – Template Class
---------------------------------------

The base estimator template class provides a scaffold for creating wind estimators which behave in a standard way, and which are therefore interchangeable with the other wind estimators found in :mod:`wcao`. Estimators should set up any non-data-dependent parameters in their initialization function, or using a configuration file. A call to :meth:`~BaseEstimator.setup` is then used to set up the data dependent parameters required by the estimator. The :meth:`~BaseEstimator.setup` method should do any work required before the estimator starts. Next the :meth:`~BaseEstimator.estimate` method is used to actually compute the wind estimates. When comparing the computational difficulty of methods, the time taken to execute the :meth:`~BaseEstimator.estimate` method is usually used. The :meth:`~BaseEstimator.finish` method is then used to create the appropriate results object class, and to add that result to the original :class:`WCAOCase` object.

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
    """A base estimator class. This class should be subclassed, and the methods :meth:`setup`, :meth:`estimate`, and :meth:`finish` should be replaced by functional methods.
    
    """
    
    __metaclass__ = abc.ABCMeta
    
    def __init__(self):
        super(BaseEstimator, self).__init__()
        
    
    @abc.abstractmethod
    def setup(self,data):
        """Setup from an instance of :class:`wcao.data.case.case`. The :class:`~wcao.data.case.case` can be held as a member object and used throughout :meth:`estimate`.
        
        """
        pass
    
    @abc.abstractmethod
    def estimate(self):
        """
        Do the estimation of the wind magnitude and direction. This method is the method which will be profiled, so it should be fast. It can refer to the :class:`wcao.data.case.case` initialized in :meth:`setup`. It should do **only** the estimation.
        """
        pass
        
    @abc.abstractmethod
    def finish(self):
        """Return the estimate to the original :class:`wcao.data.case.case` object. This method should clean up and record data, such that the :meth:`estimate` method could be called again."""
        pass
