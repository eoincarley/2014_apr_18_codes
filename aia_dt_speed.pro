pro aia_dt_speed, ps=ps

	loadct, 0
	!p.background=255
	!p.color=0
	!p.symsize=2
	!p.font = 0
	!p.charsize = 0.8
	!p.charthick = 0.5
	!p.thick=4
	;window, 0
	
	cd, '~/Data/2014_Apr_18/sdo/'
	if keyword_set(ps) then begin
		set_plot, 'ps'
		device, filename='aia_dt_speed.eps', $
				/encapsulate, $
				/color, $ 
				/inches, $
				/helvetica, $
				bits_per_pixel=32, $
				xs=5, $
				ys=9
	endif else begin
		window, 0, xs=500, ys=900
	endelse
	
	xposl = 0.15
	xposr = 0.9
	
	;--------------------------------------;
	;				171A
	;
	cd, '~/Data/2014_Apr_18/sdo/171A'
	restore,'aia_171A_dt_points.sav', /verb
	set_line_color
	
	tim171 = tim
	utplot, tim, dis, $
			title = 'Points from dt map', $
			ytitle ='Distance (Mm)', $
			color = 5, $
			yr = [40, 180], $
			/ys, $
			psym = 1, $
			position = [xposl, 0.55, xposr, 0.95]
			
	;			Non-linear fit fit
	tim_sec = tim - tim[0]
	start = [0, 0.2, 40.0]
	fit = 'p[0]*x^2 + p[1]*x + p[2]'			
	p = mpfitexpr(fit, tim_sec, dis, err, yfit=yfit, start)

	outplot, tim, yfit, color = 5
	
	speed = p[1]*1.0e3		; km/s 
	accel = p[0]*1.0e6		; m/s/s		
	print,'171 speed: ' + string(speed) + ' km/s'		
	print,'171 accel: ' + string(accel) + ' m/s'		
			
	tim1 = tim_sec[n_elements(tim_sec)-1]
	tim0 = tim_sec[0]
	tim_sim = (findgen(100)*(tim1 - tim0)/99) +tim0
	dis_sim = p[0]*tim_sim^2.0 + p[1]*tim_sim + p[2]
	vel_171 = deriv(tim_sim, dis_sim)*1e3
			
	;--------------------------------------;
	;				193A
	;	
	cd, '~/Data/2014_Apr_18/sdo/193A'
	restore,'aia_193A_dt_points.sav', /verb
	
	tim193 = tim
	outplot, tim, dis, $
			color = 4, $
			psym = 2, $
			symsize=2
	
	;			Non-linear fit fit
	tim_sec = tim - tim[0]
	start = [0, 0.2, 40.0]
	fit = 'p[0]*x^2 + p[1]*x + p[2]'			
	p = mpfitexpr(fit, tim_sec, dis, err, yfit=yfit, start)

	outplot, tim, yfit, color = 4
	
	speed = p[1]*1.0e3		; km/s 
	accel = p[0]*1.0e6		; m/s/s		
	print,'193 initial speed: ' + string(speed) + ' km/s'		
	print,'193 accel: ' + string(accel) + ' m/s'		
		
		
	tim1 = tim_sec[n_elements(tim_sec)-1]
	tim0 = tim_sec[0]
	tim_sim = (findgen(100)*(tim1 - tim0)/99) +tim0
	dis_sim = p[0]*tim_sim^2.0 + p[1]*tim_sim + p[2]
	vel_193 = deriv(tim_sim, dis_sim)*1e3	
		
	;--------------------------------------;
	;				211A
	;	
	cd, '~/Data/2014_Apr_18/sdo/211A'
	restore,'aia_211A_dt_points.sav', /verb
	tim211 = tim
	outplot, tim, dis, $
			color = 6, $
			psym = 4, $
			symsize=2
			
	;			Non-linear fit fit
	tim_sec = tim - tim[0]
	start = [0, 0.2, 40.0]
	fit = 'p[0]*x^2 + p[1]*x + p[2]'			
	p = mpfitexpr(fit, tim_sec, dis, err, yfit=yfit, start)

	outplot, tim, yfit, color = 6
	
	speed = p[1]*1.0e3		; km/s 
	accel = p[0]*1.0e6		; m/s/s		
	print,'211 speed: ' + string(speed) + ' km/s'		
	print,'211 accel: ' + string(accel) + ' m/s'
	
	tim1 = tim_sec[n_elements(tim_sec)-1]
	tim0 = tim_sec[0]
	tim_sim = (findgen(100)*(tim1 - tim0)/99) +tim0
	dis_sim = p[0]*tim_sim^2.0 + p[1]*tim_sim + p[2]
	vel_211 = deriv(tim_sim, dis_sim)*1e3
	
	legend, ['171A', '193A', '211A'], $
			color=[5, 4, 6], $
			linestyle = 0, $
			box=0, $
			/left, $
			/top
	
	;***************************************;
	;			Plot Velocities
	;***************************************;
	
	
	;window, 1
	utplot, tim171[0]+tim_sim, vel_171, $
			title = 'Derivative of fit to dt points', $
			color = 5, $
			ytitle= 'POS Velocity (km/s)', $
			yr=[40, 250], $
			position = [xposl, 0.07, xposr, 0.47], $
			/noerase
			
	outplot, tim193[0]+tim_sim, vel_193, $
			color = 4
			
	outplot, tim211[0]+tim_sim, vel_211, $
			color = 6		
			
	
	legend, ['171A', '193A', '211A'], $
			color=[5, 4, 6], $
			linestyle = 0, $
			box=0, $
			/left, $
			/top
	
	
	if keyword_set(ps) then begin
		device, /close
		set_plot,'x'
	endif
	
	
stop	
	
END