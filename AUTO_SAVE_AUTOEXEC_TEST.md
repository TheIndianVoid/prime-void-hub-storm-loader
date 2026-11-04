# Prime Void Hub | Auto Save + Autoexec (TEST)

This is a universal runtime feature layer for all current Obsidian ports launched through the test Loader.lua.

## Teleport fix based on Infinite Yield keepiy
- Register the queued payload when `LocalPlayer.OnTeleport` fires, not at script startup.
- Carry the enabled flag and original Universe ID in the payload; do not use destination `readfile` as a prerequisite.
- Treat different places of the same Universe as the original port when using an Autoexec handoff.
- Forward through unsupported intermediate lobbies instead of silently abandoning the queue.
- Reset pending-queue state when a teleport fails (`TeleportState.Failed` or `TeleportInitFailed`).
- This is a **test-only branch**; the production loader remains unchanged.

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
5. Enable Autoexec, server hop in the same place. Verify the test loader runs exactly once.
6. From a supported lobby, teleport into a different PlaceId in the **same Universe**; it should still load the correct port. Test lobby -> matchmaking -> game where available.
7. Teleport to a different supported experience. Confirm the destination's own Autoexec setting controls subsequent hops.
8. Teleport through an unsupported intermediate lobby and then back into a supported place. The queue should forward without executing a wrong port.
9. Turn Autoexec OFF and teleport. Confirm it does **not** requeue. Retry a failed teleport and confirm another attempt can queue.
10. Repeat with an executor lacking `queue_on_teleport`; confirm it reports unavailable without breaking the port.

## Known limitations
- Restores UI-backed options and native settings; values never exposed to the UI or native settings are not discoverable automatically.
- The executor controls whether queued scripts survive server hops / cross-experience teleport. Some executors do not reinject reliably or clear the queued payload between Roblox processes; this cannot be fully repaired by the script.
- Only a real Roblox-client test can validate a specific executor and a specific lobby -> match teleport.
- If a port cannot safely activate a state before the game's objects load, restoration may require a further port-specific guard.
- No live Roblox client test has yet been performed; **do not merge this branch into main until validated in-game**.

## Test loader
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/fix/autoexec-infinite-yield-teleport/Loader.lua"))()
```
