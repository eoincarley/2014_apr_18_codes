pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=6, $
          ysize=6, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

pro nrh_aia_plot_moving_source

	; Code to plot stationary and moving radio source on top of AIA.  

	aia_folder = '~/Data/2014_Apr_18/sdo/171A/'                                            	
	nrh_folder = '~/Data/2014_Apr_18/radio/nrh/clean_wresid/'
	pos = [0.17, 0.17, 0.92, 0.92]
	colors = [2, 3, 4, 10, 6, 7]
	times = anytim(['2014-04-18T12:51:00.000', $
					 '2014-04-18T12:51:10.000', $
					 '2014-04-18T12:51:20.000', $
					 '2014-04-18T12:53:09.000', $
					 '2014-04-18T12:54:00.000', $
					 '2014-04-18T12:56:10.000'])
	nrh_freqs = [150.0, 173.0, 228.0, 270.0, 298.0, 327.0, 408.0, 432.0, 445.0]
	freqs = [445.0, 432.0, 408.0, 327.0, 298.0, 270.0]	;Chosen frequencies to plot
	nrh_indices = intarr(n_elements(freqs))
	for i=0, n_elements(freqs)-1 do nrh_indices[i] = closest(nrh_freqs, freqs[i])	
	labels = ['b', 'c', 'd', 'e', 'f', 'g']	

	
	; First filter for correct exposure times.
	aia_files = findfile(aia_folder+'aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	aia_files = aia_files[where(ind.exptime gt 1.)]
	mreadfits_header, aia_files, ind
	aia_times = anytim(ind.date_obs, /utim)
	

  	cd, nrh_folder
	FOR i = 0, n_elements(times)-1 DO BEGIN
		
		tstart = anytim(times[i], /utim) 
		t0 = anytim(tstart, /yoh, /trun, /time_only)
		nrh_filenames = findfile('*.fts')
		read_nrh, nrh_filenames[8], $	; use 445 MHz just for initial time read
				nrh_hdr, $
				nrh_data, $
				hbeg=t0

		;-------------------------------------------------;
		;
		;				 	Plot AIA
		;
		aia_index = closest(aia_times, anytim(nrh_hdr.date_obs))
		read_sdo, aia_files[aia_index-1], $
			he_aia_pre, $
			data_aia_pre
		read_sdo, aia_files[aia_index], $
			he_aia, $
			data_aia

		index2map, he_aia_pre, $
			smooth(data_aia_pre, 7)/he_aia_pre.exptime, $
			map_aia_pre, $
			outsize = 2048
		index2map, he_aia, $
			smooth(data_aia, 7)/he_aia.exptime, $
			map_aia, $
			outsize = 2048		
	  
		;--------------------------------------------------;
		;
		;				  Plot diff image
		;
		FOV = [12.0, 12.0]
		CENTER = [600.0, -300.0]

		setup_ps, '~/nrh_aia_moving_src_'+string(i, format='(I1)')+'.eps'


	
		if i eq 0 then labelfmt = ['(I4)', '(I4)', 'X (arcsecs)', 'Y (arcsecs)' ]	; x and y ticks
		if i ge 1 then labelfmt = ['(I4)', '(A1)', 'X (arcsecs)', ' ' ]	; x and y ticks
		if i eq 4 then labelfmt = ['(I4)', '(I4)', 'X (arcsecs)', 'Y (arcsecs)' ]	; x and y ticks
	

		loadct, 0, /silent
		plot_map, diff_map(map_aia, map_aia_pre), $
			dmin = -20.0, $
			dmax = 15.0, $
			fov = FOV, $
			center = CENTER, $
			position = pos, $
			/normal, $
			/notitle, $
			/square, $
			xtitle = labelfmt[2], $
			ytitle = labelfmt[3], $
			XTickformat=labelfmt[0], $
			YTickformat=labelfmt[1]


		plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0

		;-------------------------------------------------;
		;
		;					PLOT NRH
		;
		nrh_index = nrh_indices[i]

		tstart = anytim(times[i], /utim) 
		t0 = anytim(tstart, /yoh, /trun, /time_only)
		nrh_filenames = findfile('*.fts')
		read_nrh, nrh_filenames[nrh_index], $	
				nrh_hdr, $
				nrh_data, $
				hbeg=t0
							
		index2map, nrh_hdr, nrh_data, $
				 nrh_map  

		nrh_data = alog10(nrh_data)	
		nrh_map.data = nrh_data 

		;			Define contour levels
		max_val = max( (nrh_data) ,/nan) 									   
		nlevels=6.0   
		top_percent = 0.8
		
		top_temp = 9.0
		levels = (findgen(nlevels)*(top_temp - 8.4)/(nlevels-1.0)) + 8.4
		levels = round(levels*10.)/10.

		freq_string = string(nrh_hdr.freq, format='(I3)')
		nlevels=8.0   
		case freq_string of		
			'270': begin
					levels = [7.7, 7.8, 7.9, 8.0]	;(findgen(nlevels)*(8.0 - 7.7)/(nlevels-1.0)) + 7.7
				   end
			'298': begin
					levels = [7.4, 7.8, 8.0, 8.2]	;(findgen(nlevels)*(8.4 - 7.4)/(nlevels-1.0)) + 7.4	
				   end
			'327': begin
					levels = [7.4, 7.8, 8.2, 8.6]	;(findgen(nlevels)*(8.4 - alt_low_temp)/(nlevels-1.0)) + 7.4	
				   end	
			'408': begin
					levels = [8.2, 8.4, 8.6, 8.8]	;(findgen(nlevels)*(8.4 - alt_low_temp)/(nlevels-1.0)) + 7.4	
				   end		   
			'432': begin
					levels = [8.2, 8.4, 8.6, 8.8]	;(findgen(nlevels)*(8.4 - alt_low_temp)/(nlevels-1.0)) + 7.4			
				   end	
			'445': begin
					levels = [8.2, 8.4, 8.6, 8.8]	;(findgen(nlevels)*(8.4 - alt_low_temp)/(nlevels-1.0)) + 7.4	
				   end		   
			else: print, 'Using only high contours.'	   
		endcase


		set_line_color
		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			/noerase, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=18, $
			color=1, $
			C_LABELS = [1, 1, 1, 1], $
			;C_ANNOTATE = ['8.4', '8.5', '8.6'], $
			C_CHARSIZE = 1.3, $
			C_CHARTHICK = 10.0



		plot_helio, nrh_hdr.date_obs, $
			/over, $
			gstyle=0, $
			gthick=3.0, $	
			gcolor=255, $
			grid_spacing=15.0


		set_line_color
		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=14, $
			color=colors[i], $
			C_LABELS = [1, 1, 1, 1], $
			;C_ANNOTATE = ['8.4', '8.5', '8.6'], $
			C_CHARSIZE = 1.3, $
			C_CHARTHICK = 4.0


		; Just for black contour labels	
		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=-1, $
			color=0, $
			C_LABELS = [1, 1, 1, 1], $
			;C_ANNOTATE = ['8.4', '8.5', '8.6'], $
			C_CHARSIZE = 1.3, $
			C_CHARTHICK = 4.0	


		
		set_line_color
		xyouts, pos[0]+0.03, pos[1]+0.03, $
			'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz '+anytim(nrh_hdr.date_obs, /cc, /trun, /time_only) +' UT', $
			/normal, $
			color=colors[i]	
		xyouts, pos[0]+0.03, pos[1]+0.03, $
			'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz '+anytim(nrh_hdr.date_obs, /cc, /trun, /time_only) +' UT', $
			/normal, $
			color=0, $
			charthick=0.1	

		levels = string(levels, format='(f3.1)')
		xyouts, pos[0]+0.02, pos[3]-0.055, labels[i], /normal, color=1, charsize=2
		;xyouts, pos[2]-0.02, pos[3]-0.055, levels[0]+' < log!L10!N(T!LB!N[K]) < ' +levels[n_elements(levels)-1], /normal, color=colors[i], charsize=1.5, align=1
		;xyouts, pos[2]-0.02, pos[3]-0.055, levels[0]+' < log!L10!N(T!LB!N[K]) < ' +levels[n_elements(levels)-1], /normal, color=0, charsize=1.5, align=1


		print, he_aia.date_obs
		print, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz'
		print, '----'
		
		;if keyword_set(postscript) then begin 
			device, /close
			set_plot, 'x'
		;endif	

	ENDFOR


END