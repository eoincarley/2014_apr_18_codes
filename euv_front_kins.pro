pro euv_front_kins

	; Code to calculate EUV front velocity from its x-y motion.

	!p.charsize = 1.0
	AU = 149e6	;  km
    folder = '~/Data/2014_apr_18/sdo/'	
    restore, folder + 'euv_front_pos_struct.sav'

    times = front_pos.times
    xarcs = transpose(front_pos.xarcsec)
    yarcs = transpose(front_pos.yarcsec)


    step=1		; This step size (or 30) produces a speed that mathces what it should be e.g., 
				; simply taking the first and last points as displacements and a time of 500 seconds gives ~360 km/s
	for i=0, n_elements(xarcs)-(step+1), step do begin
		
			;color = interpol(colors, tcolors, anytim(times[i], /utim))
			;plots, xarcs[i], yarcs[i], color=color, psym=sym, symsize=1.2
		
			x1 = xarcs[i]
			x2 = xarcs[i+step]
			y1 = yarcs[i]
			y2 = yarcs[i+step]
			dt = anytim(times[i+step], /utim) - anytim(times[i], /utim)

			displ_arcs = sqrt( (x2-x1)^2 + (y2-y1)^2 )
			displ_degs = displ_arcs/3600.0
			displ = AU*tan(displ_degs*!dtor)	;km

			if i eq 0 then begin
				displs = displ 
				times_tot = times[i] 
			endif else begin

			;	if times[i] gt times_tot[n_elements(times_tot)-1] then begin
					displs = [displs, displs[n_elements(displs)-1]+displ]
					times_tot = [times_tot, times[i]]
			;	endif
					
			endelse	

		;wait, 0.1
	endfor	 

	err = displs
	err[*] = 25.0*727.0 ;km

	window, 1, xs=600, ys=600
	utplot, times_tot, displs, $
			ytitle='Displacement (km)', $
			linestyle=0

	oploterror, times_tot, displs, err, color=1	

	tims_sec = anytim(times_tot, /utim) - anytim(times_tot[0], /utim)		
	result = linfit(tims_sec, displs, yfit=yfit)

	q = replicate({fixed:0, limited:[0,0], limits:[0.D,0.D]}, 3)
	;q(2).fixed = 1

	start = [0, 1000, 0]
	fit = 'p[0]*x^2 + p[1]*x + p[2]'			
	;fit = 'p[0] + p[1]*x'
	p = mpfitexpr(fit, tims_sec, displs, err, perror=perror, yfit=yfit, start);, parinfo=q)

	outplot, times_tot, yfit, linestyle=1

	print, 'Speed of EUV front: '+string(p[1], format='(f5.1)')+' +/- '+string(perror[1], format='(f5.1)')+' (km/s)'

STOP
END