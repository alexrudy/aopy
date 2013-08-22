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
    """Ensures that this object is an astropy quantity.
    
    :param item: The item to ensure is a quantity. If this is ``None``, the quantity value is assumed to be 0.
    :param unit: The unit.
    
    """
    if item is None:
        value = u.Quantity(0.0, unit)
    elif not isinstance(item, u.Quantity):
        value = u.Quantity(item, unit)
    else:
        value = item
    if not value.unit.is_equivalent(unit):
        raise ValueError("Quantity {} cannot be converted to {}".format(format_quantity(value), unit))
    return value
    
def format_quantity(q, fmt="{:g}", ufmt="{:s}", u=None, basefmt="{value:s} {unit:s}"):
    """Use format strings to format a quantity.
    
    :param astropy.units.Quantity q: The quantity object to format.
    :param str fmt: The value format string.
    :param str ufmt: The unit format string.
    :param u: The unit to convert to. If ``None``, no conversion will occur.
    """
    
    if u is not None:
        q = q.to(u)
    
    return basefmt.format(
        value = fmt.format(q.value),
        unit = ufmt.format(q.unit)
    )