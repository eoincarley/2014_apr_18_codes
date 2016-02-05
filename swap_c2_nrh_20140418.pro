pro setup_ps, name

    set_plot,'ps'
    !p.font=0
    !p.charsize=1.2
    device, filename = name, $
          ;/decomposed, $
          /color, $
          /helvetica, $
          /inches, $
          xsize=7, $
          ysize=7, $
          /encapsulate, $
          bits_per_pixel=32

end

pro swap_c2_nrh_20140418, postscript = postscript

    ; Code to combine AIA, NRH and C2 observations of eruptive event on 2014-Apr-18
    if keyword_set(postscript) then begin
        setup_ps, '~/Data/2014_apr_18/swap_nrh_c2_20140418_2.eps
    endif else begin
        winsz=700
        !p.charsize=1.5       
        window, 0, xs=winsz, ys=winsz
    endelse  

    loadct, 57 ;33
    FOV = [5000/60.0, 5000/60.0]
    CENTER = [1000.0, -1000.0]

    ;--------------------------------------;
    ;----------------C2 Data---------------;
    ;--------------------------------------;
    cd,'~/Data/2014_Apr_18/white_light/lasco/c2/l1/'
    c2_files = findfile('*.fts')
    c2index=1
    pre = lasco_readfits(c2_files[c2index], c2hdr_pre)
    mask = lasco_get_mask(c2hdr_pre)
    pre = pre*mask
    img = lasco_readfits(c2_files[c2index+1], c2hdr)
    img = img*mask
    imgbs = img - pre
    imgbs = (imgbs- mean(imgbs))/stdev(imgbs)
    c2map = make_map(imgbs)
    c2map.dx = 11.9
    c2map.dy = 11.9
    c2map.xc = 14.4704
    c2map.yc = 61.2137


    ;--------------------------------------;
    ;--------------SWAP Data---------------;
    ;--------------------------------------;   
    ;window, 1 
    cd,'~/Data/2014_Apr_18/swap/'
    swap_files = findfile('*.fits')
    mreadfits_header, swap_files, ind
    swap_times = anytim(ind.date_obs, /utim)
    index = closest(swap_times, anytim(c2hdr.date_obs, /utim))
    mreadfits, swap_files[index-1], hdr_pre, data_pre
    mreadfits, swap_files[index], hdr, data
    data = disk_nrgf_swap(data, hdr, 0, 0)
    index2map, hdr, data, swap_map

  
    map_new = merge_map(c2map, swap_map, /add, use_min=0)

    tstart = anytim('2014-04-18T13:11:35', /utim)
    ;for i=0, 180 do begin
        ;tstart = tstart+i

    plot_map, map_new, $
        dmin = -4, $
        dmax = 3, $
        fov=FOV, $
        center = CENTER, $
        title = ' ', $
        color=255

    plot_helio, hdr.date_obs, $
    		/over, $
    		gstyle=0, $
    		gthick=1, $
    		gcolor=1, $
    		grid_spacing=15

    oplot_nrh_on_three_color, tstart
 
    xyouts, 0.16, 0.16, 'NRH '+anytim(tstart, /cc, /trun)+' UT', /normal
    xyouts, 0.16, 0.185, 'SWAP '+ anytim(hdr.date_obs, /cc, /trun)+' UT', /normal
    xyouts, 0.16, 0.21, 'LASCO C2: '+ anytim(c2hdr.date_obs, /cc, /trun) +' UT', /normal


    restore, '~/Data/2014_apr_18/white_light/cme_back_extrpln_1000_20140418.sav'
    plots, xpoints, ypoints, /data, color=1, thick=3
    ;endfor      
    if keyword_set(postscript) then begin		
        device, /close
        set_plot, 'x'
    endif    

   

END