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


pro cal_orfees_plot_gen_typeIII_0_zoom, save_orfees = save_orfees, postscript=postscript, time_marker=time_marker

	; First type III
	; Code to read and process DAM and Orfees together

	; If /save_orfees chosen, it will process and save Orfees dynamic spectrum. This uses slide_backsub on
	; Orfees, which takes ~5-20 mins depending on paramaters chosen.

	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	callisto_folder = '~/Data/2014_apr_18/radio/callisto/'
	freq0 = 20
	freq1 = 1000
	time0 = '20140418_123410'
	time1 = '20140418_123450'
	date_string = time2file(file2time(time0), /date)

	;------------------------------------;
	;			Window params
	if keyword_set(postscript) then begin 
		setup_ps, '~/orfees_callisto_typeIII_0_'+date_string+'.eps'
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
	;		   Orfees Spec
	;***********************************;	
	cd, orfees_folder
	restore, 'orf_'+date_string+'_bsubbed_minimum.sav', /verb
	orf_spec = orfees_struct.spec
	orf_time = orfees_struct.time
	orf_freqs = orfees_struct.freq

	restore, filename = 'orf_'+date_string+'_polarised.sav'
	orf_spec_pol = orfees_struct.spec

	restore, filename = 'orf_'+date_string+'_raw.sav'
	orf_spec_raw = orfees_struct.spec

	
	;***********************************;
	;		   Callisto Spec
	;***********************************;	

	callisto_file = findfile(callisto_folder + '*.fit')
	radio_spectro_fits_read, callisto_file[0], data, cal_time, cal_freqs
	cal_spec = constbacksub(data, /auto)


	;***********************************;
	;			   PLOT
	;***********************************;	

	loadct, 74, /silent
	reverse_ct

	;cal_spec = simple_pass_filter(cal_spec, cal_time, cal_freqs, /high_pass, /time_axis, smoothing=20)
	plot_spec, smooth(cal_spec, 1), cal_time, cal_freqs, [freq0, freq1], [time0, time1], scl0=-5.0, scl1=15.0
	plot_spec, orf_spec, orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.25, scl1=1.0

			
	if keyword_set(postscript) then begin 
		device, /close
		set_plot, 'x'
	endif	

STOP


END
