# Prime Void Hub | Auto Save + Autoexec (TEST)

This is a universal runtime feature layer for all current Obsidian ports launched through the test Loader.lua.

## Defaults
- **Auto Save**: ON. Persists the states of Obsidian toggles/options separately for each port and Roblox account in `primevoid_hub/_Universal`. Keybinds, sliders, dropdowns and toggle states are included where represented by Obsidian controls. Port-native settings continue working.
- **Autoexec**: OFF until enabled. Needs an executor implementing `queue_on_teleport` or an equivalent and persistent `readfile/writefile` storage. Its queued payload verifies the latest Autoexec preference before loading the test loader.
- Disabling **Auto Save** keeps the disabled preference, ignores the port's legacy automatic settings on subsequent runs, and does not touch named manually saved profiles.

## Supported current ports
Ride Storm (Storm Suite), HUNTRESS, Steal An Exu (Exu Security Lab), Destruction Simulator and Don't Splash.

Future Obsidian ports registered in `ports` inherit the same controls automatically. Ports not using Obsidian must expose a compatible settings groupbox in `getgenv().PVH_SettingsPolish`.

## Test cases (Roblox/executor required)
1. Run the TEST loader in Ride Storm; enable Ghost, set speed, select keybind. Exit and rejoin. Verify options restore.
2. Switch Auto Save OFF, change settings, rejoin. Confirm defaults. Turn ON, make another change and rejoin to verify it remembers the new setting.
3. In Steal An Exu select a rarity, enable one farm option, relaunch. Verify selected values. Test a named manual profile independently.
4. Repeat in HUNTRESS, Don't Splash and Destruction Simulator, including multi-select and dropdown controls.
5. Enable Autoexec, server hop. Verify the test loader automatically executes once; teleport to another supported experience and confirm correct port selection. Switch Autoexec OFF and repeat.
6. Repeat with an executor lacking `queue_on_teleport`; confirm it reports unavailable without breaking the port.

## Known limitations
- Restores UI-backed options and native settings; values never exposed to the UI or native settings are not discoverable automatically.
- The executor controls whether queued scripts and saved files survive server hops / cross-experience teleport.
- If a port cannot safely activate a state before the game's objects load, restoration may require a further port-specific guard.
- No live Roblox client test has yet been performed; **do not merge this branch into main until validated in-game**.

## Test loader
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/feature/auto-save-autoexec-universal/Loader.lua"))()
```
