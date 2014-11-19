pro wavelet_analysis_20110922

;-------------------------------------------------------------------------;
;		Produces Supplementary Figure 1 for final draft of the paper      ;
;

cd,'~/Data/CALLISTO/20110922'
loadct,5

;-----------------------------------;
;		Set postscript variables
;-----------------------------------;

set_plot,'ps'
!p.font=0
device, filename='herbone_wavelet.ps', /helvetica, /color, /inches, /landscape, /encapsulate,$
xs=10, ys=10, yoffset=10, bits_per=16
!p.charsize=1
!p.charthick=0.2

xright = 0.7
xleft = 0.1
;-----------------------------------;
;		Plot Herringbones
;-----------------------------------;

files = findfile('*01.fit')
radio_spectro_fits_read,files[0], low1data, l1time, lfreq
radio_spectro_fits_read,files[1], low2data, l2time, lfreq
radio_spectro_fits_read,files[2], low3data, l3time, lfreq
low_FM_index = where(lfreq gt 90.0)
low_data = [temporary(low1data), temporary(low2data), temporary(low3data)]
low_times = [temporary(l1time), temporary(l2time), temporary(l3time)]
low_data_bg = constbacksub(low_data, /auto)
low_data_bg[*,  low_FM_index[0] : low_FM_index[n_elements(low_FM_index)-1] ] = -15.0


t1_hb = anytim(file2time('20110922_105120'),/utim)
t2_hb = anytim(file2time('20110922_105300'),/utim)

spectro_plot, low_data_bg > (5.0) , low_times, lfreq,  /ys,$
xr=[t1_hb,t2_hb], yr=[90,20], yticks=7, yminor=2, $
xticklen=-0.01, yticklen=-0.01, ytitle='Frequency (MHz)', /noerase, xtitle=' ',$
position=[xleft, 0.7, xright, 0.95], xtyle=4, title='RSTO eCallisto', charthick=0.2
set_line_color

xyouts, 0.11, 0.93, 'a', color=1, /normal 

tsim = (dindgen(100)*(t2_hb - t1_hb)/99.0 ) + t1_hb
fsim = fltarr(100)
fsim[*] = 54.44
plots, tsim, fsim, color=1, thick=5
loadct,5


;--------------------------------------------;
;		    Extract a time series
;--------------------------------------------;
freq = (dindgen(101)*(58. - 50.)/100.0)+50.0

i = closest(lfreq, 54.4)
tseries = low_data_bg[*, i]
utplot, low_times, tseries, xr=[t1_hb, t2_hb], yr=[0,60], $
position=[xleft, 0.46, xright, 0.66], /noerase, ytitle='Intensity (Arbitrary Units)', xtitle='Time in UT on 22-Sep-2011'
save, low_times, tseries, filename='tseries_wavelet.sav'
xyouts, 0.11, 0.64, 'b', color=0, /normal 

legend,['Time series: '+string(round(lfreq[i]*100.0)/100.0, format='(f5.2)')+' MHz'], $
linestyle=[0], box=0, /bottom, /right

t1_index = closest(low_times, t1_hb)
t2_index = closest(low_times, t2_hb)
tseries = tseries[t1_index:t2_index]
dt = low_times[1] - low_times[0]
t = low_times[t1_index:t2_index]

;--------------------------------------------;
;		    Wavelet analysis
;--------------------------------------------;
wave = wavelet(tseries, dt, mother='DOG', period = period, coi=coi, SIGNIF=signif, /pad, S0=dt*0.25, SCALE=scale, fft_theor = fft_theor)


;--------------------------------------------;
;		    Plot wavelet spectrum
;--------------------------------------------;
loadct,5
CONTOUR, bytscl(abs(wave),-5,35),t-t[0],period, $
/xs,XTITLE='Time in seconds after 10:51:20 UT',YTITLE='Period (s)',TITLE='Wavelet Transform (DOG)-' +string(round(lfreq[i]*100.0)/100.0, format='(f5.2)')+' MHz', $
YRANGE=[MAX(period),MIN(period)], $   ;*** Large-->Small period
/YTYPE, $                             ;*** make y-axis logarithmic
NLEVELS=25,/FILL, position=[xleft, 0.1, xright, 0.38], /noerase, charsize=1.0
	

wave_y =wave
wave_z =wave

FOR i = 0, n_elements(wave[*,0])-1 DO BEGIN
	index = where(period lt coi[i]) 
	IF index[0] ne -1 THEN BEGIN
		wave_y[i, index] = !values.f_nan
		wave_z[i, index] = 0.0
	ENDIF	
ENDFOR	

;-----------------------------------------------------;
;	Plot regions outside the cone of influence in grey
;-----------------------------------------------------;
loadct,0
CONTOUR, bytscl(abs(wave_y),-5,35),t-t[0],period, $
/xs,XTITLE='Time in seconds after 10:51:20 UT',YTITLE='Period (s)',TITLE=' ', $
YRANGE=[MAX(period),MIN(period)], $   ;*** Large-->Small period
/YTYPE, $                             ;*** make y-axis logarithmic
NLEVELS=25,/FILL, position=[xleft, 0.1, xright, 0.38], /noerase
	









ntime = n_elements(t)
nscale = N_ELEMENTS(period)
signif = WAVE_SIGNIF(tseries,dt,scale)
signif = REBIN(TRANSPOSE(signif),ntime,nscale)
	;signif = REBIN(TRANSPOSE(signif), ntime, nscale)
	
;-----------------------------;	
;  Plot significance levels	
;-----------------------------;
       set_line_color
CONTOUR,abs(wave)^2.0/signif, t-t[0], period, $
      /OVERPLOT,LEVEL=1.0,C_ANNOT='95%', color=4

PLOTS,t-t[0], coi, NOCLIP=0 , thick=6, color=4


xyouts, 0.11, 0.36, 'c', color=0, /normal 

device, /close
set_plot, 'x'



END