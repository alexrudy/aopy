# -*- coding: utf-8 -*-
# 
#  units.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-27.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

import astropy.units as u

def ensure_quantity(item,unit=None):
    """Ensures that this object is an astropy quantity"""
    
    if item is None:
        value = u.Quantity(0.0,unit)
    elif not isinstance(item, u.Quantity):
        value = u.Quantity(item,unit)
    else:
        value = item
    return value.to(unit)