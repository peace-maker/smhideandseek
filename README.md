# Hide and seek
Terrorists select models and hide on the map. Counter-Terrorists need to seek terrorists.

This is the project page of the sourcemod implementation of the **Hide and Seek** gameplay modification for Counter-Strike:Source.

Terrorists "Hiders" choose a random model on spawn, like a chair, plant or a sign, which is common on the played map and search a place, where they blend in best. The CTs "Seekers" wait a specified time to give the hiders a chance to find their spot. They have to search for the hiders and shoot them.

Seekers either lose some health (default 5 hp) on every shot or hiders get more invisible everytime they get shot - or both. Seekers gain hp by hurting or killing a hider.

Player Commands: 
* */hide /hidemenu* - Opens the menu with the list of available models if still enabled
* */tp /third /thirdperson* - Toggles the thirdperson view so hiders see how they fit into the environment
* */+3rd*|*/-3rd* - Enables/Disables thirdperson view
* */whistle* - Hiders play a random sound to give the seekers a hint
* */freeze* - Toggles freezing for hiders
* */whoami* - Shows hiders their current model name again
* */hidehelp* - Displays a panel with informations how to play.

Used convars to configure the mod to suit your needs:

* *sm_hns_version* - ...
* *sm_hns_enable* - Enable the Hide and Seek mod? (Default: 1)
* *sm_hns_freezects* - Should CTs get freezed and blinded on spawn? (Default: 1)
* *sm_hns_freezetime* - How long should the CTs are freezed after spawn? (Default: 25.0)
* *sm_hns_changelimit* - How often a T is allowed to choose his model ingame? (Default: 2)
* *sm_hns_changelimittime* - How long should a T be allowed to change his model again after spawn? (Default: 30.0)
* *sm_hns_autochoose* - Should the plugin choose models for the hiders automatically? (Default: 0)
* *sm_hns_whistle* - Are terrorists allowed to whistle? (Default: 1)
* *sm_hns_whistle_times* - How many times a hider is allowed to whistle per round? (Default: 5)
* *sm_hns_whistle_delay* - How long after spawn should we delay the use of whistle? (Default: 25.0)
* *sm_hns_anticheat* - Check player cheat convars, 0 = off/1 = on. (Default: 0)
* *sm_hns_cheat_punishment* - How to punish players with wrong cvar values after 15 seconds? (Default: 1)
  * 0: Disabled
  * 1: Switch to Spectator
  * 2: Kick 
* *sm_hns_hider_win_frags* - How many frags should surviving hiders gain? (Default: 5)
* *sm_hns_hp_seeker_enable* - Should CT lose HP when shooting, 0 = off/1 = on. (Default 1)
* *sm_hns_hp_seeker_dec* - How many HP should a CT lose on shooting? (Default 5)
* *sm_hns_hp_seeker_inc* - How many hp should a CT gain when hitting a hider? (Default 15)
* *sm_hns_hp_seeker_bonus* - How many hp should a CT gain when killing a hider? (Default 50)
* *sm_hns_opacity_enable* - Should T get more invisible on low hp, 0 = off/1 = on. (Default 0)
* *sm_hns_hidersspeed* - Hiders speed (Default: 1.00)
* *sm_hns_disable_rightknife* - Disable rightclick for CTs with knife? Prevents knifing without losing heatlh. (Default: 1)
* *sm_hns_disable_ducking* - Disable ducking. (Default: 0)
* *sm_hns_auto_thirdperson* - Enable thirdperson view for hiders automatically (Default: 1)
* *sm_hns_slay_seekers* - Slay seekers on round end, if there are still hiders alive? (Default: 0)
* *sm_hns_hider_freeze_mode* - What to do with the /freeze command? (Default: 2)
  * 0: Disables /freeze command for hiders
  * 1: Only freeze on position, be able to move camera
  * 2: Freeze completely (no cameramovents) 
* *sm_hns_hider_freeze_inair* - Are hiders allowed to freeze in the air? (Default: 0)
* *sm_hns_hide_blood* - Hide blood on hider damage. (Default: 1)
* *sm_hns_show_hidehelp* - Show helpmenu explaining the game on first player spawn. (Default: 1)
* *sm_hns_show_progressbar* - Show progressbar for last 15 seconds of freezetime. (Default: 1)
* *sm_hns_ct_ratio* - The ratio of hiders to 1 seeker. 0 to disables teambalance. (Default: 3)
* *sm_hns_disable_use* - Disable CTs pushing things. (Default: 1)
* *sm_hns_remove_shadows* - Remove shadows from players and physic models? (Default: 1)
* *sm_hns_use_taxed_in_random* - Include taxed models when using random model choice? (Default: 0) 

Available Admincommands:

* sm_hns_force_whistle <#userid|steamid|name> - Force a player to whistle, regardless of his whistle count
* sm_hns_reload_models - Reload the map config file and rebuild the model menu on the fly 

There are some protected server convars, which are enforced by the plugin to enable the mod:

* mp_flashlight 0
* sv_footsteps 0
* mp_limitteams 0
* mp_autoteambalance 0
* mp_freezetime 0
* sv_nonemesis 1
* sv_nomvp 1
* sv_nostats 1
* mp_playerid 1
* sv_allowminmodels 0
* sv_turbophysics 1
* mp_teams_unbalance_limit 0 

It's recommend to set *mp_forcecamera* to 1 in your server.cfg! 
