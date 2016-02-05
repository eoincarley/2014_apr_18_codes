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

pro nrh_plot_xy_motion, postscript=postscript

	loadct, 0, /silent
	cd,'~/Data/2014_apr_18/radio/nrh/clean_wresid/'
	if keyword_set(postscript) then begin
		setup_ps, 'nrh_source_motion.eps'
	endif else begin
		window, 0, xs=700, ys=700, retain=2
		!p.charsize=1.5
	endelse	
	
	motion_files = findfile('~/Data/2014_apr_18/radio/nrh/nrh*src*motion.sav')
	image_file = findfile('*.fts')
	AU = 149e6	;  km

	;---------------------------------;
	;		First plot the image
	;

	tstart = anytim(file2time('20140418_125310'), /utim)
	tstop = anytim(file2time('20140418_125440'), /utim) 	
	t0str = anytim(tstart, /yoh, /trun, /time_only)

	read_nrh, image_file[8], $
			  nrh_hdr, $
			  nrh_data, $
			  hbeg=t0str;, $ 
			  ;hend=t1str
			
	index2map, nrh_hdr, nrh_data, $
			   nrh_map  
				
	nrh_str_hdr = nrh_hdr
	nrh_times = nrh_hdr.date_obs
	freq = nrh_hdr.FREQ		

	;------------------------------------;
	;			Plot Total I
	;
	data = nrh_map.data
	data[*] = 240
	nrh_map.data = data
	FOV = [7, 7]
	CENTER = [750, -250]

	plot_map, nrh_map, $
		fov = FOV, $
		center = CENTER, $
		dmin = 0, $
		dmax = 300, $
		title=' ', $
		pos = [0.1, 0.15, 0.8, 0.95]
		  
	plot_helio, nrh_times, $
				/over, $
				gstyle=1, $
				gthick=3.0, $
				gcolor=1, $
				grid_spacing=15.0

	loadct, 39
			
	t1_colors = anytim(file2time('20140418_124830'), /utim)
	t2_colors = anytim(file2time('20140418_125650'), /utim)

	ncols = 250
	tcolors = (findgen(ncols )*(t2_colors - t1_colors)/(ncols -1) )+ t1_colors
	colors = findgen(ncols ) + 1			

	symbol = [1,2,4,5,6,7]
	motion_files = reverse(motion_files)
	
	for j=0, n_elements(motion_files)-1 do begin
		restore, motion_files[j], /verb
		
		xarcs = xy_arcs_struct.xarcs
		yarcs = xy_arcs_struct.yarcs
		times = xy_arcs_struct.times
		freq = xy_arcs_struct.freq

		sym = symbol[j]
		
		step=30		; This step size (or 30) produces a speed that mathces what it should be e.g., 
					; simply taking the first and last points as displacements and a time of 500 seconds gives ~360 km/s
		for i=0, n_elements(xarcs)-(step+1), step do begin
			
				color = interpol(colors, tcolors, anytim(times[i], /utim))
				plots, xarcs[i], yarcs[i], color=color, psym=sym, symsize=1.2
			
				x1 = xarcs[i]
				x2 = xarcs[i+step]
				y1 = yarcs[i]
				y2 = yarcs[i+step]
				dt = anytim(times[i+step], /utim) - anytim(times[i], /utim)

				displ_arcs = sqrt( (x2-x1)^2 + (y2-y1)^2 )
				displ_degs = displ_arcs/3600.0
				displ = AU*tan(displ_degs*!dtor)	;km

				if j eq 0 and i eq 0 then begin
					displs = displ 
					times_tot = times[i] 
				endif else begin

					if times[i] gt times_tot[n_elements(times_tot)-1] then begin
						displs = [displs, displs[n_elements(displs)-1]+displ]
						times_tot = [times_tot, times[i]]
					endif
						
				endelse	

			;wait, 0.1
		endfor	 


		if j eq 0 then freqs = 'NRH '+string(freq, format='(I3)')+' MHz' else freqs = [freqs, 'NRH '+string(freq, format='(I3)')+' MHz']
		
	endfor	

	set_line_color
	legend, reverse(freqs), psym=reverse(symbol), box=0, /bottom, /left, color=0, charsize=1.5

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

	window, 1, xs=600, ys=600
	utplot, times_tot, displs, $
			ytitle='Displacement (km)', $
			linestyle=0

	tims_sec = anytim(times_tot, /utim) - anytim(times_tot[0], /utim)		
	result = linfit(tims_sec, displs, yfit=yfit)

	q = replicate({fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
	;q(2).fixed = 1

	err = displs
	err[*] = 50.0*727. ;150 arcsecs is the approximate size of the source in the images. Multiple by 727 km (km per arcsec)
	start = [0, 200]
	fit = 'p[1]*x + p[0]'			
	
	p = mpfitexpr(fit, tims_sec, displs, err, perror=perror, yfit=yfit, start);, parinfo=q)

	outplot, times_tot, yfit, linestyle=1

	print, 'Speed: '+string(p[1]) +' '+ string(perror[1])

	stop
END