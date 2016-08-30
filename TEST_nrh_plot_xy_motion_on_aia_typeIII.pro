pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=9, $
          ysize=8, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

pro TEST_nrh_plot_xy_motion_on_aia_typeIII, postscript=postscript

	; Oplot the motion of the LT source on AIA image

	;-------------------------------------------------;
	;			Choose files unaffected by AEC
	;
	cd,'~/Data/2014_Apr_18/sdo/171A/'
	aia_files = findfile('aia*.fits')
	motion_files = findfile('~/Data/2014_apr_18/radio/nrh/nrh*src*motion.sav')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	f = aia_files[where(ind.exptime gt 1.)]

	tstart = anytim(file2time('20140418_123435'),/utim)
	tend   = anytim(file2time('20140418_124958'),/utim)

	mreadfits_header, f, ind
	aia_files = f[where(anytim(ind.date_obs, /utim) ge tstart) - 5]
  
	i=5
	;-------------------------------------------------;
	;				 	Plot AIA
	read_sdo, aia_files[i-5], $
		he_aia_pre, $
		data_aia_pre
	read_sdo, aia_files[i], $
		he_aia, $
		data_aia
	index2map, he_aia_pre, $
		smooth(data_aia_pre, 5)/he_aia_pre.exptime, $
		map_aia_pre, $
		outsize = 4096
	index2map, he_aia, $
		smooth(data_aia, 5)/he_aia.exptime, $
		map_aia, $
		outsize = 4096		

	if keyword_set(postscript) then setup_ps, '~/typeIII_0_height.eps'	
	;-----------------------------;
	;				  Plot diff image	
	FOV = [15., 15.]
	CENTER = [525, -230]
	loadct, 57, /silent
	reverse_ct
	plot_map, diff_map(map_aia, map_aia_pre), $
		dmin = -50.0, $
		dmax = 100.0, $
		fov = FOV,$
		center = CENTER, $
		title = ' ', $
		pos = [0.1, 0.15, 0.8, 0.95]

	set_line_color	

	plot_helio, he_aia.date_obs, $
		/over, $
		gstyle=0, $
		gthick=4.0, $	
		gcolor=1.0, $
		grid_spacing=15.0
		
	plot_helio_hack, he_aia.date_obs, $
		/over, $
		gstyle=0, $
		gthick=5.0, $	
		gcolor=3.0, $
		grid_spacing=0.5, $
		inflate=1.0, $
		xcor=xcor0, ycor=ycor0


	plot_helio_hack, he_aia.date_obs, $
		/over, $
		gstyle=0, $
		gthick=5.0, $	
		gcolor=4, $
		grid_spacing=0.5, $
		inflate=1.15, $
		xcor=xcor1, ycor=ycor1


 	;for i=115, n_elements(xcor0[255, *])-185, 5 do $
	;	plots, [xcor0[249, i], xcor1[249, i]], [ycor0[249, i], ycor1[249, i]], thick=2, color=0, /data



	print, he_aia.DATE_OBS
	;------------------------------------;
	;			Plot Total I
	;

	oplot_nrh_on_three_color, '2014-04-18T12:34:33'
	
	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'
	endif	
STOP
END