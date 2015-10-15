pro nrh_choose_centroid_calc_flux

	;Code to choose where the source is then calulcate flux for that source only.

	cd, '~/Data/2014_apr_18/radio/nrh'
	filenames = findfile('*.fts')
	tstart = anytim(file2time('20140418_125030'), /utim)
	tstop = anytim(file2time('20140418_125300'), /utim) 

	window, 0, xs=700, ys=700, retain=2
	window, 1, xs=700, ys=700, retain=2
	window, 2, xs=700, ys=700, retain=2
	!p.charsize=1.5
	
	nseconds = tstop - tstart
	Ray = 32.0				;Solar_R in nrh_hdr_array
	domega = FLOAT(16 * 3E-4 /Ray)^2. 		; Solid angle. Below is a summation of pixels of Tb, which is effectively and integral
											; of Tbx1unit pixels. We need an integral of TbxDomega. So after the summation of Tb
											; we multiply by a factor of solid angle per pixel. 16 here is degrees of solar radius.
											; 32 is number of pixels per radius. 3e-14 comes from (1/60)x(pi/180), conversion of degrees
											; then to radians.
	c = 299792458. 			;speed of light in m/s
	k_B = 0.138				;Boltzmann constant k=1.38e-23, for SFU: K*e+22

	
	i=0
	while tstart lt tstop do begin

		t0str = anytim(tstart, /yoh, /trun, /time_only)

		read_nrh, filenames[7], $
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
		wset, 0
		freq = nrh_hdr.FREQ
		loadct, 3, /silent
		FOV = [15, 15]
		CENTER = [700, -100]
		plot_map, nrh_map, $
			fov = FOV, $
			center = CENTER, $
			dmin = 1e3, $
			dmax = 3e8, $
			title='NRH '+string(nrh_hdr.freq, format='(I03)')+' MHz '+ $
			string( anytim( nrh_times, /yoh, /trun) )+' UT'
			  
					
		set_line_color
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

		loadct, 3, /silent
					
		;-------------------------------------;
		;
		;	  Now plot raw data structure
		;
		wset, 1
		x0 = (CENTER[0]/nrh_hdr.cdelt1 + (nrh_hdr.naxis1/2.0)) - (FOV[0]*60.0/nrh_hdr.cdelt1)/2.0
        x1 = (CENTER[0]/nrh_hdr.cdelt1 + (nrh_hdr.naxis1/2.0)) + (FOV[0]*60.0/nrh_hdr.cdelt1)/2.0
        y0 = (CENTER[1]/nrh_hdr.cdelt2 + (nrh_hdr.naxis2/2.0)) - (FOV[1]*60.0/nrh_hdr.cdelt2)/2.0
        y1 = (CENTER[1]/nrh_hdr.cdelt2 + (nrh_hdr.naxis2/2.0)) + (FOV[1]*60.0/nrh_hdr.cdelt2)/2.0
		nrh_data = nrh_map.data
		data_section = nrh_data[x0:x1, y0:y1]
		plot_image, data_section > 1e5

		;-------------------------------;
		;	   Choose data points	    ;
		;								;
		cursor, x, y, /data
		x0 = x-5 >0
		x1 = x+5
		y0 = y-5 >0
		y1 = y+5
		source_section = data_section[x0:x1, y0:y1]

		wset, 2
		plot_image, source_section > 1e5

	
		index_max = where(source_section ge max(source_section))
		xy_max = array_indices(source_section, index_max)
		plots, xy_max[0, *], xy_max[1, *], /data, psym=4, color=4

		indices = where(source_section ge max(source_section)*0.4)
		xy_indices = array_indices(source_section, indices)

		set_line_color
		plots, xy_indices[0, *], xy_indices[1, *], /data, psym=1, color=5

		total_Tb = TOTAL(data_section[indices])		;summing over specified source area
		freq = nrh_hdr.freq * 1e6			;calculate flux
		lambda = c / freq
		constant = (2.* k_B * domega) / (lambda^2.)
		flux = constant * total_Tb	; in SFU

		print, 'Source Flux: '+string(flux)+' (sfu)'

		tstart = tstart + 10.0
		i=i+1
	endwhile				

	;window, 1
	plots, xarcs, yarcs

	window, 1
	arc_displ = fltarr(n_elements(xarcs)-1)

	for i=0, n_elements(xarcs)-2 do begin
		x1 = xarcs[i]
		x2 = xarcs[i+1]
		y1 = yarcs[i]
		y2 = yarcs[i+1]
		arc_displ[i] = sqrt( (x2 - x1)^2. + (y2 - y1)^2.)
	endfor	

	displ = tan((arc_displ/3600.)*!dtor)*149e6*1e3
	for i=0, n_elements(displ)-1 do displ[i] = total(arc_displ[0:i]) 

	times = anytim(times[1:n_elements(times)-1], /utim)
	times_sec = times - times[0]


	plot, times_sec, displ;, /ylog
			
	stop		
			
END