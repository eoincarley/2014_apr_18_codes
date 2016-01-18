pro nrh_flux_plot_v2

	; Plot the AR source

	time0 = '20140418_124800'
	time1 = '20140418_125600'
	t0plot = anytim(file2time(time0), /utim)
	t1plot = anytim(file2time(time1), /utim)
	date_string = time2file(file2time(time0), /date)
	nrh_folder = '~/Data/2014_apr_18/radio/nrh/'

	set_line_color
	window, 10, xs=400, ys=1200
	!p.charsize=1.0

	nrh_flux_files1 = findfile(nrh_folder+'*src1.sav')
	nrh_flux_files2 = findfile(nrh_folder+'*src2.sav')
	yshift=0.15

	for i=0, n_elements(nrh_flux_files1)-1 do begin
		
		; AR source	
		print, 'Reading '+nrh_flux_files1[i] 
		restore, nrh_flux_files1[i], /verb
		time1 = anytim(SFU_TIME_STRUCT.time, /utim)
		flux1 = SFU_TIME_STRUCT.flux

		; Small moving source		
		print, 'Reading '+nrh_flux_files2[i] 
		restore, nrh_flux_files2[i], /verb
		time2 = anytim(SFU_TIME_STRUCT.time, /utim)
		flux2 = SFU_TIME_STRUCT.flux	

		if i eq n_elements(nrh_flux_files1)-1 then begin
			xtitle='Start time: '+anytim(time1[0], /cc, /trun) 
			xtickfmt = ''
		endif else begin
			xtitle='' 
			xtickfmt="(A1)"
		endelse	

		set_line_color
		utplot, time1, flux1, $
				/xs, $
				/ys, $
				/ylog, $
				yr=[1,1e3], $
				xr = [t0plot, t1plot], $
				color=1, $
				thick=1.0, $
				pos = [0.15, 0.80 - (i*yshift), 0.95, 0.95 - (i*yshift)], $
				/noerase, $
				xgridstyle = 0.0, $
				ygridstyle = 0.0, $
				XTICKFORMAT=xtickfmt, $
				xtitle = xtitle, $
				ytitle='Flux (SFU)'	

		outplot, time2, flux2, $
				color=3, $
				thick=1

		xyouts, 0.17, 0.95 - (i*yshift) - 0.02, 'NRH ' + string(SFU_TIME_STRUCT.freq, format='(I3)') + ' MHz', /normal
	endfor			


STOP




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

END