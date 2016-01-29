pro aia_dt_calc

	; Code to produce distance time map from line on AIA image
	; These maps are then used in the three colour map code aia_dt_plot_three_color.pro

	loadct, 1
	!p.charsize=1.5
	winsz=700
	AU = 1.49e11	; meters
	aia_waves = ['094A', '131A', '335A']	; ['094A', '131A', '335A']
	angles = [35.0, 20.0, 340.0, 300.0, 260.0]
	npoints = 300
	radius = 300	;arcsec
	x1 = 500.0
	y1 = -210.0
	FOV = [15.0, 15.0]
	CENTER = [500.0, -350.0]

	for k=0, n_elements(aia_waves)-1 do begin
		;-------------------------------------------------;
		;		  Choose files unaffected by AEC
		;
		folder = '~/Data/2014_Apr_18/sdo/'+aia_waves[k]+'/'
		aia_files = findfile(folder+'aia*.fits')
		mreadfits_header, aia_files, ind, only_tags='exptime'
		f = aia_files[where(ind.exptime gt 1.)]

		window, 0, xs=winsz, ys=winsz, retain = 2
		window, 4, xs=winsz, ys=winsz, retain = 2
		window, 3, xs=500, ys=500
		
		mreadfits_header, f, ind
		start = closest(anytim(ind.date_obs, /utim), anytim('2014-04-18T12:00:00', /utim))
		finish = closest(anytim(ind.date_obs, /utim), anytim('2014-04-18T13:00:00', /utim))
		distt = fltarr(1+(finish - start), npoints)

		tstart = anytim( (ind.date_obs)[start], /utim)
		tend = anytim( (ind.date_obs)[finish], /utim)
		tarr = anytim( (ind.date_obs)[start:finish], /utim) 	;( findgen(finish-start)*(tend - tstart)/(finish-start -1) ) + tstart

		;----------------------------------------------------;
		;		Define lines over which to interpolate
		;
		read_sdo, f[0], $
			he_dummy, $
			data_dummy

		index2map, he_dummy, $
			smooth(data_dummy, 7)/he_dummy.exptime, $
			map_dummy, $
			outsize = 1024

		axis1_sz = (size(map_dummy.data))[1]/2.0	
		axis2_sz = (size(map_dummy.data))[2]/2.0
		fnpoints = findgen(npoints)

		for j = 0, n_elements(angles)-1 do begin
			
			angle = angles[j]
			x2 = x1 + radius*cos(angle*!dtor)	;808.0	
			y2 = y1 + radius*sin(angle*!dtor)	;-120.0
			xlin = ( fnpoints*(x2 - x1)/(npoints-1) ) + x1
			ylin = ( fnpoints*(y2 - y1)/(npoints-1) ) + y1	

			;---------------------------------------------------------;
			;				Same lines on data array
			;
			pixx = FIX( axis1_sz + xlin/map_dummy.dx )
			pixy = FIX( axis2_sz + ylin/map_dummy.dy )

			;---------------------------------------------------------;
			;				Line length in arcsecs
			;
			lina = sqrt( (x2-x1)^2.0 + (y2-y1)^2.0 )
			lind = AU*tan((lina/3600.0)*!dtor)/1e6
			lindMm = fnpoints*(lind)/(npoints-1.0)

			WAVEL = string(he_dummy.WAVELNTH, format = '(I03)')
		  
		  	FOR i = start, finish DO BEGIN ;n_elements(f)-2 DO BEGIN

				;-------------------------------------------------;
				;			 		Read data
				; 
				; The actual dt_plotter takes care of the differencing now. See aia_dt_plot_three_color.
				read_sdo, f[i], $ 
					he_aia, $
					data_aia

				index2map, he_aia, $
					smooth(data_aia, 7)/he_aia.exptime, $
					map, $
					outsize = 1024

				undefine, data_aia
				wset, 4
			
				plot_map, map, $
					dmin = -25, $
					dmax = 800, $
					fov = FOV,$
					center = CENTER

				plot_helio, he_aia.date_obs, $
					/over, $
					gstyle=0, $
					gthick=1.0, $	
					gcolor=255, $
					grid_spacing=15.0

				;set_line_color
				plots, xlin, ylin, /data, color=3, thick=1.5
				plots, xlin, ylin+7.0, /data, color=3, thick=1.5
				plots, xlin, ylin-7.0, /data, color=3, thick=1.5

				prof1 = interpolate(map.data, pixx, pixy)
				prof2 = interpolate(map.data, pixx, pixy + 10.0/map.dy)
				prof3 = interpolate(map.data, pixx, pixy - 10.0/map.dy)
				prof = mean( [ [prof1], [prof2], [prof3] ], dim=2)

				distt[i-start, *] = prof 
			
				wset, 3
				spectro_plot, distt > (-25) < 800, tarr, lindMm, $
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
  	endfor
	STOP

END