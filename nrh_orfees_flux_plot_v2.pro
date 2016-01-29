pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.0
   !p.thick=4
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=8, $
          ysize=3, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end



pro nrh_orfees_flux_plot_v2, frequency, postscript=postscript

	if keyword_set(postscript) then begin
		setup_ps, '~/nrh_orfees_flux_'+string(frequency, format='(I03)')+'.eps'
	endif else begin
		loadct, 0
		!p.background=255
		!p.color=0
		!p.thick=1
		!p.multi=[0,1,1]
		!p.charsize=1.0
		window, 12, xs=700, ys=400
	endelse

		time0 = '20140418_124800'
		time1 = '20140418_125800'
		date_string = time2file(file2time(time0), /date)
		orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
		nrh_folder = '~/Data/2014_apr_18/radio/nrh/'

		t0plot = anytim(file2time(time0), /utim)
		t1plot = anytim(file2time(time1), /utim)


		;***********************************;
		;			 Orfees Flux		
		;***********************************;	

		restore, orfees_folder+'orf_'+date_string+'_bsubbed_minimum.sav', /verb
		orf_spec = orfees_struct.spec
		orf_time = orfees_struct.time
		orf_freqs = reverse(orfees_struct.freq)
		t_index = where(orf_time gt t0plot and orf_time lt t1plot)
		orf_time = orf_time[t_index]
	 

		index = closest(orf_freqs, frequency)
		orf_frequency_str = string(round(orf_freqs[index]), format='(I03)')
		orfees_flux = smooth(orf_spec[t_index, index],3)
		;orfees_flux = orfees_flux/max(orfees_flux)


		set_line_color
		utplot, orf_time, orfees_flux/max(orfees_flux), $
				/xs, $
				/ys, $
				xr = [t0plot, t1plot], $
				linestyle=0, $
				;yr=[0.0, 1.0], $
				;/ylog, $
				color=0;, $;, $
				;pos = [0.15, 0.12, 0.95, 0.45], $
				;/noerase, $
				;title='Orfees', $
		;		xgridstyle = 1.0, $
		;		ygridstyle = 1.0, $
		;		ytitle='Normalised flux';, $
		;		XTICKFORMAT="(A1)";, $
				;xtitle=' '
		

		;***********************************;
		;			  NRH Flux		
		;***********************************;	



		nrh_flux_file = 'nrh_flux_'+string(frequency, format='(I03)')+'_20140418_src1.sav'
		print, 'Reading '+nrh_flux_file 
		restore, nrh_folder + nrh_flux_file, /verb
		time = anytim(SFU_TIME_STRUCT.time, /utim)
		flux = alog10(SFU_TIME_STRUCT.flux)
		flux1 = flux/max(flux)
		
		index_src1 = where(time le anytim('2014-04-18T12:53:30', /utim))
		outplot, time[index_src1], flux1[index_src1], $
				color=3

		if frequency eq 432. then begin
			; After this time the source changes position, not active region source anymore
			index_src3 = where(time ge anytim('2014-04-18T12:53:30', /utim))
			outplot, time[index_src3], flux1[index_src3], $
				color=3, $
				thick=4, $
				linestyle=2

		endif		
		

		lag = [0]
		result = C_CORRELATE(congrid(orfees_flux, 540), congrid(flux1, 540), lag, /cov)		
		print, '---------------------'	
		print, 'C correlation flux 1: '+string( max(result)	)
		print, '---------------------'	

		nrh_flux_file = 'nrh_flux_'+string(frequency, format='(I03)')+'_20140418_src2.sav'
		print, 'Reading '+nrh_flux_file 
		restore, nrh_folder + nrh_flux_file, /verb
		time = anytim(SFU_TIME_STRUCT.time, /utim)
		flux = alog10(SFU_TIME_STRUCT.flux>0)			
		flux2 = flux/max(flux)
		remove_nans, flux2, flux2

		outplot, time, flux2, $
				color=5, $
				linestyle=3		

		result = C_CORRELATE(congrid(orfees_flux, 540), congrid(flux2, 540), lag, /cov)			
		print, '---------------------'	
		print, 'C correlation flux 2: '+string( max(result)	)		
		print, '---------------------'						
						
		freq_str = string(SFU_TIME_STRUCT.freq, format='(I03)')
		;xyouts, 0.12, 0.92, 'NRH '+freq_str+' MHz', color=0, /normal, charsize=0.8
		;xyouts, 0.12, 0.90, 'Orf AR src '+orf_frequency_str+' MHz', color=3, /normal, charsize=0.8
		;xyouts, 0.12, 0.88, 'Orf moving source' +orf_frequency_str+' MHz', color=5, /normal, charsize=0.8
					

	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif					

END