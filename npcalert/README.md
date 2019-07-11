Addon allows you to sound an alarm when a new npc appears, create a log of npc appearance and disappearance, and creates a circle around their position on screen

Log is saved as npcalert/logs.txt in addons folder

Log file format (tab seperated):

date
time
log type
npc classid
npc classname
map classname
x position
y position (height above ground)
z position


Chat command to display map link in chat bar:

"/npcalert <map classname> <x position> <z position> <extra chat strings>"


Examples:
"/npcalert c_Klaipe -63 149"

"/npcalert c_Klaipe -63 149 /s"

"/npcalert c_Klaipe -63 149 Klaipeda location"

"/npcalert c_Klaipe -63 149 /w CharacterName"

"/npcalert c_Klaipe -63 149 /w CharacterName Klaipeda location"


Patch notes
---
### v2.0.0
Config files and logs are now saved in addons/npcalert folder

Added json file for modifying display options 