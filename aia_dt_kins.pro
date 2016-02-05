pro	calc_kins, tim, dis, color=color, tim_sim=tim_sim, vel_sim=vel_sim
		

		tim_sec = tim - tim[0]
		start = [1, 50.0];, 3.0]
		fit = 'p[0]*x^3 + p[1]'			
		pi = replicate({fixed:0, limited:[0,0], limits:[0.D,0.D]}, 2)
		
		pi(0).limited(0) = 1
		pi(0).limits(0) = 0.0
		
		pi(1).limited(0) = 1
		pi(1).limits(0) = 40
		
		;pi(2).limited(0) = 1
		;pi(2).limits(0) = 40

		;pi(3).limited(0) = 1
		;pi(3).limits(0) = 2.0

		err=dis
		err[*]=5.0
		;oploterror, tim, dis, err, color=0
		p = mpfitexpr(fit, tim_sec, dis, err, yfit=yfit, start, parinfo=pi, bestnorm=bestnorm, dof=dof)

		;outplot, tim, yfit, color = color
		
		;speed = p[1]*1.0e3		; km/s 
		;accel = p[0]*1.0e6		; m/s/s		
		;print,'Initial speed: ' + string(speed) + ' km/s'		
		;print,'Accel: ' + string(accel) + ' m/s'

		tim1 = tim_sec[n_elements(tim_sec)-1]
		tim0 = tim_sec[0]
		tim_sim = (findgen(100)*(tim1 - tim0)/99) +tim0
		dis_sim = p[0]*tim_sim^3 + p[1]
		vel_sim = deriv(tim_sim, dis_sim)*1e3	;	km/s	
		tim_sim = tim_sim + tim[0]	; Chnage back to UT.
		;print, 'Final speed: '+string(vel_sim[0])

		chisqr_prob = chisqr_pdf(bestnorm, dof)*100.0
		if chisqr_prob gt 95.0 then outcome='Reject null hypothesis.' else outcome='Fail to reject null hypothesis.'	; If Chi Square is in worse 5% then reject the model.
		box_message, str2arr('Probability of better chi-square: '+string(chisqr_prob, format = '(f5.2)' )+' %,'+outcome)	

END

pro aia_dt_kins, tstart, tend, deproject

	; Develop further the code of aia_dt_speed

	; tstart and tend in UT.

	xposl = 0.15
	xposr = 0.9

	;window, 0
	
	folder = '~/Data/2014_Apr_18/sdo/dist_time/'

	; Restore and plot cool then hot channels
	cool_dt_files = findfile(folder+'*cool_dt*.sav')
	hot_dt_files = findfile(folder+'*hot_dt*.sav')

	
	for i=0, n_elements(cool_dt_files)-1 do begin
		restore, cool_dt_files[i]
		dis = map_points.dis*deproject
		times = map_points.times
		
		angle = map_points.angle

		; The following commented out commands plot dist v time.
		;utplot, times, dis, $
		;		title = 'Points from dt map', $
		;		ytitle ='Distance (Mm)', $
		;		yr = [40, 350], $
		;		/xs, $
		;		xrange = [tstart, tend], $
		;		/ys, $
		;		;/noerase, $
		;		color = 5, $
		;		psym=1, $
		;		position = [xposl, 0.55, xposr, 0.95], $
		;		xtickformat='(A1)'
		;xyouts, times[n_elements(times)-1], dis[n_elements(dis)-1]+5., string(angle, format='(I03)'), $
		;		/data, color=5

		calc_kins, times, dis, color=5, tim_sim=tim_sim, vel_sim=vel_sim
		print, angle

		if [angle] eq [020] then begin
			if i eq 0 then $
				utplot, tim_sim, vel_sim, $
					ytitle = 'Velocity (km s!U-1!N)', $
					/noerase, $
					yr = [1, 3000], $
					/ys, $
					/xs, $
					xrange = [tstart, tend], $
					position = [xposl, 0.07, xposr, 0.52], $
					thick=4, $
					;symsize=1.5, $
					/ylog, $
					color = 10;, $
					;linestyle=2

			print, 'Cold angle is: '+string(angle, format='(I03)')

		endif		
		if angle eq [260] then $	
				outplot, tim_sim, vel_sim, color = 5, thick=4, linestyle=2		

		if i eq 0 then vel_fin = vel_sim[n_elements(vel_sim)-1]	else vel_fin = [vel_fin, vel_sim[n_elements(vel_sim)-1]]

	endfor	

	for i=0, n_elements(hot_dt_files)-1 do begin
		
		restore, hot_dt_files[i]
		dis = map_points.dis*deproject
		times = map_points.times
		angle = map_points.angle

		; The following commented out commands plot dist v time.
		;utplot, times, dis, $
		;		title = 'Points from dt map', $
		;		ytitle ='Distance (Mm)', $
		;		yr = [40, 350], $
		;		/xs, $
		;		xrange = [tstart, tend], $
		;		/ys, $
				;/noerase, $
		;		color = 3, $
		;		psym=1, $
		;		position = [xposl, 0.55, xposr, 0.95], $
		;		xtickformat='(A1)'	
		;xyouts, times[n_elements(times)-1], dis[n_elements(dis)-1]+5., string(angle, format='(I03)'), $
		;		/data, color=3

		calc_kins, times, dis, color=3, tim_sim=tim_sim, vel_sim=vel_sim

		if [angle] eq [020] then begin
			if i eq 0 then $
				utplot, tim_sim, vel_sim, $
					ytitle = 'Velocity (km s!U-1!N)', $
					/noerase, $
					yr = [1, 3000], $
					/ys, $
					/xs, $
					xrange = [tstart, tend], $
					position = [xposl, 0.07, xposr, 0.52], $
					thick=4, $
					;symsize=1.5, $
					xgridstyle = 1.0, $
					/ylog, $
					color = 3

					
			if i gt 0 then $	
				outplot, tim_sim, vel_sim, color=3, thick=4

			print, 'Hot angle is: '+string(angle, format='(I03)')			
			;xyouts, times[fix(n_elements(times)/2)], dis[fix(n_elements(times)/2)]+5., string(angle, format='(I03)'), $
			;	/data, color=
		endif	

		if angle eq 260 then $	
			outplot, tim_sim, vel_sim, color = 3, thick=4, linestyle=2	


		vel_fin = [vel_fin, vel_sim[n_elements(vel_sim)-1]]	


	endfor	

	print, vel_fin
	print, mean(vel_fin)
	

END