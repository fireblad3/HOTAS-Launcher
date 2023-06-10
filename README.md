# HOTAS-Launcher

Small app to 
1) Enable/disable your HOTAS and launch your favorite game (and supporting apps if you wish) all with one click of a buttonl.
2) Refer's to your joysticks by name, even if Star Citizen won't...
3) Insures that if you unplug your joysticks and re-plug them Star Citizen and other games will always see them in the right order 
4) Ensures that your HOTAS does not keep your PC awake when its not in use as it disables them after you press stop.
5) Option to launch secondary apps at the same time as the game.
 
Couple of things,

::Administrator Priviliges::
The app needs Administrator priveleges to run (this is purely so that it can enable or disable the usb devices using usb2view.exe without individual prompts for admin access) nothing else in my script requires admin access after the first run (first run optionally installs pre-requisits).

It will only disable USB devices that you select in a game profile, no other devices are touched, and only after you click stop after playing a game.

::Credential Prompt::
To prevent issues with the game or apps being run as administrator the app will ask for your local windows username/password, The game itself and secondary applications are launched using the credentials you provide, and I suggest using your general windows username and password when prompted (these are stored securely in the windows Credential Manager).

::Powershell Script::
The Launcher.ps1 script can be run "as is" if you enable scripts to run on your PC (See https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.security/set-executionpolicy?view=powershell-7.3). This may be preferable to some however the .exe is provided as it simplify's launching it.

::Antivirus False Positives:
Please note that while my script is not malicious in any way some antivirus programs detect scripts compiled by PS2EXE as a trojen. You can tell your antivirus that this file is safe however please use your own discresion on that. The issue is well documented as it seems that there were a few malicious programs compiled using PS2EXE a few years back :( 
