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

pro plot_lasco_c2, c2index, postscript = postscript

    ; Code to combine AIA, NRH and C2 observations of eruptive event on 2014-Apr-18
    if keyword_set(postscript) then begin
        setup_ps, '~/Data/2014_apr_18/swap_nrh_c2_20140418_2.eps
    endif else begin
        winsz=700
        !p.charsize=1.5       
        window, 0, xs=winsz, ys=winsz, retain=2
    endelse  

    ;FOV = [1e4/60.0, 1e4/60.0]
    CENTER = [1000.0, -1000.0]

    ;--------------------------------------;
    ;----------------C2 Data---------------;
    ;--------------------------------------;
    cd,'~/Data/2014_Apr_18/white_light/lasco/c2/l1/'
    c2_files = findfile('*.fts')
    pre = lasco_readfits(c2_files[c2index-1], c2hdr_pre)
    mask = lasco_get_mask(c2hdr_pre)
    pre = pre*mask
    img = lasco_readfits(c2_files[c2index], c2hdr)
    img = img*mask
    imgbs = alog10(img) - alog10(pre)
    ;imgbs = (imgbs- mean(imgbs))/stdev(imgbs)
    c2map = make_map(imgbs)
    c2map.dx = 11.9
    c2map.dy = 11.9
    c2map.xc = 14.4704
    c2map.yc = 61.2137


    loadct, 0
    reverse_ct
    
    plot_map, c2map, $
        dmin = -0.12, $
        dmax = 0.12, $
        fov=FOV, $
        xtit=' ', $
        ytit=' ', $
        tit=c2hdr.date_obs
;        /nodata, $
        ;color=0

    loadct, 74 ;33    

    plot_map, c2map, $
        dmin = -0.05, $
        dmax = 0.13, $
        ;fov=FOV, $
        ;center = CENTER, $
        title = ' ', $
        xtit=' ', $
        ytit=' ', $
        xtickf='(A1)', $
        ytickf='(A1)', $
        color=255, $
        /noerase


    plot_helio, c2hdr.date_obs, $
        /over, $
        gstyle=0, $
        gthick=1, $
        gcolor=1, $
        grid_spacing=15
    
    x2png, '~/img_rd_'+string(c2index, format='(I02)')+'.png'
  
    ;endfor      
    if keyword_set(postscript) then begin		
        device, /close
        set_plot, 'x'
    endif    

   

END