pro plot_spec, data, time, freqs, frange, bg, scl0=scl0, scl1=scl1
	
  bg = 10.0*alog10(bg)	
  data = 10.0*alog10(data)
  
  data = transpose(data)
  bg_spec = data
  FOR i = 0, n_elements(data[0,*])-1 DO bg_spec[*, i] = bg[i]
  
  data = data - bg_spec
  
  ;data = constbacksub(data, /auto)
  data = data/max(data)
  data = reverse(data, 2)
  ea = string(233B)
  ;wset,0
  spectro_plot, (data > (scl0) < scl1), $
  				time, $
  				reverse(freqs), $
  				/xs, $
  				/ys, $
  				/ylog, $
  				ytitle=' ', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = '2014-Apr-18 '+['12:40:00', '13:22:00'], $
  				xtitle = ' ', $
  				/noerase, $
  				position = [0.1, 0.1, 0.95, 0.95], $
  				xticklen = -0.01, $
  				yticklen = -0.01
  				
		
  	
END

pro setup_ps, name
  
  set_plot,'ps'
  !p.charsize=1.5
  device, filename = name, $
          /color, $
          /inches, $
          bits_per_pixel = 16, $
          xsize=11, $
          ysize=11, $
          /encapsulate, $
          yoffset=5

end

pro jazzy_dam_orfees_plot

  ; Jazzing up dam_orfees_plot for the solar group promo catalogue

	;------------------------------------;
	;			    Window params
	loadct, 0
	reverse_ct
	;window, xs=1100, ys=700, retain=2
	!p.charsize=0.2
	!p.thick = 0.5
	!x.thick = 0.5
	!y.thick = 0.5

	time0='20140418_124000'
	time1='20140418_132200'

	;***********************************;
	;			      Plot DAM		
	;***********************************;
	cd,'~/Data/2014_apr_18/radio/dam/'
	restore, 'NDA_20140418_1221_left.sav', /verb
	daml = spectro_l
	timl = tim_l
	
	restore, 'NDA_20140418_1251_left.sav', /verb
	daml = [daml, spectro_l]
	timl = [timl, tim_l]
	
	
	restore, 'NDA_20140418_1221_right.sav', /verb
	damr = spectro_r
	restore, 'NDA_20140418_1251_right.sav', /verb
	damr = [damr, spectro_r]
	
	dam_spec = damr + daml
	dam_tim = timl
	
	dam_tim0 = anytim(file2time(time0), /time_only, /trun, /yoh)
	dam_tim1 = anytim(file2time(time0), /time_only, /trun, /yoh)
	;dam_spec = constbacksub(dam_spec, /auto)
	;spectro_plot, dam_spec > (-10) < (140), dam_tim, freq, $
	;			/xs, $
	;			/ys, $
	;			ytitle = 'Frequency (MHz)', $
	;			xrange = '2014-Apr-18 '+[dam_tim0, dam_tim1], $
	;			position = [0.1, 0.5, 0.9, 0.95]
	
	
	;***********************************;
	;			Plot Orfees		
	;***********************************;	
	cd,'~/Data/2014_apr_18/radio/orfees/'
	null = mrdfits('orf20140418_101743.fts', 0, hdr0)
	fbands = mrdfits('orf20140418_101743.fts', 1, hdr1)
	freqs = [ fbands.FREQ_B1, $
			fbands.FREQ_B2, $
			fbands.FREQ_B3, $
			fbands.FREQ_B4, $
			fbands.FREQ_B5  ]
	nfreqs = n_elements(freqs)			
	
	null = mrdfits('orf20140418_101743.fts', 2, hdr_bg, row=0)
	tstart = anytim(file2time('20140418_101743'), /utim)
	
	;--------------------------------------------------;
	;				 Choose time range
	t0 = anytim(file2time(time0), /utim)
	t1 = anytim(file2time(time1), /utim)
	inc0 = (t0 - tstart)*10.0 ;Sampling time is 0.1 seconds
	inc1 = (t1 - tstart)*10.0 ;Sampling time is 0.1 seconds
	range = [inc0, inc1]
	data = mrdfits('orf20140418_101743.fts', 2, hdr2, range = range)
	
	
	;--------------------------------------------------;
	;		   Choose time range for background
	tbg0 = anytim(file2time('20140418_123000'), /utim)
	tbg1 = anytim(file2time('20140418_123100'), /utim)
	incbg0 = (tbg0 - tstart)*10.0 ;Sampling time is 0.1 seconds
	incbg1 = (tbg1 - tstart)*10.0 ;Sampling time is 0.1 seconds
	bg = mrdfits('orf20140418_101743.fts', 2, hdr2, range = [incbg0, incbg1])  
	
	tstart = anytim(file2time('20140418_000000'), /utim)
	time_b1 = tstart + data.TIME_B1/1000.0
	time_b2 = tstart + data.TIME_B2/1000.0 
	time_b3 = tstart + data.TIME_B3/1000.0 
	time_b4 = tstart + data.TIME_B4/1000.0 
	time_b5 = tstart + data.TIME_B5/1000.0 
	
	freq0 = 8
	freq1 = 1000
	;-----------------------------------------;
	;						STOKESI B1
	setup_ps, 'jazzy_plot_dam_orfees_aia.eps'
	plot_spec, data.STOKESI_B1, time_b1, fbands.FREQ_B1, [freq0, freq1], average(bg.stokesi_b1, 2), scl0=-0.2, scl1=0.9
	
	loadct, 74
  reverse_ct
	
	plot_spec, data.STOKESI_B1, time_b1, fbands.FREQ_B1, [freq0, freq1], average(bg.stokesi_b1, 2), scl0=-0.0, scl1=0.9 ; Lowest frequency
	plot_spec, data.STOKESI_B2, time_b2, fbands.FREQ_B2, [freq0, freq1], average(bg.stokesi_b2, 2), scl0=-0.0, scl1=0.8
	plot_spec, data.STOKESI_B3, time_b3, fbands.FREQ_B3, [freq0, freq1], average(bg.stokesi_b3, 2), scl0=-0.0, scl1=1.5
	plot_spec, data.STOKESI_B4, time_b4, fbands.FREQ_B4, [freq0, freq1], average(bg.stokesi_b4, 2), scl0=-0.0, scl1=0.8
	plot_spec, data.STOKESI_B5, time_b5, fbands.FREQ_B5, [freq0, freq1], average(bg.stokesi_b5, 2), scl0=-0.0, scl1=0.3
	
	dam_spec = smooth(reverse(transpose(dam_spec)), 2)
	plot_spec, dam_spec, dam_tim, reverse(freq), [freq0, freq1], average(dam_spec, 2), scl0=(-0.20), scl1=0.7
	
	device, /close
  set_plot, 'x'
  
	

END
