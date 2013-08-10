#!/usr/bin/env python
# 
#  try_mulfac.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-05-15.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np
from astropy.io import fits

from wcao.data.keck import transfac

pytf = transfac()

with fits.open("tests/keck_trans_mulfac.fits") as ff:
    idtf = ff[0].data

print(np.allclose(pytf,idtf))

np.savetxt("pytf.txt",pytf)
np.savetxt("idtf.txt",idtf)