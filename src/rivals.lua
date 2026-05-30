-- ============================================================
--  Axiore.wtf | Rivals
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
    silent_fov        = 100,
    silent_part       = "Head",

    aimbot            = true,
    aimbot_fov        = 120,
    aimbot_smooth     = 0.2,
    aimbot_part       = "Head",

    esp_enabled       = true,
    esp_boxes         = true,
    esp_skeletons     = true,
    esp_distance      = true,
    esp_max_dist      = 800,
    esp_box_color     = Color3.fromRGB(0, 255, 150),
    esp_skel_color    = Color3.fromRGB(0, 200, 100),

    walk_speed        = 16,
    jump_power        = 50,
    anti_stun         = true,
    crosshair         = true,
    crosshair_size    = 8,
    crosshair_color   = Color3.fromRGB(0, 255, 150),
}

-- ============================================================
-- UTIL
-- ============================================================
local function getChar(p)  return p and p.Character end
local function getRoot(c)  return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")) end
local function getHum(c)   return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(p)    local c=getChar(p) local h=getHum(c) return h and h.Health>0 end
local function w2s(pos)    local s,o=Camera:WorldToViewportPoint(pos) return Vector2.new(s.X,s.Y),o end

local function closest(fov)
    local best,bd=nil,fov
    local c=Camera.ViewportSize*0.5
    for _,p in ipairs(Players:GetPlayers()) do
        if p~=LP and alive(p) then
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
-- SKELETON
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

local esp = {}
local function newLine(col,th) local l=Drawing.new("Line") l.Visible=false l.Thickness=th or 1 l.Color=col return l end
local function newText(col,sz) local t=Drawing.new("Text") t.Visible=false t.Size=sz or 14 t.Center=true t.Color=col t.Outline=true t.Font=2 return t end

local function create_esp(plr)
    if plr==LP then return end
    local o = {}
    o.top    = newLine(cfg.esp_box_color, 1.5)
    o.bot    = newLine(cfg.esp_box_color, 1.5)
    o.left   = newLine(cfg.esp_box_color, 1.5)
    o.right  = newLine(cfg.esp_box_color, 1.5)
    o.info   = newText(Color3.new(1,1,1), 13)
    o.skel   = {}
    for i=1,#SKEL do o.skel[i] = newLine(cfg.esp_skel_color, 1) end
    esp[plr] = o
end

local function destroy_esp(plr)
    local o=esp[plr] if not o then return end
    for k,v in pairs(o) do if type(v)=="table" then for _,l in ipairs(v) do l:Remove() end elseif v.Remove then v:Remove() end end
    esp[plr]=nil
end

Players.PlayerAdded:Connect(function(p) task.wait(1) create_esp(p) end)
Players.PlayerRemoving:Connect(destroy_esp)
for _,p in ipairs(Players:GetPlayers()) do create_esp(p) end

-- ============================================================
-- MAIN RENDER
-- ============================================================
local aimHeld = false
UIS.InputBegan:Connect(function(i,g) if not g and (i.KeyCode==Enum.KeyCode.Q or i.UserInputType==Enum.UserInputType.MouseButton2) then aimHeld=true end end)
UIS.InputEnded:Connect(function(i) if (i.KeyCode==Enum.KeyCode.Q or i.UserInputType==Enum.UserInputType.MouseButton2) then aimHeld=false end end)

local crossLines={}
local function mkCH()
    for _,l in ipairs(crossLines) do l:Remove() end crossLines={}
    if not cfg.crosshair then return end
    for i=1,4 do crossLines[i]=newLine(cfg.crosshair_color, 1.5) crossLines[i].Visible=true end
end
mkCH()

local fovCircle = Drawing.new("Circle") fovCircle.Color=Color3.new(1,1,1) fovCircle.Thickness=1 fovCircle.Transparency=0.5 fovCircle.NumSides=32

local conn
conn = RunService.RenderStepped:Connect(function()
    if _G.Hub and _G.Hub.Running == false then
        conn:Disconnect()
        for _,o in pairs(esp) do for k,v in pairs(o) do if type(v)=="table" then for _,l in ipairs(v) do l:Remove() end elseif v.Remove then v:Remove() end end end
        for _,l in ipairs(crossLines) do l:Remove() end fovCircle:Remove()
        return
    end

    local cx,cy = Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2
    local myChar=getChar(LP) local myRoot=getRoot(myChar)

    fovCircle.Position = Vector2.new(cx,cy)
    fovCircle.Radius = math.max(cfg.silent_fov, cfg.aimbot_fov)
    fovCircle.Visible = cfg.silent_aim or cfg.aimbot

    -- SPEED & JUMP
    if myChar then
        local h = getHum(myChar)
        if h then
            if cfg.walk_speed > 16 then h.WalkSpeed = cfg.walk_speed end
            if cfg.jump_power > 50 then h.JumpPower = cfg.jump_power end
            if cfg.anti_stun then
                local st = myChar:FindFirstChild("Stun")
                if st then st:Destroy() end
            end
        end
    end

    -- ESP
    for plr,o in pairs(esp) do
        local ok = cfg.esp_enabled and alive(plr)
        local ch = getChar(plr) local root=getRoot(ch)
        if not ok or not ch or not root then 
            for k,v in pairs(o) do if type(v)=="table" then for _,l in ipairs(v) do l.Visible=false end else v.Visible=false end end
            continue 
        end
        local dist = myRoot and (myRoot.Position-root.Position).Magnitude or 0
        if dist>cfg.esp_max_dist then 
            for k,v in pairs(o) do if type(v)=="table" then for _,l in ipairs(v) do l.Visible=false end else v.Visible=false end end
            continue 
        end
        local head=ch:FindFirstChild("Head")
        if not head then continue end
        local rS,rO=w2s(root.Position) local hS,hO=w2s(head.Position+Vector3.new(0,1,0))
        if not rO or not hO then 
            for k,v in pairs(o) do if type(v)=="table" then for _,l in ipairs(v) do l.Visible=false end else v.Visible=false end end
            continue 
        end

        local h = math.abs(rS.Y - hS.Y) local w = h*0.55
        local midX = (hS.X+rS.X)/2
        local x1,x2,y1,y2 = midX-w/2, midX+w/2, hS.Y, rS.Y+5

        if cfg.esp_boxes then
            o.top.From=Vector2.new(x1,y1) o.top.To=Vector2.new(x2,y1)
            o.bot.From=Vector2.new(x1,y2) o.bot.To=Vector2.new(x2,y2)
            o.left.From=Vector2.new(x1,y1) o.left.To=Vector2.new(x1,y2)
            o.right.From=Vector2.new(x2,y1) o.right.To=Vector2.new(x2,y2)
            for _,l in pairs({o.top,o.bot,o.left,o.right}) do l.Color=cfg.esp_box_color l.Visible=true end
        else o.top.Visible=false o.bot.Visible=false o.left.Visible=false o.right.Visible=false end

        if cfg.esp_distance then o.info.Position=Vector2.new(midX,y2+2) o.info.Text="["..math.floor(dist).."m]" o.info.Visible=true else o.info.Visible=false end

        if cfg.esp_skeletons then
            for i,pair in ipairs(SKEL) do
                local p1,p2=ch:FindFirstChild(pair[1]),ch:FindFirstChild(pair[2])
                if p1 and p2 then
                    local s1,o1=w2s(p1.Position) local s2,o2=w2s(p2.Position)
                    if o1 and o2 then o.skel[i].From=s1 o.skel[i].To=s2 o.skel[i].Color=cfg.esp_skel_color o.skel[i].Visible=true
                    else o.skel[i].Visible=false end
                else o.skel[i].Visible=false end
            end
        else for _,l in ipairs(o.skel) do l.Visible=false end end
    end

    -- AIMBOT
    if cfg.aimbot and aimHeld then
        local t=closest(cfg.aimbot_fov)
        if t then
            local ch2=getChar(t) local pt=ch2 and ch2:FindFirstChild(cfg.aimbot_part)
            if pt then
                local dir=(pt.Position-Camera.CFrame.Position).Unit
                Camera.CFrame=Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position+dir), cfg.aimbot_smooth)
            end
        end
    end

    if cfg.crosshair and #crossLines==4 then
        local s=cfg.crosshair_size
        crossLines[1].From=Vector2.new(cx-s,cy) crossLines[1].To=Vector2.new(cx-2,cy)
        crossLines[2].From=Vector2.new(cx+2,cy) crossLines[2].To=Vector2.new(cx+s,cy)
        crossLines[3].From=Vector2.new(cx,cy-s) crossLines[3].To=Vector2.new(cx,cy-2)
        crossLines[4].From=Vector2.new(cx,cy+2) crossLines[4].To=Vector2.new(cx,cy+s)
        for _,l in ipairs(crossLines) do l.Color=cfg.crosshair_color l.Visible=true end
    else for _,l in ipairs(crossLines) do l.Visible=false end end
end)

-- SILENT AIM HOOK
local oldNC
oldNC = hookmetamethod(game, "__namecall", function(self, ...)
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
-- GUI (RAYFIELD)
-- ============================================================
local Window = Rayfield:CreateWindow({
   Name = "Axiore.wtf - Rivals",
   LoadingTitle = "Axiore.wtf",
   LoadingSubtitle = "by cook45 x clack",
   Theme = "DarkBlue", 
   ConfigurationSaving = { Enabled = false },
   KeySystem = false
})

local TabAimbot = Window:CreateTab("Aimbot", 4483362458)
TabAimbot:CreateToggle({ Name="Silent Aim", CurrentValue=cfg.silent_aim, Callback=function(v) cfg.silent_aim=v end })
TabAimbot:CreateToggle({ Name="Aimbot (Hold Right Click/Q)", CurrentValue=cfg.aimbot, Callback=function(v) cfg.aimbot=v end })
TabAimbot:CreateSlider({ Name="Silent Aim FOV", Range={10,500}, Increment=1, CurrentValue=cfg.silent_fov, Callback=function(v) cfg.silent_fov=v end })
TabAimbot:CreateSlider({ Name="Aimbot FOV", Range={10,500}, Increment=1, CurrentValue=cfg.aimbot_fov, Callback=function(v) cfg.aimbot_fov=v end })

local TabESP = Window:CreateTab("Visuals", 4483362458)
TabESP:CreateToggle({ Name="ESP Enabled", CurrentValue=cfg.esp_enabled, Callback=function(v) cfg.esp_enabled=v end })
TabESP:CreateToggle({ Name="Draw Boxes", CurrentValue=cfg.esp_boxes, Callback=function(v) cfg.esp_boxes=v end })
TabESP:CreateToggle({ Name="Draw Skeletons", CurrentValue=cfg.esp_skeletons, Callback=function(v) cfg.esp_skeletons=v end })
TabESP:CreateToggle({ Name="Draw Distance", CurrentValue=cfg.esp_distance, Callback=function(v) cfg.esp_distance=v end })

local TabMovement = Window:CreateTab("Movement", 4483362458)
TabMovement:CreateSlider({ Name="Walk Speed", Range={16,100}, Increment=1, CurrentValue=cfg.walk_speed, Callback=function(v) cfg.walk_speed=v end })
TabMovement:CreateSlider({ Name="Jump Power", Range={50,200}, Increment=1, CurrentValue=cfg.jump_power, Callback=function(v) cfg.jump_power=v end })
TabMovement:CreateToggle({ Name="Anti-Stun", CurrentValue=cfg.anti_stun, Callback=function(v) cfg.anti_stun=v end })

local TabMisc = Window:CreateTab("Misc", 4483362458)
TabMisc:CreateToggle({ Name="Draw Crosshair", CurrentValue=cfg.crosshair, Callback=function(v) cfg.crosshair=v mkCH() end })

Rayfield:Notify({
    Title = "Axiore.wtf Loaded",
    Content = "Press RightCtrl to toggle menu.",
    Duration = 5,
    Image = 4483362458,
})
