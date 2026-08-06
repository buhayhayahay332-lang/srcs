local CloneFunction = clonefunction or function(Func) return Func end;

local PCall: (any, ...any) -> (boolean, ...any)        = CloneFunction(pcall);
local ToString: (any) -> string                        = CloneFunction(tostring);
local IPairs                                           = CloneFunction(ipairs);
local Warn: (...any) -> ()                             = CloneFunction(warn);
local TaskSpawn: (((...any) -> any), ...any) -> thread = CloneFunction(task.spawn);
local StringLower: (string) -> string                  = CloneFunction(string.lower);
local StringGsub: (string, string, string) -> (string, number) = CloneFunction(string.gsub);
local StringFind: (string, string, number?, boolean?) -> (number?, number?) = CloneFunction(string.find);
local StringByte: (string, number?) -> number          = CloneFunction(string.byte);
local StringChar: (...number) -> string                = CloneFunction(string.char);
local TableConcat: ({any}, string?) -> string          = CloneFunction(table.concat);
local MathFmod: (number, number) -> number             = CloneFunction(math.fmod);
local Bit32Bxor: (number, number) -> number            = CloneFunction(bit32.bxor);

local _, S = PCall(function(...) string.byte("a", function(...) return; end, 9999, 38); end);
if S and (StringFind(S, "httplog", 1, true) or StringFind(S, "sandbox", 1, true)) then
    while true do end;
end;

local Players = cloneref(game:GetService("Players"));

local XorDecode do
    local KEY    = "astro";
    local KeyLen = #KEY;

    XorDecode = function(Encoded: {number}): string
        local Chars: {string} = {};
        for Index, Byte in IPairs(Encoded) do
            local KeyByte = StringByte(KEY, MathFmod(Index - 1, KeyLen) + 1);
            Chars[Index]  = StringChar(Bit32Bxor(Byte, KeyByte));
        end;
        return TableConcat(Chars);
    end;
end;

local ENCODED_URL: {number} = (function(): {number}
    local Key    = "astro";
    local Url    = "https://gitlab.com/potanginamo373-lang/flick/-/raw/main/flick.luau";
    local KeyLen = #Key;
    local Out: {number} = {};
    for Index = 1, #Url do
        local UrlByte = StringByte(Url, Index);
        local KeyByte = StringByte(Key, MathFmod(Index - 1, KeyLen) + 1);
        Out[Index]    = Bit32Bxor(UrlByte, KeyByte);
    end;
    return Out;
end)();

local SCRUB_PATTERNS: {string} = {
    "https?://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;%%=]+";
    "gitlab%.com";
    "potanginamo373%-lang";
    "flick";
    "flick%.luau";
};

local PLACE_IDS = {
    Expected = 136801880565837;
};

local MESSAGES = {
    WrongGame  = "Wrong game FN";
    LoadFailed = "[Loader] Failed to load script";
    RunFailed  = "[Loader] Failed to run script";
};

local BLOCKLIST = {
    ["xx"]   = true; --//could be something
    ["xx"] = true;
};


local LocalPlayer = Players.LocalPlayer;

local SafeWarn do
    SafeWarn = function(Message: string): ()
        local Scrubbed = Message;
        for _, Pattern in IPairs(SCRUB_PATTERNS) do
            local Result, _ = StringGsub(Scrubbed, Pattern, "[redacted]");
            Scrubbed = Result;
        end;
        Warn(Scrubbed);
    end;
end;

local SafePCall do
    SafePCall = function(Fn: (any) -> any, ...: any): (boolean, any)
        local Success, Result = PCall(Fn, ...);
        if not Success then
            local Scrubbed = ToString(Result);
            for _, Pattern in IPairs(SCRUB_PATTERNS) do
                local Out, _ = StringGsub(Scrubbed, Pattern, "[redacted]");
                Scrubbed = Out;
            end;
            return false, Scrubbed;
        end;
        return true, Result;
    end;
end;

local ValidateGame do
    ValidateGame = function(): boolean
        if game.PlaceId ~= PLACE_IDS.Expected then
            Warn("[Loader] Wrong game");
            LocalPlayer:Kick(MESSAGES.WrongGame);
            return false;
        end;
        return true;
    end;
end;

local GetExecutorName do
    GetExecutorName = function(): string
        local Fn: (() -> string)? = identifyexecutor or getexecutorname or nil;
        if Fn then
            return Fn();
        end;
        return "unknown";
    end;
end;

local ValidateExecutor do
    ValidateExecutor = function(ExecName: string): boolean
        local ExecLower = StringLower(ExecName);
        if BLOCKLIST[ExecLower] then
            Warn("[Loader] Executor not supported");
            LocalPlayer:Kick("Your executor is not supported.");
            return false;
        end;
        return true;
    end;
end;

local LoadMain do
    LoadMain = function(ExecLower: string): ()
        local DecodedUrl = XorDecode(ENCODED_URL);

        TaskSpawn(function()
            local Success, Result = SafePCall(function()
                return game:HttpGet(DecodedUrl);
            end);
            if not Success then
                SafeWarn(MESSAGES.LoadFailed);
                return;
            end;

            local LoadSuccess, Loaded = SafePCall(function()
                return loadstring(Result);
            end);
            if not LoadSuccess then
                SafeWarn(MESSAGES.LoadFailed);
                return;
            end;

            local RunSuccess, RunResult = SafePCall(Loaded);
            if not RunSuccess then
                SafeWarn(MESSAGES.RunFailed);
            end;
        end);

        DecodedUrl = "";
    end;
end;

if not ValidateGame() then return; end;

if not game:IsLoaded() then
    game.Loaded:Wait();
end;

local ExecName = GetExecutorName();

if not ValidateExecutor(ExecName) then return; end;

LoadMain(StringLower(ExecName));