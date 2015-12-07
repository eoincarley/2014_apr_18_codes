pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.2
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=9, $
          ysize=12, $
          /encapsulate, $
          yoffset=5, $
          bits_per_pixel = 16

end

pro plot_spec, data, time, freqs, frange, trange, scl0=scl0, scl1=scl1
	

	print, 'Processing: '+string(freqs[0], format=string('(I4)')) + $
			' to ' + $
			string(freqs[n_elements(freqs)-1], format=string('(I4)'))+ ' MHz'

	trange = anytim(file2time(trange), /utim)
	spectro_plot, smooth(data,1) > (scl0) < (scl1), $
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
  				position = [0.11, 0.05, 0.95, 0.4], $
  				xticklen = -0.012, $
  				yticklen = -0.015
		
  	
END


;**********************************************;
;				Plot GOES

pro plot_goes, t1, t2

		x1 = anytim(file2time(t1), /utim)
		x2 = anytim(file2time(t2), /utim)
		
		;--------------------------------;
		;			 Xray
		file = findfile('~/Data/2014_apr_18/goes/20140418_Gp_xr_1m.txt')
		goes = read_goes_txt(file[0])
	
		set_line_color
		utplot, goes[0,*], goes[1,*], $
				thick = 1, $
				;tit = '1-minute GOES-15 Solar X-ray Flux', $
				ytit = 'Watts m!U-2!N', $
				xtit = ' ', $
				color = 3, $
				xrange = [x1, x2], $
				XTICKFORMAT="(A1)", $
				/xs, $
				yrange = [1e-9,1e-3], $
				/ylog, $
				position = [0.11, 0.8, 0.95, 0.98], $
				/normal, $
				/noerase
				
		outplot, goes[0,*], goes[2,*], color=5	
		
		axis, yaxis=1, ytickname=[' ','A','B','C','M','X',' ']
		axis, yaxis=0, yrange=[1e-9, 1e-3]
		
		i1 =  closest(goes[0,*], x1)
		i2 = closest(goes[0,*], x2)
		plots, goes[0, i1:i2], 1e-8
		plots, goes[0, i1:i2], 1e-7
		plots, goes[0, i1:i2], 1e-6
		plots, goes[0, i1:i2], 1e-5
		plots, goes[0, i1:i2], 1e-4
				
		legend, ['GOES15 0.1-0.8nm','GOES15 0.05-0.4nm'], $
				linestyle=[0,0], $
				color=[3,5], $
				box=0, $
				pos = [0.12, 0.975], $
				/normal, $
				charsize=0.8, $
				thick=3

END


function read_goes_txt, file

	readcol, file, y, m, d, hhmm, mjd, sod, short_channel, long_channel
	
	;-------- Time in correct format --------
	time  = strarr(n_elements(y))
	
	time[*] = string(y[*], format='(I04)') + string(m[*], format='(I02)') $
	  + string(d[*], format='(I02)') + '_' + string(hhmm[*], format='(I04)')
	    
	time = anytim(file2time(time), /utim) 
	
	;------- Build data array --------------

	goes_array = dblarr(3, n_elements(y))
	goes_array[0,*] = time
	goes_array[1,*] = long_channel
	goes_array[2,*] = short_channel
	return, goes_array

END

;**********************************************;
;				Plot RHESSI

pro plot_RHESSI, t0, t1

	search_network, /enable		; To enable online searches
	use_network

	t0_rhessi = anytim(file2time(t0), /atimes)
	t1_rhessi = anytim(file2time(t1), /atimes)

	obj = hsi_obs_summary()
	obj -> set, obs_time_interval=[t0_rhessi, t1_rhessi]
	d1 = obj -> getdata()
	data = d1.countrate
	times_rate = obj -> getaxis(/ut) 

	set_line_color
	utplot, times_rate, data[0, *], $
			thick=3, $
			/xs, $ 
			/ys, $
			/ylog, $
			yr = [1, 1e4], $
			XTICKFORMAT="(A1)", $
			xtitle=' ', $
			ytitle='Count Rate (s!U-1!N detector!U-1!N)', $
			color=0, $
			pos = [0.11, 0.6, 0.95, 0.8], $
			/noerase, $
			/normal

	for i=1, n_elements(data[*, 0])-1 do begin
		counts = data[i, *]
		outplot, times_rate, counts, $
			color = i+1, $
			thick=3
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
	plots, [night_time0, night_time1], [7000, 7000], color=10, thick=4

	saa_time0 = times_rate[saa_index[0]]
	saa_time1 = times_rate[saa_index[n_elements(saa_index)-1]]

	vline, saa_time0, color=6, thick=4
	vline, saa_time1, color=6, thick=4
	plots, [saa_time0, saa_time1], [7000, 7000], color=6, thick=4

	i1 = obj->get(/info)
	energies = i1.energy_edges
	colors = [0,2,3,4,5,6,7,8,9,10]


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
						
	legend, energies_legend, $
			color = colors, $
			linestyle = intarr(9), $
			box=0, $
			charsize=0.8, $
			pos = [0.12, 0.77], $
			/normal, $
			thick=3

END

;********************
pro plot_fermi, date_start, date_end


	FermiGBM_file= '~/Data/2014_apr_18/fermi/fermi_ctime_n0_20140418_v00.sav'   

	restore, FermiGBM_file

	utplot, anytim(ut, /utim), binned[0,*], $
			/ylog, $
			yrange=[1.e-4, 1.e4], $
			position=[0.11, 0.4, 0.95, 0.6], $
			;/nolabel, $
			xtitle=' ', $
			XTICKFORMAT="(A1)", $
			/noerase, $
			timerange=[date_start, date_end], $
			ytitle='counts [s!u-1!n cm!u-2!n keV!u-1!n]', $
			/xs, $
			color=6

	for k=1,3 do outplot, anytim(ut, /utim), binned[k,*], col=k+2

	eband_str = string(eband[0,*], format='(f5.1)')

	legend, [eband_str[0]+' keV', eband_str[1]+' keV', eband_str[2]+' keV', eband_str[3]+' keV'], $
			color = [6,3,4,5], $
			linestyle = [0,0,0,0], $
			box=0, $
			charsize=0.8, $
			pos = [0.77, 0.58], $
			/normal, $
			thick=3

	xyouts, 0.79, 0.585, 'FERMI GBM', /normal, charsize=0.8

END


pro goes_dam_orfees, postscript=postscript

	;------------------------------------;
	;			Window params
	;
	loadct, 0
	reverse_ct
	cd,'~/Data/2014_apr_18/
	dam_folder = '~/Data/2014_apr_18/radio/dam/'
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'
	freq0 = 10
	freq1 = 1000
	time0 = '20140418_122500'
	time1 = '20140418_132000'
	date_string = time2file(file2time(time0), /date)

	if keyword_set(postscript) then begin
		setup_ps, 'goes_rhessi_fermi_dam_orfees_20140418.eps
	endif else begin	
		loadct, 0
		window, xs=900, ys=1200, retain=2
		!p.charsize=1.5
	endelse			

		;***********************************;
		;			Plot GOES		
		;***********************************;
		set_line_color
		plot_goes, time0, time1


		;***********************************;
		;			Plot RHESSI		
		;***********************************;

		plot_RHESSI, time0, time1

		;***********************************;
		;			Plot FERMI		
		;***********************************;
		plot_fermi, anytim(file2time(time0), /utim), anytim(file2time(time1), /utim)


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

			;dam_spec = slide_backsub(dam_spec, dam_time, 10.0*60.0, /average)	
		dam_spec = constbacksub(dam_spec, /auto)


		;***********************************;
		;	Read and pre-processed Orfees		
		;***********************************;	

		restore, orfees_folder+'orf_'+date_string+'_bsubbed_minimum.sav', /verb
		orf_spec = orfees_struct.spec
		orf_time = orfees_struct.time
		orf_freqs = orfees_struct.freq


		;skip_orfees: print, 'Skipped Orfees.'
		;***********************************;
		;			   PLOT
		;***********************************;	

		loadct, 74, /silent
		reverse_ct
		scl_lwr = -0.4				;Lower intensity scale for the plots.

		plot_spec, dam_spec, dam_time, dam_freqs, [freq0, freq1], [time0, time1], scl0=-30, scl1=150
		
		plot_spec, orf_spec, orf_time, reverse(orf_freqs), [freq0, freq1], [time0, time1], scl0=-0.1, scl1=1.2
		
	
	
	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif

;	x2png,'dam_orfees_burst_20140418.png'
	

END

