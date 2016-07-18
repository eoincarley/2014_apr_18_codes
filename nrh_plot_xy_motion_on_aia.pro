pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=9, $
          ysize=8, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

pro nrh_plot_xy_motion_on_aia, postscript=postscript

	; Oplot the motion of the LT source on AIA image

	;-------------------------------------------------;
	;			Choose files unaffected by AEC
	cd,'~/Data/2014_Apr_18/sdo/171A/'
	aia_files = findfile('aia*.fits')
	motion_files = findfile('~/Data/2014_apr_18/radio/nrh/nrh*src*motion.sav')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	f = aia_files[where(ind.exptime gt 1.)]

	tstart = anytim(file2time('20140418_124830'),/utim)
	tend   = anytim(file2time('20140418_124958'),/utim)

	mreadfits_header, f, ind
	aia_files = f[where(anytim(ind.date_obs, /utim) ge tstart) - 5]
  
	i=5
	;-------------------------------------------------;
	;				 	Plot AIA
	read_sdo, aia_files[i-5], $
		he_aia_pre, $
		data_aia_pre
	read_sdo, aia_files[i], $
		he_aia, $
		data_aia
	index2map, he_aia_pre, $
		smooth(data_aia_pre, 5)/he_aia_pre.exptime, $
		map_aia_pre, $
		outsize = 4096
	index2map, he_aia, $
		smooth(data_aia, 5)/he_aia.exptime, $
		map_aia, $
		outsize = 4096		

	if keyword_set(postscript) then setup_ps, '~/nrh_source_motion_on_aia.eps'	
	;-----------------------------;
	;				  Plot diff image	
	;FOV = [20., 20.]
	;CENTER = [650, -250]
	loadct, 57, /silent
	reverse_ct
	plot_map, diff_map(map_aia, map_aia_pre), $
		dmin = -50.0, $
		dmax = 50.0, $
		fov = FOV,$
		center = CENTER, $
		title = ' ', $
		pos = [0.1, 0.15, 0.8, 0.95]
		
	plot_helio, he_aia.date_obs, $
		/over, $
		gstyle=0, $
		gthick=7.0, $	
		gcolor=255, $
		grid_spacing=15.0

	print, he_aia.DATE_OBS
	;------------------------------------;
	;			Plot Total I
	;


	loadct, 39
			
	t1_colors = anytim(file2time('20140418_124830'), /utim)
	t2_colors = anytim(file2time('20140418_125650'), /utim)

	ncols = 250
	tcolors = (findgen(ncols )*(t2_colors - t1_colors)/(ncols -1) )+ t1_colors
	colors = findgen(ncols) + 1			

	symbol = [1,2,4,5,6,7]
	motion_files = reverse(motion_files)
	
	for j=0, n_elements(motion_files)-1 do begin
		restore, motion_files[j];, /verb
		
		xarcs = xy_arcs_struct.xarcs
		yarcs = xy_arcs_struct.yarcs
		times = anytim(xy_arcs_struct.times, /utim)
		freq = xy_arcs_struct.freq


		sym = symbol[j]
		
		step=10		; This step size (or 30) produces a speed that mathces what it should be e.g., 
					; simply taking the first and last points as displacements and a time of 500 seconds gives ~360 km/s						
		for i=0, n_elements(xarcs)-(step+1), step do begin

			color = interpol(colors, tcolors, times[i])
			plots, xarcs[i], yarcs[i], color=color, psym=sym, symsize=2.0, thick=5
			;if i eq 0.0 or xarcs[i]*xarcs[i+1] lt 0.0 then xyouts, xarcs[i]+35.0, yarcs[i]+20.0+i*3.0, 'NRH '+string(freq, format='(I3)')+' MHz', /data, color=color
		endfor

		if j eq 0 then freqs = 'NRH '+string(freq, format='(I3)')+' MHz' else freqs = [freqs, 'NRH '+string(freq, format='(I3)')+' MHz']

	endfor	
	set_line_color
	;plots, [503., 690.], [-230, -70], color=6, thick=5
	;plots, [701.0, 649.], [-145., -105.], color=5, thick=5, psym=0




	;legend, reverse(freqs), psym=reverse(symbol), box=0, /bottom, /left, color=0, charsize=2.0

	tims = interpol(tcolors, colors, [0,50,100,150,200,250])
	tims = anytim(tims, /cc, /time, /trun)

	loadct, 39, /silent
	cgcolorbar, range = [0, 255], $
			ticknames = tims, $
			/vertical, $
			/right, $
			color=0, $
			charsize=1.5, $
			pos = [0.82, 0.15, 0.83, 0.85], $
			title = 'Time on 2014-Apr-18 (UT)';, $
			;FORMAT = '(e10.1)'
	
	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif	

END