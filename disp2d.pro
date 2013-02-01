;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This function returns centroids and actuator commands in 
; inserted in a 2-D array suitable for display. It uses the size
; of the array to determine how to package it.
; modified by Marcos, 2002/08/21

function disp2d,a
  compile_opt idl2
  
  n=n_elements(a)
;
; Begin by reading in the WFS and DM array mapping definitions.
;  openr,lun,'/kroot/rel/ao/qfix/data/IdlParms/act_map.txt',/get_lun
  openr,lun,'data/keck/act_map.txt',/get_lun
  act_map=intarr(21,21)
  readf,lun,act_map
  free_lun,lun
  
;  openr,lun,'/kroot/rel/ao/qfix/data/IdlParms/sub_ap_map.txt',/get_lun
  openr,lun,'data/keck/sub_ap_map.txt',/get_lun
  sub_map=intarr(20,20)
  readf,lun,sub_map
  free_lun,lun
;
; Create lookup vectors.
  act_map=where(act_map ne 0)
  sub_map=where(sub_map ne 0)
  
  case n of
     304: begin
        temp=fltarr(20,20)
        temp[sub_map]=a
     end
     
     608: begin
        vect=indgen(304)*2
        x=a[vect]
        y=a[vect+1]
        tempx=fltarr(20,20)
        tempy=fltarr(20,20)
        tempx=fltarr(20,20)
        tempx[sub_map]=x
        tempy[sub_map]=y
        temp=fltarr(20,20,2)
        temp[*,*,0]=tempx
        temp[*,*,1]=tempy
     end
     
     349: begin
        temp=fltarr(21,21)
        temp[act_map]=a
     end
     
     352: begin                 ; for the residual wavefront vector for the NGWFC
        a=a[0:348]
        temp=fltarr(21,21)
        temp[act_map]=a
     end
     
     1600:temp=TRANSPOSE(REFORM(a,40,40))
     
     6400:temp=TRANSPOSE(REFORM(a,80,80))
     
     else: temp=0
  endcase  
  return,temp

end






