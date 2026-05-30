-- ============================================================
--  Axiore.wtf | Hub Loader
--  Auto-detects game and loads corresponding script
-- ============================================================

local BASE_URL = "https://raw.githubusercontent.com/axiore7700-hue/Axiore-wtf/main/"

local notify = function(title, text)
    pcall(function()
        game.StarterGui:SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 5
        })
    end)
end

-- ============================================================
-- Game mapping: PlaceId -> script filename
-- ============================================================
local GAMES = {
    -- Arsenal
    [286090429]   = { name = "Arsenal",          file = "arsenal.luau"         },
    
    -- Phantom Forces
    [292439477]   = { name = "Phantom Forces",   file = "phantom_forces.luau"  },
    [11345699]    = { name = "PF Test Place",    file = "phantom_forces.luau"  },
    
    -- Rivals
    [17017769292] = { name = "Rivals",           file = "rivals.luau"          },
    [17625359962] = { name = "Rivals (Lobby)",   file = "rivals.luau"          },
}

-- ============================================================
-- INIT
-- ============================================================
local placeId = game.PlaceId
local data = GAMES[placeId]

if not data then
    notify("Axiore.wtf", "Game not supported.\nPlaceId: " .. tostring(placeId))
    return
end

notify("Axiore.wtf", "Loading " .. data.name .. " script...")

local url = BASE_URL .. data.file
local success, result = pcall(function()
    return game:HttpGet(url, true)
end)

if success then
    local f, err = loadstring(result)
    if f then
        if _G.Hub and _G.Hub.Running then
            _G.Hub.Running = false
            task.wait(0.5)
        end
        _G.Hub = { Running = true, Notify = notify }
        f()
    else
        notify("Axiore.wtf", "Syntax error in script: " .. tostring(err))
    end
else
    notify("Axiore.wtf", "Failed to download script. Is repo public?")
end
