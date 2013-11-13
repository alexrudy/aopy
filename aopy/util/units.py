# -*- coding: utf-8 -*-
# 
#  units.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-27.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

"""
:mod:`~aopy.util.units` – Functions for :mod:`astropy.units`
============================================================
"""

import astropy.units as u

def ensure_quantity(item, unit=""):
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
        raise ValueError("Quantity '{}' cannot be converted to {!s}".format(format_quantity(value), unit))
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
    
    try:
        string = basefmt.format(
            value = fmt.format(q.value),
            unit = ufmt.format(q.unit)
        )
    except ValueError:
        string = basefmt.format(
            value = repr(q.value),
            unit = ufmt.format(q.unit)
        )
    return string
    
def quantity_representer(dumper, data):
    """A YAML representer for quantities"""
    dumper.represent_scalar("!quantity",format_quantity(data))
    
def quantity_constructor(loader, node):
    """A YAML loader for quantities"""
    from yaml.nodes import ScalarNode
    scalar = loader.construct_scalar(node)
    value_str, unit_str = scalar.split(None,1)
    vnode = ScalarNode('tag:yaml.org,2002:float', value_str)
    value = loader.construct_yaml_float(vnode)
    unit = u.Unit(unit_str)
    return (value * unit)
    
def use_yaml_quantity():
    import yaml
    yaml.add_constructor('!quantity', quantity_constructor)
    yaml.add_representer(u.Quantity, quantity_representer)
