pro aia_dt_speed, ps=ps

	loadct, 0
	!p.background=255
	!p.color=0
	!p.symsize=1
	!p.font = 0
	!p.charsize = 0.8
	!p.charthick = 0.5
	!p.thick=1
	set_line_color

	;window, 0
	
	cd, '~/Data/2014_Apr_18/sdo/'
	if keyword_set(ps) then begin
		set_plot, 'ps'
		device, filename='aia_dt_speed_v2.eps', $
				/encapsulate, $
				/color, $ 
				/inches, $
				/helvetica, $
				bits_per_pixel=32, $
				xs=5, $
				ys=9
	endif else begin
		window, 0, xs=500, ys=800
	endelse
	
	xposl = 0.15
	xposr = 0.9
	tstart = anytim('2014-apr-18T12:35:00', /utim)
	tend = anytim('2014-apr-18T12:55:00', /utim)
	
	;--------------------------------------;
	;				171A
	;
	colors = [3, 4, 5, 6]
	waves = ['131','171','193','211']

	psyms = [4, 5, 6, 7]
	angles = ['020','260','300','340']

	cd, '~/Data/2014_Apr_18/sdo/dist_time'

	dtpoints = findfile('aia_*_dt*.sav')
	for i=0, n_elements(dtpoints)-1 do begin
		
		restore, dtpoints[i], /verb
		color = colors[where(waves eq DT_POINTS_STRUCT.WAVE)]
		psym = psyms[where(angles eq DT_POINTS_STRUCT.ANGLE)]

		deproject = 1.0/cos(45.0*!dtor)

		tim = dt_points_struct.time
		dis = dt_points_struct.dis*deproject
		utplot, tim, dis, $
				title = 'Points from dt map', $
				ytitle ='Distance (Mm)', $
				color = color, $
				yr = [40, 180]*deproject, $
				xrange = [tstart, tend], $
				/ys, $
				psym = psym, $
				/noerase, $
				position = [xposl, 0.55, xposr, 0.95]	

		legend, ['0','120','80','40'], $
			psym = psyms, $
			box=0, $
			position = [0.16, 0.95], $
			/normal	

		legend, ['131','171','193','211'], $
			linestyle = [0,0,0,0], $
			color = colors, $
			box=0, $
			position = [0.15, 0.86], $
			/normal		
				
		;			Non-linear fit 
		tim_sec = tim - tim[0]
		start = [0, 0.2, 40.0]
		fit = 'p[0]*x^2 + p[1]*x + p[2]'			
		p = mpfitexpr(fit, tim_sec, dis, err, yfit=yfit, start)

		outplot, tim, yfit, color = color
		
		speed = p[1]*1.0e3		; km/s 
		accel = p[0]*1.0e6		; m/s/s		
		print,'171 speed: ' + string(speed) + ' km/s'		
		print,'171 accel: ' + string(accel) + ' m/s'		
				
		tim1 = tim_sec[n_elements(tim_sec)-1]
		tim0 = tim_sec[0]
		tim_sim = (findgen(100)*(tim1 - tim0)/99) +tim0
		dis_sim = p[0]*tim_sim^2.0 + p[1]*tim_sim + p[2]
		vel_171 = deriv(tim_sim, dis_sim)*1e3	;	km/s
		
		utplot, tim_sim + tim[0], vel_171, $
			ytitle = 'Velocity (km/s)', $
			/noerase, $
			yr = [0, 450], $
			xrange = [tstart, tend], $
			position = [xposl, 0.05, xposr, 0.5], $
			color = color, $
			thick=1, $
			psym = psym, $
			symsize=1.5


	endfor
	
	
	if keyword_set(ps) then begin
		device, /close
		set_plot,'x'
	endif
	
	
stop	
	
END
