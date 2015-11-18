pro aia_c2_nrh_20140418

  ; Code to combine AIA, NRH and C2 observations of eruptive event on 2014-Apr-18
  
    winsz=700
    !p.charsize=1.5
    loadct, 57
    window, 0, xs=winsz, ys=winsz

    ;--------------------------------------;
    ;----------------C2 Data---------------;
    ;--------------------------------------;
    cd,'~/Data/2014_Apr_18/white_light/lasco/c2/l1/'
    c2_files = findfile('*.fts')

    c2index=1
    pre = lasco_readfits(c2_files[c2index], c2hdr_pre)
    mask = lasco_get_mask(c2hdr_pre)
    pre = pre*mask

    img = lasco_readfits(c2_files[c2index+1], c2hdr)
    img = img*mask

    imgbs = img - pre
    imgbs = (imgbs- mean(imgbs))/stdev(imgbs)

    ;img_filt = disk_nrgf(img, c2hdr, 0, 0)
    ;pre_filt = disk_nrgf(pre, c2hdr_pre, 0, 0) 
    ;imgbs = img_filt - pre_filt

    c2map = make_map(imgbs)
    c2map.dx = 11.9
    c2map.dy = 11.9
    c2map.xc = 14.4704
    c2map.yc = 61.2137

    FOV = [5000/60.0, 5000/60.0]
    CENTER = [1000.0, -1000.0]

    ;plot_map, c2map, $
    ;		dmin = -5.0, $
    ;		dmax = 5.0, $
    ;	title='AIA NRGF, LASCO BASE DIFF', $
    ;	fov=FOV, $s
    ;	center = CENTER

    ;--------------------------------------;
    ;--------------SWAP Data---------------;
    ;--------------------------------------;   
    ;window, 1 
    cd,'~/Data/2014_Apr_18/swap/'
    swap_files = findfile('*.fits')
    mreadfits_header, swap_files, ind
    swap_times = anytim(ind.date_obs, /utim)
    index = closest(swap_times, anytim(c2hdr.date_obs, /utim))
    

    mreadfits, swap_files[index-1], hdr_pre, data_pre
    mreadfits, swap_files[index], hdr, data
    ;stop
    data = disk_nrgf_swap(data, hdr, 0, 0)
    ;data = data - data_pre
    ;data = (data - mean(data))/stdev(data)
    index2map, hdr, data, swap_map

   ; plot_map, swap_map, $            ;diff_map(map_aia, map_aia_pre), $
        ;/composite, $
        ;/average, $
      ;  dmin = -3, $
    ;    dmax = 5, $
     ;   /noaxes
    map_new = merge_map(c2map, swap_map, /add, use_min=0)


    tstart = anytim('2014-04-18T13:11:35', /utim)
    for i=0, 180 do begin
        tstart = tstart+i
        plot_map, map_new, $
            dmin = -3, $
            dmax = 3, $
            fov=FOV, $
            center = CENTER

        ;--------------------------------------;
        ;---------------AIA Data---------------;
        ;--------------------------------------;
        ;cd,'~/Data/2014_Apr_18/sdo/171A/'
        ;aia_files = findfile('aia*.fits')
        ;mreadfits_header, aia_files, ind, only_tags='exptime'
        ;f = aia_files[where(ind.exptime gt 1.)]
        ;mreadfits_header, f, ind
        ;aia_times = anytim(ind.date_obs, /utim)

        ;index = closest(aia_times, anytim(c2hdr.date_obs, /utim))

        ;read_sdo, f[index-5], $
       ; 	hdr_aia_pre, $
        ;	data_aia_pre
        ;read_sdo, f[index], $
       ; 	hdr_aia, $
       ; 	data_aia
       ; index2map, hdr_aia_pre, $
       ; 	smooth(data_aia_pre, 1)/hdr_aia_pre.exptime, $
       ; 	map_aia_pre, $
       ; 	outsize = 1024
       ; index2map, hdr_aia, $
       ; 	smooth(data_aia, 1)/hdr_aia.exptime, $
       ; 	map_aia, $
       ; 	outsize = 1024		

        ; To Carolina. The following few lines re-define the arcseconds per pixel etc. because
        ; I have reduced AIA image size from 4096 to 1024 (see index2map outsize above). this is the
        ; only tricky part e.g., if re-sizing image arrays, make sure the cdelt and crpix in the mreadfits_header
        ; file is still correct.
          	
        ;redu_factor = hdr_aia.naxis1/(size(map_aia.data))[1]*1d
        ;hdr_aia.naxis1 = (size(map_aia.data))[1]
        ;hdr_aia.naxis2 = (size(map_aia.data))[1]
        ;hdr_aia.cdelt1 = hdr_aia.cdelt1*redu_factor
        ;hdr_aia.cdelt2 = hdr_aia.cdelt2*redu_factor
        ;hdr_aia.crpix1 = hdr_aia.crpix1/redu_factor
        ;hdr_aia.crpix2 = hdr_aia.crpix2/redu_factor
    ;
        ;map_aia_pre.data = disk_nrgf(map_aia_pre.data, he_aia_pre, 0, 0)
     ;   map_aia.data = disk_nrgf(map_aia.data, hdr_aia, 0, 0)
        ;				  Plot diff image	

        ;plot_map, map_aia, $ 			;diff_map(map_aia, map_aia_pre), $
    	;	/composite, $
    	;	/average, $
        ;	dmin = -1.5, $
        ;	dmax = 2.0, $
        ;	/noaxes
        	
        ;set_line_color


        plot_helio, hdr.date_obs, $
        		/over, $
        		gstyle=0, $
        		gthick=1, $
        		gcolor=1, $
        		grid_spacing=15

        oplot_nrh_on_three_color, tstart

        wait, 5
        stop
     endfor      		
        ;--------------------------------------;
        ;---------------NRH Data---------------;
        ;--------------------------------------;		
        cd,'~/Data/2014_Apr_18/radio/nrh/'
        tstart = anytim(hdr_aia.date_obs, /utim) - 2.0*60.0 
        tend = anytim(hdr_aia.date_obs, /utim)  + 2.0*60.0 
        t0 = anytim(tstart, /yoh, /trun, /time_only)
        t1   = anytim(tend, /yoh, /trun, /time_only)

        nrh_filenames = findfile('*.fts')
        read_nrh, nrh_filenames[n_elements(nrh_filenames)-2], $	; 445 MHz
        		nrh_hdr, $
        		nrh_data, $
        		hbeg=t0, $ 
        		hend=t1	
        				
    	
        index2map, nrh_hdr, nrh_data, $
        		 nrh_map  

        nrh_data = alog10(nrh_data)
        nrh_map.data = nrh_data
        	
        ;			Find closest NRH image to AIA		
        nrh_str_hdr = nrh_hdr
        nrh_times = nrh_hdr.date_obs
        nrh_index = closest( anytim(nrh_times, /utim), anytim(hdr_aia.date_obs, /utim) )

        ;     Now over plot the contours.	 
        nrh_map.data = nrh_data
        ;			Define contour levels
        max_val = max( (nrh_data[*, *, nrh_index]) ,/nan) 									   
        nlevels=5.0   
        top_percent = 0.95
        levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
        		+ max_val*top_percent  

        ;			Overlay NRH contours
        set_line_color
        plot_map, nrh_map[nrh_index], $
        		/overlay, $
        		/cont, $
        		levels=levels, $
        		/noxticks, $
        		/noyticks, $
        		/noaxes, $
        		thick=1.0, $
        		color=4		
         

    freq_tag = string(nrh_hdr[0].freq, format='(I03)')
    wave_tag = string(hdr_aia.WAVELNTH, format='(I03)')
    xyouts, 0.15, 0.90, 'NRH '+freq_tag+' MHz:  '+nrh_hdr[nrh_index].date_obs +' UT', /normal
    xyouts, 0.15, 0.93, 'AIA '+wave_tag+'A:  '+ hdr_aia.date_obs +' UT', /normal
    xyouts, 0.15, 0.96, 'LASCO C2:  '+ c2hdr.date_obs +' UT', /normal
    stop
END