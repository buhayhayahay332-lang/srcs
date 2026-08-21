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

`MainUI.luau` creates one shared Obsidian window after both runtime modules are started. Every original setting is available there: aim targeting and FOV visuals, weapon patches, and scanner timing/maintenance. Each callback writes directly to the settings table read by its runtime, so changes apply live.

The **UI Settings** tab provides a configurable UI-toggle keybind (default `RightShift`), an **Unload Operation Siege** button, theme controls, and Obsidian's full save/load configuration panel. Saved configurations include AimMod and GunMod settings. Both features share one Obsidian library instance, so only one GUI is created.

## Loadstring use

Keep the complete `prod` folder in the GitHub repository, then use the root loader:

```lua
loadstring(game:HttpGet(
	"https://raw.githubusercontent.com/buhayhayahay332-lang/srcs/main/OpSiege/prod/main.luau"
))()
```

`main.luau` fetches the child modules, starts both aimmod and gunmod, and opens the shared hub. Re-running it while active returns the existing hub instead of duplicating GUI windows or hooks.


