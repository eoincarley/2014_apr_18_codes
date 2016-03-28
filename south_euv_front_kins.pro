pro south_euv_front_kins
	
	; Get kinematics for EUV front along south pole during 2014-Apr-18 event
	window, 0
	folder = '/Users/eoincarley/Data/2014_apr_18/sdo/'
	restore,'aia_cool_arc_dtpoints.sav', /verb
	calc_kins_pl, map_points.times, map_points.dis, tim_sim=tim_sim, dis_sim=dis_sim, vel_sim=vel_sim
	
	utplot, map_points.times, map_points.dis, psym=4, charsize=1.5, ytitle='Distance (Mm)'
	set_line_color
	outplot, tim_sim, dis_sim, linestyle=0, color=5

	window, 1
	utplot, tim_sim, vel_sim, linestyle=0, color=5, ytitle='Velocity (km/s)'


END	