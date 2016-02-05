pro cme_back_extrapolate


	; First plot up SWAP, LASCO and NRH

	swap_c2_nrh_20140418
	AU = 150e6 			; km
	cme_speed = 1000.0 	; km/s
	time = 14.0*60.0
	pos_shift = cme_speed*time
	arc_shift = atan(pos_shift/AU)*!radeg*3600.0


	; Define rads

	n_points_rad = 3500.0
	rhos = dindgen(n_points_rad)
	angle1=12.
	angle2=-135.
	angles = (findgen(100)*(angle2-angle1)/99.0)+angle1

    ; Choose origin point

    print, 'Choose origin: '
    cursor, xorigin, yorigin, /data

    set_line_color
    for i=0, n_elements(angles)-1 do begin
    	theta = angles[i]*!dtor
    	xs = COS(theta) * rhos + xorigin
		ys = SIN(theta) * rhos + yorigin
		plots, xs, ys, color=4

		print, 'Choose CME front: '
		wait, 0.5
		cursor, xfront, yfront, /data

		xpoint = xfront - COS(theta) * arc_shift 
		ypoint = yfront - SIN(theta) * arc_shift

		plots, xpoint, ypoint, color=3, psym=1

		if i eq 0 then xpoints = xpoint else xpoints = [xpoints, xpoint]
		if i eq 0 then ypoints = ypoint else ypoints = [ypoints, ypoint]
		
	endfor	

	swap_c2_nrh_20140418

	plots, xpoints, ypoints, /data, color=1

STOP
END