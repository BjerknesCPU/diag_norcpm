undef("wallClockElapseTime")
procedure wallClockElapseTime(wcStrt:string, title:string, opt:integer)
;
; compute *Wall Clock* elapsed time in seconds
; Usage:     wcStrt = systemfunc("date")
;                   :    ; one or more statements [usually a block of code]
;            wallClockElapseTime(wcStrt, "short_info", 0)
; opt not used right now
; this will not handle case where year or month changes
;
; Haley: updated Aug 2014 to return the date in the correct format.
;
local wcNow, wcStrt_c, tSTRT, wcNow_c, tNOW, sec, NLINE, dq, date_cmd
begin
  dq        = str_get_dq()
  date_cmd  = "date +" + dq + "%a %b %d %H:%M:%S %Z %Y" + dq
;;wcNow     = systemfunc("date")
  wcNow     = systemfunc(date_cmd)   ; current ("now") time; must be
  wcNow_c   = stringtochar(wcNow)    ;    be 'Wed Aug 27 08:38:33 MDT 2014' format
  wcStrt_c  = stringtochar(wcStrt)

  if (dimsizes(wcNow_c).eq.dimsizes(wcStrt_c) .and. \
      any(dimsizes(wcNow_c).eq.(/29,30/))) then  ; includes end-of-line character

      tSTRT = stringtointeger((/wcStrt_c( 8: 9)/))*86400 \
            + stringtointeger((/wcStrt_c(11:12)/))*3600  \
            + stringtointeger((/wcStrt_c(14:15)/))*60    \
            + stringtointeger((/wcStrt_c(17:18)/))

      tNOW  = stringtointeger((/wcNow_c( 8: 9)/))*86400  \
            + stringtointeger((/wcNow_c(11:12)/))*3600   \
            + stringtointeger((/wcNow_c(14:15)/))*60     \
            + stringtointeger((/wcNow_c(17:18)/))

      secElapseTime = tNOW-tSTRT

      NLINE     = inttochar(10)   ; new line character
      print (NLINE+ \
        "=====> Wall Clock Elapsed Time: "+title+": "+   \
         secElapseTime+" seconds <====="+NLINE)
  else
      print("wallClockElapseTime: something wrong: no printed value")
  end if

end
