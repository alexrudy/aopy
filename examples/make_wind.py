#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  make_wind.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-18.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

import astropy.io.fits as pf
from aopy.atmosphere import wind

from astropy.utils.console import ProgressBar

shape = (26,26)
du = 10/30
r0 = 0.30
ntime = 1000

Screen = wind.ManyLayerScreen(shape,r0,du=du,vel=[[0,1]],tmax=ntime).setup()

print("Screen Velocity {!s}".format(Screen.velocity))

import scipy.fftpack
screen = np.zeros((ntime,)+shape)
fmodes = np.zeros((ntime,)+shape,dtype=np.complex)
for i in ProgressBar(range(ntime)):
    screen[i,...] = Screen.get_screen(i)
    fmodes[i,...] = scipy.fftpack.fft2(screen[i,...])

print("Done... {}".format(screen.shape))
pf.writeto("test_screen.fits",screen,clobber=True)

