pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=12, $
          ysize=12, $
          /encapsulate, $
          yoffset=5

end


pro plot_nrh_aia

	; This plots the times and at which both the AR source and LT source are visible.



	loadct,0
	!p.color=0
	!p.background=255
	window, xs=1500, ys=1500, retain = 2
	!p.charsize=2.0

	
	times = anytim(['2014-04-18T12:51:00.000', $
					 '2014-04-18T12:51:10.000', $
					 '2014-04-18T12:51:20.000', $
					 '2014-04-18T12:53:09.000', $
					 '2014-04-18T12:54:00.000', $
					 '2014-04-18T12:56:10.000'])
				
	freqs = [445.0, 432.0, 408.0, 327.0, 298.0, 270.0]

	nrh_aia_imgs_all_freqs_20140418_v2, times, freqs

	

END

;-----------------------------------------------------------------;
;
;							Version 2.0
;
;-----------------------------------------------------------------;

pro nrh_aia_imgs_all_freqs_20140418_v2, times, freqs

	; This version will plot the chosen points underneath the dynmaic spectrum
	
	; Set image positions
	ybottom = 0.05
	ytop = 0.25
	aia171_img_pos = [ [[0.05, ybottom, 0.2, ytop ]], $
				       [[0.2, ybottom, 0.35, ytop ]], $
				       [[0.35, ybottom, 0.5, ytop ]], $
				       [[0.5, ybottom, 0.65, ytop ]], $
				   	   [[0.65, ybottom, 0.8, ytop ]], $
				       [[0.8, ybottom, 0.95, ytop ]] ]


	cd,'~/Data/2014_Apr_18/sdo/171A/'
	
	; First filter for correct exposure times.
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	aia_files = aia_files[where(ind.exptime gt 1.)]
	mreadfits_header, aia_files, ind
	aia_times = anytim(ind.date_obs, /utim)
	

	nrh_freqs = [150.0, 173.0, 228.0, 270.0, 298.0, 327.0, 408.0, 432.0, 445.0]
	nrh_indices = intarr(n_elements(freqs))
	for i=0, n_elements(freqs)-1 do nrh_indices[i] = closest(nrh_freqs, freqs[i])		       

  
	FOR i = 0, n_elements(times)-1 DO BEGIN
		
		tstart = anytim(times[i], /utim) 
		t0 = anytim(tstart, /yoh, /trun, /time_only)
		cd,'~/Data/2014_Apr_18/radio/nrh/'
		nrh_filenames = findfile('*.fts')
		read_nrh, nrh_filenames[8], $	; use 445 MHz
				nrh_hdr, $
				nrh_data, $
				hbeg=t0


		cd, '~/Data/2014_Apr_18/sdo/171A/'
		;-------------------------------------------------;
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
		;				  Plot diff image
		;
		pos = aia171_img_pos[*, *, i]
		FOV = [16.0, 16.0]
		CENTER = [600.0, -300.0]
		loadct, 0, /silent
		plot_map, diff_map(map_aia, map_aia_pre), $
			dmin = -25.0, $
			dmax = 25.0, $
			fov = FOV, $
			center = CENTER, $
			position = pos, $
			/noerase, $
			/normal, $
			/notitle, $
			charsize=0.5, $
			/square


		plot_helio, he_aia.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
			gcolor=255, $
			grid_spacing=15.0

		;-------------------------------------------------;
		;					PLOT NRH
		;
		nrh_index = nrh_indices[i]

		tstart = anytim(times[i], /utim) 
		t0 = anytim(tstart, /yoh, /trun, /time_only)
		cd,'~/Data/2014_Apr_18/radio/nrh/'
		nrh_filenames = findfile('*.fts')
		read_nrh, nrh_filenames[nrh_index], $	; use 445 MHz
				nrh_hdr, $
				nrh_data, $
				hbeg=t0
							
		index2map, nrh_hdr, nrh_data, $
				 nrh_map  

		;nrh_data = alog10(nrh_data)		
		;nrh_map.data = nrh_data 

		;			Define contour levels
		max_val = max( (nrh_data) ,/nan) 									   
		nlevels=10.0   
		top_percent = 0.8
		
		levels = (dindgen(nlevels)*(1e9 - 1e8)/(nlevels-1.0)) $
				+ 1e8

		freq_string = string(nrh_hdr.freq, format='(I3)')
		nlevels=4.0   
		case freq_string of		
			'298': begin
					levels = (dindgen(nlevels)*(1e9 - 1e8)/(nlevels-1.0)) + 1e8
					low_levels = (dindgen(nlevels)*(5e7 - 2e7)/(nlevels-1.0)) + 2e7
					levels = [levels, low_levels]	
				   end
			'327': begin
					levels = (dindgen(nlevels)*(1e9 - 1e8)/(nlevels-1.0)) + 1e8
					low_levels = (dindgen(nlevels)*(7e7 - 2e7)/(nlevels-1.0)) + 2e7
					levels = [levels, low_levels]	
				   end	
			'270': begin
					levels = (dindgen(nlevels)*(1e9 - 1e8)/(nlevels-1.0)) + 1e8
					low_levels = (dindgen(nlevels)*(1e8 - 8e7)/(nlevels-1.0)) + 8e7
					levels = [levels, low_levels]
				   end
			else: print,'Using only high contours.'	   
		endcase

		;print, levels		
		;loadct, 33
		set_line_color
		plot_map, nrh_map, $
			/overlay, $
			/cont, $
			/noerase, $
			levels=levels, $
			/noxticks, $
			/noyticks, $
			/noaxes, $
			thick=2, $
			color=1;, $

		plot_helio, nrh_hdr.date_obs, $
			/over, $
			gstyle=0, $
			gthick=1.0, $	
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
			thick=1, $
			color=[i+2];, $
;		
		set_line_color
		xyouts, pos[0]+0.01, pos[1]+0.01, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz', /normal, charsize=1.0, color=i+2
		xyouts, pos[0]+0.01, pos[3]+0.01,  anytim(nrh_hdr.date_obs, /cc, /trun, /time_only) +' UT', /normal, charsize=1.0


		print, i
		print, he_aia.date_obs
		print, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz'
		print,'----'
		
		if i eq 1 then freqs = nrh_hdr.freq else freqs = [freqs, nrh_hdr.freq] 

	ENDFOR		


END

