# -*- coding: utf-8 -*-
# 
#  estimate_wind_gn.py
#  aopy
#  
#  Created by Alexander Rudy on 2013-04-29.
#  Copyright 2013 Alexander Rudy. All rights reserved.
# 
"""
This is a pIDLy implementation of estimate_wind_gn.pro
"""

from .core import BasePIDLYEstimator
from aopy.aperture import Aperture

import numpy as np

import os.path, os, textwrap
import pidly

class GaussNewtonPIDLY(BasePIDLYEstimator):
    """docstring for GaussNewtonPIDLY"""
    
    array_modes = {
        'fits' : 0,
        'fits_partial' : 1,
        'pidly' : 2,
        'pidly_full': 3,
    }
    
    method = "estimate_wind_gn"
    
    def __init__(self, astron_path, array_mode='fits', linear=False, filename='phase.fits', nstep=None, iterations=1):
        super(GaussNewtonPIDLY, self).__init__()
        self.path += [(astron_path,True)]
        self.array_mode = array_mode
        self.linear = linear
        self.filename = filename
        self.iterations = iterations
        self.nstep = nstep
        self.nlayers = 1
        
    def setup(self,aperture):
        """docstring for setup"""
        self.IDL = pidly.IDL(max_sendline=(2**11 - 1),long_delay=0.05)
        self.setup_path()
        self.aperture = Aperture(aperture)
        self.IDL.ap_every = self.aperture.pupil
        self.IDL.ap_inner = self.aperture.edgemask
        self._load("edgemask","depiston",self.method)
        self.IDL("a = edgemask(ap_every,ap_inloc)")
        self.IDL("n = {:d}".format(self.aperture.shape[0]))
        self.IDL("p_ap_every = ptr_new(ap_every)")
        self.IDL("p_ap_inloc = ptr_new(ap_inloc)")
        self.IDL("wind = [0.0,0.0]")
        self.IDL("ewind = fltarr(2)")
        if self.nstep is not None:
            self.IDL("results = fltarr({nstep:d},2)".format(nstep=self.nstep))
        self.load_phase()
        return self
    
    def load_phase(self):
        """docstring for load_phase"""
        if self.array_mode is "fits":
            self.IDL.ex("sig = readfits('{:s}',tmphead)".format(os.path.relpath(self.filename)),print_output=False)
        
    def estimate(self,tstep):
        """docstring for estimate"""
        cmd = textwrap.dedent("""\
        previous = sig[*,*,{prev:d}]
        current = sig[*,*,{curr:d}]
        pprev = ptr_new(previous)
        pcurr = ptr_new(current)
        ewind = estimate_wind_gn(pcurr,pprev,n,p_ap_every,p_ap_inloc,wind,{iter:d})
        ptr_free,pcurr
        ptr_free,pprev
        wind[0] = ewind[0,0]
        wind[1] = ewind[0,1]""").format(
            iter = self.iterations,
            curr = tstep,
            prev = tstep-1,
        ).splitlines()
        if self.nstep is not None:
            cmd += ["results[{curr:d},*] = wind".format(curr=tstep)]
        for line in cmd:
            self.IDL.ex(line,print_output=False)
        if self.nstep is None:
            return self.IDL.ev("ewind").T
        else:
            return