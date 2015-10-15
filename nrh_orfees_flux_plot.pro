pro setup_ps, name
  
   set_plot,'ps'
   !p.font=0
   !p.charsize=1.5
   device, filename = name, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=10, $
          ysize=13, $
          bits_per_pixel=16, $
          /encapsulate, $
          yoffset=5

end

function get_goes, file

	readcol, file, y, m, d, hhmm, mjd, sod, short_channel, long_channel

	;-------- Time in correct format --------
	time  = strarr(n_elements(y))
	time[*] = string(y[*], format='(I04)') + string(m[*], format='(I02)') $
		  + string(d[*], format='(I02)') + '_' + string(hhmm[*], format='(I04)')

	;------ Get start and stop indices -----
	time = anytim(file2time(time), /utime)
	
	goes_array = dblarr( 3, n_elements(time) )
	goes_array[0, *] = time
	goes_array[1, *] = long_channel
	goes_array[2, *] = short_channel

	return, goes_array
	
END

pro plot_goes, goes, tstart, tend

	utplot, goes[0,*], goes[1,*], $
		psym=3, $
		/xs, $
		yrange=[1e-9, 1e-3], $
		/ylog, $
		ytitle = 'Watts m!U-2!N', $
		xrange = [tstart, tend], $
		position=[0.14, 0.78, 0.95, 0.99], $
		/normal, $
		XTICKFORMAT="(A1)", $
		xtitle=' '
		

	outplot, goes[0,*], goes[1,*], color=3 ;for some reason utplot won't color the line

	axis,yaxis=1,ytickname=[' ','A','B','C','M','X',' ']
	axis,yaxis=0,yrange=[1e-9,1e-3]

 	g0 = closest(goes[0,*], tstart)
  	g1 = closest(goes[0,*], tend)

	plots, goes[0, g0:g1], 1e-8, linestyle=1
	plots, goes[0, g0:g1], 1e-7, linestyle=1
	plots, goes[0, g0:g1], 1e-6, linestyle=1
	plots, goes[0, g0:g1], 1e-5, linestyle=1
	plots, goes[0, g0:g1], 1e-4, linestyle=1
	
	outplot, goes[0,*], goes[1,*], color=3
	outplot, goes[0,*], goes[2,*], color=5

	legend, ['GOES15 0.1-0.8nm','GOES15 0.05-0.4nm'], $
			linestyle=[0,0], $
			color=[3,5], $
			box=0, $
			pos=[0.14, 0.98],$
			/normal, $
			charsize=1.0
	
END

pro plot_fermi, date_start, date_end


	FermiGBM_file= '~/Data/2014_apr_18/fermi/fermi_ctime_n0_20140418_v00.sav'   

	restore, FermiGBM_file

	utplot, anytim(ut, /utim), binned[0,*], $
			/ylog, $
			yrange=[1.e-4, 1.e4], $
			position=[0.14,0.54,0.95,0.78], $
			XTICKFORMAT="(A1)", $
			;/nolabel, $
			xtitle=' ', $
			/noerase, $
			timerange=[date_start, date_end], $
			ytitle='counts [s!u-1!n cm!u-2!n keV!u-1!n]', $
			/xs, $
			color=6

	for k=1,3 do outplot, anytim(ut, /utim), binned[k,*], col=k+2

	eband_str = string(eband[0,*], format='(f5.1)')

	legend, [eband_str[0]+' keV', eband_str[1]+' keV', eband_str[2]+' keV', eband_str[3]+' keV'], $
			color = [6,3,4,5], $
			linestyle = [0,0,0,0], $
			box=0, $
			charsize=1.0, $
			pos = [0.15, 0.76], $
			/normal, $
			thick=3

	xyouts, 0.15, 0.76, 'FERMI GBM', /normal, charsize=1.0	

END

pro nrh_orfees_flux_plot, postscript=postscript

	if keyword_set(postscript) then begin
		setup_ps, '~/Data/2014_apr_18/nrh_orfees_goes_flux.eps'
	endif else begin
		loadct, 0
		!p.background=255
		!p.color=0
		!p.multi=[0,1,1]
		!p.charsize=1.5
		window, 0, xs=1000, ys=1300
	endelse

	set_line_color

	time0 = '20140418_123000'
	time1 = '20140418_133000'

	t0plot = anytim(file2time('20140418_123000'), /utim)
	t1plot = anytim(file2time('20140418_131000'), /utim)

	;-----------------------;
	;	    Plot GOES
	;
	goes = get_goes('~/Data/2014_apr_18/goes/20140418_Gp_xr_1m.txt')
	plot_goes, goes, t0plot, t1plot


	;-----------------------;
	;	   Plot FERMI
	;
	plot_fermi, t0plot, t1plot


	;-----------------------;
	;	   Read Orfees
	;
	cd,'~/Data/2014_apr_18/radio/orfees/'
	null = mrdfits('orf20140418_101743.fts', 0, hdr0)
	fbands = mrdfits('orf20140418_101743.fts', 1, hdr1)
	freqs = [ fbands.FREQ_B1, $
			  fbands.FREQ_B2, $
			  fbands.FREQ_B3, $
			  fbands.FREQ_B4, $
			  fbands.FREQ_B5  ]

	nfreqs = n_elements(freqs)		
	freqs = reverse(freqs)	
	
	null = mrdfits('orf20140418_101743.fts', 2, hdr_bg, row=0)
	tstart = anytim(file2time('20140418_101743'), /utim)
	
	;--------------------------------------------------;
	;				 Choose time range
	t0 = anytim(file2time(time0), /utim)
	t1 = anytim(file2time(time1), /utim)
	inc0 = (t0 - tstart)*10.0 ;Sampling time is 0.1 seconds
	inc1 = (t1 - tstart)*10.0 ;Sampling time is 0.1 seconds
	range = [inc0, inc1]
	data = mrdfits('orf20140418_101743.fts', 2, hdr2, range = range)
	
	
	tstart = anytim(file2time('20140418_000000'), /utim)
	time_b1 = tstart + data.TIME_B1/1000.0
	time_b2 = tstart + data.TIME_B2/1000.0 
	time_b3 = tstart + data.TIME_B3/1000.0 
	time_b4 = tstart + data.TIME_B4/1000.0 
	time_b5 = tstart + data.TIME_B5/1000.0 

	;***********************************;
	;			Orfees Flux		
	;***********************************;	

	data = transpose([data.stokesi_b1, data.stokesi_b2, data.stokesi_b3, data.stokesi_b4, data.stokesi_b5])
	data = reverse(data, 2)


	;spectro_plot, sigrange(data), time_b1, freqs, $
	;		/xs, $
	;		/ys

	nrh_freqs = [150.0, 173.0, 228.0, 270.0, 293.0, 327.0, 408.0, 432.0, 405.0]
	orfees_fluxes = dblarr(n_elements(time_b1), n_elements(nrh_freqs))
	indices = nrh_freqs
	for i=0, n_elements(nrh_freqs)-1 do begin
		index = closest(freqs, nrh_freqs[i])
		orfees_fluxes[*, i] = data[*, index]
	endfor	

	times = time_b1
	for i=0, n_elements(nrh_freqs)-1,2 do begin

		fluxes = orfees_fluxes[*, i]

		if i eq 0 then begin
			utplot, times, smooth(fluxes, 1), $
					/xs, $
					/ys, $
					xr = [t0plot, t1plot], $
					/ylog, $
					color=0, $
					pos = [0.14, 0.30, 0.95, 0.54], $
					/noerase, $
					;title='Orfees', $
					ytitle='Flux (Arbitrary Units)', $
					XTICKFORMAT="(A1)", $
					xtitle=' '
			xyouts, 0.82, 0.52, 'Orfees '+string(nrh_freqs[i], format='(I03)')+' MHz', color=0, /normal, charsize=1.0
		endif else begin
			outplot, times, smooth(fluxes, 1), $
					color=i+1
			xyouts, 0.82, 0.52-i/120.0, 'Orfees '+string(nrh_freqs[i], format='(I03)')+' MHz', color=i+1, /normal, charsize=1.0
		endelse		
	endfor


	;***********************************;
	;			NRH Flux		
	;***********************************;	


	restore,'~/Data/2014_apr_18/radio/nrh/nrh_flux_20140418.sav', /verb

	for i=0, (size(flux_struct))[2],2 do begin

		success = execute('data = flux_struct.'+ (tag_names(flux_struct))[i])
		times = anytim(data[*, 0], /utim)
		fluxes = data[*, 1]
		if i eq 0 then begin
			utplot, times, smooth(fluxes, 2), $
					/xs, $
					/ys, $
					xr = [t0plot, t1plot], $
					color=0, $
					/ylog, $
					ytitle='Flux Density (SFU)', $
					yr=[0.1, 600], $
					pos = [0.14, 0.07, 0.95, 0.30], $
					/noerase;, $
					;title='Nancay Radioheliograph'
			xyouts, 0.82, 0.28, (tag_names(flux_struct))[i]+' MHz', color=0, /normal, charsize=1.0
		endif else begin
			outplot, times, smooth(fluxes, 2), $
					color=i+1
			xyouts, 0.82, 0.28-i/140.0, (tag_names(flux_struct))[i]+' MHz', color=i+1, /normal, charsize=1.0		
		endelse		
		
	endfor			

	if keyword_set(postscript) then begin
		device, /close
		set_plot, 'x'	
	endif

	STOP

	;***********************************;
	;		   Relative Flux		
	;***********************************;	

	for i=0, (size(flux_struct))[2] do begin
		wset, 0
		success = execute('data = flux_struct.'+ (tag_names(flux_struct))[i])
		times = data[*, 0]
		nrh_flux = smooth(data[*, 1],20);/max(data[*,1])

		orfees_flux = smooth(orfees_fluxes[*, i],20);/max(orfees_fluxes[*, i])
		

		nrh_flux = congrid(nrh_flux, n_elements(orfees_flux))

		rel_flux = orfees_flux[5000:10000]/nrh_flux[5000:10000]

		if i eq 0 then begin
			plot, orfees_flux[5000:10000], 1/rel_flux, $;times, smooth(rel_flux,10), $
					/xs, $
					/ys, $
					xr = [1000, 2e4], $
					color=0, $
					/ylog, $
					/xlog, $
					psym=1
					;ytitl='Flux Density (SFU)', $
					;yr=[0.0, 100]
			;xyouts, 0.9, 0.92, (tag_names(flux_struct))[i], color=0, /normal
		endif else begin
			oplot, orfees_flux, 1/rel_flux, $
					color=i+1, psym=1
			;xyouts, 0.9, 0.92-i/50.0, (tag_names(flux_struct))[i], color=i+1, /normal		
		endelse		
		stop
	endfor			


	stop


END