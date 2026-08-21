# Operation Siege production modules

This is an executor-first GitHub module system. Each feature is isolated so its UI, runtime state, and game-specific logic can be updated without editing the other feature.

```
prod/
├── aimmod/
│   ├── Config.luau        # Defaults and target-part mapping
│   ├── Targeting.luau     # Enemy selection and live target state
│   ├── FovCircle.luau     # Drawing API visual
│   ├── PayloadCache.luau  # Captures game Damage payload context
│   ├── Hook.luau          # Raycast and remote interception
│   ├── Obsidian.luau      # Shared Obsidian loader
│   ├── UI.luau            # Obsidian bindings only
│   ├── init.luau          # Feature composition and lifecycle
│   └── main.luau          # Entry point
└── gunmod/
    ├── Config.luau        # Defaults
    ├── TableStore.luau    # Original-value snapshots and restoration
    ├── Patcher.luau       # Gun/attachment patch rules
    ├── Scanner.luau       # GC discovery
    ├── Runtime.luau       # Alive-gated lifecycle scheduling
    ├── Obsidian.luau      # Shared Obsidian loader
    ├── UI.luau            # Obsidian bindings only
    ├── init.luau          # Feature composition and lifecycle
    └── main.luau          # Entry point
```

## How it works

`prod/main.luau` is a custom HTTP module loader. It downloads the `.luau` files from GitHub and resolves internal module IDs such as `require("aimmod.Config")`; there are no Roblox Studio `ModuleScript` or `script.Parent` requirements.

Each UI callback writes directly to the same settings table read by its runtime module. Changes from the Obsidian interface therefore apply live; you do not need to rerun the loader to toggle a feature, adjust the aim FOV, change the target part, or alter the gun settings.

Both features load Obsidian from its upstream `Library.lua` endpoint. They share one `OperationSiegeObsidian` environment reference, so running both modules does not download or initialize a second library copy.

## Loadstring use

Keep the complete `prod` folder in the GitHub repository, then use the root loader:

```lua
loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/buhayhayahay332-lang/srcs/main/OpSiege/prod/main.luau"
))()
```

`main.luau` fetches the child modules and starts both aimmod and gunmod.


