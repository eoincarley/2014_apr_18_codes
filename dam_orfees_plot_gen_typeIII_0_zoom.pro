pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.0
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=2, $
          ysize=5, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

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
  				xtitle = ' '

  	;axis, xaxis=0, xrange = [ trange[0], trange[1] ], xticks=2, xticklen = -0.012, $
  	;		xtickname=['12:42:50', '12:43', '12:44:30']
		
  	
END


pro dam_orfees_plot_gen_typeIII_0_zoom, save_orfees = save_orfees, postscript=postscript, time_marker=time_marker

	; First type III
	; Code to read and process DAM and Orfees together

	; If /save_orfees chosen, it will process and save Orfees dynamic spectrum. This uses slide_backsub on
	; Orfees, which takes ~5-20 mins depending on paramaters chosen.

	dam_folder = '~/Data/2014_apr_18/radio/dam/'
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 10
	freq1 = 1000
	time0 = '20140418_124200'
	time1 = '20140418_124600'
	date_string = time2file(file2time(time0), /date)

	;------------------------------------;
	;			Window params
	if keyword_set(postscript) then begin 
		setup_ps, '~/orfees_dam_'+date_string+'.eps'
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
	;		Read and plot GOES	
	;***********************************;
	;goes_file = '~/Data/2014_sep_01/goes/20140901_Gp_xr_1m.txt'
	;plot_goes_txt, time0, time1, goes_file

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
	;dam_spec = simple_pass_filter(dam_spec, dam_time, dam_freqs, /low_pass, /time_axis, smoothing=10)
	;dam_spec = smooth(dam_spec, 5)	
	
	dam_spec = alog10(dam_spec)
	dam_spec = constbacksub(dam_spec, /auto)


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
	
	;skip_orfees: print, 'Skipped Orfees.'
	;***********************************;
	;			   PLOT
	;***********************************;	

	loadct, 74, /silent
	reverse_ct

	data = orf_spec
	;orf_spec_high = simple_pass_filter(data, orf_time, orf_freqs, /high_pass, /time_axis, smoothing=50)

	;orf_spec = orf_spec + 0.5*orf_spec_high

	plot_spec, smooth(dam_spec, 5), dam_time, dam_freqs, [freq0, freq1], [time0, time1], scl0=0.0, scl1=0.6
	plot_spec, smooth(orf_spec, 5), orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.25, scl1=0.7

	if keyword_set(time_marker) then begin
		!p.thick=4
		set_line_color

		; These times and frequencies are points taken a long the drift of the type IV radio burst.
		; They are used to produced the radio burst plot in Figure 4 of the overview paper
					;times = anytim('2014-04-18T'+ ['12:51:00.000', '12:51:10.000', '12:51:20.000', '12:53:09.000', '12:54:00.000', '12:56:10.000'], /utim)
					;freqs = [445.0, 432.0, 408.0, 327.0, 298.0, 270.0]
		
		times = anytim( '2014-04-18T' + ['12:49:30', '12:50:30', '12:51:45', '12:52:50', '12:53:10'], /utim )
		freqs = [298.0, 327.0, 432.0]

		plots, times, freqs[0], psym=1, symsize=1.5, thick=7, color=10, /data
		plots, times, freqs[0], psym=1, symsize=1.0, thick=1, color=0, /data

		plots, times, freqs[1], psym=1, symsize=1.5, thick=7, color=6, /data
		plots, times, freqs[1], psym=1, symsize=1.0, thick=1, color=0, /data

		plots, times, freqs[2], psym=1, symsize=1.5, thick=7, color=4, /data
		plots, times, freqs[2], psym=1, symsize=1.0, thick=1, color=0, /data


		time_line0 = anytim(file2time(time0), /utim)
		time_line1 = anytim(file2time(time1), /utim)
		;plots, [time_line0, time_line1], [150, 150], color=2, linestyle=2, /data
		;plots, [time_line0, time_line1], [173, 173], color=3, linestyle=2, /data
		;plots, [time_line0, time_line1], [228, 228], color=4, linestyle=2, /data
		;plots, [time_line0, time_line1], [270, 270], color=0, linestyle=2, /data
		;plots, [time_line0, time_line1], [298, 298], color=0, linestyle=2, /data
		;plots, [time_line0, time_line1], [327, 327], color=0, linestyle=2, /data
		;plots, [time_line0, time_line1], [408, 408], color=0, linestyle=2, /data
		;plots, [time_line0, time_line1], [432, 432], color=9, linestyle=2, /data
		;plots, [time_line0, time_line1], [445, 445], color=10, linestyle=2, /data

	endif	

			
	if keyword_set(postscript) then begin 
		device, /close
		set_plot, 'x'
	endif	

STOP

	;reverse_ct
	;window, 1, xs=600, ys=600, retain=2
	;!p.charsize=1.5
	;!p.thick=1
	;!x.thick=1
	;!y.thick=1

	;freq0 = 140
	;freq1 = 1000
	;loadct, 70
			;orf_spec_pol = slide_backsub(orf_spec_pol,  orf_time, 10.0*60.0, /minimum)	
			;orf_spec_pol = constbacksub(orf_spec_pol, /auto)
	;plot_spec, orf_spec_pol, orf_time, reverse(orf_freqs), $
	;			[freq0, freq1], $
	;			[time0, time1], $
	;			scl0=-50, $
	;			scl1=50
	
	;window, 2, xs=500, ys=500
	;plothist, (orf_spec_pol/orf_spec_raw)*100.0, $
	;	/auto, $
	;	/ylog, $
	;	xr=[-10, 10], $
	;	yr=[1, 1e8], $
	;	xtitle = 'Circular Polarization (%)', $
	;	ytitle = 'Number of pixels'


	;print, max(orf_spec_pol)
	;print, min(orf_spec_pol)

END
