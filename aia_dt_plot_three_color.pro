pro stamp_date, wave1, wave2, wave3
   set_line_color

   xpos_aia_lab = 0.18
   ypos_aia_lab = 0.82

   xyouts, xpos_aia_lab, ypos_aia_lab+0.07, wave1, alignment=0, /normal, color = 0, charthick=5, charsize=1.3
   xyouts, xpos_aia_lab, ypos_aia_lab+0.07, wave1, alignment=0, /normal, color = 3, charthick=0.5, charsize=1.3
   
   xyouts, xpos_aia_lab, ypos_aia_lab+0.035, wave2, alignment=0, /normal, color = 0, charthick=5, charsize=1.3
   xyouts, xpos_aia_lab, ypos_aia_lab+0.035, wave2, alignment=0, /normal, color = 4, charthick=2, charsize=1.3
   
   xyouts, xpos_aia_lab, ypos_aia_lab, wave3, alignment=0, /normal, color = 0, charthick=5, charsize=1.3
   xyouts, xpos_aia_lab, ypos_aia_lab, wave3, alignment=0, /normal, color = 10, charthick=2, charsize=1.3

END

pro aia_dt_plot_three_color, ps=ps, choose_points=choose_points

	;Code to plot the distance time maps from AIA

	!p.font = 0
	!p.charsize = 1.0
	;!p.charthick = 0.5

	cd, '~/Data/2014_Apr_18/sdo/'
	
	if keyword_set(ps) then begin
		set_plot, 'ps'
		device, filename='~/aia_dt_maps_hot_20.eps', $
				/encapsulate, $
				/color, $ 
				/inches, $
				/helvetica, $
				bits_per_pixel=32, $
				xs=5, $
				ys=5
	endif else begin
		window, 0, xs=600, ys=600
	endelse

	min_scl = -1
	max_scl = 0.05
	;-------------------------------------------;
	;				Plot 171
	;
	angle = '020'
	waves = ['094', '131', '335']
	cd, '~/Data/2014_Apr_18/sdo/dist_time/'
	restore, 'aia_'+waves[0]+'_dt_map_'+angle+'.sav', /verbose
	t_a = dt_map_struct.time
	lindMm = dt_map_struct.distance	
	distt_a = dt_map_struct.dtmap
	distt_a = distt_a;/max(distt_a)				;	( distt_a - mean(distt_a) ) /stdev(distt_a)   
	distt_a = distt_a ;> (min_scl) < (max_scl)

	restore, 'aia_'+waves[1]+'_dt_map_'+angle+'.sav', /verbose
	t_b = dt_map_struct.time
	distt_b = dt_map_struct.dtmap
	distt_b = distt_b ;/max(distt_b)				;( distt_b - mean(distt_b) ) /stdev(distt_b)   
	distt_b = distt_b ;> (min_scl) < (max_scl) 

	restore, 'aia_'+waves[2]+'_dt_map_'+angle+'.sav', /verbose
	t_c = dt_map_struct.time
	distt_c = dt_map_struct.dtmap
	distt_c = distt_c ;/max(distt_c)				;( distt_c - mean(distt_c) ) /stdev(distt_c)   
	distt_c = distt_c ;> (min_scl) < (max_scl)


	arrs = [n_elements(t_a), n_elements(t_b), n_elements(t_c)]
	val = max(arrs, t_max, subscript_min = t_min)
	n_array = [0,1,2]


	case t_min of
	  0: image_time = t_a
	  1: image_time = t_b
	  2: image_time = t_c
	endcase

	t_mid = n_array[where(n_array ne t_max and n_array ne t_min)]

	if t_min eq t_max then begin
	     max_tim = t_a
	     mid_tim = t_b
	     min_tim = t_c
	endif else begin
	  case t_max of
	     0: max_tim = t_a
	     1: max_tim = t_b
	     2: max_tim = t_c
	  endcase
	  case t_min of
	     0: min_tim = t_a
	     1: min_tim = t_b
	     2: min_tim = t_c
	  endcase
	  case t_mid of
	     0: mid_tim = t_a
	     1: mid_tim = t_b
	     2: mid_tim = t_c
	  endcase
	endelse


	; This loop finds the closest file to min_tim[n] for each of the filters. It constructs an
	; array of indices for each of the filters.
	for n = 0, n_elements(min_tim)-1 do begin
	  sec_min = min(abs(min_tim - min_tim[n]), loc_min)
	  if n eq 0 then next_min_im = loc_min else next_min_im = [next_min_im, loc_min]

	  sec_max = min(abs(max_tim - min_tim[n]), loc_max)
	  if n eq 0 then next_max_im = loc_max else next_max_im = [next_max_im, loc_max]

	  sec_mid = min(abs(mid_tim - min_tim[n]), loc_mid)
	  if n eq 0 then next_mid_im = loc_mid else next_mid_im = [next_mid_im, loc_mid]
	endfor

	if t_min eq t_max then begin
	     loc_a = next_max_im
	     loc_b = next_mid_im
	     loc_c = next_min_im
	endif else begin
	  case t_max of
	     0: loc_a = next_max_im
	     1: loc_b = next_max_im
	     2: loc_c = next_max_im
	  endcase
	  case t_mid of
	     0: loc_a = next_mid_im
	     1: loc_b = next_mid_im
	     2: loc_c = next_mid_im
	  endcase
	  case t_min of
	     0: loc_a = next_min_im
	     1: loc_b = next_min_im
	     2: loc_c = next_min_im
	  endcase
	endelse  

	distt_a = distt_a[loc_a, *] 
	distt_b = distt_b[loc_b, *] 
	distt_c = distt_c[loc_c, *] 
	
	sizex = (size(distt_a))[1]
	sizey = (size(distt_a))[2]
	plota = fltarr(sizex-5, sizey)
	plotb = fltarr(sizex-5, sizey)
	plotc = fltarr(sizex-5, sizey)
	min_tim = min_tim[5:n_elements(min_tim)-1]

	
	for i=5, sizex-1 do begin
		plota[i-5, *] = distt_a[i, *]/distt_a[i-5, *] >0.7 <1.15 
		plotb[i-5, *] = distt_b[i, *]/distt_b[i-5, *] >0.7 <1.15
		plotc[i-5, *] = distt_c[i, *]/distt_c[i-5, *] >0.7 <1.15
	endfor
	

	tstart = anytim('2014-04-18T12:00:00',/utim)
	tend = anytim('2014-04-18T13:00:00',/utim)
	istart = closest(min_tim, tstart)
	istop = closest(min_tim, tend) 
	min_tim = min_tim[istart:istop]

	truecolorim = [[[ plota[istart:istop, *] ]], [[ plotb[istart:istop, *] ]], [[ plotc[istart:istop, *] ]]]
	;truecolorim = [[[ distt_a[istart:istop, 50:150] ]], [[ distt_b[istart:istop, 50:150] ]], [[ distt_c[istart:istop, 50:150] ]]] ;contruct RGB image

	img = congrid(truecolorim, 500, 500, 3)

	loadct, 1
	spectro_plot, plota > (-25) < 25, min_tim, lindMm, $
  				/xs, $
  				/ys, $
  				ytitle = 'Distance (Mm)', $
  				;xtitle='Start time: '+'2014-Apr-18 '+tstart+' UT', $
  				;title = 'AIA 171A', $
  				xr = [tstart, tend], $
  				position = [0.15, 0.15, 0.95, 0.95], $
 				/normal, $
 				/noerase, $
			 	xticklen=-0.015, $
		        yticklen=-0.015
			

    plot_image, img, true=3, $
    	position = [0.15, 0.15, 0.95, 0.95], $
    	XTICKFORMAT="(A1)", $
    	YTICKFORMAT="(A1)", $
	 	/noerase, $
	 	/normal, $
	 	xticklen=-0.001, $
        yticklen=-0.001

    utplot, min_tim, lindMm, $
	  	/nodata, $
	  	/xs, $
	  	/ys, $
	  	xr = [tstart, tend], $
		position = [0.15, 0.15, 0.95, 0.95], $
		/noerase, $
		/normal


    stamp_date, 'AIA '+waves[0], 'AIA '+waves[1], 'AIA '+waves[2]
    if waves[0] eq '094' then channels = 'hot' else channels='cool'
			
	if keyword_set(choose_points) then begin
		point, tim, dis, /data
		print, tim
		map_points = { name:'dt_map_points', times:tim, dis:dis, angle:angle, waves:waves }
		save, map_points, filenam='aia_'+channels+'_dtpoints_'+angle+'.sav'
	endif

	
	if keyword_set(ps) then begin
		device, /close
		set_plot,'x'
	endif

END