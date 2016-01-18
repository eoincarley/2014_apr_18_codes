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
			yrange=[1.e-2, 1.e2], $
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
		!p.charsize=1.0
		window, 12, xs=500, ys=500
	endelse

	set_line_color

	time0 = '20140418_124800'
	time1 = '20140418_125500'
	date_string = time2file(file2time(time0), /date)
	orfees_folder = '~/Data/2014_apr_18/radio/orfees/'

	t0plot = anytim(file2time(time0), /utim)
	t1plot = anytim(file2time(time1), /utim)

	;-----------------------;
	;	    Plot GOES
	;
	;goes = get_goes('~/Data/2014_apr_18/goes/20140418_Gp_xr_1m.txt')
	;plot_goes, goes, t0plot, t1plot


	;-----------------------;
	;	   Plot FERMI
	;
	;plot_fermi, t0plot, t1plot


	restore, orfees_folder+'orf_'+date_string+'_bsubbed_minimum.sav', /verb
	orf_spec = orfees_struct.spec
	orf_time = orfees_struct.time
	orf_freqs = orfees_struct.freq

 	;hfreq_img = orf_spec - smooth(orf_spec, 20)
    ;orf_spec = orf_spec + 3.5*hfreq_img

	nrh_freqs = [327.0] ;	[150.0, 173.0, 228.0, 270.0, 293.0, 327.0, 408.0, 432.0, 405.0]
	orfees_fluxes = dblarr(n_elements(orf_time), n_elements(nrh_freqs))
	indices = nrh_freqs
	for i=0, n_elements(nrh_freqs)-1 do begin
		index = closest(orf_freqs, nrh_freqs[i])
		orfees_fluxes[*, i] = orf_spec[*, index]
	endfor	

	for i=0, n_elements(nrh_freqs)-1 do begin

		fluxes = orfees_fluxes[*, i]

		if i eq 0 then begin
			utplot, orf_time, smooth(fluxes, 10), $
					/xs, $
					/ys, $
					xr = [t0plot, t1plot], $
					yr=[0.2, 1.2], $
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
			outplot, orf_time, smooth(fluxes, 1), $
					color=i+1
			xyouts, 0.82, 0.52-i/120.0, 'Orfees '+string(nrh_freqs[i], format='(I03)')+' MHz', color=i+1, /normal, charsize=1.0
		endelse		

	endfor


	;***********************************;
	;			  NRH Flux		
	;***********************************;	


	restore,'~/Data/2014_apr_18/radio/nrh/nrh_flux_327_20140418_src1.sav', /verb
	time = anytim(SFU_TIME_STRUCT.time, /utim)
	flux1 = SFU_TIME_STRUCT.flux
	utplot, time, smooth(flux1, 2), $
					/xs, $
					/ys, $
					xr = [t0plot, t1plot], $
					color=0, $
					/ylog, $
					ytitle='Flux Density (SFU)', $
					yr=[0.1, 1000], $
					pos = [0.14, 0.07, 0.95, 0.30], $
					/noerase


	restore,'~/Data/2014_apr_18/radio/nrh/nrh_flux_327_20140418_src2.sav', /verb
	time = anytim(SFU_TIME_STRUCT.time, /utim)
	flux2 = SFU_TIME_STRUCT.flux + flux1
	utplot, time, smooth(flux2, 2), $
					/xs, $
					/ys, $
					xr = [t0plot, t1plot], $
					color=0, $
					/ylog, $
					ytitle='Flux Density (SFU)', $
					yr=[0.1, 1000], $
					pos = [0.14, 0.07, 0.95, 0.30], $
					/noerase				



STOP
	for i=5, 5 do begin		; (size(flux_struct))[2],2 do begin

		success = execute('data = flux_struct.'+ (tag_names(flux_struct))[i])
		times = anytim(data[*, 0], /utim)
		fluxes = data[*, 1]

		if i eq 5 then begin
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