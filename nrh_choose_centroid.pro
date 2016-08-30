function my2Dgauss, x, y, pars

	;This is for use in mpfit2dfun below
	;result_pars = MPFIT2DFUN('my2Dgauss', xjunk, yjunk, junk_array, ERR, $
	;		start_parms, perror=perror, yfit=yfit)

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

pro calculate_flux, source_section, freq, $
					flux, max_tb
	

	Ray = 32.0								; Solar_R in nrh_hdr_array
	domega = FLOAT(16 * 3E-4 /Ray)^2. 		; Solid angle. Below is a summation of pixels of Tb, which is effectively and integral
											; of Tbx1unit pixels. We need an integral of TbxDomega. So after the summation of Tb
											; we multiply by a factor of solid angle per pixel. 16 here is degrees of solar radius.
											; 32 is number of pixels per radius. 3e-14 comes from (1/60)x(pi/180), conversion of degrees
											; then to radians.
	c = 299792458. 			;speed of light in m/s
	k_B = 0.138				;Boltzmann constant k=1.38e-23, for SFU: K*e+22

	loadct, 25, /silent
	wset, 5
	plot_image, source_section > 1e5

	; Find the max point and mark with a diamond
	index_max = where(source_section eq max(source_section))
	xy_max = array_indices(source_section, index_max)
	plots, xy_max[0, *], xy_max[1, *], /data, psym=4, color=4
	max_tb = source_section[index_max]

	; Find points above 0.4 of max and mark with cross.
	indices = where(source_section ge max(source_section)*0.4)
	if n_elements(indices) eq 1 then indices=0
	xy_indices = array_indices(source_section, indices)

	set_line_color
	plots, xy_indices[0, *], xy_indices[1, *], /data, psym=1, color=5

	total_Tb = TOTAL(source_section[indices])		;summing over specified source are					
	lambda = c / freq
	constant = (2.* k_B * domega) / (lambda^2.)
	flux = constant * total_Tb	; in SFU
STOP

END

pro nrh_choose_centroid

	; Code to firstly choose the source. A 2D Gaussian is then fit to the source, the 
	; paramaters of which are saved. The source flux and brighness temperature are also
	; saved.

	folder = '~/Data/2014_sep_01/radio/nrh/clean_wresid' 
	cd, folder
	filenames = findfile('*.fts')

	winsize=600
	window, 0, xs=winsize, ys=winsize, retain=2
	window, 1, xs=winsize, ys=winsize, retain=2
	winsize=500
	window, 2, xs=winsize, ys=winsize, xpos = 100, ypos=100, retain=2
	window, 3, xs=winsize, ys=winsize, xpos = 600, ypos=100, retain=2
	window, 4, xs=winsize, ys=winsize, xpos = 1100, ypos=100, retain=2
	window, 5, xs=winsize, ys=winsize, xpos = 1100, ypos=600, retain=2
	!p.charsize=1.5
	
	tstart = anytim(file2time('20140901_110015'), /utim)	;anytim(file2time('20140418_125000'), /utim)	;anytim(file2time('20140418_125546'), /utim)	;anytim(file2time('20140418_125310'), /utim)
	tstop =  anytim(file2time('20140901_110600'), /utim)    ;anytim(file2time('20740418_125440'), /utim)	;anytim(file2time('20140418_125650'), /utim)		;anytim(file2time('20140418_125440'), /utim) 
	FOV = [25, 25]
	CENTER = [-1000, 650]
	nlevels=5.0   
	top_percent = 0.50

	i=0
	while tstart lt tstop do begin

		t0str = anytim(tstart, /yoh, /trun, /time_only)

		read_nrh, filenames[0], $
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
		plot_map, nrh_map, $
			fov = FOV, $
			center = CENTER, $
			dmin = 1e5, $
			dmax = 1e8, $
			title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
			string( anytim( nrh_times, /yoh, /trun) )+' UT'
			  
		set_line_color
		plot_helio, nrh_times, $
			/over, $
			gstyle=1, $
			gthick=1.0, $
			gcolor=4, $
			grid_spacing=15.0

		max_val = max( (nrh_data) ,/nan) 									   
		levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
				+ max_val*top_percent  

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

		loadct, 25, /silent
		plot_image, data_section > 1e4 <1e9, title='Raw data, pixel numbers.'


		;-------------------------------;
		;	   Choose data points	    ;
		;								;
		print, 'Choose approximate source centroid.'
		;if i eq 0 then begin   ; Implent this if statement if source is stationary and easy to track automatically
			cursor, source_x, source_y, /data
		;endif else begin	
		;	source_x = source_max_x
		;	source_y = source_max_x
		;endelse 
		
		zoom_sz = 15
		x0zoom = (source_x-zoom_sz > 0 < ((size(data_section))[1]-1) )
		x1zoom = (source_x+zoom_sz > 0 < ((size(data_section))[1]-1) )
		y0zoom = (source_y-zoom_sz > 0 < ((size(data_section))[2]-1) )
		y1zoom = (source_y+zoom_sz > 0 < ((size(data_section))[2]-1) )

		source_section = data_section[x0zoom:x1zoom, y0zoom:y1zoom] 
		
		x_len = (size(source_section))[1]
		y_len = (size(source_section))[2]
		junk_arr_sz = 50.
		junk_arr_halfsz = junk_arr_sz/2.
		junk_array = dblarr(x_len+junk_arr_sz, y_len+junk_arr_sz) ;Mode is good estimate of quiet thermal
		junk_array[*] = 7.0	; The backround logTb value. 6 for above 228 MHz
		junk_array[ junk_arr_halfsz:junk_arr_halfsz+x_len-1, $
					junk_arr_halfsz:junk_arr_halfsz+y_len-1] = alog10(source_section) > 7.0	

		wset, 2
		shade_surf, junk_array
STOP
		;---------------------------------------;
		;			Fit 2D Gaussian 
		;
		result = gauss2dfit(junk_array, a, /tilt)

		;Since gauss2dfit doens't give errors, use a as start values
		;for mpfit2dfun (which provides ucnertainties).
		start_parms = a
		xjunk = dindgen( n_elements(junk_array[*,0]) )
		yjunk = dindgen( n_elements(junk_array[0,*]) )
		result_pars = MPFIT2DFUN('my2Dgauss', xjunk, yjunk, junk_array, ERR, $
			start_parms, perror=perror, yfit=yfit)

		wset, 3
		result = yfit	
		plot_image, result, title='Result from IDL gauss2dfit'

		wset, 4
		result_2 = my2Dgauss(xjunk, yjunk, result_pars)
		plot_image, result_2, title='Result from my function.'


		max_x = result_pars[4] - junk_arr_halfsz
		max_y = result_pars[5] - junk_arr_halfsz

		max_tb_indeces = array_indices(junk_array, where(junk_array eq max(junk_array)))
		max_tb_x = max_tb_indeces[0] - junk_arr_halfsz
		max_tb_y = max_tb_indeces[1] - junk_arr_halfsz
		
		if result_pars[4] eq 1.0 then begin
			source_max_x = x0 + source_x
			source_max_y = y0 + source_y
			;index_max = where(source_section eq max(source_section))
			;max_x = (array_indices(source_section, index_max))[0] 
			;max_y = (array_indices(source_section, index_max))[1]
		endif else begin
			source_max_x = x0 + x0zoom + max_x 
			source_max_y = y0 + y0zoom + max_y 
		endelse
		source_maxTb_x = x0 + x0zoom + max_tb_x 
		source_maxTb_y = y0 + y0zoom + max_tb_y
		

		source_max_x_arcs = (source_max_x - (nrh_hdr.crpix1-0.5))*nrh_hdr.cdelt1	;0.5 for closer to pixel center
		source_max_y_arcs = (source_max_y - (nrh_hdr.crpix2-0.5))*nrh_hdr.cdelt2
		source_maxTb_x_arcs = (source_maxTb_x - (nrh_hdr.crpix1-0.5))*nrh_hdr.cdelt1
		source_maxTb_y_arcs = (source_maxTb_y - (nrh_hdr.crpix2-0.5))*nrh_hdr.cdelt2

		wset, 2
		plot_map, nrh_map, $
			fov = FOV, $
			center = CENTER, $
			dmin = 1e5, $
			dmax = 3e7, $
			title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
			string( anytim( nrh_times, /yoh, /trun) )+' UT'

		set_line_color
		plots, source_max_x_arcs, source_max_y_arcs, psym=1, color=5, symsize=3, thick=3, /data
		plots, source_maxTb_x_arcs, source_maxTb_y_arcs, psym=4, color=5, symsize=3, thick=3, /data

		;----------------------------------------------;
		;
		;			 Calculate the flux 
		;
		calculate_flux, source_section, nrh_hdr.freq*1e6, $
						source_flux, $
						source_Tb
		print, 'Source Flux at '+anytim(nrh_times, /yoh)+' : '+string(source_flux)+' (sfu)'				
		
		if i eq 0 then begin
			xarcs = source_max_x_arcs
			yarcs = source_max_y_arcs
			x_maxTb = source_maxTb_x_arcs
			y_maxTb = source_maxTb_y_arcs
			gauss_params = result_pars
			max_tb = source_Tb
			flux = source_flux
			times = nrh_times
		endif else begin
			xarcs = [xarcs, source_max_x_arcs]
			yarcs = [yarcs, source_max_y_arcs]
			x_maxTb = [x_maxTb, source_maxTb_x_arcs]
			y_maxTb = [y_maxTb, source_maxTb_y_arcs]
			gauss_params = [ [gauss_params], [result_pars] ]
			max_tb = [max_tb, source_Tb]
			flux = [flux, source_flux]
			times = [times, nrh_times]
		endelse	
	
		tstart = tstart + 1.0
		i=i+1
	endwhile				

	wset, 0
	loadct, 3, /silent
	plot_map, nrh_map, $
		fov = FOV, $
		center = CENTER, $
		dmin = 1e5, $
		dmax = 3e8, $
		title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
		string( anytim( nrh_times, /yoh, /trun) )+' UT'

	loadct, 39
	colors = findgen(n_elements(xarcs))*(255)/(n_elements(xarcs)-1)
	for i=0, n_elements(xarcs)-1 do plots, xarcs[i], yarcs[i], psym=1, color=colors[i]

	freq_string = string(nrh_hdr.freq, format='(I03)')
	
	xy_arcs_struct = {name:'src_properties_'+freq_string, $
						freq:nrh_hdr.freq, $
						x_max_fit:xarcs, $
						y_max_fit:yarcs, $
						x_maxTb:x_maxTb, $
						y_maxTb:y_maxTb, $
						flux_density:flux, $
						Tb:max_Tb, $ 
						gauss_params:gauss_params, $
						times:times}
	
	save, xy_arcs_struct, filename=folder+'/nrh_'+freq_string+'_src_properties.sav', $
			description = 'xy coords in arc seconds. Made using nrh_choose_centroid.pro'
		
STOP
END