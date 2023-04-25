# HOTAS-Launcher

Small app to 
1) Enable/disable your HOTAS  and launch your favorite game (all with one click of a button)
2) Refer's to your joysticks by name, even if Star Citizen won't...
3) Insures that if you unplug your joysticks and re-plug them Star Citizen will always see them in the right order 
4) Ensures that your HOTAS does not keep your PC awake when its not in use.
5) Option to launch secondary apps at the same time as the game.
 
Couple of things,
It needs to be launched as administrator either by right click then select  "Properties" click "Compatability" then select "Run this program as an Administrator" or every time you launch it, right click and select "run as administrator" (this is purely so that it can enable or disable the usb devices without individual prompts for admin access)

It will only disable USB devices that you select in a game profile, and only after you click stop after playing a game. (edited)

The game itself and secondary applications are launched using the credentials you provide, and I advise using your general windows username and password when prompted (these are stored securely in the windows Credential Manager).
