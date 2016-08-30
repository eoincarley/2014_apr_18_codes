pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=0.9
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=5, $
          ysize=5, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

pro manual_detection, date, ints, window, tonset, $
				onset_times = onset_times, plot_sep = plot_sep

	; manual_detection_linfit in a seperate .pro file is also an option here 

	;plot_sep_zoom = "utplot, date, ints, /noerase, /xs, /ys, yr = yzoom, xr=xzoom, /ylog, ytitle = 'Intensity (cm!U-2!N sr!U-1!N s!U-1!N MeV!U-1!N)', xticklen = 1.0, xgridstyle = 1.0, yticklen = 1.0, ygridstyle = 1.0, /normal"
	print, 'Choose approximate max: '
	cursor, t_local, i_local, /data

	; Choose 1 hr around this window.
	t0_zoom	= t_local - window	;2.0*60.*60.
	t1_zoom	= t_local + window	;5.0*60.*60.
	
	ints_zoom = ints[where(date ge t0_zoom and date le t1_zoom)]
	date_zoom = date[where(date ge t0_zoom and date le t1_zoom)]

	i_max = ints_zoom[ where(ints_zoom eq max(ints_zoom)) ]
	tonset = date_zoom[ where(ints_zoom eq max(ints_zoom)) ]
	set_line_color
	plots, tonset, i_max, /data, psym=2, symsize=3, color=4


END

pro cusum_detection, date, ints, average_window, $
			tonset, onset_times = onset_times, plot_sep = plot_sep

	; Cumulative sum quality-control scheme.
	; Outlined in Huttunen-Heikinmaa et al. (2005)

	set_line_color
	seconds = average_window	; 

	;junk = execute(plot_sep)
	tcenter = date[0]

	t0 = tcenter ;- minutes*60.0
	t1 = tcenter + 1.0

	t0_index = closest(date, t0)
	t1_index = closest(date, t1)  <  (n_elements(ints)-5)

	ints_sub = ints[t0_index:t1_index]
	time_sub = date[t0_index:t1_index]

	plots, time_sub, ints_sub, /data, color=5

	mu_a = mean( ints_sub )
	sig_a = stdev( ints_sub ) ;> 0.05*mu_a 	
	mu_d = mu_a + 2.0*sig_a
	k = (mu_d - mu_a)/(alog(mu_d) - alog(mu_a))
	if k gt 1.0 then h=1.0
	if k le 1.0 then h=2.0

	if ~isa(h) then h=1.0

	pass=1
	for j=1, n_elements(ints)-5 do begin

		sum = 0.0	;total(ints[0:j])
		sum = max([0, ints[j+1] - k + sum])
		
		plots, date[j], [sum], /data, psym=1, symsize=1, color=7

		if sum ge h then begin
			pass = [pass, 1] 
		endif else begin
			pass = 1
		endelse	
	
		num_points = 10.0
		; If thirty out of control points are found then detection is positive
		if n_elements(pass) ge num_points and (where(pass ne 1))[0] eq -1 then begin
			plots, date[j-num_points+5.], ints[j-num_points+5.], /data, psym=2, symsize=3, color=6
			print, 'Onset time: ' + anytim(date[j-num_points+5.], /cc)
			tonset = date[j-num_points+5.]
			BREAK
		endif
	
	endfor	


END

pro plot_spec, data, time, freqs, frange, trange, scl0=scl0, scl1=scl1
	

	print, 'Processing: '+string(freqs[0], format=string('(I4)')) + $
			' to ' + $
			string(freqs[n_elements(freqs)-1], format=string('(I4)'))+ ' MHz'

	trange = anytim(file2time(trange), /utim)

	;kernelSize = [2, 2]
	;kernel = REPLICATE(-1., kernelSize[0], kernelSize[1])
	;kernel[1, 1] = 8
	 
	; Apply the filter to the image.
	;data = CONVOL(data, kernel, $
	;  /CENTER, /EDGE_TRUNCATE)


	spectro_plot, data > (scl0) < (scl1), $
  				time, $
  				freqs, $
  				/xs, $
  				/ys, $
  				/ylog, $
  				ytitle='Frequency (MHz)', $
  				;title = 'Orfees and DAM', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = [ trange[0], trange[1] ], $
  				/noerase, $
  				position = [0.15, 0.15, 0.95, 0.95], $
  				xticklen = -0.016, $
  				yticklen = -0.015, $
  				;xticks=1
  				;xtickv=[anytim('2014-04-18T12:43', /utim)]
  				;xtickname=['2014-04-18T12:43']
  				;xtickformat='(A1)', $
  				xtitle = 'Time (UT)'

  	;axis, xaxis=0, xrange = [ trange[0], trange[1] ], xticks=2, xticklen = -0.012, $
  	;		xtickname=['12:42:50', '12:43', '12:44:30']
		
  	
END


pro dam_orfees_typeIII_find_drift, save_orfees = save_orfees, postscript=postscript, time_marker=time_marker

	; First type III
	; Code to read and process DAM and Orfees together

	; If /save_orfees chosen, it will process and save Orfees dynamic spectrum. This uses slide_backsub on
	; Orfees, which takes ~5-20 mins depending on paramaters chosen.

	dam_folder = '~/Data/2014_apr_18/radio/dam/'
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 140
	freq1 = 1000
	time0 = '20140418_123410'
	time1 = '20140418_123430'
	date_string = time2file(file2time(time0), /date)

	;------------------------------------;
	;			Window params
	if keyword_set(postscript) then begin 
		setup_ps, '~/orfees_dam_typeIII_0_'+date_string+'.eps'
	endif else begin
		loadct, 0
		reverse_ct
		window, 10, xs=800, ys=800, retain=2
		!p.charsize=1.5
		!p.thick=1
		!x.thick=1
		!y.thick=1
	endelse	

	;***********************************;
	;		Read and process DAM		
	;***********************************;

	cd, dam_folder
	restore, 'NDA_'+date_string+'_1051.sav', /verb
	dam_freqs = nda_struct.freq
	daml = nda_struct.spec_left
	damr = nda_struct.spec_right
	times = nda_struct.times

	restore, 'NDA_'+date_string+'_1151.sav', /verb
	daml = [daml, nda_struct.spec_left]
	damr = [damr, nda_struct.spec_right]
	times = [times, nda_struct.times]

	restore, 'NDA_'+date_string+'_1251.sav', /verb
	daml = [daml, nda_struct.spec_left]
	damr = [damr, nda_struct.spec_right]
	times = [times, nda_struct.times]
	
	dam_spec = damr + daml
	dam_time = times
	
	dam_tim0 = anytim(file2time(time0), /time_only, /trun, /yoh)
	dam_tim1 = anytim(file2time(time1), /time_only, /trun, /yoh)

	;dam_spec = slide_backsub(dam_spec, dam_time, 15.0*60.0, /minimum)	
	;dam_spec = smooth(dam_spec, 5)	
	
	dam_spec = alog10(dam_spec)
	dam_spec = constbacksub(dam_spec, /auto)

	;dam_spec = simple_pass_filter(dam_spec, dam_time, dam_freqs, /low_pass, /freq_axis, smoothing=20)


	;goto, skip_orfees
	;***********************************;
	;	   Read and process Orfees		
	;***********************************;	

	cd, orfees_folder
	if keyword_set(save_orfees) then begin
		orfees_file = findfile('*.fts')
		null = mrdfits(orfees_file[0], 0, hdr0)
		fbands = mrdfits(orfees_file[0], 1, hdr1)
		orf_freqs = [ fbands.FREQ_B1, $
					  fbands.FREQ_B2, $
					  fbands.FREQ_B3, $
					  fbands.FREQ_B4, $
					  fbands.FREQ_B5  ]
		nfreqs = n_elements(orf_freqs)		
		
		null = mrdfits(orfees_file[0], 2, hdr_bg, row=0)
		tstart = anytim(file2time(orfees_file[0]), /utim)
		
		;-------------------------------------;
		;	   Choose/build time range
		;-------------------------------------;

		t0 = anytim(file2time(time0), /utim)
		t1 = anytim(file2time(time1), /utim)
		inc0 = (t0 - tstart)*10.0 	;Sampling time is 0.1 seconds
		inc1 = (t1 - tstart)*10.0 	;Sampling time is 0.1 seconds
		range = [inc0, inc1]
		data = mrdfits(orfees_file[0], 2, hdr2, range = range)
		
		tstart = anytim(file2time(date_string+'_000000'), /utim)
		time_b1 = tstart + data.TIME_B1/1000.0
		time_b2 = tstart + data.TIME_B2/1000.0 
		time_b3 = tstart + data.TIME_B3/1000.0 
		time_b4 = tstart + data.TIME_B4/1000.0 
		time_b5 = tstart + data.TIME_B5/1000.0 
	
		;-------------------------------------;
		;		    STOKES I data	
		;-------------------------------------;

		orf_spec = transpose([data.stokesi_b1, data.stokesi_b2, data.stokesi_b3, data.stokesi_b4, data.stokesi_b5])
		orf_spec = reverse(orf_spec, 2)
		orf_time = time_b1

		orfees_struct = {name:'orfees_'+date_string+'_raw', $
						spec:orf_spec, $
						time:orf_time, $
						freq:orf_freqs, $
						hdr:hdr2}

		save, orfees_struct, filename = 'orf_'+date_string+'_raw.sav', $
			description='Orfees raw data.'				

		;-------------------------------------;
		;  STOKES I Background Subtract Data	
		;-------------------------------------;

		orf_spec = slide_backsub(orf_spec, time_b1, 10.0*60.0, /minimum)	
		
		orfees_struct = {name:'orfees_'+date_string+'_bsubbed', $
						spec:orf_spec, $
						time:orf_time, $
						freq:orf_freqs, $
						hdr:hdr2}

		save, orfees_struct, filename = 'orf_'+date_string+'_bsubbed_minimum.sav', $
			description='Data produced using sliding 5 minute background. Data is logged.'


		;-------------------------------------;
		;		    STOKES V data	
		;-------------------------------------;

		orf_spec_pol = transpose([data.stokesv_b1, data.stokesv_b2, data.stokesv_b3, data.stokesv_b4, data.stokesv_b5])
		orf_spec_pol = reverse(orf_spec_pol, 2)	

		orfees_struct = {name:'orfees_'+date_string+'_polarised', $
						spec:orf_spec_pol, $
						time:orf_time, $
						freq:orf_freqs, $
						hdr:hdr2}

		save, orfees_struct, filename = 'orf_'+date_string+'_polarised.sav', $
			description='Polarisation data. No background subtraction.'

	endif else begin

		restore, 'orf_'+date_string+'_bsubbed_minimum.sav', /verb
		orf_spec = orfees_struct.spec
		orf_time = orfees_struct.time
		orf_freqs = orfees_struct.freq

		restore, filename = 'orf_'+date_string+'_polarised.sav'
		orf_spec_pol = orfees_struct.spec

		restore, filename = 'orf_'+date_string+'_raw.sav'
		orf_spec_raw = orfees_struct.spec

	endelse
	
	;***********************************;
	;			   PLOT
	;***********************************;	

	loadct, 74, /silent
	reverse_ct
	plot_spec, smooth(dam_spec, 1), dam_time, dam_freqs, [freq0, freq1], [time0, time1], scl0=0.0, scl1=0.6
	plot_spec, smooth(orf_spec, 5), orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.25, scl1=1.0


	loadct, 0	
	window, 20, xs=700, ys=700, xpos=1000, ypos=1000

	freqs = reverse(orf_freqs)
	trange = anytim(file2time([time0, time1]), /utim)


	for i=160, 280, 5 do begin
		index = closest(freqs, i)
		print, index
		flux = orf_spec[*, index]

		tindex = where(orf_time ge trange[0] and orf_time le trange[1])
		flux = 10.0^flux[tindex]
		times = orf_time[tindex]

		
		utplot, times, flux, $
				/xs, $
				/ys, $
				xrange = [ trange[0], trange[1] ], $
				/ylog, $
				title = 'Frequency: '+string(freqs[index])+' (MHz)'


		cusum_detection, times, flux, 10.0, $
					tonset, onset_times=onset_times

		;manual_detection, times, flux, 2.0, $
	;				tonset, onset_times=onset_times	

		if ISA(onset_times) eq 0 then begin
			onset_times = tonset
			onset_freqs = freqs[index]
		endif

		;time_diff = (onset_times[n_elements(onset_times)-1] - tonset)
		if ISA(onset_times) ne 0 then begin ;time_diff ne 0.0 then begin ;and time_diff lt 1.5*60.0*60.0 then begin
			onset_times = [onset_times, tonset]
			onset_freqs = [onset_freqs, freqs[index] ]
		endif	
	endfor
	
	wset, 10
	loadct, 74, /silent
	reverse_ct
	plot_spec, smooth(dam_spec, 1), dam_time, dam_freqs, [freq0, freq1], [time0, time1], scl0=0.0, scl1=0.6
	plot_spec, smooth(orf_spec, 5), orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.25, scl1=1.0

	set_line_color
	plots, onset_times, onset_freqs, psym=1, color=4


	onset_freqs = reverse(onset_freqs)
	onset_times = reverse(onset_times)
	times_sec = onset_times - onset_times[0]
	good = where(times_sec lt 1.0 and times_sec ge 0.05)
	times_sec = [ 0.0, times_sec[good] ]
	onset_freqs = [ 280.0, onset_freqs[good] ]


	loadct, 0
	window, 21, xs=700, ys=700, xpos=1100, ypos=1100
	


	plot, times_sec, onset_freqs, $
		 /xs, $
		 /ys, $
		 xr=[-0.1, 1.0], $
		 psym=4, $
		 yr=[290, 140], $
		 xtitle='Time (s)', $
		 ytitle='Freqyency (MHz)'

	oplot, times_sec, onset_freqs	 

	result = linfit(times_sec, onset_freqs, yfit=yfit)	 

	oplot, times_sec, yfit, linestyle=1

	onset_times = times_sec + onset_times[0]
	radio_drift = {name:'typeIII_00_drift_20140418', times:onset_times, freqs:onset_freqs}

	cd, '~/Data/2014_apr_18/radio/kinematics/type_III/'
	save_file0 = 'typeIII_00_drift_20140418.sav'	
	save, radio_drift, filename=save_file0
			
	if keyword_set(postscript) then begin 
		device, /close
		set_plot, 'x'
	endif	

STOP



END
