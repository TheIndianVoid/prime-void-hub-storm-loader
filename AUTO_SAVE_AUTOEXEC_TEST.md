# Prime Void Hub — Autoexec v3 (minimal queue)

**Status:** TEST ONLY. Do not merge to production before real Roblox tests.

## Fixes since v2
- Tiny `queue_on_teleport` script now fetches `PVH_AutoexecBootstrap.lua` in the target; long boot logic is no longer queued inline.
- Corrected duplicate-run guard for reconnects to the same JobId, even when executor globals persist.
- Both `BeforePort` and `OnTeleport` can arm a queue; unsupported intermediate places pre-arm their next hop.
- The tested Auto Save capture/restore code remains unchanged.
- **Infinite Yield conflict:** `keepiy` also calls `queue_on_teleport` on teleport. Some executors replace a prior queued script. Use `;unkeepiy` during the isolated PVH test. You may still use `;rejoin` after disabling KeepIY.

## Diagnostic flow
1. Execute the test loader in a supported place. In Settings, turn Autoexec ON. Observe `[PVH Autoexec v3] QUEUE ACCEPTED`.
2. Use Infinite Yield `;unkeepiy` and then `;rejoin`. Observe `[PVH Autoexec v3] QUEUE FIRED` in the new session.
3. Then `[PVH Autoexec v3] PAYLOAD RECEIVED` proves the new session downloaded the bootstrap.
4. `[PVH Autoexec] ROUTING` reports target PlaceId, UniverseId and chosen port.
5. `[PVH Autoexec v3] LOADER EXECUTED` confirms the Lua loader returned without throwing, *not* necessarily that the port UI appeared.
6. If `QUEUE ACCEPTED` appears before teleport but `QUEUE FIRED` never appears afterward, the executor did not run the queued script (or another script overwrote it). This cannot be fixed solely by a script loaded in the previous session.
7. If `QUEUE FIRED` appears but `PAYLOAD RECEIVED` does not, check that `game:HttpGet` can fetch the bootstrap on the destination.
8. For HUNTRESS lobby -> private match, include **both** destination PlaceId and UniverseId from `ROUTING` if it says `selected=unsupported`. We must identify the correct place instead of blindly running a mismatched port.

## Test Loader
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/TheIndianVoid/prime-void-hub-storm-loader/fix/autoexec-minimal-queue-v3/Loader.lua"))()
```

## Caveat for Infinite Yield rejoin
The Infinite Yield `rejoin` command takes a special path when only one player is present: it calls `Kick` before attempting `TeleportService:Teleport`. That is **not** a reliable teleport queue test because the client session may end before the teleport starts. Prefer a real game lobby -> match teleport or a rejoin from a server with more than one player for this diagnostic.

## Limitations
- External injectors decide when or whether they execute queued code.
- Some queue implementations support only one payload; running Infinite Yield keepiy alongside the PVH queue can cause overwriting.
- Disabling Autoexec after it is queued is honored when the setting persists in destination storage or executor globals; cross-process storage isolation can prevent cancellation.
- This is static-reviewed code and requires Roblox tests before production rollout.
