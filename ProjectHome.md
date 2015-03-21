# SM: Hide and Seek #

This is the project page of the sourcemod implementation of the **Hide and Seek** gameplay modification for Counter-Strike:Source.

Terrorists "Hiders" choose a random model on spawn, like a chair, plant or a sign, which is common on the played map and search a place, where they blend in best.
The CTs "Seekers" wait a specified time to give the hiders a chance to find their spot. They have to search for the hiders and shoot them.

Seekers either lose some health (default 5 hp) on every shot or hiders get more invisible everytime they get shot - or both. Seekers gain hp by hurting or killing a hider.

Player Commands:
  * _/hide /hidemenu_ - Opens the menu with the list of available models if still enabled
  * _/tp /third /thirdperson_ - Toggles the thirdperson view so hiders see how they fit into the environment
  * _/+3rd|/-3rd_ - Enables/Disables thirdperson view
  * _/whistle_ - Hiders play a random sound to give the seekers a hint
  * _/freeze_ - Toggles freezing for hiders
  * _/whoami_ - Shows hiders their current model name again
  * _/hidehelp_ - Displays a panel with informations how to play.


Used convars to configure the mod to suit your needs:
  * _sm\_hns\_version_ - ...
  * _sm\_hns\_enable_ - Enable the Hide and Seek mod? (Default: 1)
  * _sm\_hns\_freezects_ - Should CTs get freezed and blinded on spawn? (Default: 1)
  * _sm\_hns\_freezetime_ - How long should the CTs are freezed after spawn? (Default: 25.0)
  * _sm\_hns\_changelimit_ - How often a T is allowed to choose his model ingame? (Default: 2)
  * _sm\_hns\_changelimittime_ - How long should a T be allowed to change his model again after spawn? (Default: 30.0)
  * _sm\_hns\_autochoose_ - Should the plugin choose models for the hiders automatically? (Default: 0)
  * _sm\_hns\_whistle_ - Are terrorists allowed to whistle? (Default: 1)
  * _sm\_hns\_whistle\_times_ - How many times a hider is allowed to whistle per round? (Default: 5)
  * _sm\_hns\_whistle\_delay_ - How long after spawn should we delay the use of whistle? (Default: 25.0)
  * _sm\_hns\_anticheat_ - Check player cheat convars, 0 = off/1 = on. (Default: 0)
  * _sm\_hns\_cheat\_punishment_ - How to punish players with wrong cvar values after 15 seconds? (Default: 1)
    * 0: Disabled
    * 1: Switch to Spectator
    * 2: Kick
  * _sm\_hns\_hider\_win\_frags_ - How many frags should surviving hiders gain? (Default: 5)
  * _sm\_hns\_hp\_seeker\_enable_ - Should CT lose HP when shooting, 0 = off/1 = on. (Default 1)
  * _sm\_hns\_hp\_seeker\_dec_ - How many HP should a CT lose on shooting? (Default 5)
  * _sm\_hns\_hp\_seeker\_inc_ - How many hp should a CT gain when hitting a hider? (Default 15)
  * _sm\_hns\_hp\_seeker\_bonus_ - How many hp should a CT gain when killing a hider? (Default 50)
  * _sm\_hns\_opacity\_enable_ - Should T get more invisible on low hp, 0 = off/1 = on. (Default 0)
  * _sm\_hns\_hidersspeed_ - Hiders speed (Default: 1.00)
  * _sm\_hns\_disable\_rightknife_ - Disable rightclick for CTs with knife? Prevents knifing without losing heatlh. (Default: 1)
  * _sm\_hns\_disable\_ducking_ - Disable ducking. (Default: 0)
  * _sm\_hns\_auto\_thirdperson_ - Enable thirdperson view for hiders automatically (Default: 1)
  * _sm\_hns\_slay\_seekers_ - Slay seekers on round end, if there are still hiders alive? (Default: 0)
  * _sm\_hns\_hider\_freeze\_mode_ - What to do with the /freeze command? (Default: 2)
    * 0: Disables /freeze command for hiders
    * 1: Only freeze on position, be able to move camera
    * 2: Freeze completely (no cameramovents)
  * _sm\_hns\_hider\_freeze\_inair_ - Are hiders allowed to freeze in the air? (Default: 0)
  * _sm\_hns\_hide\_blood_ - Hide blood on hider damage. (Default: 1)
  * _sm\_hns\_show\_hidehelp_ - Show helpmenu explaining the game on first player spawn. (Default: 1)
  * _sm\_hns\_show\_progressbar_ - Show progressbar for last 15 seconds of freezetime. (Default: 1)
  * _sm\_hns\_ct\_ratio_ - The ratio of hiders to 1 seeker. 0 to disables teambalance. (Default: 3)
  * _sm\_hns\_disable\_use_ - Disable CTs pushing things. (Default: 1)
  * _sm\_hns\_remove\_shadows_ - Remove shadows from players and physic models? (Default: 1)
  * _sm\_hns\_use\_taxed\_in\_random_ - Include taxed models when using random model choice? (Default: 0)


Available Admincommands:
  * sm\_hns\_force\_whistle <#userid|steamid|name> - Force a player to whistle, regardless of his whistle count
  * sm\_hns\_reload\_models - Reload the map config file and rebuild the model menu on the fly

There are some protected server convars, which are enforced by the plugin to enable the mod:
  * mp\_flashlight 0
  * sv\_footsteps 0
  * mp\_limitteams 0
  * mp\_autoteambalance 0
  * mp\_freezetime 0
  * sv\_nonemesis 1
  * sv\_nomvp 1
  * sv\_nostats 1
  * mp\_playerid 1
  * sv\_allowminmodels 0
  * sv\_turbophysics 1
  * mp\_teams\_unbalance\_limit 0

It's recommend to set _mp\_forcecamera_ to 1 in your server.cfg!
