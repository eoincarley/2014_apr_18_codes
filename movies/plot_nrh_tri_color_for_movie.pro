pro setup_ps, name;, xsize, ysize

    set_plot,'ps'
    !p.font=0
    !p.charsize=1.0
    device, filename = name, $
          ;/decomposed, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=14, $ ;xsize/100, $
          ysize=7, $ ;xsize/100, $
          /encapsulate, $
          bits_per_pixel=32

end

pro stamp_date_nrh, nrh0, nrh1, nrh2, xpos
   
   set_line_color
   !p.charsize = 1.2

   xyouts, xpos-0.0001, 0.84, 'NRH '+string(nrh0.freq, format='(I03)') +' MHz '+anytim(nrh0.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 1
   xyouts, xpos+0.0001, 0.84, 'NRH '+string(nrh0.freq, format='(I03)') +' MHz '+anytim(nrh0.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 1
   xyouts, xpos, 0.84, 'NRH '+string(nrh0.freq, format='(I03)') +' MHz '+anytim(nrh0.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 3
  
   xyouts, xpos-0.0001, 0.81, 'NRH '+string(nrh1.freq, format='(I03)') +' MHz '+anytim(nrh1.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 1
   xyouts, xpos+0.0001, 0.81, 'NRH '+string(nrh1.freq, format='(I03)') +' MHz '+anytim(nrh1.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 1
   xyouts, xpos, 0.81, 'NRH '+string(nrh1.freq, format='(I03)') +' MHz '+anytim(nrh1.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 4

   xyouts, xpos-0.0001, 0.78, 'NRH '+string(nrh2.freq, format='(I03)') +' MHz '+anytim(nrh2.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 1    
   xyouts, xpos+0.0001, 0.78, 'NRH '+string(nrh2.freq, format='(I03)') +' MHz '+anytim(nrh2.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 1
   xyouts, xpos, 0.78, 'NRH '+string(nrh2.freq, format='(I03)') +' MHz '+anytim(nrh2.date_obs, /cc, /trun)+ ' UT', alignment=0, /normal, color = 10

END

pro plot_nrh_tri_color_for_movie, time, freqs, x_size, y_size, $
         hdr_freqs = hdr_freqs

        ; plot_nrh_tri_color_for_movie, '2014-04-18T12:57:57', [0,1,1], 512, 512     

        border=273.                      ; (700./512.)*200. Had to make the border different than the AIA plot. Takes into account window size, image size
        t0 = anytim(time, /utim) - 2.0   ; -2 to match images in paper.
        t0str = anytim(t0, /yoh, /trun, /time_only) 

        cd, '~/Data/2014_apr_18/radio/nrh/clean_wresid/'
        filenames = findfile('*.fts')

        read_nrh, filenames[freqs[0]], $
        nrh_hdr0, $
        nrh_data0, $
        hbeg=t0str

        read_nrh, filenames[freqs[1]], $
        nrh_hdr1, $
        nrh_data1, $
        hbeg=t0str

        read_nrh, filenames[freqs[2]], $
        nrh_hdr2, $
        nrh_data2, $
        hbeg=t0str

        max_value0 = max(nrh_data0)
        max_value1 = max(nrh_data1)
        max_value2 = max(nrh_data2)
        max_value = max([nrh_data0, nrh_data1, nrh_data2])

        nrh_data0 = nrh_data0 > max_value*0.1 < max_value*0.7
        nrh_data1 = nrh_data1 > max_value*0.1 < max_value*0.7
        nrh_data2 = nrh_data2 > max_value*0.1 < max_value*0.7 

        image_half = (nrh_hdr0.naxis1/2.0)*nrh_hdr0.cdelt1 
        CENTER = [0, 0] 
        xcen = (CENTER[0]+image_half)/nrh_hdr0.cdelt1  ;nrh_hdr0.crpix1
        ycen = (CENTER[1]+image_half) /nrh_hdr0.cdelt2   ;nrh_hdr0.crpix2

        truecolorim = [[[nrh_data0]], [[nrh_data1]], [[nrh_data2]]]

        ; 31 pixels per radius. Want to have FOV as 1.3 Rsun (same as AIA). So ~31*1.3 = 40.3
        ; Have 40.3 pixels on either side of image center to have FOV of 1.3 Rsun. 


        rsun_fov = 1.3     ;10 arcmin fov
        pix_fov = nrh_hdr0.solar_r*rsun_fov
        map_fov = ( (2.0*rsun_fov*nrh_hdr0.solar_r)*nrh_hdr0.cdelt1 )/60.0
        print, map_fov

        truecolorim_zoom = [[[nrh_data0[xcen-pix_fov:xcen+pix_fov, ycen-pix_fov:ycen+pix_fov]]], $
                            [[nrh_data1[xcen-pix_fov:xcen+pix_fov, ycen-pix_fov:ycen+pix_fov]]], $
                            [[nrh_data2[xcen-pix_fov:xcen+pix_fov, ycen-pix_fov:ycen+pix_fov]]]]

        img_origin = [-1.0*x_size/2, -1.0*y_size/2]

        img = congrid(truecolorim, x_size, y_size, 3)
        im_zoom = congrid(truecolorim_zoom, x_size, y_size, 3)

        hdr_freqs = [nrh_hdr0.freq, nrh_hdr1.freq, nrh_hdr2.freq]
        hdr_freqs = string(hdr_freqs, format='(I03)')

        ;setup_ps, '~/test.eps';, x_size+border, y_size+border ;'+string(i - start_index, format='(I03)' )+'.eps', x_size+border, y_size+border
        loadct, 0, /silent
        xshift = 20.
        plot_image, img, true=3, $
            position = [x_size+border/4.-xshift, border/2., 2.0*x_size-border/4.-xshift, 2.0*y_size-border/2.0]/(2.0*x_size), $
            /normal, $
            /noerase, $
            xticklen=-0.001, $
            yticklen=-0.001, $
            xtickname=[' ',' ',' ',' ',' ',' ',' '], $
            ytickname=[' ',' ',' ',' ',' ',' ',' ']

          
        index2map, nrh_hdr0, nrh_data0, map0
        data = map0.data 
        data = data < 50.0   ; Juse to make sure the map contours of the dummy map don't sow up.
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
            position = [x_size+border/4.-xshift, border/2., 2.0*x_size-border/4.-xshift, 2.0*y_size-border/2.]/(2.0*x_size), $ 
            /normal, $
            /noerase, $
            /notitle, $
            xticklen=-0.02, $
            yticklen=-0.02, $
            fov = [map_fov, map_fov], $
            center = CENTER         

        plot_helio, nrh_hdr0.date_obs, $
            /over, $
            gstyle=1, $
            gthick=5.5, $  
            gcolor=255, $
            grid_spacing=15.0 

        xpos_labels = (x_size+border/4-xshift)/(2.0*x_size)+0.005
        stamp_date_nrh, nrh_hdr0, nrh_hdr1, nrh_hdr2, xpos_labels

        min_tb = string(round(alog10(max_value*0.2)*10.0)/10.0, format='(f3.1)')
        max_tb = string(round(alog10(max_value*0.7)*10.0)/10.0, format='(f3.1)')
        xyouts, xpos_labels, 0.15, min_tb+' < log!L10!N(T!LB!N [K]) < '+max_tb, /normal, color=1

        date = time2file(t0, /date_only)
        freq_string = string(nrh_hdr0.freq, format='(I03)') + '_'+ string(nrh_hdr1.freq, format='(I03)') + '_' +string(nrh_hdr2.freq, format='(I03)')

       ; device, /close
       ; set_plot, 'x'

END