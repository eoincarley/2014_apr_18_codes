pro aia_get_dt_points, wave, angle , ps=ps, choose_points=choose_points

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
		window, 0, xs=600, ys=600, xpos=1000, ypos=1000
	endelse
	
	xposl = 0.15
	xposr = 0.9
	tstart = '12:30:00'
	tend = '12:56:00'
	
	;------------------------------------------------;
	;				Plot 171
	;
	cd, '~/Data/2014_Apr_18/sdo/dist_time/'
	restore, 'aia_'+wave+'_dt_map_'+angle+'.sav', /verbose
	distt = dt_map_struct.dtmap
	tarr = dt_map_struct.time
	lindMm = dt_map_struct.distance	

	loadct, 1
	spectro_plot, distt > (-25) < 25, tarr, lindMm, $
	  				/xs, $
	  				/ys, $
	  				ytitle = 'Distance (Mm)', $
	  				xtitle='Start time: '+'2014-Apr-18 '+tstart+' UT', $
	  				title = 'AIA '+wave+'A', $
	  				xrange='2014-apr-18 ' + [tstart, tend], $
	  				;position = [xposl, 0.71, xposr, 0.97], $
	  				/normal
	  				
	if keyword_set(choose_points) then begin
		point, tim, dis
		dt_points_struct = {name:'dt_points', time:tim, dis:dis, wave:wave, angle:angle}
		save, dt_points_struct, filenam='aia_'+wave+'A_dt_points_'+angle+'.sav'
	endif

END