# Instructions

## Lua Standard

- Always create code with LuaLS typing
- Documentation reference can be found at:
  - `./specs/LuaLS_annotations.md`

## Important - Folders

**Specifications:**
  - `./specs` contains program design specifications
  - `./tasks` contain current implementation design documents
  - `./specs/WoW-API` contains the full Blizzard UI code and Function Documentation
**Code Directories:**
  - `./Trackers` contains all the implementations of different areas we track in World of Warcraft.
**Code Files:**
  - `./QuestLogTrace-Classic.toc` World of Warcraft toc file - how files are loaded
  - `./QuestLogTrace.lua` - Entrypoint
  - `./globals.lua` - Global variables and constants
  - `./QuestLogTrace_StateTracking.lua` - State tracking and management
  - `./QuestLogTrace_UI.lua` - User interface code

**Forbidden folders**

- `Trace` contains old code for a Trace UI that is not in use by the code.
- `.shit` this is my manual trashcan, any code from here should never be used.

## World of Warcraft documentation

  - WebSearch `warcraft.wiki.gg` is the most up to date source.
    - e.g. https://warcraft.wiki.gg/wiki/API_GetTimePreciseSec
  - Local full API documentation and Blizzard UI code can be found in `./specs/WoW-API`

## Language Server

  - Check code for issues using cli `lua-language-server --check=.` in the root directory.
  - It takes a pretty long time due to blizzard UI so ALWAYS use a 180s (3m) timeout for lua-language-server commands.
