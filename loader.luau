-- ============================================================
--  Axiore.wtf Hub | Loader
--  Usage: loadstring(game:HttpGet("https://raw.githubusercontent.com/axiore7700-hue/Axiore-wtf/main/loader.luau"))()
-- ============================================================

-- Prevent double-load
if _G.AxioreLoaded then
    warn("[Axiore.wtf] Already loaded, skipping.")
    return
end
_G.AxioreLoaded = true

local BASE_URL = "https://raw.githubusercontent.com/axiore7700-hue/Axiore-wtf/main/"

-- ============================================================
-- Game mapping: PlaceId -> script filename
-- ============================================================
local GAMES = {
    [286090429]   = { name = "Arsenal",         file = "games/arsenal.luau"         },
    [292439477]   = { name = "Phantom Forces",   file = "games/phantom_forces.luau"  },
    [17017769292] = { name = "Rivals",           file = "games/rivals.luau"          },
}

-- ============================================================
-- Notification helper
-- ============================================================
local function notify(title, msg, dur, icon)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title    = title or "Axiore.wtf",
            Text     = msg or "",
            Duration = dur or 4,
            Icon     = icon or "",
        })
    end)
end

-- ============================================================
-- Shared hub table (all sub-scripts access this)
-- ============================================================
_G.Hub = {
    Version  = "1.0",
    BaseUrl  = BASE_URL,
    Running  = true,
    Notify   = notify,
    Unload   = function()
        _G.Hub.Running  = false
        _G.AxioreLoaded = false
        notify("Axiore.wtf", "Unloaded.", 3)
    end,
}

-- ============================================================
-- Detect game
-- ============================================================
local placeId  = game.PlaceId
local gameInfo = GAMES[placeId]

-- Fallback: try matching by game name
if not gameInfo then
    local ok, product = pcall(function()
        return game:GetService("MarketplaceService"):GetProductInfo(placeId)
    end)
    if ok and product then
        local n = product.Name:lower()
        if n:find("arsenal")       then gameInfo = GAMES[286090429]
        elseif n:find("phantom")   then gameInfo = GAMES[292439477]
        elseif n:find("rivals")    then gameInfo = GAMES[17017769292]
        end
    end
end

-- ============================================================
-- Load game script
-- ============================================================
if gameInfo then
    _G.Hub.GameName = gameInfo.name
    notify("Axiore.wtf", "Loading " .. gameInfo.name .. "...", 3)

    local url = BASE_URL .. gameInfo.file
    local ok, err = pcall(function()
        local src = game:HttpGet(url, true)
        if not src or #src < 10 then
            error("Empty response from " .. url)
        end
        loadstring(src)()
    end)

    if not ok then
        notify("Axiore.wtf", "Load failed: " .. tostring(err), 6)
        warn("[Axiore.wtf] Failed to load " .. gameInfo.name .. ": " .. tostring(err))
    end
else
    notify("Axiore.wtf", "Game not supported.\nPlaceId: " .. tostring(placeId), 6)
    warn("[Axiore.wtf] Unsupported PlaceId: " .. tostring(placeId))
    warn("[Axiore.wtf] Supported: Arsenal, Phantom Forces, Rivals")
end
