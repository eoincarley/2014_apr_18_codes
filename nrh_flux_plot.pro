pro nrh_flux_plot

	restore,'nrh_flux_20140418.sav', /verb

	loadct, 0
	!p.background=255
	!p.color=0
	window, 0
	set_line_color

	for i=0, (size(flux_struct))[2] do begin

		success = execute('data = flux_struct.'+ (tag_names(flux_struct))[i])
		times = data[*, 0]
		fluxes = data[*, 1]

		if i eq 0 then begin
			utplot, times, smooth(fluxes, 5), $
					/xs, $
					/ys, $
					color=0, $
					/ylog, $
					ytitl='Flux Density (SFU)', $
					yr=[0.1,500]
			xyouts, 0.9, 0.92, (tag_names(flux_struct))[i], color=0, /normal
		endif else begin
			outplot, times, smooth(fluxes, 5), $
					color=i+1
			xyouts, 0.9, 0.92-i/50.0, (tag_names(flux_struct))[i], color=i+1, /normal		
		endelse		
		
	endfor			


	stop


END