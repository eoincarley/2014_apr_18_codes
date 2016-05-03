pro setup_postscript, name, xsize, ysize

    set_plot,'ps'
    !p.font=0
    !p.charsize=0.8
    device, filename = name, $
          ;/decomposed, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=14, $;xsize/100, $
          ysize=7, $;xsize/100, $
          /encapsulate, $
          bits_per_pixel=32;, $
         ; yoffset=5

end

pro return_struct, bridge, struct_name, struct

      ; IDL bridges cannot pass structures I/O. This procedure works around that.

      tag_namess = bridge->GetVar('tag_names('+struct_name+')') 
      first_val = bridge->GetVar(struct_name+'.(0)')
      first_tag = tag_namess[0]
      struct = CREATE_STRUCT(NAME=struct_name, first_tag, first_val)
      for i =1, n_elements(tag_namess)-2 do begin
         append_name = tag_namess[i]
         append_value = bridge->GetVar(struct_name+".("+strcompress(string(i), /remove_all)+")")
         struct = CREATE_STRUCT(struct, append_name, append_value)
      endfor

END

pro stamp_date, i_a, i_b, i_c
   
   !p.charsize=1.2
   set_line_color
   xpos_aia_lab = 0.075
   ypos_aia_lab = 0.78

   xyouts, xpos_aia_lab+0.0012, ypos_aia_lab+0.05, 'AIA '+string(i_a.wavelnth, format='(I03)') +' A '+anytim(i_a.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=4
   xyouts, xpos_aia_lab-0.0012, ypos_aia_lab+0.05, 'AIA '+string(i_a.wavelnth, format='(I03)') +' A '+anytim(i_a.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=4
   xyouts, xpos_aia_lab, ypos_aia_lab+0.05, 'AIA '+string(i_a.wavelnth, format='(I03)') +' A '+anytim(i_a.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 3
   
   xyouts, xpos_aia_lab+0.0012, ypos_aia_lab+0.025, 'AIA '+string(i_b.wavelnth, format='(I03)') +' A '+anytim(i_b.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=4
   xyouts, xpos_aia_lab-0.0012, ypos_aia_lab+0.025, 'AIA '+string(i_b.wavelnth, format='(I03)') +' A '+anytim(i_b.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=4
   xyouts, xpos_aia_lab, ypos_aia_lab+0.025, 'AIA '+string(i_b.wavelnth, format='(I03)') +' A '+anytim(i_b.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 4
   
   xyouts, xpos_aia_lab+0.0012, ypos_aia_lab, 'AIA '+string(i_c.wavelnth, format='(I03)') +' A '+anytim(i_c.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=4
   xyouts, xpos_aia_lab-0.0012, ypos_aia_lab, 'AIA '+string(i_c.wavelnth, format='(I03)') +' A '+anytim(i_c.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 0, charthick=4
   xyouts, xpos_aia_lab, ypos_aia_lab, 'AIA '+string(i_c.wavelnth, format='(I03)') +' A '+anytim(i_c.t_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 10
END

;--------------------------------------------------------------------;
;
; Routine to plot three-color AIA images. From code by Paolo Grigis.
;
;--------------------------------------------------------------------;

pro aia_three_color_for_movie, date = date, mssl = mssl, xwin = xwin, $
            zoom=zoom, parallelise=parallelise, winnum=winnum, $
            hot = hot, postscript=postscript, im_type=im_type

    if ~keyword_set(im_type) then im_type = 'total_b' 
    if ~keyword_set(winnum) then winnum = 0 
   
    !p.charsize = 1.0
    folder = '~/Data/elevate_db/'+date+'/SDO/AIA'
    time_stop = anytim('2014-04-18T13:10:00', /utim)  ;For the 2014-April-Event

    if keyword_set(hot) then begin
       pass_a = '094'
       pass_b = '131'
       pass_c = '335'

       file_loc_211 = folder + '/094'
       file_loc_193 = folder + '/131'
       file_loc_171 = folder + '/335'
    endif else begin
       pass_a = '211'
       pass_b = '193'
       pass_c = '171'

       file_loc_211 = folder + '/211'
       file_loc_193 = folder + '/193'
       file_loc_171 = folder + '/171'
    endelse

    fls_a = file_search( file_loc_211 +'/*.fits' )
    fls_b = file_search( file_loc_193 +'/*.fits' )
    fls_c = file_search( file_loc_171 +'/*.fits' )
  
    if n_elements(fls_a) lt 5 or n_elements(fls_b) lt 5 or n_elements(fls_c) lt 5 then goto, files_missing

    array_size = 4096
    downsize = array_size/4096.
    shrink = 2.0   ;shrink image size
    if keyword_set(zoom) then begin
    
        read_sdo, fls_a[0], i_a, /nodata, only_tags='cdelt1,cdelt2,naxis1,naxis2', /mixed_comp, /noshell   
        ;FOV = [20.0, 20.0]
        ;CENTER = [800.0, -800.0]
        FOV = [27.15, 27.15];   [10, 10]  ;[16.0, 16.0]  ;[10, 10]    ;[27.15, 27.15];
        CENTER = [500, -350];[600.0, -220] ;[500.0, -230]  ;[600.0, -220] ; [500, -350];
        
        arcs_per_pixx = i_a.cdelt1/downsize
        arcs_per_pixy = i_a.cdelt2/downsize
        naxisx = i_a.naxis1*downsize
        naxisy = i_a.naxis1*downsize

        x0 = (CENTER[0]/arcs_per_pixx + (naxisx/2.0)) - (FOV[0]*60.0/arcs_per_pixx)/2.0
        x1 = (CENTER[0]/arcs_per_pixx + (naxisx/2.0)) + (FOV[0]*60.0/arcs_per_pixx)/2.0
        y0 = (CENTER[1]/arcs_per_pixy + (naxisy/2.0)) - (FOV[1]*60.0/arcs_per_pixy)/2.0
        y1 = (CENTER[1]/arcs_per_pixy + (naxisy/2.0)) + (FOV[1]*60.0/arcs_per_pixy)/2.0 
        
        ; The following if statements prevent the zoom and center from 
        ; going outside the array area
        if x0 lt 0.0 then begin
            diff = abs(x0 - 0)
            x1 = x1 + abs(diff)
            x0 = x0 > 0.0
            CENTER[1] = CENTER[1] + diff*arcs_per_pixx
        endif   
        if x1 gt array_size then begin
            diff = abs(x1 - array_size)
            x1 = x1 < (array_size-1.)
            x0 = (x0 - diff) > 0.0
            CENTER[0] = CENTER[0] - diff*arcs_per_pixx
        endif   
        if y0 lt 0.0 then begin
            diff = abs(y0 - 0)
            y1 = y1 + abs(diff)
            y0 = y0 > 0.0
            CENTER[1] = CENTER[1] + diff*arcs_per_pixy
        endif   
        if y1 gt array_size then begin
            diff = abs(y1 - array_size)
            y1 = y1 < (array_size-1.)
            y0 = (y0 - diff) > 0.0
            CENTER[1] = CENTER[1] - diff*arcs_per_pixy
        endif   

        x_range = [x0, x1]  
        y_range = [y0, y1]    

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
        border = 200

    endif else begin
        x_range = [0,  array_size-1]
        y_range = [0,  array_size-1]
        x_size = 1024
        y_size = 1024
        border = 200
    endelse

    x_size = x_size/shrink
    y_size = y_size/shrink


    ; Check the images to make sure we're not using AEC-affected images
    min_exp_t_193 = 1.0
    min_exp_t_211 = 1.5
    min_exp_t_171 = 1.5

    read_sdo, fls_a, i_a, /nodata, only_tags='exptime,date-obs', /mixed_comp, /noshell
    f_a = fls_a[where(i_a.exptime gt min_exp_t_211)]
    t = anytim(i_a.date_d$obs)
    t_a = t[where(i_a.exptime gt min_exp_t_211)]

    read_sdo, fls_b, i_b, /nodata, only_tags='exptime,date-obs', /mixed_comp, /noshell
    f_b = fls_b[where(i_b.exptime gt min_exp_t_193)]
    t = anytim(i_b.date_d$obs)
    t_b = t[where(i_b.exptime gt min_exp_t_193)]

    read_sdo, fls_c, i_c, /nodata, only_tags='exptime,date-obs', /mixed_comp, /noshell
    f_c = fls_c[where(i_c.exptime gt min_exp_t_171)]
    t = anytim(i_c.date_d$obs)
    t_c = t[where(i_c.exptime gt min_exp_t_171)]

    t_str_a = anytim(t_a)
    t_str_b = anytim(t_b)
    t_str_c = anytim(t_c)


    ; Now identify images adjacent in time using the smallest array to get
    ; the image times
    arrs = [n_elements(f_a), n_elements(f_b), n_elements(f_c)]
    val = max(arrs, f_max, subscript_min = f_min)
    n_array = [0,1,2]


    case f_min of
      0: image_time = t_a
      1: image_time = t_b
      2: image_time = t_c
    endcase

    f_mid = n_array[where(n_array ne f_max and n_array ne f_min)]

    if f_min eq f_max then begin
         max_tim = t_str_a
         mid_tim = t_str_b
         min_tim = t_str_c
    endif else begin
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
    endelse


    ; This loop finds the closest file to min_tim[n] for each of the filters. It constructs an
    ; array of indices for each of the filters.
    for n = 0, n_elements(min_tim)-1 do begin
      sec_min = min(abs(min_tim - min_tim[n]),loc_min)
      if n eq 0 then next_min_im = loc_min else next_min_im = [next_min_im, loc_min]

      sec_max = min(abs(max_tim - min_tim[n]),loc_max)
      if n eq 0 then next_max_im = loc_max else next_max_im = [next_max_im, loc_max]

      sec_mid = min(abs(mid_tim - min_tim[n]),loc_mid)
      if n eq 0 then next_mid_im = loc_mid else next_mid_im = [next_mid_im, loc_mid]
    endfor

    if f_min eq f_max then begin
         loc_211 = next_max_im
         loc_193 = next_mid_im
         loc_171 = next_min_im
    endif else begin
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
    endelse  

    fls_211 = f_a[loc_211]
    fls_193 = f_b[loc_193]
    fls_171 = f_c[loc_171]
    
    ; Setup plotting parameters  
    if keyword_set(xwin) then begin
        loadct, 0, /silent  
        window, winnum, xs = 2.0*(x_size+border), ys = y_size+border, retain=2
        !p.multi = 0
    endif else begin     
        ;set_plot, 'z'
        ;!p.multi = 0
        ;img = fltarr(3, x_size+border, x_size+border)
        ;device, set_resolution = [x_size+border, x_size+border], set_pixel_depth=24, decomposed=0
    endelse


    dam_folder = '~/Data/2014_apr_18/radio/dam/'
    orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
    time0 = '20140418_122500'
    time1 = '20140418_132000'
    date_string = time2file(file2time(time0), /date)

    ;***********************************;
    ;       Read and process DAM        
    ;***********************************;

    restore,  dam_folder+'/NDA_'+date_string+'_1051.sav', /verb
    dam_freqs = nda_struct.freq
    daml = nda_struct.spec_left
    damr = nda_struct.spec_right
    times = nda_struct.times
    restore, dam_folder+'/NDA_'+date_string+'_1151.sav', /verb
    daml = [daml, nda_struct.spec_left]
    damr = [damr, nda_struct.spec_right]
    times = [times, nda_struct.times]
    restore, dam_folder+'/NDA_'+date_string+'_1251.sav', /verb
    daml = [daml, nda_struct.spec_left]
    damr = [damr, nda_struct.spec_right]
    times = [times, nda_struct.times]
    dam_spec = damr + daml
    dam_time = times
    dam_tim0 = anytim(file2time(time0), /time_only, /trun, /yoh)
    dam_tim1 = anytim(file2time(time1), /time_only, /trun, /yoh)
    dam_spec = alog10(dam_spec)
    dam_spec = constbacksub(dam_spec, /auto)

    ;***********************************;
    ;      Read Orfees      
    ;***********************************;   
    restore, orfees_folder+'orf_'+date_string+'_bsubbed_minimum.sav', /verb
    orf_spec = orfees_struct.spec
    orf_time = orfees_struct.time
    orf_freqs = orfees_struct.freq


    ;-------------------------------------------------;
    ;        *********************************
    ;            Image Loop starts here
    ;        *********************************
    ;-------------------------------------------------;

    first_img_index = closest(min_tim, anytim('2014-04-18T12:25:00'))
    last_img_index = closest(min_tim, anytim('2014-04-18T13:20:00'))

    lwr_lim = first_img_index     ; 161 for type III image of initial flare. 188 for type IIIs. For 2014-Apr-18 Event. 
                    ; 190 on cool AIA channels for good CME legs.
                    ; 185 for detached EUV wave
    img_num = lwr_lim
    for i = lwr_lim, last_img_index do begin    ;n_elements(fls_211)-1 do begin
      
        get_utc, start_loop_t, /cc

        IF keyword_set(parallelise) THEN BEGIN
            ;---------- Run processing of three images in parallel using IDL bridges -------------;
            pref_set, 'IDL_STARTUP', '/Users/eoincarley/idl/.idlstartup',/commit             
            oBridge1 = OBJ_NEW('IDL_IDLBridge', output='/Users/eoincarley/child1_output.txt') 
            oBridge1->EXECUTE, '@' + PREF_GET('IDL_STARTUP')   ;Necessary to define startup file because child process has no memory of ssw_path of parent process
            oBridge1->SetVar, 'fls_211', fls_211
            oBridge1->SetVar, 'fls_193', fls_193
            oBridge1->SetVar, 'fls_171', fls_171
            oBridge1->SetVar, 'i', i

            oBridge2 = OBJ_NEW('IDL_IDLBridge')
            oBridge2->EXECUTE, '@' + PREF_GET('IDL_STARTUP')
            oBridge2->SetVar, 'fls_211', fls_211
            oBridge2->SetVar, 'fls_193', fls_193
            oBridge2->SetVar, 'fls_171', fls_171
            oBridge2->SetVar, 'i', i

            oBridge3 = OBJ_NEW('IDL_IDLBridge')
            oBridge3->EXECUTE, '@' + PREF_GET('IDL_STARTUP') 
            oBridge3->SetVar, 'fls_211', fls_211
            oBridge3->SetVar, 'fls_193', fls_193
            oBridge3->SetVar, 'fls_171', fls_171
            oBridge3->SetVar, 'i', i

            oBridge1 -> Execute, 'aia_process_image, fls_211[i], fls_211[i-5], i_a, i_a_pre, iscaled_a, im_type, imsize = array_size', /nowait

            oBridge2 -> Execute, 'aia_process_image, fls_193[i], fls_193[i-5], i_b, i_b_pre, iscaled_b, im_type, imsize = array_size', /nowait

            oBridge3 -> Execute, 'aia_process_image, fls_171[i], fls_171[i-5], i_c, i_c_pre, iscaled_c, im_type, imsize = array_size', /nowait

            print, 'Waiting for child processes to finish.'
            WHILE (oBridge1->Status() EQ 1 or oBridge2->Status() EQ 1 or oBridge3->Status() EQ 1) DO BEGIN
                junk=1
            ENDWHILE

            return_struct, oBridge1, 'i_a', i_a
            return_struct, oBridge2, 'i_b', i_b
            return_struct, oBridge3, 'i_c', i_c

            iscaled_a = oBridge1->GetVar('iscaled_a')
            iscaled_b = oBridge2->GetVar('iscaled_b')
            iscaled_c = oBridge3->GetVar('iscaled_c')

        ENDIF ELSE BEGIN
            ;Simply runs processing in series, as opposed to parallel
            aia_process_image, fls_211[i], fls_211[i-5], i_a, i_a_pre, iscaled_a, im_type, imsize = array_size
            aia_process_image, fls_193[i], fls_193[i-5], i_b, i_b_pre, iscaled_b, im_type, imsize = array_size
            aia_process_image, fls_171[i], fls_171[i-5], i_c, i_c_pre, iscaled_c, im_type, imsize = array_size
        ENDELSE
     
        ; Check that the images are closely spaced in time
        if (abs(anytim(i_a.date_d$obs)-anytim(i_b.date_d$obs)) or $
            abs(anytim(i_a.date_d$obs)-anytim(i_c.date_d$obs)) or $
            abs(anytim(i_b.date_d$obs)-anytim(i_c.date_d$obs))) gt 12. then goto, skip_img

        truecolorim = [[[iscaled_a]], [[iscaled_b]], [[iscaled_c]]] ;contruct RGB image

        if keyword_set(zoom) then $
        img = congrid(truecolorim[x_range[0]:x_range[1],y_range[0]:y_range[1], *], x_size, y_size, 3) else $
           img = rebin(truecolorim, x_size, y_size, 3)

            ;expand_tv, img, x_size, y_size, border/2, border/2, true = 3;, min = -3.0, max = 3.0;, origin=img_origin, scale=img_scale, /data
            ;if keyword_set(grid) then plot_helio, i_a1[0].date_d$obs, grid=15, /over, b0=map.b0, rsun=map.rsun, l0=map.l0, gthick=thicky

        ;---------------------------;
        ;        PLOT IMAGE
        ;---------------------------;
        loadct, 0, /silent

        if keyword_set(postscript) then $
            setup_postscript, '~/Data/2014_apr_18/combos/AIA_dynspec_movie/image_'+string(img_num-lwr_lim, format='(I03)' )+'.eps', $
                2.0*(x_size+border), (y_size+border)/4.0

            plot_image, img, true=3, $
                position = [border/4, border/2, x_size/2+border/4, y_size+border/2]/(x_size+border), $
                /normal, $
                xticklen=-0.001, $
                yticklen=-0.001, $
                xtickname=[' ',' ',' ',' ',' ',' '], $
                ytickname=[' ',' ',' ',' ',' ',' ']

            ;---------------------------------------------------------------;
            ; In order to plot a heligraphic grid. Overplot an empty dummy 
            ; map of the same size then use plot_helio aia_prep, fls_211[i],
            ; -1, i_0, d_0, /uncomp_delete, /norm
            read_sdo, fls_211[i], i_0, d_0, outsize=1024
            index2map, i_0, d_0, map0
            data = map0.data 
            data = data < 50.0   ; Just to make sure the map contours of the dummy map don't sow up.
            map0.data = data
            levels = [100,100,100]


            set_line_color
            plot_map, map0, $
                /cont, $
                levels=levels, $
                ; /noxticks, $
                ; /noyticks, $
                ; /noaxes, $
                thick=2.5, $
                color=0, $
                position = [border/4, border/2, x_size/2+border/4, y_size+border/2]/(x_size+border), $ 
                /normal, $
                /noerase, $
                /notitle, $
                xticklen=-0.02, $
                yticklen=-0.02, $
                fov = FOV,$
                center = CENTER         

            plot_helio, i_0.date_obs, $
                 /over, $
                 gstyle=0, $
                 gthick=2.5, $  
                 gcolor=255, $
                 grid_spacing=15.0 

            oplot_nrh_on_three_color_for_movie, i_c.date_obs      ;For the 2014-April-Event

            stamp_date, i_a, i_b, i_c

            dam_orfees_plot_for_movie, orf_spec, orf_time, orf_freqs, $
                                       dam_spec, dam_time, dam_freqs, $
                                       time_marker=anytim(i_c.date_obs, /utim)

        if keyword_set(postscript) then begin
            device, /close
            set_plot, 'x'
        endif 
        spawn, 'cp ~/Data/2014_apr_18/combos/AIA_dynspec_movie/image_'+string(img_num-lwr_lim, format='(I03)' )+'.eps ~/Data/2014_apr_18/combos/AIA_dynspec_movie/image_'+string(img_num-lwr_lim+1.0, format='(I03)' )+'.eps '    
    
        cd, folder  ;change back to aia folder
        
        if keyword_set(xwin) then x2png, folder + '/image_'+string(img_num-lwr_lim, format='(I03)' )+'.png'
  
        if keyword_set(zbuffer) then begin
            img = tvrd(/true)
            ;  write_png, 'SDO_3col_plain_'+time2file(i_a.t_obs, /sec)+'.png', img
            ;  image_loc_name = folder + '/image_'+string(i-lwr_lim, format='(I03)' )+'.png' 
            cd, '~
            write_png, image_loc_name , img
        endif
        print, img_num
        img_num = img_num + 2

        ; If images too far apart in time then go to here.
        skip_img: print, 'Images too far spaced in time.'

        get_utc, end_loop_t, /cc
        loop_time = anytim(end_loop_t, /utim) - anytim(start_loop_t, /utim)
        print,'-------------------'
        print,'Currently '+string(loop_time, format='(I04)')+' seconds per 3 color image.'
        print,'-------------------'
    
        ;if anytim(i_a.date_obs, /utim) gt time_stop then BREAK  ;For the 2014-April-Event
    endfor

    ;date = time2file(i_a.t_obs, /date_only) 
    ;type0 = 'ratio' ;else type0 = 'totB'
    ;if keyword_set(hot) then chans = 'hot' else chans = 'cool'
    ;movie_type = '3col_'+type0+'_'+chans ;else movie_type = '3col_ratio' cd, folder
    ;print, folder 
    ;spawn, 'ffmpeg -y -r 25 -i image_%03d.png -vb 50M AIA_'+date+'_'+movie_type+'.mpg'

    ;spawn, 'cp AIA_'+date+'_'+movie_type+'.mpg ~/Dropbox/sdo_movies/'
    ;spawn, 'cp image_000.png ~/Dropbox/sdo_movies/'
    ;spawn, 'rm -f image*.png'

    files_missing: print,'Files missing for : '+date

END