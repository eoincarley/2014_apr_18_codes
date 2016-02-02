pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=8, $
          ysize=8, $
          bits_per_pixel=32, $
          /encapsulate, $
          yoffset=5

end

pro aia_plot_dt_traces

	; Code simply to plot an AIA image and the vectors along which the distance
	; time traces were taken

	angles = [20.0, 260.0] ;[35.0, 20.0, 340.0, 300.0, 260.0]
	npoints = 300
	radius = 150	;arcsec
	x1 = 500.0
	y1 = -210.0
	FOV = [4, 4]
	CENTER = [510.0, -210.0]

	folder = '~/Data/2014_Apr_18/sdo/131A/'
	aia_files = findfile(folder+'aia*.fits')
	mreadfits_header, aia_files, ind, only_tags='exptime'
	f = aia_files[where(ind.exptime gt 1.)]


	;-------------------------------------------------;
	;			 Read and plot the data
	; 
	i=0
	read_sdo, f[i], $ 
		he_aia, $
		data_aia

	index2map, he_aia, $
		smooth(data_aia, 7)/he_aia.exptime, $
		map, $
		outsize = 4096

	undefine, data_aia

	setup_ps, '~/aia_dt_lines.eps'

	loadct, 0
	plot_map, map, $
		dmin = -50, $
		dmax = 300, $
		fov = FOV,$
		center = CENTER, $
		color=0, $
		/noxticks, $
		/noyticks, $
		/normal, $
		/noerase, $
		/notitle, $
		/nolabels

	loadct, 16
	plot_map, map, $
		dmin = -50, $
		dmax = 300, $
		fov = FOV,$
		center = CENTER, $
		color=0, $
		/noxticks, $
		/noyticks, $
		/normal, $
		/noerase, $
		/notitle, $
		/nolabels

	plot_helio, he_aia.date_obs, $
		/over, $
		gstyle=0, $
		gthick=7.0, $	
		gcolor=255, $
		grid_spacing=15.0


	axis1_sz = (size(map.data))[1]/2.0	
	axis2_sz = (size(map.data))[2]/2.0
	fnpoints = findgen(npoints)	

	linestyles=[0,2]
	for i=0, n_elements(angles)-1 do begin
		angle = angles[i]
		x2 = x1 + radius*cos(angle*!dtor)	;808.0	
		y2 = y1 + radius*sin(angle*!dtor)	;-120.0
		xlin = ( fnpoints*(x2 - x1)/(npoints-1) ) + x1
		ylin = ( fnpoints*(y2 - y1)/(npoints-1) ) + y1			

		set_line_color
		plots, xlin, ylin, /data, color=0, thick=8, linestyle=linestyles[i]
	endfor	

	loadct, 0
	plot_map, map, $
		dmin = -50, $
		dmax = 300, $
		fov = FOV,$
		center = CENTER, $
		/nodata, $
		/noerase, $
		color=0

	device, /close
	set_plot, 'x'	

END