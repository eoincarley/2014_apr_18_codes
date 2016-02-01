pro	calc_kins, tim, dis, color=color, tim_sim=tim_sim, vel_sim=vel_sim
		

		tim_sec = tim - tim[0]
		start = [1, 0.01, 50.0];, 3.0]
		fit = 'p[0]*x^3 + p[1]*x + p[2]'			
		pi = replicate({fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
		
		pi(0).limited(0) = 1
		pi(0).limits(0) = 0.0
		
		pi(1).limited(0) = 1
		pi(1).limits(0) = 0.001
		
		pi(2).limited(0) = 1
		pi(2).limits(0) = 40

		;pi(3).limited(0) = 1
		;pi(3).limits(0) = 2.0

		err=dis
		err[*]=5.0
		;oploterror, tim, dis, err, color=0
		p = mpfitexpr(fit, tim_sec, dis, err, yfit=yfit, start, parinfo=pi, bestnorm=bestnorm, dof=dof)

		outplot, tim, yfit, color = color
		
		speed = p[1]*1.0e3		; km/s 
		accel = p[0]*1.0e6		; m/s/s		
		print,'Initial speed: ' + string(speed) + ' km/s'		
		print,'Accel: ' + string(accel) + ' m/s'

		tim1 = tim_sec[n_elements(tim_sec)-1]
		tim0 = tim_sec[0]
		tim_sim = (findgen(100)*(tim1 - tim0)/99) +tim0
		dis_sim = p[0]*tim_sim^3 + p[1]*tim_sim + p[2]
		vel_sim = deriv(tim_sim, dis_sim)*1e3	;	km/s	
		tim_sim = tim_sim + tim[0]	; Chnage back to UT.
		;print, 'Final speed: '+string(vel_sim[0])

		chisqr_prob = chisqr_pdf(bestnorm, dof)*100.0
		if chisqr_prob gt 95.0 then outcome='Reject null hypothesis.' else outcome='Fail to reject null hypothesis.'	; If Chi Square is in worse 5% then reject the model.
		box_message, str2arr('Probability of better chi-square: '+string(chisqr_prob, format = '(f5.2)' )+' %,'+outcome)	

END

pro aia_dt_kins, tstart, tend

	; Develop further the code of aia_dt_speed

	; tstart and tend in UT.

	xposl = 0.15
	xposr = 0.9
	deproject = 1./cos(45.0*!dtor)

	;window, 0
	
	folder = '~/Data/2014_Apr_18/sdo/dist_time/'

	; Restore and plot cool then hot channels
	cool_dt_files = findfile(folder+'*cool_dt*.sav')
	hot_dt_files = findfile(folder+'*hot_dt*.sav')

	
	for i=0, n_elements(cool_dt_files)-1 do begin
		restore, cool_dt_files[i]
		dis = map_points.dis*deproject
		times = map_points.times
		;dis = dis[0:n_elements(dis)-1]
		;times = times[1:n_elements(times)-1]
		angle = map_points.angle

		utplot, times, dis, $
				title = 'Points from dt map', $
				ytitle ='Distance (Mm)', $
				yr = [40, 350], $
				/xs, $
				xrange = [tstart, tend], $
				/ys, $
				/noerase, $
				color = 5, $
				psym=1, $
				position = [xposl, 0.55, xposr, 0.95]	

		xyouts, times[n_elements(times)-1], dis[n_elements(dis)-1]+5., string(angle, format='(I03)'), $
				/data, color=5

		calc_kins, times, dis, color=5, tim_sim=tim_sim, vel_sim=vel_sim

		utplot, tim_sim, vel_sim, $
			ytitle = 'Velocity (km/s)', $
			/noerase, $
			yr = [1, 3000], $
			/ys, $
			/xs, $
			xrange = [tstart, tend], $
			position = [xposl, 0.05, xposr, 0.5], $
			thick=1, $
			symsize=1.5, $
			/ylog, $
			color = 5

	endfor	

	for i=0, n_elements(hot_dt_files)-1 do begin
		
		restore, hot_dt_files[i]
		dis = map_points.dis*deproject
		times = map_points.times
		angle = map_points.angle

		utplot, times, dis, $
				title = 'Points from dt map', $
				ytitle ='Distance (Mm)', $
				yr = [40, 350], $
				/xs, $
				xrange = [tstart, tend], $
				/ys, $
				/noerase, $
				color = 3, $
				psym=1, $
				position = [xposl, 0.55, xposr, 0.95]	

		xyouts, times[n_elements(times)-1], dis[n_elements(dis)-1]+5., string(angle, format='(I03)'), $
				/data, color=3

		calc_kins, times, dis, color=3, tim_sim=tim_sim, vel_sim=vel_sim

		utplot, tim_sim, vel_sim, $
			ytitle = 'Velocity (km/s)', $
			/noerase, $
			yr = [1, 3000], $
			/ys, $
			/xs, $
			xrange = [tstart, tend], $
			position = [xposl, 0.05, xposr, 0.5], $
			thick=1, $
			symsize=1.5, $
			/ylog, $
			color = 3		

	endfor	



END