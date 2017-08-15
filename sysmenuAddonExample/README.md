Example for creating sysmenu icons for patch 166969.ipf


Likely bug:
Addon icon may disappear for 1 map when the game adds in a new icon in the middle of a map (joining a guild, class change to necromancer, etc.)


Patch notes
v1.0.1
Patched icon disappearing if language is changed, but addon requires map change to recover


A better method of making the addon icon is for all addons to agree to use 1 common function hook to create a sysmenu icon, but this is unlikely to happen