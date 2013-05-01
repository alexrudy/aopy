# -*- coding: utf-8 -*-
# 
#  screengen.py
#  aopy
#  
#  Created by Jaberwocky on 2013-04-12.
#  Copyright 2013 Jaberwocky. All rights reserved.
# 
from __future__ import (absolute_import, unicode_literals, division,
                        print_function)

import numpy as np

def generate_filter(shape,r0,du,L0=None,nsh=0):
    """Generate the filter for this screen.
    
    :param shape: Shape of the desired screen.
    :param r0: $r_0$ fried parameter for the screen.
    :param L0: $L_0$ outer scale for the screen.
    :param nsh: Number of subharmonics to use. Results are good below ``nsh=8``
    :param shf:
    """
    n,m = shape
    dkx = 2 * np.pi / (n*du)
    dky = 2 * np.pi / (m*du)
    kx,ky = np.meshgrid((np.arange(n) - n//2) * dkx,(np.arange(m) - m//2) * dky,indexing='ij')
    if L0 is None:
        k0 = 0
    else:
        k0 = 2 * np.pi / L0
    k2 = np.power(kx,2) + np.power(ky,2) + (k0 ** 2.0)
    k2[n//2,m//2] = 1.0
    
    f = np.sqrt(0.023) * np.power(2.0 * np.pi / r0,5/6) * np.power(k2,-11/12) * np.sqrt(dkx * dky)
    
    f[n//2,m//2] = 0.0
    
    if nsh > 0:
        shf = np.zeros((8,nsh))
        for i in range(nsh):
            dkx = dkx/3.
            dky = dky/3.
            k2 = dkx**2 + dky**2 + k0**2
            shf[0,i] = k2**(-11./12.)*np.sqrt(dkx*dky)
            shf[1,i] = (dky**2+k0**2)**(-11./12.)*np.sqrt(dkx*dky)
            shf[2,i] = k2**(-11./12.)*np.sqrt(dkx*dky)
            shf[3,i] = (dkx**2+k0**2)**(-11./12.)*np.sqrt(dkx*dky)
            shf[4,i] = (dkx**2+k0**2)**(-11./12.)*np.sqrt(dkx*dky)
            shf[5,i] = k2**(-11./12.)*np.sqrt(dkx*dky)
            shf[6,i] = (dky**2+k0**2)**(-11./12.)*np.sqrt(dkx*dky)
            shf[7,i] = k2**(-11./12.)*np.sqrt(dkx*dky)
        shf = shf*np.sqrt(0.023)*(2*np.pi)**(5./6.)*r0**(-5./6.)
    else:
        shf = None
    
    return f, shf

def generate_screen_with_noise(f,noise=None,shf=None,shn=None,du=1.0):
    """
    Generate a screen from a given grid of noise.
    
    :param f: Filter, from :func:`generate_filter`
    :param noise: Noise, shame shape as ``f``.
    
    """
    import numpy.fft
    rn = noise if noise is not None else np.ones(f.shape)
    frn = numpy.fft.fftshift(numpy.fft.fft2(rn)) * np.sqrt(np.prod(f.shape))
    s = np.real(numpy.fft.ifft2(numpy.fft.ifftshift(frn*f)))
    if shf is not None:
        n,m = f.shape
        dkx = 2.0*np.pi/(n*du)
        dky = 2.0*np.pi/(m*du)
        x = (np.arange(n)*du) # (fltarr(m)+1)
        y = (np.arange(n)+1) # (findgen(m)*du)
        rn = np.ones((8,),dtype=np.complex)
        nsh = shf.shape[0]
        for i in range(nsh):            
            rn[0:4] = shn
            rn[7] = np.conj(rn[0])
            rn[6] = np.conj(rn[1])
            rn[5] = np.conj(rn[2])
            rn[4] = np.conj(rn[3])
            dkx = dkx/3.0
            dky = dky/3.0
            s = s + rn[0]*shf[0,i]*np.exp(1j*(-dkx*x-dky*y))
            s = s + rn[1]*shf[1,i]*np.exp(1j*(-dky*y))
            s = s + rn[2]*shf[2,i]*np.exp(1j*(dkx*x-dky*y))
            s = s + rn[3]*shf[3,i]*np.exp(1j*(-dkx*y))
            s = s + rn[4]*shf[4,i]*np.exp(1j*(dkx*y))
            s = s + rn[5]*shf[5,i]*np.exp(1j*(-dkx*x+dky*y))
            s = s + rn[6]*shf[6,i]*np.exp(1j*(dky*y))
            s = s + rn[7]*shf[7,i]*np.exp(1j*(dkx*x+dky*y))
    
    return s
    

def generate_screen(f,seed=None,shf=None,du=None):
    """
    Generate a screen from a given grid of noise.
    
    :param f: Filter, from :func:`generate_filter`
    :param seed: Random number seed, to make noise suitable.
    :param shf:
    :param du: Pixels per subaperture
    
    """
    import numpy.random
    rn = numpy.random.RandomState(seed).randn(*f.shape)
    shn = (numpy.random.RandomState(seed).randn(4) + 1j*numpy.random.RandomState(seed).randn(4))/np.sqrt(2.0)
    return generate_screen_with_noise(f,rn,shf,shn,du)

class Screen(object):
    """A base phase screen class.
    
    :param tuple shape: The shape of the screen (x,y) tuple.
    :param float r0: $r_0$ fried parameter for the screen.
    :param float L0: $L_0$ outer scale for the screen.
    :param int nsh: Number of subharmonics. (default``=0`` for no subharmonics)
    :param float du: Pixels per subaperture
    
    """
    def __init__(self, shape, r0, seed = None, du=1.0, L0=None,nsh=0):
        super(Screen, self).__init__()
        
        # Parameters
        self._shape = shape
        self._r0 = r0
        self._du = du
        self._L0 = L0
        self._nsh = nsh
        
        # Generated Quantities
        self._shf = None
        self._filter = None
        self._screen = None
        
        # User-editable quantities
        self.seed = seed
        
    @property
    def shape(self):
        """Shape of the screen (n x m)."""
        return self._shape
        
    @property
    def r0(self):
        """Fried's parameter"""
        return self._r0
        
    @property
    def L0(self):
        """docstring for L0"""
        return self._L0
        
    @property
    def du(self):
        """docstring for du"""
        return self._du
        
    @property
    def nsh(self):
        """Number of sub-harmonics"""
        return self._nsh
        
    @property
    def screen(self):
        """Return the actual screen"""
        return self._screen
        
    def get_screen(self):
        """Return the screen"""
        return self.screen
        
    def setup(self):
        """Set up this screen"""
        self.generate_filter()
        self.generate_screen()
        return self
        
    def generate_filter(self):
        """Generate the filter required for this screen object."""
        self._filter, self._shf = generate_filter(self.shape,self.r0,self.du,self.L0,self.nsh)
        
    def generate_screen(self,seed=None):
        """Generate the actual screen.
        
        :param seed: The random number generator seed.
        """
        if seed is not None:
            self.seed = seed
        self._screen = generate_screen(self.filter,self.seed,self._shf,self.du)
        
        
        
    