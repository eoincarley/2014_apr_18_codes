pro cme_kins_20140418, choose_points=choose_points



    if keyword_set(choose_points) then begin

	    winsz=1000
	    !p.charsize=1.5
	    loadct, 70
	    window, 0, xs=winsz, ys=winsz
	    c2_folder = '~/Data/2014_Apr_18/white_light/lasco/c2/l1/'
	    c3_folder = '~/Data/2014_Apr_18/white_light/lasco/c3/l1/'
	    c2_files = findfile(c2_folder+'*.fts')
	    mreadfits_header, c2_files, ind
	    c2_times = anytim(ind.date_obs, /utim)
	 
	    c3_files = findfile(c3_folder+'*.fts')
	    mreadfits_header, c3_files, ind
	    c3_times = anytim(ind.date_obs, /utim)


	    for i=2, 7 do begin

	    	;---------------------------------------;
		    ;				 C2 Data				;
		    ;---------------------------------------;
		    c2img = lasco_readfits(c2_files[i], c2hdr)
		    c2mask = lasco_get_mask(c2hdr)
		    ;c2img = c2img*mask

		    c2pre = lasco_readfits(c2_files[i-1], c2hdr_pre)
		   ; c2pre = c2pre*mask

		    c2img = c2img - c2pre
		    c2img = disk_nrgf(c2img, c2hdr, 0, 0)
		    c2img = (c2img - mean(c2img))/stdev(c2img)
		    index2map, c2hdr, temporary(c2img), c2map

		    ;---------------------------------------;
		    ;				 C3 Data				;
		    ;---------------------------------------;
			c3index = closest(c3_times, c2_times[i])
		    c3img = lasco_readfits(c3_files[c3index], c3hdr)
		   	c3mask = lasco_get_mask(c3hdr)
		    ;c3img = c3img*mask

		    c3pre = lasco_readfits(c3_files[c3index-1], c3hdr_pre)
		    ;c3pre = c3pre*mask


		    c3img = c3img - c3pre
		    c3img = disk_nrgf(c3img, c3hdr, 0, 0)
		    c3img = 3.0*( (c3img - mean(c3img))/stdev(c3img) )	; Factor of 2.5 is to engance C3 values so they are comparable to C2.
		    index2map, c3hdr, c3img, c3map

		   	;hfreq = imgbs - smooth(imgbs, 5)
		    ;imgbs = imgbs + 5.0*hfreq
		    ;img_filt = disk_nrgf(img, c2hdr, 0, 0)
		    ;pre_filt = disk_nrgf(pre, c2hdr_pre, 0, 0) 
		    ;imgbs = img_filt - pre_filt

		    print, 'Merging C2 ' + c2hdr.date_obs + ' and C3 ' + c3hdr.date_obs

		    c2map.data = c2map.data*c2mask
		    c3map.data = c3map.data*c3mask

		    c2c3map = merge_map(temporary(c2map), temporary(c3map), /add, use_min=0)


		    FOV = [2e4/60.0, 2e4/60.0]
		    CENTER = [0, 0]

		    plot_map, c2c3map, $
				dmin = -1, $
				dmax = 2, $
		    ;	title='AIA NRGF, LASCO BASE DIFF', $
		    	fov=FOV, $
		    	center = CENTER

		    plot_helio, c2hdr.date_obs, $
				/over, $
				gstyle=0, $
				gthick=1, $
				gcolor=1, $
				grid_spacing=15	


			;---------------------------------------;
		    ;		NOW CHOOSE FRONT POINTS			;
		    ;---------------------------------------;
			angles = (findgen(5)*(320-280.0)/4.)+280.0 ;angles[j]
			radius = 1e4
			npoints = 100.0
			fnpoints = findgen(npoints)
			axis1_sz = (size(c2c3map.data))[1]/2.0	
			axis2_sz = (size(c2c3map.data))[2]/2.0
			x1 = 0.0
			y1 = 0.0
			for j=0, n_elements(angles)-1 do begin
				x2 = x1 + radius*cos(angles[j]*!dtor)	;808.0	
				y2 = y1 + radius*sin(angles[j]*!dtor)	;-120.0
				xlin = ( fnpoints*(x2 - x1)/(npoints-1) ) + x1
				ylin = ( fnpoints*(y2 - y1)/(npoints-1) ) + y1
				plots, xlin, ylin, /data, color=3, thick=1.5
			endfor

			wait, 0.1
			print, 'Choose front: '
			point, xarc, yarc, /data

			rads = sqrt([xarc]^2.0 + [yarc]^2.0)/c2hdr.rsun	

			rad = mean(rads)
			if i eq 2 then begin
				times = anytim(c2hdr.date_obs, /utim)
				front_rsun = rad
			endif else begin
				times = [times, anytim(c2hdr.date_obs, /utim)]
				front_rsun = [front_rsun, rad]
			endelse

		endfor	
		cme_rads_struct = {name:'cme_rads', times:times, front_rsun:front_rsun}
		save, cme_rads_struct, filename='~/Data/2014_Apr_18/white_light/lasco/cme_rads_struct.sav'
    
    endif else begin
    	restore, '~/Data/2014_Apr_18/white_light/lasco/cme_rads_struct.sav', /verb
    	times = cme_rads_struct.times
    	front_rsun = cme_rads_struct.front_rsun
   		
   		loadct, 0
   		window, 1, xs=700, ys=700
    endelse
    	

	utplot, times, front_rsun, $
		psym=4, $
		yr=[2.5, 10.5], $
		/ys, $
		ytitle='CME heliocentric distance (Rsun)'

	;-------------------------;
	;		Linear fit        ;
	tims_sec = anytim(times, /utim) - anytim(times[0], /utim)		
	result = linfit(tims_sec, front_rsun, yfit=yfit)	
	oplot, times, yfit
	speed = result[1]*6.695e5
	print, 'Speed from linear fit: ' +string(speed)+ ' km/s'

	;-------------------------;
	;	   Quadratic fit      ;
	err = front_rsun
	err[*] = findgen(n_elements(err))*(0.5 -0.1)/(n_elements(err)-1) + 0.1
	start = [1.0, result[1], 0]
	fit = 'p[0]*x^2 + p[1]*x + p[2]'			
	p = mpfitexpr(fit, tims_sec, front_rsun, err, perror=perror, yfit=yfit, start);, parinfo=q)
	outplot, times, yfit, linestyle=1
	speed2 = p[1]*6.695e5
	accel = p[0]*6.695e5
	print, 'Initial speed from quadratic fit: ' +string(speed2)+ ' '+string(perror[1]*6.695e5)+' km/s'
	print, 'Acceleration from quadratic fit: ' +string(accel*1e3)+ ' m/s'


    STOP

END