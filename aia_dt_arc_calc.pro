pro aia_dt_arc_calc

	; Modify to use an arc off the solar limb

	; Code to produce distance time map from line on AIA image
	; These maps are then used in the three colour map code aia_dt_plot_three_color.pro

	loadct, 1
	!p.charsize=1.5
	winsz=700
	AU = 1.49e11	; meters
	aia_waves = ['171A', '211A', '193A']	;['094A', '131A', '335A']	
	min_exp = [1.5, 1.5, 1.0]
	npoints = 1000
	angles = findgen(npoints)*(260. - 300.)/(npoints-1) + 300.0
	radius = 1000.0	;arcsec
	arc0 = transpose( [ [radius*cos(angles*!dtor)], [radius*sin(angles*!dtor)] ] )
	arc1 = transpose( [ [(radius+40.0)*cos(angles*!dtor)], [(radius+40.0)*sin(angles*!dtor)] ] )
	arc2 = transpose( [ [(radius+80.0)*cos(angles*!dtor)], [(radius+80.0)*sin(angles*!dtor)] ]	)	;808.0
	arc3 = transpose( [ [(radius+120.0)*cos(angles*!dtor)], [(radius+120.0)*sin(angles*!dtor)] ] )


	for k=0, n_elements(aia_waves)-1 do begin
		;-------------------------------------------------;
		;		  Choose files unaffected by AEC
		;
		folder = '~/Data/2014_Apr_18/sdo/'+aia_waves[k]+'/'
		aia_files = findfile(folder+'aia*.fits')
		mreadfits_header, aia_files, ind, only_tags='exptime'
		f = aia_files[where(ind.exptime gt min_exp[k])]

		window, 0, xs=winsz, ys=winsz, retain = 2
		window, 4, xs=winsz, ys=winsz, retain = 2
		window, 3, xs=500, ys=500
		
		mreadfits_header, f, ind
		start = closest(anytim(ind.date_obs, /utim), anytim('2014-04-18T12:55:00', /utim))
		finish = closest(anytim(ind.date_obs, /utim), anytim('2014-04-18T13:18:00', /utim))
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

		;---------------------------------------------------------;
		;				Line length in arcsecs
		;
		lina = sqrt( (arc0[0, *])^2.0 + (arc0[1, *])^2.0 )
		lind = AU*tan((lina/3600.0)*!dtor)/1e6
		lindMm = fnpoints*(lind)/(npoints-1.0)

		WAVEL = string(he_dummy.WAVELNTH, format = '(I03)')
	  
	  	FOR i = start, finish DO BEGIN ;n_elements(f)-2 DO BEGIN

			;-------------------------------------------------;
			;			 		Read data
			; 
			; The actual dt_plotter takes care of the differencing now. 
			; See aia_dt_plot_three_color.

			read_sdo, f[i], $ 
				he_aia, $
				data_aia

			index2map, he_aia, $
				smooth(data_aia, 3)/he_aia.exptime, $
				map, $
				outsize = 1024

			undefine, data_aia
			
			loadct, 1, /silent
			wset, 4
			plot_map, map, $
				dmin = -25, $
				dmax = 800;, $
				;fov = FOV,$
				;center = CENTER

			plot_helio, he_aia.date_obs, $
				/over, $
				gstyle=0, $
				gthick=1.0, $	
				gcolor=255, $
				grid_spacing=15.0

			set_line_color
			plots, arc0[0, *], arc0[1, *], /data, color=3, thick=1.5
			plots, arc1[0, *], arc1[1, *], /data, color=3, thick=1.5
			plots, arc2[0, *], arc2[1, *], /data, color=3, thick=1.5
			plots, arc2[0, *], arc3[1, *], /data, color=3, thick=1.5

			;---------------------------------------------------------;
			;				Same lines on data array
			;
			loadct, 1, /silent
			wset, 0
			plot_image, map.data
			pixx0 = FIX( axis1_sz + arc0[0, *]/map_dummy.dx )
			pixy0 = FIX( axis2_sz + arc0[1, *]/map_dummy.dy )
			set_line_color
			plots, pixx0, pixy0, /data, color=3

			pixx1 = FIX( axis1_sz + arc1[0, *]/map_dummy.dx )
			pixy1 = FIX( axis2_sz + arc1[1, *]/map_dummy.dy )
			pixx2 = FIX( axis1_sz + arc2[0, *]/map_dummy.dx )
			pixy2 = FIX( axis2_sz + arc2[1, *]/map_dummy.dy )
			pixx3 = FIX( axis1_sz + arc3[0, *]/map_dummy.dx )
			pixy3 = FIX( axis2_sz + arc3[1, *]/map_dummy.dy )

			prof1 = transpose( interpolate(map.data, pixx0, pixy0) )
			prof2 = transpose( interpolate(map.data, pixx1, pixy1) )
			prof3 = transpose( interpolate(map.data, pixx2, pixy2) )
			prof4 = transpose( interpolate(map.data, pixx3, pixy3) )
			prof = mean( [ [prof1], [prof2], [prof3], [prof4] ], dim=2)

			distt[i-start, *] = prof 
		
			wset, 3
			spectro_plot, distt > (-25) < 800, tarr, lindMm, $
							/xs, $
							/ys, $
							ytitle='Distance (Mm)'

			;print, anytim(tarr[i-start], /yoh), ' and '+he_aia.date_obs
			progress_percent, i, start, finish-1

		ENDFOR
		dt_map_struct = {name:'dt_map_'+WAVEL, dtmap:distt, time:tarr, distance:lindMm, xyarcsec:[[arc0], [arc1], [arc2], [arc3]] }
	  	save, dt_map_struct, $
	  		filename='~/Data/2014_apr_18/sdo/dist_time/aia_'+WAVEL+'arc_dt_map.sav'
  	ENDFOR		
 
	STOP

END