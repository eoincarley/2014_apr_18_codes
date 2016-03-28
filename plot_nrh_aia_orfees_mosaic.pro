pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=12, $
          ysize=12/(1.666), $	; For a 4 x 3 (x, y) image.
          /encapsulate, $
          yoffset=5

end


pro plot_nrh_aia_orfees_mosaic, all_freqs=all_freqs, postscript=postscript

	; Firstly, select the the time and frequency points from Orfées.
	
	dam_orfees_oplot, time_points = times, freq_points = freqs, /choose
	;times = anytim( '2014-04-18T' + ['12:49:30', '12:50:30', '12:51:32', '12:52:50', '12:53:10']);, '12:56:10'], /utim )
	;------------------------------------;
	;			Window params
	;
	xsize = 1500
	ysize = xsize
	if keyword_set(postscript) then begin 
		setup_ps, '~/aia_nrh_mosaic_20140418_v2.eps'
	endif else begin
		loadct, 0
		reverse_ct
		!p.charsize=1.5
		!p.thick=1
		!x.thick=1
	endelse	
	
	nrh_freqs = [298.0, 327.0, 432.0] 	;[150.0, 173.0, 228.0, 270.0, 298.0, 327.0, 408.0, 432.0, 445.0]

	nimages = n_elements(times) + 1
	xpos = findgen(nimages)*(0.95 - 0.06)/(nimages-1) + 0.06
	nfreqs = n_elements(nrh_freqs) + 1
	ypos = findgen(nfreqs)*(0.95 - 0.06)/(nfreqs -1) + 0.06
	
	
	if keyword_set(all_freqs) then begin

		;
		; N_times X N_freqs
		;
		; Construct the positions matrix in 'mosaic'
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
		; Window parameters. Aspect ratio adjusted depending on num of times and freqs
		; 

		if yaspect lt 1 then xsize = xsize*yaspect else ysize = ysize/yaspect
		if ~keyword_set(postscript) then window, 20, xs=xsize, ys=ysize, retain=2

		;
		; Plot image at each position
		; 
		colors = [10, 6, 4]	;indgen(n_elements(freqs)) + 2
		img_num = 0
		for i=n_elements(freqs)-1, 0, -1 do begin	; Backwards loop to plot highest frequency at the bottom
			for j=0, n_elements(times)-1 do begin
				nrh_aia_mosaic, times[j], freqs[i], positions=mosaic[*, *, img_num], $
							color = colors[i]
				img_num = img_num+1
			endfor
			j=0
		endfor	

	endif else begin

		;
		; this part for when specific time and frequcney points are chosen.
		; 
		for i=0, n_elements(times)-1 do begin
			pos = [xpos[i], 0.05, xpos[i+1], 0.95]
			if i eq 0 then mosaic = [[pos]] else mosaic = [ [[mosaic]], [[pos]] ]
		endfor		
		yaspect=float(n_elements(times))
		colors = 10.0-indgen(n_elements(times))
	
		if yaspect lt 1 then xsize = xsize*yaspect else ysize = ysize/yaspect
		if ~keyword_set(postscript) then window, 20, xs=xsize, ys=ysize, retain=2

		for i=0, n_elements(times)-1 do $	
			nrh_aia_mosaic, times[i], freqs[i], positions=mosaic[*, *, i]
	endelse	

	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif	

END



pro nrh_aia_mosaic, times, freqs, positions=positions, color=color

	; Plots AIA with NRH contours for a particular time and frequency

	; times: time of the image. The closest NRH file is chosen. Then the closest AIA file.

	; freqs: Frequency at which to overplot NRH contours.

	; position: Position of the image in normal coordinates.

	; color: color of NRH contours.

	border_size = 0.005
	positions[0] = positions[0] + border_size
	positions[1] = positions[1] + border_size
	positions[2] = positions[2] - border_size
	positions[3] = positions[3] - border_size

	aia_folder = '~/Data/2014_Apr_18/sdo/171A/'
	nrh_folder = '~/Data/2014_Apr_18/radio/nrh/clean_wresid/'
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
	;		 Plot diff image
	;
	FOV = [12.0, 12.0]
	CENTER = [600.0, -300.0]
	loadct, 0, /silent

	; Sort out label and tick formats based on image position
	pos = positions
	if pos[3] gt 0.945 then title = anytim(nrh_hdr.date_obs, /cc, /trun, /time_only)+' UT' else title = ' '
	if pos[0] eq 0.065 and pos[1] eq 0.065 then labelfmt = ['(I4)', '(I4)', 'X (arcsecs)', 'Y (arcsecs)' ]	; x and y ticks
	if pos[0] gt 0.065 and pos[1] eq 0.065 then labelfmt = ['(I4)', '(A1)', 'X (arcsecs)', ' ' ]	; x ticks
	if pos[0] eq 0.065 and pos[1] gt 0.065 then labelfmt = ['(A1)', '(I4)', ' ', 'Y (arcsecs)' ]	; y ticks
	if pos[0] gt 0.065 and pos[1] gt 0.065 then begin
		labelfmt = ['(A1)', '(A1)', ' ', ' ']	; no ticks
	endif else begin
		; Just to cover when specific freqs and times are chosen.
		lebelfmt = ['(I4)', '(I4)', 'X (arcsecs)', 'Y (arcsecs)' ]
	endelse	

	
	plot_map, diff_map(map_aia, map_aia_pre), $
		dmin = -20.0, $
		dmax = 20.0, $
		fov = FOV, $
		center = CENTER, $
		position = positions, $
		/noerase, $
		/normal, $
		title=title, $
		xtitle = labelfmt[2], $
		ytitle = labelfmt[3], $
		charsize=1.0, $
		color=0, $
		XTickformat=labelfmt[0], $
		YTickformat=labelfmt[1]

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

	nrh_data = alog10(smooth(nrh_data, 1))		
	nrh_map.data = nrh_data 

	;		Define contour levels
	max_val = max( (nrh_data) ,/nan) 									   
	nlevels=6.0   
	;top_percent = 0.8
	top_contour = 9.0 		; Kelvin
	bottom_contour = 8.0	; Kelvin
	levels = (dindgen(nlevels)*(top_contour - bottom_contour)/(nlevels-1.0)) + bottom_contour

	freq_string = string(nrh_hdr.freq, format='(I3)')
	case freq_string of		
		'270': begin	
				levels = [7.8, 7.9, levels]
			   end
		'298': begin
				top_contour = 9.0 		; Kelvin
				bottom_contour = 7.8	; Kelvin
				levels = (dindgen(nlevels)*(top_contour - bottom_contour)/(nlevels-1.0)) + bottom_contour
			   end  
		'327': begin
				top_contour = 9.0 		; Kelvin
				bottom_contour = 7.8	; Kelvin
				levels = (dindgen(nlevels)*(top_contour - bottom_contour)/(nlevels-1.0)) + bottom_contour
			   end  	   
		else: print, 'Using only high contours.'	   
	endcase

	levels = round(levels*10.0)/10.0
	set_line_color
	plot_map, nrh_map, $
		/overlay, $
		/cont, $
		/noerase, $
		levels=levels, $
		;/noxticks, $
		;/noyticks, $
		/noaxes, $
		thick=7, $
		color=0, $
			C_LABELS = [1, 0, 1, 0, 1, 0, 1], $
			C_ANNOTATE = string(levels, format='(f3.1)'), $
			C_CHARSIZE = 0.9, $
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
		thick=5, $
		color=color, $
			C_LABELS =  [1, 0, 0, 0, 1, 0, 1], $
			C_ANNOTATE = string(levels, format='(f3.1)'), $
			C_CHARSIZE = 0.9, $
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
		color=1, $
			C_LABELS =  [1, 0, 1, 0, 1, 0, 1], $
			C_ANNOTATE = string(levels, format='(f3.1)'), $
			C_CHARSIZE = 0.9, $
			C_CHARTHICK = 4.0	

	set_line_color
	if pos[2] gt 0.9 then $
		xyouts, 0.95, positions[3]-0.07, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz', /normal, charsize=1.0, color=color, orientation=270.0
	;xyouts, positions[0]+0.01, positions[3]+0.01,  anytim(nrh_hdr.date_obs, /cc, /trun, /time_only) +' UT', /normal, charsize=1.0


	print, he_aia.date_obs
	print, 'NRH ' + string(nrh_hdr.freq, format='(I3)') + ' MHz'
	print,'----'
	

END