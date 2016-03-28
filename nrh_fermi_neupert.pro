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

;********************
pro plot_fermi, date_start, date_end


	FermiGBM_file= '~/Data/2014_apr_18/fermi/fermi_ctime_n0_20140418_v00.sav'   

	restore, FermiGBM_file

	tims = anytim(ut, /utim)
	;counts_orig = (smooth(binned[0,*], 50))
	counts = (smooth(binned[2,*], 10))
	counts = deriv(tims, counts)
	counts = smooth((counts+0.05), 10)		;min(counts)



	utplot, tims, (counts/max(counts)), $
			;/ylog, $
			yr=[0.1, 1.0], $
			;position=[0.15, 0.15, 0.95, 0.95], $
			linestyle=0, $
			;thick=0.5, $
			xtitle=' ', $
			XTICKFORMAT="(A1)", $
			YTICKFORMAT="(A1)", $
			xticklen=-0.001, $
			yticklen=-0.001, $
			/noerase, $
			/noyticks, $
			timerange=[date_start, date_end], $
			;ytitle='counts [s!u-1!n cm!u-2!n keV!u-1!n]', $
			ytitle=' ', $
			/xs, $
			/ys, $
			color=4

	;for k=1,3 do outplot, anytim(ut, /utim), binned[k,*], col=k+2


END

pro plot_RHESSI, t0, t1

	search_network, /enable		; To enable online searches
	use_network

	t0_rhessi = anytim(t0, /atimes)
	t1_rhessi = anytim(t1, /atimes)

	obj = hsi_obs_summary()
	obj -> set, obs_time_interval=[t0_rhessi, t1_rhessi]
	d1 = obj -> getdata()
	data = d1.countrate
	times_rate = obj -> getaxis(/ut) 

	set_line_color
	plot_indeces = where(times_rate gt anytim('2014-04-18T12:48:00', /utim))

	counts = data[0, plot_indeces]

	utplot, times_rate[plot_indeces], counts/max(counts), $
			thick=1, $
			/xs, $ 
			/ys, $
			;/ylog, $
			xr=anytim([file2time(t0), file2time(t1)], /utim), $
			;yr = [1, 1e4], $
			;XTICKFORMAT="(A1)", $
			;xtitle=' ', $
			ytitle='Count Rate (s!U-1!N detector!U-1!N)', $
			color=6, $
			;pos = [0.11, 0.6, 0.95, 0.8], $
			/noerase, $
			/normal

	colors = [6,3,4,5,7,10];6,3,4,5];,7,8,10];,8,9,10, 0,2,3,4,5]		

	for i=1, n_elements(data[*, 0])-5,2 do begin
		counts = data[i, plot_indeces]
		outplot, times_rate[plot_indeces], counts/max(counts), $
			color = colors[i], $
			thick=1, $
			psym=10
	endfor			

	flags = obj -> getdata(class='flag')
	times = obj -> getaxis(/ut, class='flag')
	info = obj -> get(/info, class='flag')

	saa_index = where( (flags.flags)[0,*] eq 1)
	night_index = where( (flags.flags)[1,*] eq 1)

	night_time0 = times_rate[night_index[0]]
	night_time1 = times_rate[night_index[n_elements(night_index)-1]]

	vline, night_time0, color=10, thick=4
	vline, night_time1, linestyle=2, color=10, thick=4
	;plots, [night_time0, night_time1], [7000, 7000], color=10, thick=4

	saa_time0 = times_rate[saa_index[0]]
	saa_time1 = times_rate[saa_index[n_elements(saa_index)-1]]

	vline, saa_time0-60*4.0, color=9, thick=5
	;vline, saa_time1-60*5.0, color=6, thick=4
	;plots, [saa_time0-60*4.0, saa_time1], [7000, 7000], color=9, thick=5

	i1 = obj->get(/info)
	energies = i1.energy_edges

	energies_str = strcompress(string(energies, format='(I5)'))
	energies_legend = [ energies_str[0]+' -'+energies_str[1] + ' keV', $
						energies_str[1]+' -'+energies_str[2] + ' keV', $
						energies_str[2]+' -'+energies_str[3] + ' keV', $
						energies_str[3]+' -'+energies_str[4] + ' keV', $
						energies_str[4]+' -'+energies_str[5] + ' keV', $
						energies_str[5]+' -'+energies_str[6] + ' keV', $
						energies_str[6]+' -'+energies_str[7] + ' keV', $
						energies_str[7]+' -'+energies_str[8] + ' keV', $
						energies_str[8]+' -'+energies_str[9] + ' keV' ]
					

	xyouts, 0.14, 0.777, 'RHESSI', /normal, charsize=0.8					
						
	legend, energies_legend[0:4], $
			color = colors[0:4], $
			linestyle = intarr(5), $
			box=0, $
			charsize=0.8, $
			pos = [0.12, 0.775], $
			/normal, $
			thick=3

	xyouts, 0.925, 0.77, 'b', /normal				

END


pro nrh_fermi_neupert, frequency, postscript=postscript

	; This code plots flux v time for flux comparison figure in 2014-04-18 paper.

	; Modification of nrh_orfees_flux_plot_v2.pro

	if keyword_set(postscript) then begin
		setup_ps, '~/nrh_orfees_fermi_flux_'+string(frequency, format='(I03)')+'.eps'
	endif else begin
		loadct, 0
		!p.background=255
		!p.color=0
		!p.thick=1
		!p.multi=[0,1,1]
		!p.charsize=1.0
		window, 12, xs=700, ys=400
	endelse

		time0 = '20140418_124900'
		time1 = '20140418_125000'
		date_string = time2file(file2time(time0), /date)
		orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
		nrh_folder = '~/Data/2014_apr_18/radio/nrh/'

		t0plot = anytim(file2time(time0), /utim)
		t1plot = anytim(file2time(time1), /utim)

		;***********************************;
		;			 Orfees Flux		
		;***********************************;	

		restore, orfees_folder+'orf_'+date_string+'_bsubbed_minimum.sav', /verb
		orf_spec = simple_pass_filter(orfees_struct.spec, orfees_struct.time, $
					orfees_struct.freq, /time, /high_pass, smooth=100)
		

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
				yr=[0.0, 1.0], $
				;/ylog, $
				color=0;, $;, $
				;pos = [0.15, 0.12, 0.95, 0.45], $
				;/noerase, $
				;title='Orfees', $
		;		xgridstyle = 1.0, $
		;		ygridstyle = 1.0, $
		;		ytitle='Normalised flux';, $
				;XTICKFORMAT="(A1)", $
				;xtitle=' '
		
plot_fermi, t0plot, t1plot
		;***********************************;
		;			  NRH Flux		
		;***********************************;	

STOP

		nrh_flux_file = 'nrh_flux_'+string(frequency, format='(I03)')+'_20140418_src1.sav'
		print, 'Reading '+nrh_flux_file 
		restore, nrh_folder + nrh_flux_file, /verb
		time = anytim(SFU_TIME_STRUCT.time, /utim)
		flux = (SFU_TIME_STRUCT.flux)
		flux1 = flux/max(flux)
		

		if frequency gt 430. then begin

			index_src1 = where(time le anytim('2014-04-18T12:53:30', /utim))
			outplot, time[index_src1], flux1[index_src1], $
				color=3
			; After this time the source changes position, not active region source anymore
			index_src3 = where(time ge anytim('2014-04-18T12:53:30', /utim))
			outplot, time[index_src3], flux1[index_src3], $
				color=3, $
				thick=4, $
				linestyle=2

		endif else begin
			outplot, time, flux1, $
				color=3
		endelse		
		

		lag = [0]
		result = C_CORRELATE(congrid(orfees_flux, 540), congrid(flux1, 540), lag, /cov)		
		print, '---------------------'	
		print, 'C correlation flux 1: '+string( max(result)	)
		print, '---------------------'	

		nrh_flux_file = 'nrh_flux_'+string(frequency, format='(I03)')+'_20140418_src2.sav'
		print, 'Reading '+nrh_flux_file 
		restore, nrh_folder + nrh_flux_file, /verb
		time = anytim(SFU_TIME_STRUCT.time, /utim)
		flux = (SFU_TIME_STRUCT.flux>0)			
		flux2 = flux/max(flux)
		remove_nans, flux2, flux2

		;outplot, time, flux2, $
	;			color=5, $
;				linestyle=3		

		result = C_CORRELATE(congrid(orfees_flux, 540), congrid(flux2, 540), lag, /cov)			
		print, '---------------------'	
		print, 'C correlation flux 2: '+string( max(result)	)		
		print, '---------------------'						
						
		freq_str = string(SFU_TIME_STRUCT.freq, format='(I03)')
		;xyouts, 0.12, 0.92, 'NRH '+freq_str+' MHz', color=0, /normal, charsize=0.8
		;xyouts, 0.12, 0.90, 'Orf AR src '+orf_frequency_str+' MHz', color=3, /normal, charsize=0.8
		;xyouts, 0.12, 0.88, 'Orf moving source' +orf_frequency_str+' MHz', color=5, /normal, charsize=0.8
					
		
		
		
		;axis, yaxis=1
		;plot_RHESSI, t0plot, t1plot

		xyouts, 0.125, 0.83, 'e', /normal, charsize=1.2
		xyouts, 0.85, 0.83, freq_str+' MHz', /normal, charsize=1.2



	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif					

END