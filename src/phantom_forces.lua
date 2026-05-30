-- ============================================================
--  Axiore.wtf | Phantom Forces
--  GUI Version: Rayfield
-- ============================================================

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local Camera       = Workspace.CurrentCamera
local LP           = Players.LocalPlayer

-- ============================================================
-- CONFIG STATE
-- ============================================================
local cfg = {
    silent_aim        = true,
    silent_fov        = 130,
    silent_part       = "Head",
    team_check        = true,

    no_recoil         = true,
    no_spread         = true,

    aimbot            = true,
    aimbot_fov        = 160,
    aimbot_smooth     = 0.12,
    aimbot_part       = "Head",

    esp_enabled       = true,
    esp_boxes         = true,
    esp_names         = true,
    esp_health        = true,
    esp_distance      = true,
    esp_skeletons     = true,
    esp_max_dist      = 1500,
    esp_box_color     = Color3.fromRGB(255, 80, 0),
    esp_skel_color    = Color3.fromRGB(255, 150, 0),
    esp_name_color    = Color3.fromRGB(255, 255, 255),
    esp_enemy_only    = true,

    crosshair         = true,
    crosshair_size    = 12,
    crosshair_color   = Color3.fromRGB(255, 100, 0),
    crosshair_thick   = 1.5,
    crosshair_dot     = true,
}

-- ============================================================
-- UTIL
-- ============================================================
local function getChar(p)  return p and p.Character end
local function getRoot(c)  return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")) end
local function getHum(c)   return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(p)    local c=getChar(p) local h=getHum(c) return h and h.Health>0 end
local function enemy(p)    if not cfg.team_check then return true end return p.Team~=LP.Team end
local function w2s(pos)    local s,o=Camera:WorldToViewportPoint(pos) return Vector2.new(s.X,s.Y),o end

local function closest(fov)
    local best,bd=nil,fov
    local c=Camera.ViewportSize*0.5
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and alive(p) and enemy(p) then
            local ch=getChar(p) local pt=ch and ch:FindFirstChild(cfg.silent_part)
            if pt then
                local sp,on=w2s(pt.Position)
                if on then local d=(sp-c).Magnitude if d<bd then best,bd=p,d end end
            end
        end
    end
    return best
end

-- ============================================================
-- SKELETON BONES (R15)
-- ============================================================
local SKEL = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},
    {"LeftUpperLeg","LeftLowerLeg"},{"RightUpperLeg","RightLowerLeg"},
    {"LeftLowerLeg","LeftFoot"},{"RightLowerLeg","RightFoot"},
    {"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},
    {"LeftUpperArm","LeftLowerArm"},{"RightUpperArm","RightLowerArm"},
    {"LeftLowerArm","LeftHand"},{"RightLowerArm","RightHand"},
}

-- ============================================================
-- ESP (full Drawing API)
-- ============================================================
local esp = {}

local function newLine(col,th)
    local l=Drawing.new("Line") l.Visible=false l.Thickness=th or 1.5
    l.Color=col l.Transparency=1 return l
end
local function newText(col,sz)
    local t=Drawing.new("Text") t.Visible=false t.Size=sz or 14 t.Center=true
    t.Color=col t.Outline=true t.OutlineColor=Color3.new(0,0,0) t.Font=2 return t
end

local function create_esp(plr)
    if plr==LP then return end
    local o = {}
    o.top    = newLine(cfg.esp_box_color)
    o.bot    = newLine(cfg.esp_box_color)
    o.left   = newLine(cfg.esp_box_color)
    o.right  = newLine(cfg.esp_box_color)
    o.name   = newText(cfg.esp_name_color, 14)
    o.info   = newText(cfg.esp_name_color, 13)
    o.hpbg   = newLine(Color3.fromRGB(40,40,40), 3)
    o.hpfill = newLine(Color3.fromRGB(60,255,60), 2)
    o.skel   = {}
    for i=1,#SKEL do o.skel[i] = newLine(cfg.esp_skel_color, 1) end
    esp[plr] = o
end

local function destroy_esp(plr)
    local o=esp[plr] if not o then return end
    for k,v in pairs(o) do
        if type(v)=="table" then for _,l in ipairs(v) do l:Remove() end
        elseif v.Remove then v:Remove() end
    end
    esp[plr]=nil
end

local function hide_esp(o)
    for k,v in pairs(o) do
        if type(v)=="table" then for _,l in ipairs(v) do l.Visible=false end
        else v.Visible=false end
    end
end

Players.PlayerAdded:Connect(function(p) task.wait(1) create_esp(p) end)
Players.PlayerRemoving:Connect(destroy_esp)
for _,p in ipairs(Players:GetPlayers()) do create_esp(p) end

-- ============================================================
-- SILENT AIM
-- ============================================================
local oldNC
oldNC = hookmetamethod(game, "__namecall", function(self, ...)
    if checkcaller() then return oldNC(self, ...) end
    
    local method = getnamecallmethod()
    local args = {...}
    if cfg.silent_aim and method == "FireServer" then
        local t = closest(cfg.silent_fov)
        if t then
            local ch=getChar(t) local pt=ch and ch:FindFirstChild(cfg.silent_part)
            if pt then
                for i,v in ipairs(args) do
                    if typeof(v)=="Vector3" then args[i]=pt.Position break end
                    if typeof(v)=="CFrame"  then args[i]=CFrame.new(pt.Position) break end
                end
            end
        end
    end
    return oldNC(self, table.unpack(args))
end)

-- ============================================================
-- NO RECOIL
-- ============================================================
local lastCF = Camera.CFrame
local recoilConn = RunService.RenderStepped:Connect(function()
    if cfg.no_recoil then
        local cur = Camera.CFrame
        local _,lp,_ = lastCF:ToEulerAnglesYXZ()
        local _,cp,_ = cur:ToEulerAnglesYXZ()
        local delta = cp - lp
        if delta > 0.0008 then
            Camera.CFrame = lastCF * CFrame.Angles(-delta, 0, 0)
        end
    end
    lastCF = Camera.CFrame
end)

-- ============================================================
-- AIMBOT (Right Click or Q)
-- ============================================================
local aimHeld = false
UIS.InputBegan:Connect(function(i,g) if not g and (i.KeyCode==Enum.KeyCode.Q or i.UserInputType==Enum.UserInputType.MouseButton2) then aimHeld=true end end)
UIS.InputEnded:Connect(function(i) if (i.KeyCode==Enum.KeyCode.Q or i.UserInputType==Enum.UserInputType.MouseButton2) then aimHeld=false end end)

-- ============================================================
-- CROSSHAIR & FOV
-- ============================================================
local crossLines = {}
local crossDot = nil
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(255, 255, 255)
fovCircle.Thickness = 1
fovCircle.Transparency = 0.5
fovCircle.NumSides = 32

local function mkCross()
    for _,l in ipairs(crossLines) do l:Remove() end crossLines={}
    if crossDot then crossDot:Remove() crossDot=nil end
    if not cfg.crosshair then return end
    for i=1,4 do
        local l=Drawing.new("Line") l.Thickness=cfg.crosshair_thick
        l.Color=cfg.crosshair_color l.Transparency=1 l.Visible=true crossLines[i]=l
    end
    if cfg.crosshair_dot then
        crossDot=Drawing.new("Circle") crossDot.Radius=2 crossDot.Filled=true
        crossDot.Color=cfg.crosshair_color crossDot.Transparency=1 crossDot.NumSides=8
        crossDot.Visible=true
    end
end
mkCross()

-- ============================================================
-- MAIN LOOP
-- ============================================================
local conn
conn = RunService.RenderStepped:Connect(function()
    if _G.Hub and _G.Hub.Running == false then
        conn:Disconnect() recoilConn:Disconnect()
        for _,o in pairs(esp) do
            for k,v in pairs(o) do
                if type(v)=="table" then for _,l in ipairs(v) do l:Remove() end
                elseif v.Remove then v:Remove() end
            end
        end
        for _,l in ipairs(crossLines) do l:Remove() end
        if crossDot then crossDot:Remove() end
        fovCircle:Remove()
        return
    end

    local vp = Camera.ViewportSize
    local cx,cy = vp.X/2, vp.Y/2
    local myRoot = getRoot(getChar(LP))

    fovCircle.Position = Vector2.new(cx, cy)
    fovCircle.Radius = math.max(cfg.silent_fov, cfg.aimbot_fov)
    fovCircle.Visible = cfg.silent_aim or cfg.aimbot

    -- ---- ESP ----
    for plr,o in pairs(esp) do
        local ok = cfg.esp_enabled and alive(plr) and (not cfg.esp_enemy_only or enemy(plr))
        local ch = getChar(plr)
        local root = getRoot(ch)

        if not ok or not ch or not root then hide_esp(o) continue end

        local dist = myRoot and (myRoot.Position - root.Position).Magnitude or 0
        if dist > cfg.esp_max_dist then hide_esp(o) continue end

        local head = ch:FindFirstChild("Head")
        if not head then hide_esp(o) continue end

        local rootSP, rootOn = w2s(root.Position)
        local headSP, headOn = w2s(head.Position + Vector3.new(0,1,0))
        if not rootOn or not headOn then hide_esp(o) continue end

        local h = math.abs(rootSP.Y - headSP.Y)
        local w = h * 0.55
        local topY = headSP.Y
        local botY = rootSP.Y + 5
        h = botY - topY
        w = h * 0.55
        local midX = (headSP.X + rootSP.X) / 2
        local x1,x2,y1,y2 = midX-w/2, midX+w/2, topY, botY

        -- Box
        if cfg.esp_boxes then
            o.top.From=Vector2.new(x1,y1)   o.top.To=Vector2.new(x2,y1)
            o.bot.From=Vector2.new(x1,y2)   o.bot.To=Vector2.new(x2,y2)
            o.left.From=Vector2.new(x1,y1)  o.left.To=Vector2.new(x1,y2)
            o.right.From=Vector2.new(x2,y1) o.right.To=Vector2.new(x2,y2)
            for _,l in pairs({o.top,o.bot,o.left,o.right}) do l.Color=cfg.esp_box_color l.Visible=true end
        else o.top.Visible=false o.bot.Visible=false o.left.Visible=false o.right.Visible=false end

        -- Skeleton
        if cfg.esp_skeletons then
            for i,pair in ipairs(SKEL) do
                local p1=ch:FindFirstChild(pair[1]) local p2=ch:FindFirstChild(pair[2])
                if p1 and p2 then
                    local s1,o1=w2s(p1.Position) local s2,o2=w2s(p2.Position)
                    if o1 and o2 then
                        o.skel[i].From=s1 o.skel[i].To=s2 o.skel[i].Color=cfg.esp_skel_color o.skel[i].Visible=true
                    else o.skel[i].Visible=false end
                else o.skel[i].Visible=false end
            end
        else for _,l in ipairs(o.skel) do l.Visible=false end end

        -- Name
        if cfg.esp_names then
            o.name.Position=Vector2.new(midX, y1-16) o.name.Text=plr.DisplayName
            o.name.Color=cfg.esp_name_color o.name.Visible=true
        else o.name.Visible=false end

        -- Health
        local hum = getHum(ch)
        local hp = hum and math.floor(hum.Health) or 0
        local mhp = hum and math.floor(hum.MaxHealth) or 100
        local ratio = math.clamp(hp/math.max(mhp,1), 0, 1)

        if cfg.esp_health or cfg.esp_distance then
            local txt=""
            if cfg.esp_health then txt=hp.."/"..mhp end
            if cfg.esp_distance then txt=txt.." ["..math.floor(dist).."m]" end
            o.info.Position=Vector2.new(midX, y2+2) o.info.Text=txt
            o.info.Color=Color3.fromRGB(math.floor(255*(1-ratio)),math.floor(255*ratio),0)
            o.info.Visible=true
        else o.info.Visible=false end

        -- HP bar
        if cfg.esp_health then
            o.hpbg.From=Vector2.new(x1-5,y2) o.hpbg.To=Vector2.new(x1-5,y1) o.hpbg.Visible=true
            local fy=y2-(y2-y1)*ratio
            o.hpfill.From=Vector2.new(x1-5,y2) o.hpfill.To=Vector2.new(x1-5,fy)
            o.hpfill.Color=Color3.fromRGB(math.floor(255*(1-ratio)),math.floor(255*ratio),0)
            o.hpfill.Visible=true
        else o.hpbg.Visible=false o.hpfill.Visible=false end
    end

    -- ---- AIMBOT ----
    if cfg.aimbot and aimHeld then
        local t=closest(cfg.aimbot_fov)
        if t then
            local ch2=getChar(t) local pt=ch2 and ch2:FindFirstChild(cfg.aimbot_part)
            if pt then
                local dir=(pt.Position-Camera.CFrame.Position).Unit
                Camera.CFrame=Camera.CFrame:Lerp(
                    CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position+dir),
                    cfg.aimbot_smooth)
            end
        end
    end

    -- ---- CROSSHAIR ----
    if cfg.crosshair and #crossLines==4 then
        local s=cfg.crosshair_size
        crossLines[1].From=Vector2.new(cx-s,cy) crossLines[1].To=Vector2.new(cx-4,cy)
        crossLines[2].From=Vector2.new(cx+4,cy) crossLines[2].To=Vector2.new(cx+s,cy)
        crossLines[3].From=Vector2.new(cx,cy-s) crossLines[3].To=Vector2.new(cx,cy-4)
        crossLines[4].From=Vector2.new(cx,cy+4) crossLines[4].To=Vector2.new(cx,cy+s)
        for _,l in ipairs(crossLines) do l.Color=cfg.crosshair_color l.Thickness=cfg.crosshair_thick l.Visible=true end
        if crossDot then crossDot.Position=Vector2.new(cx,cy) crossDot.Color=cfg.crosshair_color crossDot.Visible=true end
    else
        for _,l in ipairs(crossLines) do l.Visible=false end
        if crossDot then crossDot.Visible=false end
    end
end)

-- ============================================================
-- GUI (RAYFIELD)
-- ============================================================
local Window = Rayfield:CreateWindow({
   Name = "Axiore.wtf - Phantom Forces",
   LoadingTitle = "Axiore.wtf",
   LoadingSubtitle = "by cook45 x clack",
   Theme = "DarkBlue", 
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabAimbot = Window:CreateTab("Aimbot", 4483362458)
TabAimbot:CreateToggle({ Name = "Silent Aim", CurrentValue = cfg.silent_aim, Callback = function(v) cfg.silent_aim = v end })
TabAimbot:CreateToggle({ Name = "Aimbot (Hold Right Click or Q)", CurrentValue = cfg.aimbot, Callback = function(v) cfg.aimbot = v end })
TabAimbot:CreateSlider({ Name = "Silent Aim FOV", Range = {10, 500}, Increment = 1, CurrentValue = cfg.silent_fov, Callback = function(v) cfg.silent_fov = v end })
TabAimbot:CreateSlider({ Name = "Aimbot FOV", Range = {10, 500}, Increment = 1, CurrentValue = cfg.aimbot_fov, Callback = function(v) cfg.aimbot_fov = v end })

local TabCombat = Window:CreateTab("Gun Mods", 4483362458)
TabCombat:CreateToggle({ Name = "No Recoil", CurrentValue = cfg.no_recoil, Callback = function(v) cfg.no_recoil = v end })
TabCombat:CreateToggle({ Name = "No Spread (Visual)", CurrentValue = cfg.no_spread, Callback = function(v) cfg.no_spread = v end })

local TabESP = Window:CreateTab("Visuals", 4483362458)
TabESP:CreateToggle({ Name="ESP Enabled", CurrentValue=cfg.esp_enabled, Callback=function(v) cfg.esp_enabled=v end })
TabESP:CreateToggle({ Name="Draw Boxes", CurrentValue=cfg.esp_boxes, Callback=function(v) cfg.esp_boxes=v end })
TabESP:CreateToggle({ Name="Draw Skeletons", CurrentValue=cfg.esp_skeletons, Callback=function(v) cfg.esp_skeletons=v end })
TabESP:CreateToggle({ Name="Draw Names", CurrentValue=cfg.esp_names, Callback=function(v) cfg.esp_names=v end })
TabESP:CreateToggle({ Name="Draw Health", CurrentValue=cfg.esp_health, Callback=function(v) cfg.esp_health=v end })

local TabMisc = Window:CreateTab("Misc", 4483362458)
TabMisc:CreateToggle({ Name="Draw Crosshair", CurrentValue=cfg.crosshair, Callback=function(v) cfg.crosshair=v; mkCross() end })

Rayfield:Notify({
    Title = "Axiore.wtf Loaded",
    Content = "Press RightCtrl to toggle menu.",
    Duration = 5,
    Image = 4483362458,
})
