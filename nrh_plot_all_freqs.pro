pro nrh_oplot, freq, hdr_aia, color
	;----------------------------------------------;
	;				Define time
	tstart = anytim(hdr_aia.date_obs, /utim) 
	tend = anytim(hdr_aia.date_obs, /utim) + 1.0*60.0
	t0 = anytim(tstart, /yoh, /trun, /time_only)
	t1 = anytim(tend, /yoh, /trun, /time_only)
	
	;----------------------------------------------;
	;			Read data, produce map
	cd,'~/Data/2014_Apr_18/radio/nrh/'
	nrh_filename = findfile('*' + freq + '*.fts')
	
	read_nrh, nrh_filename[0], $	
			nrh_hdr, $
			nrh_data, $
			hbeg=t0, $ 
			hend=t1				
	index2map, nrh_hdr, nrh_data, $
			 nrh_map  
		
	;----------------------------------------------;	
	;		Find closest NRH image to AIA		
	nrh_str_hdr = nrh_hdr
	nrh_times = nrh_hdr.date_obs
	nrh_index = closest( anytim(nrh_times, /utim), anytim(hdr_aia.date_obs, /utim) )
			
	;----------------------------------------------;
	;      		 Define contours.	 
	nrh_data = alog10(nrh_data)
	nrh_map.data = nrh_data
	max_val = max( (nrh_data[*, *, nrh_index]) ,/nan) 									   
	nlevels = 3   
	top_percent = 0.95
	levels = (dindgen(nlevels)*(max_val - max_val*top_percent)/(nlevels-1.0)) $
			+ max_val*top_percent  
	
	;----------------------------------------------;
	;      			Overlay	 
	set_line_color
	plot_map, nrh_map[nrh_index], $
		/overlay, $
		/cont, $
		levels=levels, $
		/noxticks, $
		/noyticks, $
		/noaxes, $
		thick=2.5, $
		color=color	
	
	
	freq_tag = string(nrh_hdr[0].freq, format='(I03)')
	
END


	;******************************************;
	;			  MAIN PROCEDURE
	;******************************************;


pro nrh_plot_all_freqs

	;Code to plot all NRH frequencies on AIA
	
	;---------------------------------------;
	;			Window params
	winsz = 800.0
  	window, xs=winsz, ys=winsz, retain = 2
  	!p.charsize=1.5
	
	tstart = anytim(file2time('20140418_125200'),/utim)
	tend   = anytim(file2time('20140418_132158'),/utim)
	
	;******************************************;
	;				  AIA
	;******************************************;

	;			Choose AIA files
	cd, '~/Data/2014_Apr_18/sdo/171A/'
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	f = aia_files[where(ind.exptime gt 1.)]
	mreadfits_header, f, ind
	aia_files = f[where(anytim(ind.date_obs, /utim) ge tstart)]
	
	FOR i = 5, n_elements(aia_files)-1 DO BEGIN
		
		;-------------------------------------------------;
		;			Read AIA into map
		cd, '~/Data/2014_Apr_18/sdo/171A/'
		read_sdo, aia_files[i-5], $
			hdr_aia_pre, $
			data_aia_pre
		read_sdo, aia_files[i], $
			hdr_aia, $
			data_aia
		index2map, hdr_aia_pre, $
			smooth(data_aia_pre, 7)/hdr_aia_pre.exptime, $
			map_aia_pre, $
			outsize = 2048
		index2map, hdr_aia, $
			smooth(data_aia, 7)/hdr_aia.exptime, $
			map_aia, $
			outsize = 2048		
		
		;--------------------------------------------------;
		;			Plot diff image	
		FOV = [16.6, 16.6]
		CENTER = [500.0, -350.0]
		loadct, 1, /silent
		plot_map, diff_map(map_aia, map_aia_pre), $
			dmin = -25.0, $
			dmax = 25.0, $
			fov = FOV,$
			center = CENTER, $
			/notitle
			
		plot_helio, hdr_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0
			
			
		;******************************************;
		;				  NRH
		;******************************************;
		;nrh_oplot, '1509', hdr_aia, 2
		;nrh_oplot, '1732', hdr_aia, 3
		;nrh_oplot, '2280', hdr_aia, 4
		;nrh_oplot, '2706', hdr_aia, 5
		;nrh_oplot, '2987', hdr_aia, 2
		nrh_oplot, '3270', hdr_aia, 2
		nrh_oplot, '4080', hdr_aia, 3
		nrh_oplot, '4320', hdr_aia, 4
		nrh_oplot, '4450', hdr_aia, 7
		
	 	xyouts, 0.5, 0.86, 'AIA 171A '+hdr_aia.date_obs+' UT', $
	 		/normal, $
	 		alignment=0.5, $
	 		charsize=2.0
	 		
	 	xyouts, 0.86, 0.85, 'NRH 327 MHz', color=2, /normal
	 	xyouts, 0.86, 0.8, 'NRH 408 MHz', color=3, /normal
	 	xyouts, 0.86, 0.75, 'NRH 432 MHz', color=4, /normal
	 	xyouts, 0.86, 0.7, 'NRH 445 MHz', color=7, /normal
	 		
	 	stop	
		
	ENDFOR

END
