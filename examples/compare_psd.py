#!/usr/bin/env python
# -*- coding: utf-8 -*-
# 
#  compare_psd.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-06-04.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 

import numpy as np
import matplotlib.pyplot as plt

import scipy.fftpack

scPY = np.loadtxt("tf.txt")
scIDL = np.loadtxt("tf_phase.txt")

PY = np.loadtxt("phPSD04.txt")
IDL = np.loadtxt("phPSD04_IDL.txt")
plt.plot(PY)
plt.plot(scipy.fftpack.fftshift(IDL))
plt.yscale('log')
plt.show()
