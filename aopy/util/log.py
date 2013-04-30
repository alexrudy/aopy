# -*- coding: utf-8 -*-
# 
#  log.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-29.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import logging

class LType(object):
    """Set a record's logtype"""
    def __init__(self, ltype):
        super(LType, self).__init__()
        self.ltype = ltype
        
    def filter(self,record):
        record.ltype = self.ltype
        return True
        
    def set(self,ltype):
        self.ltype = ltype
        

class LTypeFilter(object):
    
    def __init__(self,*ltypes):
        self.ltypes = set(ltypes)
    
    def filter(self,record):
        if getattr(record,'ltype','') in self.ltypes:
            return False
        return True