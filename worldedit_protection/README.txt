Because worldedit can easily cause massive destruction when in the wrong hands, the only use it has seen outside of singleplayer games is when wielded by an admin or moderator.
I (khonkhortisan) intend to change that, by tying its use to, and making it respect, owned areas:
  On a non-creative server (say, survival) it does not make sense to be able to create valuable ores out of thin air, so the "worldedit" privilege is required to do anything.
  On a creative server that does not have any form of land ownership, the "worldedit" privilege is required to do anything. A malicious player is limited by the speed of their arm.
  On a creative server that has an ownership mod (say, areas) the ability to use worldedit is more complicated than a simple "yes" or "no":
    Commands that do not actually edit nodes can be used by anyone. This includes setting the region, inspecting nodes, saving (to a standard filename, see below) and copying (the initial region with //copy or //stack)
    Commands that do edit nodes check the current worldedit region (or the bounding box for the command) for the player's ability both to edit manually, and through this mod: (this includes the second region with //copy or //stack)
      If the region is completely contained by area assigned to you, the command succeeds.
      If the whole region is not owned by anyone (with or without part of it being owned by you):
        If you do not have the "worldedit" privilege, you can only edit area you fully own, and the command fails.
        If you do have the "worldedit" privilege, you can edit unowned area and/or your area (but not someone else's area), and the command succeeds.
      If part of the region is owned by someone else (with or without part of it being unowned, or owned by you):
        If you have the "areas" privilege, you could make yourself the owner anyway, so the command succeeds.
        If you do not have the "areas" privilege, the land cannot be edited by you (worldedit does not currently understand owned but shared area?)
    File writes - if you can set a region, you can read from the world.
      If you have the "server" privilege, you can save to an arbitrary filename, as usual.
      If you do not have the "server" privilege, the filename is forced to "worldedit.we" or "worldedit.mts".
    File reads (of *.we or *.mts, of course) will succeed, but must pass the region write check.
    Lua commands (//lua and //luatransform) require first "server", then "admin", as usual.

minetest.register_chatcommand
  privs = {worldedit}, is what it used to have, but that privilege is only required in certain cases (see above)
  privs = {}, func = worldedit.privs(function(name, param)...end), passes to func a wrapper that checks first whether the worldedit privilege is required, then if the player has it, before running the inner function.

worldedit.privs can also be used in an if statement, as it returns both whether execution should continue (nil or 1), and whether a region permission check should be skipped (2) due to the areas privilege.

worldedit.can_edit_volume
  It takes the player's name, then a list of either two or four points (two points per region, //move has two regions to check)
  It re-runs worldedit.privs to attempt skipping a region permission check (if the player has the "areas" privilege)
    This return value should probably be cached instead of running the function twice.
    func = worldedit.privs(safe_region(function(name, param)...if worldedit.can_edit_volume(name, {pos1, pos2}) then...
    The "wp" return value has to make it past safe_region somehow.
  It returns whether the command should actually be run, along with telling the player why it wasn't.

minetest.allocate_schematic
  A function for schematics corresponding with worldedit.allocate for .we files


