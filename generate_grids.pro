;; CVS header information for IDL files
;; $Revision: 1.6 $
;; $Author: poyneer1 $
;; $Date: 2011/11/03 23:25:43 $


;; ****** OFFICIAL USE ONLY ***************
;; May be exempt from public release under the 
;; Freedom of Information Act (5 U.S.C 552), 
;; exemption and category 4: Commercial.
;; 
;; ****** IMPORTANT RESTRICTIONS **********
;; This code is for strictly limited release 
;; within the Gemini Planet Imager project and 
;; may not be made publicly available. Under EAR99,
;; there are restrictions on the availability of this
;; code to foreign nationals. Please contact 
;; Lisa Poyneer <poyneer1@llnl.gov>.
;; ****************************************


;; --------------------------------------------------------
;; This work was performed under the auspices of the U.S. Department of 
;; Energy by the University of California, Lawrence Livermore National 
;; Laboratory under contract No. W-7405-Eng-48.
;; OR 
;; This work performed under the auspices of the U.S. Department of Energy 
;; by Lawrence Livermore National Laboratory under Contract DE-AC52-07NA27344.

;; Developed by Lisa A. Poyneer 2001-2008
;; No warranty is expressed or implied.
;; --------------------------------------------------------

;; this is a helper since I am always making these stupid 
;; x and y-indices grids!!!!!


pro generate_grids, xgrid, ygrid, n, scale=sfac, $
                    double=doubleflag, whole=wholeflag, $
                    freqshift=fflag

if keyword_set(fflag) then begin
    xgrid = make_array(n,n,double=doubleflag)
    for j=0, n-1 do xgrid[j,*] = j - (j GT n/2)*n
    if keyword_set(sfac) then xgrid = xgrid*sfac
    ygrid = transpose(xgrid)
    
endif else begin

    xgrid = make_array(n,n,double=doubleflag)
    for j=0, n-1 do xgrid[j,*] = j*1.
    if (n mod 2 ) eq 0 then begin
        if keyword_set(wholeflag) then offset = n/2. else offset = (n-1)/2.
    endif else begin
        if keyword_set(wholeflag) then offset = (n-1)/2. else offset = n/2.
    endelse

    xgrid = xgrid - offset
    if keyword_set(sfac) then xgrid = xgrid*sfac
    ygrid = transpose(xgrid)
endelse

end


