# -*- coding: utf-8 -*-
# 
#  test_screengen.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-12.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 

from aopy.atmosphere import screen

import nose.tools as nt
import numpy as np

import os, os.path

import pidly

def npeq_(a,b,msg):
    """Assert numpy equal"""
    nt.ok_(np.allclose(a,b,rtol=1e-4),"{:s} {!s}!={!s}".format(msg,a,b))

class test_screen_functions(object):
    """aopy.atmosphere.screen functions"""
    
    def setup(self):
        """Initialize IDL"""
        
        IDL_PATH = os.path.normpath(os.path.join(os.path.dirname(__file__),"../IDL/screengen/"))
        self.a = {
            'n': 10,
            'm': 10,
            'r0': 4,
            'du': 0.25,
            'seed':5,
            'nsh':2,
        }
        self.idl_output = False
        self.IDL = pidly.IDL()
        self.IDL('!PATH=expand_path("<IDL_default>")+":"+expand_path("+{:s}")'.format(IDL_PATH),print_output=self.idl_output)
        
        
    def teardown(self):
        """Teardown IDL"""
        self.IDL.close()
        
    def test_filter(self):
        """_generate_filter"""
        self.IDL('f = screengen({n:d},{m:d},{r0:f},{du:f})'.format(**self.a),print_output=self.idl_output)
        f_don = self.IDL.f
        f_alex, shf = screen._generate_filter((self.a['n'],self.a['m']),self.a['r0'],self.a['du'])
        npeq_(f_don,f_alex,"Filters do not match!")
              
    def test_screen(self):
        """_generate_screen"""
        # We do this to remove the dependency on how numpy vs. IDL generate noise.
        self.IDL.ex('noise = randomn({seed:d},{n:d},{m:d})'.format(**self.a),print_output=self.idl_output)
        noise = self.IDL.noise
        self.IDL('f = screengen({n:d},{m:d},{r0:f},{du:f})'.format(**self.a),print_output=self.idl_output)
        self.IDL('s = screengen(f,{seed:d})'.format(**self.a),print_output=self.idl_output)
        s_don = self.IDL.s
        f_alex, shf = screen._generate_filter((self.a['n'],self.a['m']),self.a['r0'],self.a['du'])
        s_alex = screen._generate_screen_with_noise(f_alex,noise,du=self.a['du'])
        npeq_(s_don,s_alex,"Screens do not match!")
        
    def test_filter_sh(self):
        """_generate_filter with subharmonics"""
        self.IDL('f = screengen({n:d},{m:d},{r0:f},{du:f},{nsh:d},shf)'.format(**self.a),print_output=self.idl_output)
        f_don = self.IDL.f
        shf_don = self.IDL.shf
        f_alex, shf_alex = screen._generate_filter((self.a['n'],self.a['m']),r0=self.a['r0'],du=self.a['du'],nsh=self.a['nsh'])
        nt.ok_(np.allclose(f_don,f_alex),"Filters do not match!")
        nt.ok_(np.allclose(shf_don,shf_alex.T),"Subharmonic Filters do not match!") # NOTE THE TRANSPOSE HERE!
        
    def test_screen_sh(self):
        """_generate_screen with subharmonics"""
        self.IDL.ex('noise = randomn({seed:d},{n:d},{m:d})'.format(**self.a),print_output=self.idl_output)
        self.IDL.ex('shf_noise = (randomn({seed:d},4) + complex(0,1)*randomn({seed:d},4))/sqrt(2.)'.format(**self.a),print_output=self.idl_output)
        noise = self.IDL.noise
        sh_noise = self.IDL.ev('real(shf_noise)') + 1.0j * self.IDL.ev('imaginary(shf_noise)')
        
        self.IDL('f = screengen({n:d},{m:d},{r0:f},{du:f},{nsh:d},shf)'.format(**self.a),print_output=self.idl_output)
        self.IDL('s = screengen_fn(f,{seed:d},shf,{du:f},shf_noise)'.format(**self.a),print_output=self.idl_output)
        f_don = self.IDL.f
        shf_don = self.IDL.shf
        sh_don = self.IDL.s
        
        f_alex, shf_alex = screen._generate_filter((self.a['n'],self.a['m']),r0=self.a['r0'],du=self.a['du'],nsh=self.a['nsh'])
        sh_alex = screen._generate_screen_with_noise(f_alex,noise,shf_alex,sh_noise,self.a["du"])
        npeq_(f_don,f_alex,"Filters do not match!")
        npeq_(shf_don,shf_alex.T,"Subharmonic Filters do not match!")
        npeq_(sh_don,sh_alex,"Screens do not match!")
        