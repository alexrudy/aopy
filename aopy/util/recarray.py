# -*- coding: utf-8 -*-
# 
#  recarray.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-07-27.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
.. _util.recarray:

:mod:`~aopy.util.recarray` – Handle Record Arrays
-------------------------------------------------

"""

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

def lodtorec(listofdicts,order=None,dtypes=None):
    """Convert a list of dictionaries each with the same keys to a numpy record array.
    
    :param list listofdicts: A list of dictionaries to convert to a record-array.
    :param list order: A list of keys for the dictionaries, in the desired column order.
    
    The first item in `listofdicts` is used as the master list of keys, and is used to type the resulting numpy arrays, unless both order and dtypes are provided.
    
    """
    nrows = len(listofdicts)
    columns = {}
    
    keys = set(order)
    for row in listofdicts:
        keys.update(row.keys())
    
    keys = list(keys)
    # Set up the datatypes
    if order is not None and dtypes is not None:
        for key,dtype in zip(order,dtypes):
            columns[key] = np.empty(nrows, dtype=dtype)
    else:
        for col in keys:
            columns[col] = np.empty(nrows, dtype=type(listofdicts[0][col]))
    
    # Convert to a recrod array, with proper error catching.
    for i,row in enumerate(listofdicts):
        rowcols = dict.fromkeys(columns.keys(),False)
        for key in row.keys():
            try:
                columns[key][i] = row[key]
            except KeyError:
                raise KeyError("Column '{:s}' was not in the master!".format(key))
            rowcols[key] = True
        if not all(rowcols.values()):
            missing_cols = [ key for key in columns.keys() if ~rowcols[key] ]
            raise KeyError("Missing columns {:s} for row {:d}".format(missing_cols,i))
    
    if order is None:
        names = columns.keys()
    else:
        names = order
    arrays = [ columns[key] for key in names ]
    return np.rec.fromarrays(arrays, names=names)
    
def rectolod(recarray):
    """Convert a record array to a list of dictionaries."""
    return [dict(zip(recarray.dtype.names,x)) for x in recarray]
    
    