# Operation Siege production modules

Each feature is intentionally isolated so its UI, runtime state, and game-specific logic can be updated without editing the other feature.

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

## Deployment

Deploy each folder as a ModuleScript container: place every `.luau` file in its named folder as a ModuleScript, then run that feature's `main` ModuleScript. `init.luau` uses Roblox instance-relative `require(script.ModuleName)` calls, so the files must keep this hierarchy.

Both modules load Obsidian from its upstream `Library.lua` endpoint. They share one `OperationSiegeObsidian` environment reference, so running both modules does not download or initialize a second library copy.

## Executor / loadstring use

Host the complete `prod` folder somewhere that serves raw `.luau` files, then use the root loader:

```lua
getgenv().OperationSiegeProductionUrl =
	"https://raw.githubusercontent.com/USERNAME/REPOSITORY/main/prod/"

-- Optional: { "aimmod" }, { "gunmod" }, or omit for both.
getgenv().OperationSiegeProductionModules = { "aimmod", "gunmod" }

loadstring(game:HttpGet(getgenv().OperationSiegeProductionUrl .. "main.luau"))()
```

`main.luau` fetches the child modules and supplies their module-relative `require(script.X)` dependencies at runtime. This means the same source tree works both as Roblox ModuleScripts and from a loadstring bootstrap.

The original `aimmod.luau` and `backups/gunmod.luau` remain unchanged as reference implementations.
