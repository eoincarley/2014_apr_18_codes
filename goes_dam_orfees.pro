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
  wset,0
  spectro_plot, (data > (scl0) < scl1), $
  				time, $
  				reverse(freqs), $
  				/xs, $
  				/ys, $
  				/ylog, $
  				ytitle='Frequency (MHz)', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = '2014-Apr-18 '+['12:15:00', '13:15:00'], $
  				/noerase, $
  				position = [0.1, 0.1, 0.95, 0.75], $
  				xtitle='Start time: 2014-Apr-18 12:15:00 UT'
			
  					
END

;******************************
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
				tit = '1-minute GOES-15 Solar X-ray Flux', $
				ytit = 'Watts m!U-2!N', $
				xtit = ' ', $
				color = 3, $
				xrange = [x1, x2], $
				/xs, $
				yrange = [1e-9,1e-3], $
				/ylog, $
				position = [0.1, 0.75, 0.95, 0.99], $
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
				box=0

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

;********************



pro goes_dam_orfees

	;------------------------------------;
	;			Window params
	loadct, 0
	reverse_ct
	window, xs=900, ys=700, retain=2
	!p.charsize=1.5

	time0='20140418_121500'
	time1='20140418_131500'

	plot_goes, time0, time1
	loadct, 0
	reverse_ct

	;***********************************;
	;			Read DAM		
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
	;-----------------------------------------------------;
	;						STOKESI B1
	plot_spec, data.STOKESI_B1, time_b1, fbands.FREQ_B1, [freq0, freq1], average(bg.stokesi_b1, 2), scl0=-0.2, scl1=0.9
	plot_spec, data.STOKESI_B2, time_b2, fbands.FREQ_B2, [freq0, freq1], average(bg.stokesi_b2, 2), scl0=-0.2, scl1=0.9
	plot_spec, data.STOKESI_B3, time_b3, fbands.FREQ_B3, [freq0, freq1], average(bg.stokesi_b3, 2), scl0=-0.2, scl1=0.9
	plot_spec, data.STOKESI_B4, time_b4, fbands.FREQ_B4, [freq0, freq1], average(bg.stokesi_b4, 2), scl0=-0.2, scl1=0.9
	plot_spec, data.STOKESI_B5, time_b5, fbands.FREQ_B5, [freq0, freq1], average(bg.stokesi_b5, 2), scl0=-0.2, scl1=0.4
	
	dam_spec = reverse(transpose(dam_spec))
	plot_spec, dam_spec, dam_tim, reverse(freq), [freq0, freq1], average(dam_spec, 2), scl0=(-0.3), scl1=0.8
	
;	x2png,'dam_orfees_burst_20140418.png'
	

END

