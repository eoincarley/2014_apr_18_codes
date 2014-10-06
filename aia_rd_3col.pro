; Routine to plot three-color AIA images. From code by Paolo Grigis.

pro aia_rd_3col, date=date, xwin=xwin, mssl=mssl, zoom=zoom, grid=grid, diff=diff
     
  angstrom = '!3!sA!r!u!9 %!3!n'
  if keyword_set(mssl) then f_loc = '/disk/solar/dml/data' else f_loc = '~/Data/SDO';'/Volumes/DATA_HDD/Data/SDO';

; If we want to zoom in on a region
  if keyword_set(zoom) then begin
;     x_range = [1000, 2000]     ; 20120307
;     y_range = [2000, 3000]     ; 20120307
;     x_range = [1900, 3500]     ; x_range = [1650, 3350]     ; 20120105
;     y_range = [900, 1900]      ; y_range = [800, 2850]     ; 20120105
;     x_range = [0, 950]         ; 2014/02/25
;     y_range = [1150, 2100]     ; 2014/02/25
     x_range = [2047, 4095]     ; 20110607
     y_range = [512, 2560]      ; 20110607
;     x_range = [1535, 2368]     ; 20110213
;     y_range = [1344, 1920]     ; 20110213
;     x_range = [0, 2047]     ; 20120831
;     y_range = [0, 2047]      ; 20120831
;     x_range = [1800, 3800]     ; 20110216
;     y_range = [600, 2600]      ; 20110216
     
     if (x_range[1]-x_range[0]) gt 1024 or (y_range[1]-y_range[0]) gt 1024 then begin
        if (x_range[1]-x_range[0]) ge (y_range[1]-y_range[0]) then begin
           x_size = 1024
           y_size = round(1024*(float(y_range[1]-y_range[0])/float(x_range[1]-x_range[0])))
        endif
        if (x_range[1]-x_range[0]) lt (y_range[1]-y_range[0]) then begin
           y_size = 1024
           x_size = round(1024*(float(x_range[1]-x_range[0])/float(y_range[1]-y_range[0])))
        endif
     endif else begin
        x_size = (x_range[1]-x_range[0])
        y_size = (y_range[1]-y_range[0])
     endelse        
  endif else begin
     x_range = [0, 4095]        ; 20120307
     y_range = [0, 4095]        ; 20120307
     x_size = 1024;512
     y_size = 1024;512
  endelse

  if n_elements(date) eq 0 then date = '2012/03/07'
  
  pass_a = '211'
  pass_b = '193'
  pass_c = '171'
  min_exp_t_193 = 1.
  min_exp_t_211 = 1.5
  min_exp_t_171 = 1.5

  if keyword_set(cutout) then fls_a = file_search(f_loc+'/'+date+'/cutout/'+pass_a+'a/*.fts') $
  else fls_a = file_search(f_loc+'/'+date+'/'+pass_a+'a/*.fits')
  read_sdo, fls_a, i_a, /nodata, only_tags='exptime,date-obs', /mixed_comp, /noshell
  f_a = fls_a[where(i_a.exptime gt min_exp_t_211)]
  t = anytim(i_a.date_d$obs)
  t_a = t[where(i_a.exptime gt min_exp_t_211)]

  if keyword_set(cutout) then fls_b = file_search(f_loc+'/'+date+'/cutout/'+pass_b+'a/*.fts') $
  else fls_b = file_search(f_loc+'/'+date+'/'+pass_b+'a/*.fits')
  read_sdo, fls_b, i_b, /nodata, only_tags='exptime,date-obs', /mixed_comp, /noshell
  f_b = fls_b[where(i_b.exptime gt min_exp_t_193)]
  t = anytim(i_b.date_d$obs)
  t_b = t[where(i_b.exptime gt min_exp_t_193)]

  if keyword_set(cutout) then fls_c = file_search(f_loc+'/'+date+'/cutout/'+pass_c+'a/*.fts') $
  else fls_c = file_search(f_loc+'/'+date+'/'+pass_c+'a/*.fits')
  read_sdo, fls_c, i_c, /nodata, only_tags='exptime,date-obs', /mixed_comp, /noshell
  f_c = fls_c[where(i_c.exptime gt min_exp_t_171)]
  t = anytim(i_c.date_d$obs)
  t_c = t[where(i_c.exptime gt min_exp_t_171)]

  t_str_a = anytim(t_a)
  t_str_b = anytim(t_b)
  t_str_c = anytim(t_c)

; Define the plotting variables
  if keyword_set(xwin) then begin
     window, 0, xs = 750, ys = 750
     !p.multi = 0
  endif else begin     
     set_plot, 'z'
     !p.multi = 0
     img = fltarr(3, x_size, y_size)
     device, set_resolution = [x_size, y_size], set_pixel_depth=24, decomposed=0
  endelse

; Create output folder
  mk_files = 'mkdir SDO '+$
             'SDO/3col '+$
             'SDO/3col/'+time2file(date, /date_only)+' '
  
  spawn, mk_files

; Now identify images adjacent in time using the smallest array to get
; the image times
  arrs = [n_elements(f_a), n_elements(f_b), n_elements(f_c)]
  val = max(arrs, f_max, subscript_min = f_min)
  n_array = [0,1,2]

  if n_elements(f_a) eq n_elements(f_b) and n_elements(f_b) eq n_elements(f_c) then begin
     f_min = 0
     f_max = 2
  endif

  case f_min of
     0: image_time = t_a
     1: image_time = t_b
     2: image_time = t_c
  endcase

  f_mid = n_array[where(n_array ne f_max and n_array ne f_min)]

  case f_max of
     0: max_tim = t_str_a
     1: max_tim = t_str_b
     2: max_tim = t_str_c
  endcase
  case f_min of
     0: min_tim = t_str_a
     1: min_tim = t_str_b
     2: min_tim = t_str_c
  endcase
  case f_mid of
     0: mid_tim = t_str_a
     1: mid_tim = t_str_b
     2: mid_tim = t_str_c
  endcase

  for n = 0, n_elements(min_tim)-1 do begin
     sec_min = min(abs(min_tim - min_tim[n]),loc_min)
     if n eq 0 then next_min_im = loc_min else next_min_im = [next_min_im, loc_min]

     sec_max = min(abs(max_tim - min_tim[n]),loc_max)
     if n eq 0 then next_max_im = loc_max else next_max_im = [next_max_im, loc_max]

     sec_mid = min(abs(mid_tim - min_tim[n]),loc_mid)
     if n eq 0 then next_mid_im = loc_mid else next_mid_im = [next_mid_im, loc_mid]
  endfor

  case f_max of
     0: loc_211 = next_max_im
     1: loc_193 = next_max_im
     2: loc_171 = next_max_im
  endcase
  case f_mid of
     0: loc_211 = next_mid_im
     1: loc_193 = next_mid_im
     2: loc_171 = next_mid_im
  endcase
  case f_min of
     0: loc_211 = next_min_im
     1: loc_193 = next_min_im
     2: loc_171 = next_min_im
  endcase
  
  fls_211 = f_a[loc_211]
  fls_193 = f_b[loc_193]
  fls_171 = f_c[loc_171]

  first_img = 5
  img_diff = 5
  chars = 2
  thicky = 3
  
  if keyword_set(grid) then begin
     read_sdo, fls_a[0], i, d, /mixed_comp, /noshell
     index2map, i, d/i.exptime, map, outsize=x_size
     sz = size(d)
     map2wcs, map, wcs
     pix=wcs_get_pixel(wcs, [0,0])
     img_scale = [map.dx, map.dy]
     img_origin = -[(pix[0]-1)*map.dx, (pix[1]-1)*map.dy]
     
     x1 = img_origin[0] - img_scale[0]/2. & x2 = x1 + sz[1]*img_scale[0]
     y1 = img_origin[1] - img_scale[1]/2. & y2 = y1 + sz[2]*img_scale[1]
          
  endif

  for j = first_img, n_elements(min_tim)-1 do begin

     f_0 = [fls_211[j-img_diff], fls_193[j-img_diff], fls_171[j-img_diff]]
     f_1 = [fls_211[j], fls_193[j], fls_171[j]]

; First image
     aia_prep, f_0, -1, i_a0, d_a0, /uncomp_delete, /norm
     img_0 = d_a0[x_range[0]:x_range[1], y_range[0]:y_range[1], *]

; Second image     
     aia_prep, f_1, -1, i_a1, d_a1, /uncomp_delete, /norm
     img_1 = d_a1[x_range[0]:x_range[1], y_range[0]:y_range[1], *]
     
; Process the images
     if keyword_set(diff) then begin
        if keyword_set(zoom) then d_img = congrid(img_1-img_0, x_size, y_size, 3) else d_img = rebin(img_1-img_0, x_size, y_size, 3)
     endif else begin
        if keyword_set(zoom) then d_img = congrid(img_1/img_0, x_size, y_size, 3) else d_img = rebin(img_1/img_0, x_size, y_size, 3)
     endelse

     if keyword_set(diff) then begin
        min=-20
        max=20
     endif else begin
        min=0.85
        max=1.15
     endelse

     expand_tv, d_img, x_size, y_size, 0, 0, true = 3, min = min, max = max, origin=img_origin, scale=img_scale, /data
     if keyword_set(grid) then plot_helio, i_a1[0].date_d$obs, grid=15, /over, b0=map.b0, rsun=map.rsun, l0=map.l0, gthick=thicky

     !p.font = 0
     xyouts, 0.03, 0.02, pass_a+angstrom+'; '+anytim(i_a1[0].date_d$obs, /yohkoh, /truncate)+' UT', charsize = chars, charthick = thicky, $
             color = cgcolor('red'), /normal
     xyouts, 0.03, 0.06, pass_b+angstrom+'; '+anytim(i_a1[1].date_d$obs, /yohkoh, /truncate)+' UT', charsize = chars, charthick = thicky, $
             color = cgcolor('green'), /normal
     xyouts, 0.03, 0.10, pass_c+angstrom+'; '+anytim(i_a1[2].date_d$obs, /yohkoh, /truncate)+' UT', charsize = chars, charthick = thicky, $
             color = cgcolor('blue'), /normal

     if ~keyword_set(xwin) then begin
        img = tvrd(/true)
        if keyword_set(zoom) then $
           write_png, 'SDO/3col/SDO_3col_zoom_rd_'+time2file(image_time[j], /sec)+'.png', img $
        else write_png, 'SDO/3col/SDO_3col_rd_'+time2file(image_time[j], /sec)+'.png', img
     endif else $
        if keyword_set(zoom) then x2png, 'SDO/3col/SDO_3col_zoom_rd_'+time2file(image_time[j], /sec)+'.png' $
        else x2png, 'SDO/3col/SDO_3col_rd_'+time2file(image_time[j], /sec)+'.png'
    
  endfor
  
  device, /close
  set_plot, 'x'

end
