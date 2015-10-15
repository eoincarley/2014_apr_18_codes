pro fermi_get_data

	;Fermi_GBM_string='http://heasarc.gsfc.nasa.gov/FTP/fermi/data/gbm/daily/'+d[0]+'/'+d[1]+'/'+num2str(fix(strmid(d[2],0,2))+1,length=2,padchar='0',padtype=1)+'/current/glg_ctime_n'+dect+'_'+strmid(d[0],2,2)+d[1]+num2str(fix(strmid(d[2],0,2))+1,length=2,padchar='0',padtype=1)+'_v00.pha'


	;sock_copy, Fermi_GBM_string, out_dir=FermiGBM_dataloc

	window, 0
	!p.charsize=1.5
	set_line_color

	date_start = '2014-04-18T12:20:00'
	date_end = '2014-04-18T13:20:00'

	FermiGBM_file= '~/Data/2014_apr_18/fermi/glg_ctime_n0_140418_v00.pha' ;FermiGBM_dataloc+'glg_ctime_n'+dect+'_'+strmid(d[0],2,2)+d[1]+num2str(fix(strmid(d[2],0,2))+1,length=2,padchar='0',padtype=1)+'_v00.pha'
	print, FermiGBM_file 


	o=ospex()
	o->set,spex_specfile=FermiGBM_file	

	data = o->getdata(spex_units='flux')
	dobj = o->get(/obj, class='spex_data')
	eband = o->get(/spex_eband)
	binned = dobj->bin_data(data=data, intervals=eband)
	ut = o->getaxis(/ut,/mean)

	window, 0
	set_line_color
	utplot, anytim(ut,/ext), binned[0,*], $
			/ylog, $
			yrange=[1.e-4, 1.e4], $
			;position=[0.1,0.41,0.95,0.6], $
			;XTICKFORMAT="(A1)", $
			;/nolabel, $
			;/noerase, $
			timerange=[date_start, date_end], $
			ytitle='counts [s!u-1!n cm!u-2!n keV!u-1!n]', $
			/xs

	for k=0,3 do outplot, anytim(ut,/ext), binned[k,*], col=k+2

	eband_str = string(eband[0,*], format='(f5.1)')

	legend, [eband_str[0]+' keV', eband_str[1]+' keV', eband_str[2]+' keV', eband_str[3]+' keV'], $
			color = [2,3,4,5], $
			linestyle = [0,0,0,0], $
			box=0, $
			charsize=1.5

	save, ut, binned, eband, filename='fermi_ctime_n0_20140418_v00.sav', $
			description='Just the lightcurves and time. No need to call object.'	


STOP

END