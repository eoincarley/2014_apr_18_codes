pro radio_kins_norm_height_error

	;+
	; Assumed normalisation starting height of 50 Mm for 445 MHz. This finds the speed increase 
	; assuming the norm height is 100 Mm for 445 MHz.
	;-

	folder = '~/Data/2014_apr_18/radio/kinematics/error'
	radio_kins_files_100 = findfile(folder+'/*speeds_100Mm.sav')
	radio_kins_files_50 = findfile(folder+'/*speeds_50Mm.sav')	

	for i=0, n_elements(radio_kins_files_100)-1 do begin
	
		restore, radio_kins_files_100[i], /verb
		saito_100Mm = (burst_speeds.saito_fold_speed)[1]
		newkirk_100Mm = (burst_speeds.newkirk_fold_speed)[1]
		baum_100Mm = (burst_speeds.baum_fold_speed)[1]
		leblanc_100Mm = (burst_speeds.leblanc_fold_speed)[1]
		mann_100Mm = (burst_speeds.mann_fold_speed)[1]

		restore, radio_kins_files_50[i], /verb
		saito_50Mm = (burst_speeds.saito_fold_speed)[1]
		newkirk_50Mm = (burst_speeds.newkirk_fold_speed)[1]
		baum_50Mm = (burst_speeds.baum_fold_speed)[1]
		leblanc_50Mm = (burst_speeds.leblanc_fold_speed)[1]
		mann_50Mm = (burst_speeds.mann_fold_speed)[1]

		saito_error = 100*(saito_100Mm - saito_50Mm)/saito_50Mm
		newkirk_error = 100*(newkirk_100Mm - newkirk_50Mm)/newkirk_50Mm
		baum_error = 100*(baum_100Mm - baum_50Mm)/baum_50Mm
		leblanc_error = 100*(leblanc_100Mm - leblanc_50Mm)/leblanc_50Mm
		mann_error = 100*(mann_100Mm - mann_50Mm)/mann_50Mm

		print, '-----------------------------'
		print, burst_speeds.name
		print, 'Saito error: ' + string(saito_error) + ' %'
		print, 'Newkirk error: ' + string(newkirk_error)+ ' %'
		print, 'Baum error: ' + string(baum_error) + ' %'
		print, 'Leblanc error: ' + string(leblanc_error) + ' %'
		print, 'Mann error: ' + string(mann_error) + ' %'

		mean_err = (saito_error+newkirk_error+baum_error+leblanc_error+mann_error)/5.0
		print, 'Mean error: '+string(mean_err) + '%'

		stop
	endfor





END