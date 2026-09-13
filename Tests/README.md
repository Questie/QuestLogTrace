# Offline tests

Run from the addon root:

```sh
lua5.1 Tests/run.lua
```

The tests load the real tracker and capture code in isolated Lua environments
with mocked WoW APIs and timers. No game client, bridge, saved files, or installed
packages are required.

Coverage includes greeting count-shrink retries after unsettled returns/errors,
close cancellation, capture restart, recording-contract metadata with legacy
saves, and spellbook tuple arity. These tests verify recording logic, not native
client return values or event timing.
