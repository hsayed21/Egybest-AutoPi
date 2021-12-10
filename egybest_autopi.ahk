/*
Name: Egybest_Autopi.ahk
Description: Watching Movies AutoPlay Without Ads
Version: v1
Authors: hsayed21 [https://github.com/hsayed21]
Link: https://github.com/hsayed21/Egybest_Autopi.ahk
; Copyright hsayed21 2021
*/

#SingleInstance force
#NoEnv
#Persistent ; needed to keep script running
SetBatchLines, -1
SetWorkingDir, %A_ScriptDir%
#Include lib\Chrome.ahk
#Include lib\JSON_Beautify.ahk

; Here Put Movies Links
urls := ["http://lake.egybest.ink/movie/castle-falls-2021/", "http://lake.egybest.ink/movie/venom-let-there-be-carnage-2021/?ref=home-trends"]

Egy := new Egybest("--disable-extensions")
Egy.Movie(urls)

return

;=============================================================

class Egybest
{
	; Member Variable
	countTryIframe := 1
	indexCurrentMovie := 0
	JS := this.JS_Scripts()
	ChromePID := 0
  
  ; Methods
	__New(flag:="", profile:="")
	{
		this.flag := flag
		this.profile := profile
		if (Chromes := Chrome.FindInstances())
		{
			this.ChromeInst := {"base": Chrome, "DebugPort": Chromes.MinIndex(), "PID": this.ChromePID}
		}
		else
		{
			this.ChromeInst := new Chrome(profile,,flag)
			this.ChromePID := this.ChromeInst.PID
			this.timer := new this.Timer() ; new instance timer adblock
		}
		
		chrome_ahk_pid := "ahk_pid " . this.ChromeInst.PID

		if WinExist(chrome_ahk_pid)
		{
			WinActivate, %chrome_ahk_pid%
			this.page := Chrome.GetPageByURL("about:blank")
		}
		else
		{
			this.__New(flag,profile)
		}
		
		ToolTip ;clear tooltip

	}
	
	Movie(urls)
	{
		this.URLs := urls
		for index, value in urls
		{
			if (index >= this.indexCurrentMovie)
			{
				this.indexCurrentMovie := index
				Cat := this.UrlParse(value)
				
				if (Cat == "movie")
				{
					this.movie_url := value
					this.Main(value)
				}
				else if (Cat == "series")
				{
					;~ this.Series(value)
				}
			}
		}
		
		;~ Say Bye :)
		this.ChromeInst.Kill()
		this.page.Disconnect()
		ExitApp
	}
	
	Main(url)
	{
		if (this.countTryIframe >= 10)
		{
			arr := ["Profile 1", "Person 1", "debugTest"]
			Random, randNum, 1, arr.Length()
			this.__New(this.flag, arr[randNum])
		}
		else
		{
			chPID := this.ChromePID
			chrome_ahk_pid := "ahk_pid " . chPID
			if (chPID != 0 && !WinExist(chrome_ahk_pid))
			{
				;~ MsgBox Chrome is Closed, will initiate a new instance
				this.__New(this.flag, this.profile)
			}
		}
		
		ToolTip
		
		this.page.Call("Page.navigate", {"url": url})
		this.page.WaitForLoad()
		; Start Adblock
		this.timer.StartBlockAds(this.page, this.ChromePID)
		; Check Exist Iframe Tag
		this.check_iframe_exist()

		; Monitor if movie end or not
		flag := true
		while (flag)
		{
			ck_ended := this.page.Evaluate(this.JS.js_check_end).value
			if(ck_ended == "true")
			{
				flag := false
			}
		}
		
	}
	
	JS_Scripts()
	{
		js_window_location_href = 
		(
			window.location.href;
		)
		
		js_get_iframe_src = 
		(
			(function () {

				var ff = document.querySelector("iframe");
				if (ff)
				{
					return ff.src;
				}
				else
				{
					return "false";
				}
				
			})();
		)
		
		js_check_div_click = 
		(
			(function () {
				var div_elem = document.querySelector('div.vidplay');
				if (div_elem)
				{
					div_elem.click();
					//return "true";
				}
				else
				{
					return "false";
				}
			})();
		)
		
		js_check_video_exist = 
		(
			(function () {
				var video_elem = document.querySelector('video');
				if (video_elem)
				{
					return "true";
				}
				else
				{
					return "false";
				}
			})();
		)
		
		js_check_video_play_loading = 
		(
			(function () {
				var video_elem = document.querySelector("video");
				if (video_elem)
				{
					video_elem.play();
					if (video_elem.readyState >= 2)
					{
						return "true";
					}
					else
					{
						return "false";
					}
				}
				else
				{
					return "false";
				}
			})();
		)
		
		js_video_fullscreen = 
		(
			document.querySelector("video").requestFullscreen();
		)
		
		js_check_end = 
		(
			(function () {
				var ck_ended = document.querySelector("video").ended;
				if(ck_ended)
				{
					return "true";
				}
				else
				{
					return "false";
				}
			})();
		)
		
		obj := {js_window_location_href: js_window_location_href, js_iframe_src: js_get_iframe_src, js_check_div_click: js_check_div_click, js_check_video_exist: js_check_video_exist, js_check_video_play_loading: js_check_video_play_loading, js_video_fullscreen:js_video_fullscreen, js_check_end:js_check_end }
		
		return obj
		
	}
	
	reload_page()
	{
		url := this.page.Evaluate(this.JS.js_window_location_href).value
		this.page.Call("Page.navigate", {"url": url})
		this.page.WaitForLoad()
	}
	
	check_iframe_exist()
	{
		flag := true
		i := 0
		while (flag)
		{
			ck_exist := this.page.Evaluate(this.JS.js_iframe_src).value
			if (ck_exist != "false")
			{
				flag := false
				this.page.Call("Page.navigate", {"url": ck_exist})
				this.page.WaitForLoad()
				this.check_video_exist()
			}
			else
			{
				i++
				if (i >= 10)
				{
					this.timer.StopBlockAds()
					flag := false
					this.countTryIframe := this.countTryIframe + 1
					this.ChromeInst.Kill()
					this.page.Disconnect()
					this.Movie(this.URLs) ;start again
				}
				else
				{
					Sleep, 200
					ci := this.countTryIframe
					ToolTip, iframe try.no`( %ci% `) -- check existing video.. try no.`( %i% `)
					this.reload_page()
				}
			}
		}
	}
	
	check_video_exist()
	{
		flag := true
		i := 0
		result := false
		while(flag)
		{
			if (this.page.Evaluate(this.JS.js_check_video_exist).value == "true")
			{
				flag := false
				result := this.check_video_play_loading()
			}
			else
			{
				i++
				this.page.Evaluate(this.JS.js_check_div_click)
			}
			
			Sleep, 500
			
			if !(result)
			{
				ci := this.countTryIframe
				ToolTip, iframe try.no`( %ci% `) -- click | check video.. try no.`( %i% `)
				if (i >= 10)
				{
					this.timer.StopBlockAds()
					flag := false
					this.countTryIframe := this.countTryIframe + 1
					this.ChromeInst.Kill()
					this.page.Disconnect()
					this.Movie(this.URLs) ;start again
				}
			}	
			
			Sleep, 500
			ToolTip
		}
	}
	
	check_video_play_loading()
	{
		flag := true
		flag_video_exist := false
		i := 0
		while (flag)
		{
			ck_video_loaded := this.page.Evaluate(this.JS.js_check_video_play_loading).value
			if (ck_video_loaded == "true")
			{
				ToolTip
				flag := false
				this.countTryIframe := 1
				MsgBox, Everything Ok now happy watching :)
				WinActivate, % "ahk_pid " . this.ChromePID
				WinMaximize, % "ahk_pid " . this.ChromePID
				this.page.Evaluate(this.JS.js_video_fullscreen)
				return true
			}
			else
			{
				i++
			}
			
			
			if (i >= 5)
			{
				flag := false
				ToolTip, check video loading.....
				this.check_video_exist()
			}
			
			Sleep, 500
		}
	}
	
	UrlParse(url)
	{
		RE = ^(?<Protocol>https?|ftp)://(?:(?<Username>[^:]+)(?::(?<Password>[^@]+))?@)?(?<Domain>(?:[\w-]+\.)+\w\w+)(?::(?<Port>\d+))?/?(?<Path>(?:[^/?# ]*/?)+)(?:\?(?<Query>[^#]+)?)?(?:\#(?<Hash>.+)?)?$
		RegExMatch(url, RE, URL_)
		URL_Domain := Format("{}://{}",URL_Protocol, URL_Domain) 
		Cat := StrSplit(URL_Path, "/")[1]
		
		return Cat

	}
	
	
	class Timer {
		__New()
		{
			this.timer := ObjBindMethod(this, "Tick")
		}
		
		StartBlockAds(page, pid, interval:=1000) {
			timer := this.timer
			SetTimer % timer, % interval
			this.page := page
			this.pid := pid
		}
		StopBlockAds() {
			timer := this.timer
			SetTimer % timer, Off
		}
		Tick() {
			;check process exist
			process, exist, % this.pid 
			if !errorlevel
				ExitApp
			;~ else
				;~ msgbox Excel process does not exist
			
			this.getTarget()
		}
		
		getTarget()
		{
			target_arr := this.page.Call("Target.getTargets")
			if (target_arr != "")
			{
				target_arr_beauty := JSON_Beautify(target_arr)
				JsonObj := Chrome.Jxon_Load(target_arr_beauty)
				for index, value in JsonObj.targetInfos
				{
					if (!instr(value.url, "egybest") && !instr(value.url, ":blank") && value.type == "page")
					{
						this.page.Call("Target.closeTarget", {"targetId": value.targetId})
					}
				}
			}
		}
		
		
		DeleteTimer() {                
			this.timer := ObjBindMethod(this, "Tick")
			timer := this.timer
			this.timer := ""            ; Free reference to bound method.
			SetTimer % timer, Delete    ; Delete the timer. Turning off a timer does not release the object.
		}
		; This function is the only addition to the class
		__Delete() {
		  ToolTip Deleting object ...
		}
	}
	
}


;Shortcuts
;Ctrl + ` => goto next movie
^`::
flag := false
return

;Alt + Esc => Exit App
!Esc::
this.ChromeInst.Kill()
this.page.Disconnect()
ExitApp
return
