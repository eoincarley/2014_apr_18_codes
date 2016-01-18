pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.2
   !p.thick=4
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



pro nrh_orfees_flux_plot_v2, frequency, postscript=postscript

	if keyword_set(postscript) then begin
		setup_ps, '~/nrh_orfees_flux_'+string(frequency, format='(I03)')+'.eps'
	endif else begin
		loadct, 0
		;!p.background=255
		;!p.color=0
		!p.thick=1
		;!p.multi=[0,1,1]
		;!p.charsize=1.0
		;window, 12, xs=700, ys=400
	endelse

		time0 = '20140418_124800'
		time1 = '20140418_125800'
		date_string = time2file(file2time(time0), /date)
		orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
		nrh_folder = '~/Data/2014_apr_18/radio/nrh/'

		t0plot = anytim(file2time(time0), /utim)
		t1plot = anytim(file2time(time1), /utim)

		restore, orfees_folder+'orf_'+date_string+'_bsubbed_minimum.sav', /verb
		orf_spec = orfees_struct.spec
		orf_time = orfees_struct.time
		orf_freqs = reverse(orfees_struct.freq)

	 	;hfreq_img = orf_spec - smooth(orf_spec, 20)
	    ;orf_spec = orf_spec + 3.5*hfreq_img

		index = closest(orf_freqs, frequency)
		orf_frequency_str = string(round(orf_freqs[index]), format='(I03)')
		orfees_flux = orf_spec[*, index]


		set_line_color
		utplot, orf_time, smooth(orfees_flux/max(orfees_flux), 5), $
				/xs, $
				/ys, $
				xr = [t0plot, t1plot], $
				yr=[0.0, 1.0], $
				;/ylog, $
				color=0, $
				pos = [0.15, 0.12, 0.95, 0.45], $
				/noerase, $
				;title='Orfees', $
				xgridstyle = 1.0, $
				ygridstyle = 1.0, $
				ytitle='Normalised flux';, $
				;XTICKFORMAT="(A1)", $
				;xtitle=' '

		;***********************************;
		;			  NRH Flux		
		;***********************************;	

		nrh_flux_file = 'nrh_flux_'+string(frequency, format='(I03)')+'_20140418_src1.sav'
		print, 'Reading '+nrh_flux_file 
		restore, nrh_folder + nrh_flux_file, /verb
		time = anytim(SFU_TIME_STRUCT.time, /utim)
		flux = alog10(SFU_TIME_STRUCT.flux)
		
		outplot, time, smooth(flux/max(flux), 2), $
						color=3


		nrh_flux_file = 'nrh_flux_'+string(frequency, format='(I03)')+'_20140418_src2.sav'
		print, 'Reading '+nrh_flux_file 
		restore, nrh_folder + nrh_flux_file, /verb
		time = anytim(SFU_TIME_STRUCT.time, /utim)
		flux = alog10(SFU_TIME_STRUCT.flux>0)			


		outplot, time, flux/max(flux), $
						color=5					
						
		freq_str = string(SFU_TIME_STRUCT.freq, format='(I03)')
		xyouts, 0.16, 0.42, 'Orfees '+orf_frequency_str+' MHz', color=0, /normal, charsize=0.8
		xyouts, 0.16, 0.40, 'NRH '+freq_str+' MHz', color=3, /normal, charsize=0.8
					

	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif					

END