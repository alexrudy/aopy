# -*- coding: utf-8 -*-
# 
#  __init__.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-06-01.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from .case import WCAOCase

import pyshell

__all__ = ['WCAOCase']

class WCAOData(object):
    """A base type for generic WCAO data objects."""
    
    def __init__(self, case):
        if not isinstance(case, WCAOCase):
            raise TypeError("{}: 'case' must be an instance of {}, got {}".format(
                self, WCAOCase.__name__, type(case)
            ))
        self.case = case
        self.log = pyshell.getLogger(__name__)
        
