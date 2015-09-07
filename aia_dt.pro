pro aia_dt

	;Code to produce distance time map from line on AIA image


	;-------------------------------------------------;
	;			Choose files unaffected by AEC
	AU = 1.49e11	; meters

	cd,'~/Data/2014_Apr_18/sdo/131A/'
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
  
  	FOR i = start, finish-1 DO BEGIN ;n_elements(f)-2 DO BEGIN
		  print,i
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

		;-------------------------------------------------;
		;				  Plot diff image	
		FOV = [15.0, 15.0]
		CENTER = [500.0, -350.0]
		wset, 4
		; map_aia.data = (map_aia.data - mean(map_aia.data))/stdev(map_aia.data)


		plot_map, diff_map(map_aia, map_aia_pre), $
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

		;x2png, 'aia_'+string(he_aia.wavelnth, format='(I3)')+'A_'$
		;			+time2file(he_aia.date_obs, /sec)+'_rdiff.png'

		;---------------------------------------------------------;
		;				 First plot lines on map
		;
		;---------------------------------;
		;	  Choose points to plot over?
		;---------------------------------;

		x1 = 531.0
		x2 = 808.0
		y1 = -203.0
		y2 = -157.0
		xlin = ( findgen(npoints)*(x2 - x1)/(npoints-1) ) + x1
		ylin = ( findgen(npoints)*(y2 - y1)/(npoints-1) ) + y1

		set_line_color
		plots, xlin, ylin, /data, color=3, thick=1.5
		plots, xlin, ylin+7.0, /data, color=3, thick=1.5
		plots, xlin, ylin-7.0, /data, color=3, thick=1.5

		;---------------------------------------------------------;
		;				Same lines on data array
		;
					;xp1 = FIX( (size(map_aia.data))[1]/2.0 + 50./map_aia.dx )
					;xp2 = FIX( (size(map_aia.data))[1]/2.0 + 950./map_aia.dx )
					;yp1 = FIX( (size(map_aia.data))[1]/2.0 - 800./map_aia.dx )
					;yp2 = FIX( (size(map_aia.data))[1]/2.0 + 100./map_aia.dx )
		pixx = FIX( (size(map_aia.data))[1]/2.0 + xlin/map_aia.dx )
		pixy = FIX( (size(map_aia.data))[2]/2.0 + ylin/map_aia.dy )

		;---------------------------------------------------------;
		;					Line length in arcsecs
		;
		lina = sqrt( (x2-x1)^2.0 + (y2-y1)^2.0 )
		lind = AU*tan((lina/3600.0)*!dtor)/1e6
		lindMm = findgen(npoints)*(lind)/(npoints-1.0)

					;window, 1, xs=700, ys=700
					;loadct, 1, /silent
					;plot_image, sigrange( (map_aia.data) );[xp1:xp2, yp1:yp2] )
					;set_line_color
					;plots, pixx, pixy, /data, color=3, thick=2
					;plots, pixx, pixy + 10.0/map_aia.dy, /data, color=3, thick=2
					;plots, pixx, pixy - 10.0/map_aia.dy, /data, color=3, thick=2

					;prof1 = interpolate(map_aia.data, pixx, pixy)
					;prof2 = interpolate(map_aia.data, pixx, pixy + 10.0/map_aia.dy)
					;prof3 = interpolate(map_aia.data, pixx, pixy - 10.0/map_aia.dy)
					;prof = findgen(npoints)
					;FOR j=0, n_elements(prof)-1 DO prof[j] = mean([prof1[j], prof2[j], prof3[j]]) 

		map_aia = diff_map(map_aia, map_aia_pre)

		prof1 = interpolate(map_aia.data, pixx, pixy)
		prof2 = interpolate(map_aia.data, pixx, pixy + 10.0/map_aia.dy)
		prof3 = interpolate(map_aia.data, pixx, pixy - 10.0/map_aia.dy)
		prof = findgen(npoints)
		FOR j=0, n_elements(prof)-1 DO prof[j] = mean([prof1[j], prof2[j], prof3[j]]) 

						;window,2
						;plot, prof < 1000.0

		distt[i-start, *] = prof 
		loadct, 1, /silent 
		wset, 3
					;plot_image, distt > (-25) < 25, $
					;		position=[0.15, 0.15, 0.9, 0.9], $
					;		/normal, $
					;		xticks=2, xtickname=[' ', ' ', ' ']	
		spectro_plot, distt > (-25) < 25, tarr, lindMm, $
						/xs, $
						/ys, $
						ytitle='Distance (Mm)'

		print, anytim(tarr[i-start], /yoh), ' and '+he_aia.date_obs
	ENDFOR
  ;save, distt, tarr, lindMm, filename='aia_211A_dtmap.sav'
		stop

END