pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.3
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=9, $
          ysize=10, $
          /encapsulate, $
          yoffset=5, $
          bits_per_pixel = 16

end

pro plot_spec, data, time, freqs, frange, bg, scl0=scl0, scl1=scl1
	
 
	print, 'Processing: '+string(freqs[0], format=string('(I4)')) + $
			' to ' + $
			string(freqs[n_elements(freqs)-1], format=string('(I4)'))+ ' MHz'

	
	spectro_plot, data > (scl0) < (scl1), $
  				time, $
  				reverse(freqs), $
  				/xs, $
  				/ys, $
  				/ylog, $
  				ytitle='Frequency (MHz)', $
  				;title = 'Orfees and DAM', $
  				yr=[ frange[0], frange[1] ], $
  				xrange = '2014-Apr-18 '+['12:25:00', '13:20:00'], $
  				/noerase, $
  				position = [0.11, 0.08, 0.95, 0.50], $
  				xticklen=-0.01, $
  				yticklen=-0.01
			
  					
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
				XTICKFORMAT="(A1)", $
				/xs, $
				yrange = [1e-9,1e-3], $
				/ylog, $
				position = [0.11, 0.74, 0.95, 0.94], $
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
				pos = [0.12, 0.945], $
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

;********************
pro plot_fermi, date_start, date_end


	FermiGBM_file= '~/Data/2014_apr_18/fermi/fermi_ctime_n0_20140418_v00.sav'   

	restore, FermiGBM_file

	utplot, anytim(ut, /utim), binned[0,*], $
			/ylog, $
			yrange=[1.e-4, 1.e4], $
			position=[0.11, 0.54, 0.95, 0.74], $
			;/nolabel, $
			xtitle=' ', $
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
			pos = [0.77, 0.72], $
			/normal, $
			thick=3

	xyouts, 0.79, 0.72, 'FERMI GBM', /normal, charsize=0.8

END


pro goes_dam_orfees, postscript=postscript

	;------------------------------------;
	;			Window params
	cd,'~/Data/2014_apr_18/
	if keyword_set(postscript) then begin
		setup_ps, 'goes_dam_orfees_20140418.eps
	endif else begin	
		loadct, 0
		window, xs=900, ys=1200, retain=2
		!p.charsize=1.5
	endelse
			
	freq0 = 8
	freq1 = 1000
	time0='20140418_122500'
	time1='20140418_132000'


	plot_goes, time0, time1

	plot_fermi, anytim(file2time(time0), /utim), anytim(file2time(time1), /utim)

	loadct, 0
	reverse_ct

	;***********************************;
	;			 Read DAM		
	;***********************************;
	cd,'~/Data/2014_apr_18/radio/dam/'
	restore, 'NDA_20140418_1221_left.sav', /verb
	dam_freqs = freq
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
	dam_time = timl

	dam_spec = constbacksub(dam_spec, /auto)
	
	dam_tim0 = anytim(file2time(time0), /time_only, /trun, /yoh)
	dam_tim1 = anytim(file2time(time1), /time_only, /trun, /yoh)

	restore, '~/Data/2014_apr_18/radio/orfees/orf_20140418_bsubbed_min.sav', /verb
	orf_spec = orfees_struct.spec
	orf_time = orfees_struct.time
	orf_freqs = orfees_struct.freq

	
	;***********************************;
	;			   PLOT
	;***********************************;	
	loadct, 74
	reverse_ct
	scl_lwr = -0.4				;Lower intensity scale for the plots.

	plot_spec, dam_spec, dam_time, dam_freqs, [freq0, freq1], scl0=-20, scl1=100
	
	plot_spec, orf_spec, orf_time, orf_freqs, [freq0, freq1], scl0=-0.1, scl1=1.2
	
	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif

;	x2png,'dam_orfees_burst_20140418.png'
	

END

