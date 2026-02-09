# QuestLogTest AddOn - MapTest MVP

## Project Overview

This is a World of Warcraft Classic Era AddOn focused on debugging and testing quest log functionality and Blizzard's Map API. The project contains multiple components but the main focus area is the **MapTest** folder which contains an MVP implementation for analyzing Blizzard's Map API usage.

## Core Components

### MapTest MVP (Primary Focus Area)

Located in `/MapTest/` - This is the main area of current development.

**Purpose**: Create a debugging environment to understand how Blizzard's Map API works by using proxy metatables that log all API calls and parameters.

#### Key Files:

- **`Map.lua`** (`/MapTest/Map.lua`):

  - Creates `MetaMapProvider` - a metatable proxy that wraps `MapCanvasDataProviderMixin`
  - Logs all function calls with arguments for debugging purposes
  - Implements specific override functions: `RefreshAllData`, `OnAdded`, `OnHide`
  - Integrates with WorldMapFrame by adding the provider: `WorldMapFrame:AddDataProvider(MetaMapProvider)`

- **`FramePool.lua`** (`/MapTest/FramePool.lua`):
  - Creates a custom pin pool using `CreateUnsecuredRegionPoolInstance`
  - Implements `MetaMapPin` - another metatable proxy that wraps `MapCanvasPinMixin`
  - Provides `createFunc` and `resetFunc` for pool management
  - Logs all pin-related API calls for debugging

#### BlizzardAPI Folder (`/MapTest/BlizzardAPI/`):

Contains copied/referenced Blizzard API files for understanding the underlying implementation:

- `Blizzard_MapCanvas.lua` - Core map canvas functionality
- `MapCanvas_DataProviderBase.lua` - Data provider base class
- `MapCanvas_PinFrameLevelsManager.lua` - Pin frame level management

### Quest Log Test System

#### Proximity-Based Tooltip System

The addon uses a sophisticated proximity-based tooltip system that replaces traditional single/cluster tooltips with area-of-effect tooltip aggregation.

**Key Features:**

- **Map Coordinate System**: All proximity calculations use normalized map coordinates (0-1 range)
- **Elliptical Detection**: Uses width-normalized coordinates creating an oval detection area
- **Configurable Radius**: Pixel input radius converted to map coordinates via canvas scaling
- **Template-Specific**: Only enumerates our own pin templates to avoid other addon interference

**Architecture (`BasePin.lua`):**

```lua
-- Proximity detection in OnMouseEnter
local nearby = QLT_PinRegistry.FindPinsInRadius(self, proximityRadius)
if #nearby > 0 then
  QLT_PinRegistry.ShowProximityTooltip(self, nearby)
end
```

**Core Functions (`PinRegistry.lua`):**

- `FindPinsInRadius(centerPin, radiusInput)` - Finds pins within map coordinate radius
- `ShowProximityTooltip(centerPin, nearbyPins)` - Aggregates tooltip data by type

### Visual Configuration System

The system provides comprehensive visual control over pin rendering through a centralized configuration approach.

**Visual Configuration Class (`TypeRegistry.lua`):**

```lua
---@class QLT_VisualConfig
---@field frameSize { width: number, height: number }  -- Pin frame dimensions for mouse interaction
---@field textureSize { width: number, height: number } -- Icon texture dimensions
---@field color { r: number, g: number, b: number, a: number } -- RGBA color values
---@field alpha number -- Overall alpha transparency
---@field desaturated boolean -- Grayscale rendering
---@field blendMode string -- Texture blend mode ("BLEND", "ADD", etc.)
```

**Default Visual Configuration:**

- Frame Size: 16x16 (mouse interaction area)
- Texture Size: 12x12 (visual icon size)
- Color: White (1,1,1,1)
- Alpha: 1.0 (fully opaque)
- Blend Mode: "BLEND"

**Type Registration Example:**

```lua
QLT_TypeRegistry.Register("available", {
  icon = "Interface\\GossipFrame\\AvailableQuestIcon",
  visual = {
    frameSize = { width = 16, height = 16 },
    textureSize = { width = 12, height = 12 },
    color = { r = 0.2, g = 1.0, b = 0.2, a = 1.0 } -- Bright green
  }
})
```

### Debug Visualization and Controls

Comprehensive debug system for testing and fine-tuning proximity and clustering behavior.

#### Debug Visualization (`DebugDraw.lua`)

- **Cluster Debug**: Yellow centers, blue elliptical rings for cluster radii, type-colored payload points
- **Proximity Debug**: Purple circles showing proximity detection radius around pins
- **Coordinate Conversion**: Proper pixel input to map coordinate conversion using canvas scaling

#### Interactive Debug Panel (`DebugFrame.lua`)

**Controls Available:**

- Min/Max Radius sliders for clustering (0.001-0.100 range)
- Debug dots visualization checkbox
- Proximity radius slider (0-500 pixel input range)
- Proximity debug visualization checkbox
- Per-type cluster radius controls (X/Y dimensions)

#### Slash Commands (`DebugCommands.lua`)

```
/qltc viz on|off                    - Toggle debug dots
/qltc radius <number>               - Override cluster radius
/qltc proximity viz on|off          - Toggle proximity debug circles
/qltc proximity radius <0-500>      - Set proximity radius (pixel input)
```

### Map-Specific Rendering System

The system supports selective rendering based on World of Warcraft map IDs.

**Point Structure (`ClusterManager.lua`):**

```lua
---@class QLT_Point
---@field x number -- Normalized map coordinate (0-1)
---@field y number -- Normalized map coordinate (0-1)
---@field type string -- Point type for visual/behavior configuration
---@field uiMapId integer -- World of Warcraft map ID
---@field visualState string|nil -- Optional visual state modifier
```

**Map Filtering (`DemoProvider.lua`):**

- Currently configured for maps 1429 and 1436
- Automatic map change detection via `OnShow` events
- Efficient point generation only for target maps

### Technical Approach

#### Metatable Proxy Pattern

The core debugging strategy uses Lua metatables with `__index` metamethods to:

1. **Intercept API Calls**: Every function call to Blizzard's Map API is logged
2. **Preserve Original Behavior**: Calls are forwarded to the original Blizzard functions
3. **Debug Visibility**: All arguments and function names are printed to chat/console
4. **Non-Intrusive**: The original game functionality remains unchanged

#### Coordinate System Architecture

**Map Coordinates vs Screen Pixels:**

- **Map Coordinates**: Normalized 0-1 range representing the full map canvas
- **Screen Pixels**: Physical pixel positions on screen
- **Conversion**: Uses canvas dimensions and effective scale for proper coordinate transformation

```lua
-- Pixel input to map coordinates
local normalizedRadius = pixelRadius / (canvasWidth * effectiveScale)
```

#### Pin Pool Management (`PinRegistry.lua`)

- Shared texture and font string pools for efficiency
- Template-based pin categorization (GENERIC, CLUSTER, DEBUG)
- Frame level management for proper z-ordering
- Automatic cleanup and recycling

### Supporting Infrastructure

#### Event Tracing System (`/Trace/`):

- `QLTrace.lua` - Modified copy of Blizzard's EventTrace addon for quest log event debugging
- Provides comprehensive event logging and filtering capabilities

#### Main AddOn Files:

- **`QuestLogTest.lua`** - Main addon logic with slash commands (`/questlogtest`, `/qlt`)
  - Implements quest history tracking
  - Provides save/test functionality for debugging
- **`QuestLogTest-Classic.toc`** - AddOn manifest file listing all included files

## File Organization

```
/MapTest/                      # Main MVP development area
├── Map.lua                   # MapProvider proxy implementation
├── FramePool.lua             # Pin pool proxy implementation
├── BasePin.lua               # Pin base class with proximity mouse handling
├── ClusterManager.lua        # Radius-based clustering algorithm
├── PinRegistry.lua           # Pin pool management and proximity detection
├── TypeRegistry.lua          # Visual configuration and type definitions
├── DemoProvider.lua          # Demo point generation with map filtering
├── Config.lua                # Runtime configuration toggles
├── DebugDraw.lua            # Debug visualization rendering
├── DebugFrame.lua           # Interactive debug panel
├── DebugCommands.lua        # Slash command interface
└── BlizzardAPI/             # Reference Blizzard API files
    ├── Blizzard_MapCanvas.lua
    ├── MapCanvas_DataProviderBase.lua
    └── MapCanvas_PinFrameLevelsManager.lua

/Trace/                      # Event debugging system
└── QLTrace.lua              # Modified Blizzard EventTrace

# Root files
├── QuestLogTest.lua         # Main addon logic
├── QuestLogTest-Classic.toc # AddOn manifest
└── globals.lua              # Global definitions
```

## Key API Understanding

The MVP demonstrates interaction with:

- `WorldMapFrame` - Main map interface
- `MapCanvasDataProviderMixin` - Data provider base class
- `MapCanvasPinMixin` - Map pin functionality
- Frame pools for efficient pin management
- Map canvas event system (`OnAdded`, `OnHide`, `RefreshAllData`)

## Lua Type Annotations Reference

### Core Data Structures

```lua
---@class QLT_Point
---@field x number -- Normalized map coordinate (0-1)
---@field y number -- Normalized map coordinate (0-1)
---@field type string -- Point type identifier
---@field uiMapId integer -- WoW map ID
---@field visualState string|nil -- Optional visual state modifier

---@class QLT_Cluster
---@field x number -- Center X coordinate
---@field y number -- Center Y coordinate
---@field radiusX number|nil -- Horizontal radius
---@field radiusY number|nil -- Vertical radius
---@field payload QLT_Point[] -- Points in this cluster
---@field byType table<string, integer> -- Point counts by type

---@class QLT_VisualConfig
---@field frameSize { width: number, height: number }
---@field textureSize { width: number, height: number }
---@field color { r: number, g: number, b: number, a: number }
---@field alpha number
---@field desaturated boolean
---@field blendMode string

---@class QLT_TypeDefinition
---@field icon string -- Texture path
---@field visual QLT_VisualConfig
---@field priority integer -- Z-order priority
---@field renderSingle function|nil -- Custom single renderer
---@field click function|nil -- Click handler

---@class QLT_Pools
---@field texturePool any -- Shared texture pool
---@field fontStringPool any -- Shared font string pool
```

### Aliases and Enums

```lua
---@alias QLT_PinKind "single"|"cluster"
---@alias QLT_ClusterMode "radius"
```

## Development Focus

- **Primary**: MapTest MVP development and Blizzard Map API analysis
- **Secondary**: Quest log functionality testing and event debugging
- **Goal**: Understand Map API behavior changes and create robust debugging tools

## Configuration

Runtime settings accessible via `QLT_Config`:

- **Clustering**: Always enabled, radius-based mode
- **Debug Visualization**: Toggle cluster and proximity debug rendering
- **Proximity**: Configurable radius and debug visualization
- **Per-Type Settings**: Individual cluster radii for different point types

---

# Lua Type Annotations

## Overview

Lua type annotations add context and type checking. Prefix annotations with `---` (a comment with an extra dash).

## Basic Example

```lua
---@alias MyCustomType integer

---Calculate a value using MyCustomType
---@param x MyCustomType
function calculate(x) end
```

## Core Annotations

### @param

Defines a function parameter’s type.

```lua
---@param name string Description
function myFunc(name) end
```

### @return

Defines return type(s) for a function.

```lua
---@return boolean # If successful
function myFunc() end
```

### @class

Describes a table as a class with fields. Supports inheritance.

```lua
---@class Person
---@field name string
---@field age number
local Person = {}

---@class Employee : Person
---@field salary number
local Employee = {}
```

#### Example Usage

```lua
---@param p Person
function greet(p)
    print("Hello, " .. p.name)
end

---@param e Employee
function showSalary(e)
    print(e.name .. " earns " .. e.salary)
end

local john = { name = "John", age = 30 }
greet(john)

local alice = { name = "Alice", age = 25, salary = 50000 }
showSalary(alice)
```

### @field

Defines fields within a class.

```lua
---@field key string Description
```

### @alias

Create a custom type or enum.

```lua
---@alias UserID integer
---@alias Mode "r" | "w"
```

### @type

Assigns a type to a variable.

```lua
---@type string[]
local names
```

### @generic

Defines generics for functions and tables. Supports backticks to capture and return types.

```lua
---@generic T
---@param x T
---@return T
function identity(x) end

---@class Vehicle
local Vehicle = {}
function Vehicle:drive() end

---@generic T
---@param class `T` # Captures the type
---@return T
function new(class) end

-- Example
local car = new("Vehicle") -- car is Vehicle
car:drive()
```

### @enum

Marks a table as an enum.

```lua
---@enum Colors
local Colors = { Red = 1, Blue = 2 }
```

### @cast

Casts a variable to a type.

```lua
---@cast x string
```

### @async

Marks a function as asynchronous.

```lua
---@async
function fetchData() end
```

### @nodiscard

Warn if return value is ignored. Only warns if **all return values are discarded**.

```lua
---@nodiscard
---@return string, boolean
function importantCall() end

local a, b = importantCall() -- This is fine
local a = importantCall()    -- This is fine
importantCall()              -- Warning if @nodiscard

local result = importantCall() -- This is fine
importantCall() -- Warning if @nodiscard is applied
```

### @overload

Define multiple function signatures.

```lua
---@overload fun(x: string): boolean
function foo(x) end
```

### @as

Force a type onto an expression.

```lua
local x = nil
doSomething(x --[[@as string]])
```

### @meta

Marks a file as a meta file, used for definitions, not functional Lua code.

```lua
---@meta
```

### @package

Marks a function as private to the file. Cannot be accessed from another file.

```lua
---@package
local function secret() end
```

### @private and @protected

Define access modifiers for class fields or methods.

```lua
---@class Animal
---@field private eyes integer
---@field protected legs integer
```

### @operator

Provides type declarations for metamethod operators like `+`, `-`, `call`, etc.

```lua
---@class Vector
---@operator add(Vector): Vector
```

## Common Type Patterns

| Pattern                    | Description     |
| -------------------------- | --------------- |
| `TYPE_1 \| TYPE_2`         | Union Type      |
| `VALUE_TYPE[]`             | Array           |
| `[TYPE_1, TYPE_2]`         | Tuple           |
| `{[string]: TYPE}`         | Dictionary      |
| `table<K, V>`              | Key-Value Table |
| `{key1: TYPE, ...}`        | Table literal   |
| `fun(PARAM: TYPE): RETURN` | Function Type   |

### Examples for Common Type Patterns

#### Optional Type

Always use `string?` for optional types, not `string | nil`.

```lua
---@param value string | number
---@param debugActive boolean?
function printValue(value, debugActive)
  if debugActive then
    print(value)
  end
end
```

#### Union Type

```lua
---@param value string | number
function printValue(value)
    print(value)
end
```

#### Array

```lua
---@type string[]
local names = {"Alice", "Bob", "Charlie"}
```

#### Tuple

```lua
---@type [string, number]
local person = {"Alice", 30}
```

#### Dictionary

```lua
---@type { [string]: number }
local scores = { Alice = 100, Bob = 90 }
```

#### Key-Value Table

```lua
---@type table<string, boolean>
local isActive = { Alice = true, Bob = false }
```

#### Table Literal

```lua
---@type { name: string, age: number }
local person = { name = "Alice", age = 30 }
```

#### Function Type

```lua
---@type fun(x: number, y: number, z?: string): number
local add = function(x, y, z)
    if z then
        print(z)
    end
    return x + y
end
```

## Advanced Notes

- `?` after a type means `nil` is allowed, e.g., `boolean?` is `boolean | nil` only use `<type>?`.
- Parentheses sometimes needed for unions: `(string | number)[]`.

---

Claude, always use LuaLS annotations for objects.
