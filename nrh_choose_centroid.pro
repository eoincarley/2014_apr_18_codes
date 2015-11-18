function my2Dgauss, x, y, pars

	;This is for use in mpfit2dfun below

	z = dblarr(n_elements(x),n_elements(y))

	FOR i = 0, n_elements(x)-1.0 DO BEGIN
		FOR j=0, n_elements(y)-1.0 DO BEGIN
			T = pars[6]
			xp = (x[i]-pars[4])*cos(T) - (y[j]-pars[5])*sin(T)
			yp = (x[i]-pars[4])*sin(T) - (y[j]-pars[5])*cos(T)
			U = (xp/pars[2])^2.0 + (yp/pars[3])^2.0
			z[i,j] = pars[0] + pars[1]*exp(-U/2.0)
		ENDFOR
	ENDFOR	

	return,z

END

pro nrh_choose_centroid

	;Code to produce pngs of NRH observations of the 2014 April 18 event 
	;Produces pngs for all frequencies
	;Written 2014-Oct-2

	cd, '~/Data/2014_apr_18/radio/nrh'
	filenames = findfile('*.fts')

	window, 0, xs=700, ys=700, retain=2
	window, 1, xs=700, ys=700, retain=2
	!p.charsize=1.5
	

	tstart = anytim(file2time('20140418_125310'), /utim)
	tstop = anytim(file2time('20140418_125440'), /utim) 
	i=0

	while tstart lt tstop do begin

		t0str = anytim(tstart, /yoh, /trun, /time_only)

		read_nrh, filenames[2], $
				  nrh_hdr, $
				  nrh_data, $
				  hbeg=t0str;, $ 
				  ;hend=t1str
				
		index2map, nrh_hdr, nrh_data, $
				   nrh_map  
				
		nrh_str_hdr = nrh_hdr
		nrh_times = nrh_hdr.date_obs
				
		;------------------------------------;
		;			Plot Total I
		freq = nrh_hdr.FREQ
		loadct, 3, /silent
		wset, 0
		FOV = [15, 15]
		CENTER = [700, -100]
		plot_map, nrh_map, $
			fov = FOV, $
			center = CENTER, $
			dmin = 1e5, $
			dmax = 1e8, $
			title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
			string( anytim( nrh_times, /yoh, /trun) )+' UT'
			  
		
		plot_helio, nrh_times, $
					/over, $
					gstyle=1, $
					gthick=1.0, $
					gcolor=1, $
					grid_spacing=15.0

		max_val = max( (nrh_data) ,/nan) 									   
		nlevels=5.0   
		top_percent = 0.50
		levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
				+ max_val*top_percent  

		set_line_color
		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=1, $
			color=5		

	
		;------------------------------------;
		;	  Now plot raw data structure	 ;
		;
		wset, 1
		x0 = (CENTER[0]/nrh_hdr.cdelt1 + (nrh_hdr.naxis1/2.0)) - (FOV[0]*60.0/nrh_hdr.cdelt1)/2.0
        x1 = (CENTER[0]/nrh_hdr.cdelt1 + (nrh_hdr.naxis1/2.0)) + (FOV[0]*60.0/nrh_hdr.cdelt1)/2.0
        y0 = (CENTER[1]/nrh_hdr.cdelt2 + (nrh_hdr.naxis2/2.0)) - (FOV[1]*60.0/nrh_hdr.cdelt2)/2.0
        y1 = (CENTER[1]/nrh_hdr.cdelt2 + (nrh_hdr.naxis2/2.0)) + (FOV[1]*60.0/nrh_hdr.cdelt2)/2.0
		nrh_data = nrh_map.data
		data_section = nrh_data[x0:x1, y0:y1]

		loadct, 3, /silent
		plot_image, data_section > 1e5 <1e8


		;-------------------------------;
		;	   Choose data points	    ;
		;								;
		cursor, source_x, source_y, /data
		source_x = (source_x)
		source_y = (source_y)
	
		x0zoom = (source_x-3 > 0)
		x1zoom = (source_x+3)
		y0zoom = (source_y-3 > 0)
		y1zoom = (source_y+3)

		source_section = data_section[x0zoom:x1zoom, y0zoom:y1zoom]

		
		x_len = (size(source_section))[1]
		y_len = (size(source_section))[2]
		junk_array = dblarr(x_len+50, y_len+50) ;Mode is good estimate of quiet thermal
		junk_array[*] = 4
		junk_array[25:25+x_len-1, 25:25+y_len-1] = alog10(source_section)
		
		;---------------------------------------;
		;			  FIT 2D Gauss 
		;
		result = gauss2dfit(junk_array, a, /tilt)

		;Since gauss2dfit doens't give errors, use a as start values
		;for mpfit2dfun (which provides ucnertainties).
		start_parms = a
		xjunk = dindgen( n_elements(junk_array[*,0]) )
		yjunk = dindgen( n_elements(junk_array[0,*]) )
		result_pars = MPFIT2DFUN('my2Dgauss', xjunk, yjunk, junk_array, ERR, $
			start_parms, perror=perror, yfit=yfit)
		window, 3, xs=500, ys=500
		shade_surf, yfit, charsize=3.0
		result = yfit	

		max_x = result_pars[4] - 25.
		max_y = result_pars[5] - 25.
		
		if result_pars[4] eq 1.0 then begin
			;wset, 3
			
			source_max_x = x0 + source_x
			source_max_y = y0 + source_y
			;index_max = where(source_section eq max(source_section))
			;max_x = (array_indices(source_section, index_max))[0] 
			;max_y = (array_indices(source_section, index_max))[1]
		endif else begin
			;------------------------------
			;------------------------------
			;------------------------------

			source_max_x = x0 + x0zoom + max_x 
			source_max_y = y0 + y0zoom + max_y 
		endelse

		source_max_x = (source_max_x - (nrh_hdr.crpix1-0.5))*nrh_hdr.cdelt1	;0.5 for closer to pixel center
		source_max_y = (source_max_y - (nrh_hdr.crpix2-0.5))*nrh_hdr.cdelt2

		print, source_max_x
		print, source_max_y
	
		
		wset, 0
		plot_map, nrh_map, $
			fov = FOV, $
			center = CENTER, $
			dmin = 1e5, $
			dmax = 3e8, $
			title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
			string( anytim( nrh_times, /yoh, /trun) )+' UT'

		set_line_color
		plots, source_max_x, source_max_y, psym=1, color=5, /data
	
		;wait, 0.5
		
		if i eq 0 then begin
			xarcs = source_max_x
			yarcs = source_max_y
			times = nrh_times
		endif else begin
			xarcs = [xarcs, source_max_x]
			yarcs = [yarcs, source_max_y]
			times = [times, nrh_times]
		endelse	
					
		tstart = tstart + 1.0
		i=i+1
	endwhile				

	wset, 0
	loadct, 3, /silent
	FOV = [7, 7]
	CENTER = [800, -200]
	plot_map, nrh_map, $
		fov = FOV, $
		center = CENTER, $
		dmin = 1e5, $
		dmax = 3e8, $
		title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
		string( anytim( nrh_times, /yoh, /trun) )+' UT'

	loadct, 39
	colors = findgen(n_elements(xarcs))*(255)/(n_elements(xarcs)-1)

	for i=0, n_elements(xarcs)-1 do plots, xarcs[i], yarcs[i], psym=1, color=150;colors[i]

	freq_string = string(nrh_hdr.freq, format='(I03)')
	xy_arcs_struct = {name:'xy_src_motion', xarcs:xarcs, yarcs:yarcs, times:times, freq:nrh_hdr.freq}
	save, xy_arcs_struct, filename='nrh_'+freq_string+'_src_xy_motion.sav', $
			description = 'xy coords in arc seconds'
		
			stop
END