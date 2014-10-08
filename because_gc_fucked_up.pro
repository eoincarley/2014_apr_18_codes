pro because_gc_fucked_up

cd,'~/Data/2014_Apr_18/sdo/211A/'

files = findfile('*.png')

FOR i=0, n_elements(files)-1 DO BEGIN
	spawn,'cp '+files[i]+' '+string(i,format='(I03)')+'.png'
ENDFOR


END