pro aia_dt

	;Code to produce distance time map from line on AIA image

	;-------------------------------------------------;
	;			Choose files unaffected by AEC
	AU = 1.49e11	; meters

	cd,'~/Data/2014_Apr_18/sdo/193A/'
	aia_files = findfile('aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	f = aia_files[where(ind.exptime gt 1.)]

	window, 0, xs=700, ys=700, retain = 2
	window, 4, xs=700, ys=700, retain = 2
	!p.charsize=1.5
	loadct, 1
	window, 3, xs=500, ys=500
	start = 5
	finish = 160

	npoints = 200

	distt = fltarr(finish - start, npoints)
	mreadfits_header, f, ind

	tstart = anytim( (ind.date_obs)[start], /utim)
	tend = anytim( (ind.date_obs)[finish-1], /utim)
	tarr = anytim((ind.date_obs)[start:finish-1], /utim) ; ( findgen(finish-start)*(tend - tstart)/(finish-start -1) ) + tstart
	freq = dindgen(npoints)

	;------------------------------------------------------;
	;		Define lines over which to interpolate
	read_sdo, f[0], $
		he_dummy, $
		data_dummy

	index2map, he_dummy, $
		smooth(data_dummy, 7)/he_dummy.exptime, $
		map_dummy, $
		outsize = 1024

	x1 = 520.0
	y1 = -210.0

	angles = [20.0, 340.0, 300.0, 260.0]
	for j = 0, n_elements(angles)-1 do begin
		radius = 300	;arcsec
		angle = angles[j]
		x2 = x1 + radius*cos(angle*!dtor)	;808.0	
		y2 = y1 + radius*sin(angle*!dtor)	;-120.0
		xlin = ( findgen(npoints)*(x2 - x1)/(npoints-1) ) + x1
		ylin = ( findgen(npoints)*(y2 - y1)/(npoints-1) ) + y1	

		;---------------------------------------------------------;
		;				Same lines on data array
		;
		pixx = FIX( (size(map_dummy.data))[1]/2.0 + xlin/map_dummy.dx )
		pixy = FIX( (size(map_dummy.data))[2]/2.0 + ylin/map_dummy.dy )

		;---------------------------------------------------------;
		;				Line length in arcsecs
		;
		lina = sqrt( (x2-x1)^2.0 + (y2-y1)^2.0 )
		lind = AU*tan((lina/3600.0)*!dtor)/1e6
		lindMm = findgen(npoints)*(lind)/(npoints-1.0)

		FOV = [15.0, 15.0]
		CENTER = [500.0, -350.0]
		WAVEL = string(he_dummy.WAVELNTH, format = '(I03)')

			;undefine, map_dummy
			;undefine, he_dummy
			;undefine, data_dummy
	  
	  	FOR i = start, finish-1 DO BEGIN ;n_elements(f)-2 DO BEGIN

			;-------------------------------------------------;
			;			 		Read data
			read_sdo, f[i-5], $
				he_aia_pre, $
				data_aia_pre
			read_sdo, f[i], $ 
				he_aia, $
				data_aia

			index2map, he_aia_pre, $
				smooth(data_aia_pre, 7)/he_aia_pre.exptime, $
				map_aia_pre, $
				outsize = 1024
			index2map, he_aia, $
				smooth(data_aia, 7)/he_aia.exptime, $
				map_aia, $
				outsize = 1024

			undefine, data_aia
			undefine, data_aia_pre	
			;-------------------------------------------------;
			;				  Plot diff image	
			wset, 4
			; map_aia.data = (map_aia.data - mean(map_aia.data))/stdev(map_aia.data)
			map = diff_map(map_aia, map_aia_pre)
			plot_map, map, $
				dmin = -25, $
				dmax = 25, $
				fov = FOV,$
				center = CENTER

			plot_helio, he_aia.date_obs, $
				/over, $
				gstyle=0, $
				gthick=1.0, $	
				gcolor=255, $
				grid_spacing=15.0

			set_line_color
			plots, xlin, ylin, /data, color=3, thick=1.5
			plots, xlin, ylin+7.0, /data, color=3, thick=1.5
			plots, xlin, ylin-7.0, /data, color=3, thick=1.5

			prof1 = interpolate(map.data, pixx, pixy)
			prof2 = interpolate(map.data, pixx, pixy + 10.0/map.dy)
			prof3 = interpolate(map.data, pixx, pixy - 10.0/map.dy)
			prof = average( [ [prof1], [prof2], [prof3] ], 2)

			distt[i-start, *] = prof 
			loadct, 1, /silent 
			wset, 3
			spectro_plot, distt > (-25) < 25, tarr, lindMm, $
							/xs, $
							/ys, $
							ytitle='Distance (Mm)'

			;print, anytim(tarr[i-start], /yoh), ' and '+he_aia.date_obs
			progress_percent, i, start, finish-1

		ENDFOR
		dt_map_struct = {name:'dt_map_'+WAVEL, dtmap:distt, time:tarr, distance:lindMm, angle:angle, xyarcsec:[[xlin], [ylin]] }
	  	save, dt_map_struct, $
	  		filename='~/Data/2014_apr_18/sdo/dist_time/aia_'+WAVEL+'_dt_map_'+string(angle, format='(I03)')+'.sav'
  	ENDFOR		
  	
	STOP

END