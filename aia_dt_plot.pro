pro aia_dt_plot, ps=ps, choose_points=choose_points

	;Code to plot the distance time maps of from AIA
	!p.font = 0
	!p.charsize = 0.8
	!p.charthick = 0.5
	cd, '~/Data/2014_Apr_18/sdo/'
	
	if keyword_set(ps) then begin
		set_plot, 'ps'
		device, filename='aia_dt_maps.eps', $
				/encapsulate, $
				/color, $ 
				/inches, $
				/helvetica, $
				bits_per_pixel=32, $
				xs=4, $
				ys=10
	endif else begin
		window, 0, xs=400, ys=1000
	endelse
	
	xposl = 0.15
	xposr = 0.9
	tstart = '12:37:00'
	tend = '12:56:00'
	
	;------------------------------------------------;
	;				Plot 171
	;
	cd, '~/Data/2014_Apr_18/sdo/171A'
	restore, 'aia_171A_dtmap.sav', /verbose
	
	loadct, 1
	spectro_plot, distt > (-25) < 25, tarr, lindMm, $
	  				/xs, $
	  				/ys, $
	  				ytitle = 'Distance (Mm)', $
	  				xtitle='Start time: '+'2014-Apr-18 '+tstart+' UT', $
	  				title = 'AIA 171A', $
	  				xrange='2014-apr-18 ' + [tstart, tend], $
	  				position = [xposl, 0.71, xposr, 0.97], $
	  				/normal
	  				
	if keyword_set(choose_points) then begin
		point, tim, dis
		save, tim, dis, filenam='aia_171A_dt_points.sav'
	endif	
	
	;------------------------------------------------;
	;				Plot 193
	;
	cd, '~/Data/2014_Apr_18/sdo/193A'
	restore, 'aia_193A_dtmap.sav', /verbose
	
	loadct, 9
	spectro_plot, distt > (-25) < 25, tarr, lindMm, $
	  				/xs, $
	  				/ys, $
	  				ytitle = 'Distance (Mm)', $
	  				xtitle='Start time: '+'2014-Apr-18 '+tstart+' UT', $
	  				title = 'AIA 193A', $
	  				xrange='2014-apr-18 ' + [tstart, tend], $
	  				position = [xposl, 0.38, xposr, 0.63], $
	  				/normal, $
	  				/noerase
	  				
	if keyword_set(choose_points) then begin
		point, tim, dis
		save, tim, dis, filenam='aia_193A_dt_points.sav'
	endif			
	
	;------------------------------------------------;
	;				Plot 211
	;
	cd, '~/Data/2014_Apr_18/sdo/211A'
	restore, 'aia_211A_dtmap.sav', /verbose
	
	loadct, 3
	spectro_plot, distt > (-25) < 25, tarr, lindMm, $
	  				/xs, $
	  				/ys, $
	  				ytitle = 'Distance (Mm)', $
	  				xtitle='Start time: '+'2014-Apr-18 '+tstart+' UT', $
	  				title = 'AIA 211A', $
	  				xrange='2014-apr-18 ' + [tstart, tend], $
	  				position = [xposl, 0.05, xposr, 0.30], $
	  				/normal, $
	  				/noerase
	
	if keyword_set(choose_points) then begin
		point, tim, dis
		save, tim, dis, filenam='aia_211A_dt_points.sav'
	endif	
	
	if keyword_set(ps) then begin
		device, /close
		set_plot,'x'
	endif

END