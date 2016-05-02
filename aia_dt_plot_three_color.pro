pro stamp_date, wave1, wave2, wave3
   set_line_color

   xpos_aia_lab = 0.17
   ypos_aia_lab = 0.83

   xyouts, xpos_aia_lab+0.0012, ypos_aia_lab+0.07, wave1, alignment=0, /normal, color = 1, charthick=5
   xyouts, xpos_aia_lab-0.0012, ypos_aia_lab+0.07, wave1, alignment=0, /normal, color = 1, charthick=5
   xyouts, xpos_aia_lab, ypos_aia_lab+0.07, wave1, alignment=0, /normal, color = 3, charthick=0.5
   
   xyouts, xpos_aia_lab+0.0012, ypos_aia_lab+0.035, wave2, alignment=0, /normal, color = 0, charthick=5
   xyouts, xpos_aia_lab-0.0012, ypos_aia_lab+0.035, wave2, alignment=0, /normal, color = 0, charthick=5
   xyouts, xpos_aia_lab, ypos_aia_lab+0.035, wave2, alignment=0, /normal, color = 4, charthick=2
   
   xyouts, xpos_aia_lab+0.0012, ypos_aia_lab, wave3, alignment=0, /normal, color = 0, charthick=5
   xyouts, xpos_aia_lab-0.0012, ypos_aia_lab, wave3, alignment=0, /normal, color = 0, charthick=5
   xyouts, xpos_aia_lab, ypos_aia_lab, wave3, alignment=0, /normal, color = 10, charthick=2

END

pro aia_dt_plot_three_color, angle, postscript=postscript, choose_points=choose_points, ratio=ratio

	;Code to plot the distance time maps from AIA

	!p.font = 0
	!p.charsize = 1.0
	;!p.charthick = 0.5

	folder = '~/Data/2014_Apr_18/sdo/'	;'~/Data/2015_nov_04/sdo/event1/'	;'~/Data/2014_Apr_18/sdo/'
	
	if keyword_set(postscript) then begin
		set_plot, 'ps'
		device, filename='~/aia_dt_maps_cool_20140418.eps', $
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

	min_scl = -2
	max_scl = 4
	;-------------------------------------------;
	;				Plot 171
	;
	;angle = '020'
	waves = ['211', '193', '171']	;['094', '131', '335']	;
	cd, folder+'/dist_time/'
	restore, 'aia_'+waves[0]+'_dt_map_'+angle+'.sav', /verbose
	;restore, 'aia_'+waves[0]+'arc_dt_map.sav', /verbose
	t_a = dt_map_struct.time
	lindMm = dt_map_struct.distance	
	distt_a = dt_map_struct.dtmap
	if ~keyword_set(ratio) then begin
		for i=0, n_elements(lindMm)-1 do distt_a[*,i] = ( distt_a[*,i] - mean(distt_a[*,i]) ) /stdev(distt_a[*,i])   
		distt_a = distt_a > (min_scl) < (max_scl)
	endif else begin
		distt_a = distt_a/max(distt_a)
	endelse	

	restore, 'aia_'+waves[1]+'_dt_map_'+angle+'.sav', /verbose
	;restore, 'aia_'+waves[1]+'arc_dt_map.sav', /verbose	
	t_b = dt_map_struct.time
	distt_b = dt_map_struct.dtmap
	if ~keyword_set(ratio) then begin
		for i=0, n_elements(lindMm)-1 do distt_b[*,i] = ( distt_b[*,i] - mean(distt_b[*,i]) ) /stdev(distt_b[*,i])   
		distt_b = distt_b > (min_scl) < (max_scl)
	endif else begin
		distt_b = distt_b/max(distt_b)
	endelse	

	restore, 'aia_'+waves[2]+'_dt_map_'+angle+'.sav', /verbose
	;restore, 'aia_'+waves[1]+'arc_dt_map.sav', /verbose	
	t_c = dt_map_struct.time
	distt_c = dt_map_struct.dtmap
	if ~keyword_set(ratio) then begin
		for i=0, n_elements(lindMm)-1 do distt_c[*,i] = ( distt_c[*,i] - mean(distt_c[*,i]) ) /stdev(distt_c[*,i])   
		distt_c = distt_c > (min_scl) < (max_scl)
	endif else begin
		distt_c = distt_c/max(distt_c)
	endelse	

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
	
	step_size = 5
	sizex = (size(distt_a))[1]
	sizey = (size(distt_a))[2]
	plota = fltarr(sizex, sizey)
	plotb = fltarr(sizex, sizey)
	plotc = fltarr(sizex, sizey)
	;min_tim = min_tim[step_size:n_elements(min_tim)-1]
	
	distt_a_hf = distt_a - smooth(distt_a, 10)
	distt_b_hf = distt_b - smooth(distt_b, 10)
	distt_c_hf = distt_c - smooth(distt_c, 10)

	distt_a_lf = smooth(distt_a, 2)
	distt_b_lf = smooth(distt_b, 2)
	distt_c_lf = smooth(distt_c, 2)

	distt_a = distt_a ;+ 0.7*distt_a_hf
	distt_b = distt_b ;+ 0.7*distt_b_hf
	distt_c = distt_c ;+ 0.7*distt_c_hf

	;distt_a = smooth(distt_a, 3) - distt_a_hf
	;distt_b = smooth(distt_b, 3) - distt_b_hf
	;distt_c = smooth(distt_c, 3) - distt_c_hf

	if ~keyword_set(ratio) then begin
			plota = distt_a	;/distt_a[i-5, *] >0.8 <1.15 
			plotb = distt_b	;/distt_b[i-5, *] >0.8 <1.15
			plotc = distt_c	;/distt_c[i-5, *] >0.8 <1.15
	endif else begin
		for i=step_size, sizex-1 do begin
			plota[i, *] = distt_a[i, *]/distt_a[(i-step_size)>0, *] >0.8 < 1.8
			plotb[i, *] = distt_b[i, *]/distt_b[(i-step_size)>0, *] >0.8 < 1.8
			plotc[i, *] = distt_c[i, *]/distt_c[(i-step_size)>0, *] >0.8 < 1.8
		endfor
	endelse
	
	tstart = anytim('2014-04-18T12:00:00',/utim) > min_tim[0]
	tend = anytim('2014-04-18T13:10:00', /utim)	< min_tim[n_elements(min_tim)-1]
	istart = closest(min_tim, tstart)
	istop = closest(min_tim, tend)
	
	;-------------------------------------------;
	;	The deletion of AIA images with an incorrect exposure time leads to the images having an uneven sampling in time.
	;	The following two for loops find where the time is unevenly sample and inserts new times at the mininum sampling
	;   of AIA (12 seconds). This gives an evenly sampled time array between start and end times with a cadence of 12 s.
	;
	min_t_int = 12.0
	new_min_tim = min_tim[0]
	for i=1, n_elements(min_tim)-1 do begin

		int = min_tim[i] - min_tim[i-1] 
		if int gt min_t_int then begin
			n_new_tims = (int - (int mod min_t_int))/min_t_int
			new_tims = (dindgen(n_new_tims)+1)*min_t_int + min_tim[i-1] 
			new_min_tim = [new_min_tim, new_tims]	
		endif else begin
			new_min_tim = [new_min_tim, min_tim[i]]
		endelse

	endfor
	;-------------------------------------------;
	;		Now create evenly space dt map
	;
	new_map_a = findgen(n_elements(new_min_tim), n_elements(lindMm))
	new_map_b = findgen(n_elements(new_min_tim), n_elements(lindMm))
	new_map_c = findgen(n_elements(new_min_tim), n_elements(lindMm))

	for i=0, n_elements(new_min_tim)-1 do begin
		index = closest(min_tim, new_min_tim[i])
		new_map_a[i, *] = plota[index, *]
		new_map_b[i, *] = plotb[index, *]
		new_map_c[i, *] = plotc[index, *]
	endfor
	
	; Take section of the array
	hstop = 350.0 	;Mm
	hindex = closest(lindMm, hstop)
	istart = closest(new_min_tim, tstart)
	istop = closest(new_min_tim, tend)

	truecolorim = [[[ new_map_a[istart:istop, 0:hindex] ]], [[ new_map_b[istart:istop, 0:hindex] ]], [[ new_map_c[istart:istop, 0:hindex] ]]]
	
	;window, 0, xs=500, ys=500	 
	plot_image, truecolorim , true=3, $	;usually img
    	position = [0.15, 0.15, 0.95, 0.95], $
    	XTICKFORMAT="(A1)", $
    	YTICKFORMAT="(A1)", $
	 	/noerase, $
	 	/normal, $
	 	xticklen=-0.001, $
        yticklen=-0.001       

    ; This allows a point and click for the distance and time.    
 	utplot, new_min_tim, lindMm, $	;/rsun + 0.9, $
	 	/nodata, $
	 	/xs, $
	 	/ys, $
	 	yr=[0, lindMm(hindex)], $	;/rsun + 0.9, $
	  	xr = [tstart, tend], $
		position = [0.15, 0.15, 0.95, 0.95], $
		/noerase, $
		/normal, $
    	ytitle='Distance (Mm)'


    stamp_date, 'AIA '+waves[0], 'AIA '+waves[1], 'AIA '+waves[2]
    if waves[0] eq '094' then channels = 'hot' else channels='cool'
			
	if keyword_set(choose_points) then begin
		point, tim, dis, /data
		print, tim
		map_points = { name:'dt_map_points', times:tim, dis:dis, angle:angle, waves:waves }
		save, map_points, filenam='aia_'+channels+'_dtpoints_'+angle+'.sav'
	endif


	
	if keyword_set(postscript) then begin
		device, /close
		set_plot,'x'
	endif

END