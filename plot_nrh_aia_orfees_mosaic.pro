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


pro plot_nrh_aia_orfees_mosaic, all_freqs=all_freqs

	xsize = 2000
	ysize = xsize
	loadct, 0
	reverse_ct
	!p.charsize=1.5
	!p.thick=1
	!x.thick=1


	; Firstly, select the the time and frequency points from Orfées.
	dam_orfees_oplot, time_points = times, freq_points = freqs, /choose

	;
	; Construct the positions matrix
	; 
	nrh_freqs = [270.0, 298.0, 327.0, 408.0, 432.0];, 445.0];[150.0, 173.0, 228.0, 270.0, 298.0, 327.0, 408.0, 432.0, 445.0]

	nimages = n_elements(times) + 1
	xpos = findgen(nimages)*(0.95 - 0.05)/(nimages-1) + 0.05
	nfreqs = n_elements(nrh_freqs) + 1
	ypos = findgen(nfreqs)*(0.95 - 0.05)/(nfreqs -1) + 0.05
	

	if keyword_set(all_freqs) then begin

		;
		; N_times X N freqs
		; 
		freqs = nrh_freqs
		for j=0, n_elements(nrh_freqs)-1 do begin
			for i=0, n_elements(times)-1 do begin
				pos = [xpos[i], ypos[j], xpos[i+1], ypos[j+1]]
				if i eq 0 then row = [pos] else row = [ [[row]], [[pos]] ]
			endfor		
			if j eq 0 then mosaic = [row] else mosaic = [ [[mosaic]], [[row]] ]
		endfor
		yaspect=float(n_elements(times))/float(n_elements(nrh_freqs))

		;
		; Window parameters. Aspect tatio adjusted depending on num of times and freqs
		; 

		if yaspect lt 1 then xsize = xsize*yaspect else ysize = ysize/yaspect
		window, 20, xs=xsize, ys=ysize, retain=2

		;
		; Plot image at each position
		; 
		colors = indgen(n_elements(freqs)) + 2
		img_num = 0
		for i=0, n_elements(freqs)-1 do begin
			for j=0, n_elements(times)-1 do begin
				nrh_aia_mosaic, times[j], freqs[i], positions=mosaic[*, *, img_num], $
							color = colors[i]
				img_num = img_num+1
			endfor
			j=0
		endfor	

	endif else begin

		;
		; this part for when just specific time and frequcney points are needed.
		; 
		for i=0, n_elements(times)-1 do begin
			pos = [xpos[i], 0.05, xpos[i+1], 0.95]
			if i eq 0 then mosaic = [[pos]] else mosaic = [ [[mosaic]], [[pos]] ]
		endfor		
		yaspect=float(n_elements(times))

	
		if yaspect lt 1 then xsize = xsize*yaspect else ysize = ysize/yaspect
		window, 20, xs=xsize, ys=ysize, retain=2

		for i=0, n_elements(times)-1 do $	
			nrh_aia_mosaic, times[i], freqs[i], positions=mosaic[*, *, i]

	endelse	

END



pro nrh_aia_mosaic, times, freqs, positions=positions, color=color

	; Plots AIA with NRH contours for a particular time and frequency

	; times: time of the image. The closest NRH file is chosen. Then the closest AIA file.

	; freqs: Frequency at which to over plot NRH contours.

	; position: Position of the image in normal coordinates.

	; color: color of NRH contours.

	aia_folder = '~/Data/2014_Apr_18/sdo/171A/'
	nrh_folder = '~/Data/2014_Apr_18/radio/nrh/';clean_wresid/'
	read_nrh = 'read_nrh, nrh_filenames[nrh_index], nrh_hdr, nrh_data, hbeg=t0'

	; First filter AIA for correct exposure times.
	aia_files = findfile(aia_folder+'aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	aia_files = aia_files[where(ind.exptime gt 1.)]
	mreadfits_header, aia_files, ind
	aia_times = anytim(ind.date_obs, /utim)
	
	cd, nrh_folder
	nrh_filenames = findfile('*.fts')
	nrh_freqs = [150.0, 173.0, 228.0, 270.0, 298.0, 327.0, 408.0, 432.0, 445.0]
	nrh_index = closest(nrh_freqs, freqs)		       

				;freqs = nrh_freqs(nrh_indices[UNIQ(nrh_indices, SORT(nrh_indices))])
		
	tstart = anytim(times, /utim) 
	t0 = anytim(tstart, /yoh, /trun, /time_only)
	
	read_nrh, nrh_filenames[8], $	; Use 445 MHz
			nrh_hdr, $
			nrh_data, $
			hbeg=t0

	;-------------------------------------------------;
	;				 	Read AIA
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
  
	;
	;			     Plot diff image
	;
	FOV = [16.0, 16.0]
	CENTER = [600.0, -300.0]
	loadct, 0, /silent
	plot_map, diff_map(map_aia, map_aia_pre), $
		dmin = -25.0, $
		dmax = 25.0, $
		fov = FOV, $
		center = CENTER, $
		position = positions, $
		/noerase, $
		/normal, $
		title=nrh_hdr.date_obs, $
		charsize=1.0, $
		/square, $
		color=0


	plot_helio, he_aia.date_obs, $
		/over, $
		gstyle=0, $
		gthick=1.0, $	
		gcolor=255, $
		grid_spacing=15.0


	;-----------------------------------------------;
	;				   PLOT NRH
	;
	junk = execute(read_nrh)
	index2map, nrh_hdr, nrh_data, $
			 nrh_map  

	nrh_data = alog10(nrh_data)		
	nrh_map.data = nrh_data 

	;		Define contour levels
	max_val = max( (nrh_data) ,/nan) 									   
	nlevels=6.0   
	top_percent = 0.8
	levels = (dindgen(nlevels)*(9. - 8.0)/(nlevels-1.0)) + 8.0

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
		color=color

	set_line_color
	plot_map, nrh_map, $
		/overlay, $
		/cont, $
		levels=levels, $
		/noxticks, $
		/noyticks, $
		/noaxes, $
		thick=1

	set_line_color
	xyouts, positions[0]+0.01, positions[1]+0.01, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz', /normal, charsize=1.0
	xyouts, positions[0]+0.01, positions[3]+0.01,  anytim(nrh_hdr.date_obs, /cc, /trun, /time_only) +' UT', /normal, charsize=1.0


	print, he_aia.date_obs
	print, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz'
	print,'----'
	

END