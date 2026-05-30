-- ============================================================
--  Axiore.wtf | Arsenal
--  Auto-loaded via hub or standalone
--  Features: Silent Aim, ESP, Aimbot, Inf Jump,
--            Anti-Ragdoll, Crosshair
-- ============================================================

local Players      = game:GetService("Players")
local RunService   = game:GetService("RunService")
local UIS          = game:GetService("UserInputService")
local Workspace    = game:GetService("Workspace")
local Camera       = Workspace.CurrentCamera
local LP           = Players.LocalPlayer
local notify       = (_G.Hub and _G.Hub.Notify) or function() end

-- ============================================================
-- CONFIG
-- ============================================================
local cfg = {
    silent_aim        = true,
    silent_fov        = 120,
    silent_part       = "Head",

    aimbot            = false,
    aimbot_key        = Enum.KeyCode.Q,
    aimbot_fov        = 150,
    aimbot_smooth     = 0.15,
    aimbot_part       = "Head",
    team_check        = true,

    esp_enabled       = true,
    esp_boxes         = true,
    esp_names         = true,
    esp_health        = true,
    esp_distance      = true,
    esp_max_dist      = 1000,
    esp_box_color     = Color3.fromRGB(255, 60, 60),
    esp_name_color    = Color3.fromRGB(255, 255, 255),
    esp_enemy_only    = true,

    inf_jump          = true,
    anti_ragdoll      = true,
    crosshair         = true,
    crosshair_size    = 10,
    crosshair_color   = Color3.fromRGB(255, 60, 60),
    crosshair_thick   = 1.5,
}

-- ============================================================
-- UTIL
-- ============================================================
local function getChar(p)  return p and p.Character end
local function getRoot(c)  return c and (c:FindFirstChild("HumanoidRootPart") or c:FindFirstChild("UpperTorso")) end
local function getHum(c)   return c and c:FindFirstChildOfClass("Humanoid") end
local function alive(p)    local c=getChar(p) local h=getHum(c) return h and h.Health>0 end
local function enemy(p)    if not cfg.team_check then return true end return p.Team~=LP.Team end
local function w2s(pos)    local s,o=Camera:WorldToViewportPoint(pos) return Vector2.new(s.X,s.Y),o,s.Z end

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
-- ESP (Drawing API — screen-space boxes)
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
    local o={}
    o.top    = newLine(cfg.esp_box_color)
    o.bot    = newLine(cfg.esp_box_color)
    o.left   = newLine(cfg.esp_box_color)
    o.right  = newLine(cfg.esp_box_color)
    o.name   = newText(cfg.esp_name_color, 14)
    o.info   = newText(Color3.fromRGB(60,255,60), 13)
    -- Health bar (2 lines: bg + fill)
    o.hpbg   = newLine(Color3.fromRGB(40,40,40), 3)
    o.hpfill = newLine(Color3.fromRGB(60,255,60), 2)
    esp[plr] = o
end

local function destroy_esp(plr)
    local o=esp[plr] if not o then return end
    for _,v in pairs(o) do if v.Remove then v:Remove() end end
    esp[plr]=nil
end

local function hide_esp(o)
    for _,v in pairs(o) do v.Visible=false end
end

Players.PlayerAdded:Connect(function(p) task.wait(1) create_esp(p) end)
Players.PlayerRemoving:Connect(destroy_esp)
for _,p in ipairs(Players:GetPlayers()) do create_esp(p) end

-- ============================================================
-- SILENT AIM
-- ============================================================
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
-- AIMBOT
-- ============================================================
local aimHeld = false
UIS.InputBegan:Connect(function(i,g) if not g and i.KeyCode==cfg.aimbot_key then aimHeld=true end end)
UIS.InputEnded:Connect(function(i) if i.KeyCode==cfg.aimbot_key then aimHeld=false end end)

-- ============================================================
-- INF JUMP
-- ============================================================
UIS.JumpRequest:Connect(function()
    if not cfg.inf_jump then return end
    local c=getChar(LP) local h=getHum(c)
    if h and h:GetState()~=Enum.HumanoidStateType.Dead then
        h:ChangeState(Enum.HumanoidStateType.Jumping)
    end
end)

-- ============================================================
-- ANTI-RAGDOLL
-- ============================================================
local function patchRag(char)
    if not char then return end
    local function kill(v)
        if cfg.anti_ragdoll and (v:IsA("BallSocketConstraint") or v:IsA("HingeConstraint")) then
            v.Enabled = false
        end
    end
    for _,v in ipairs(char:GetDescendants()) do kill(v) end
    char.DescendantAdded:Connect(kill)
end
patchRag(LP.Character)
LP.CharacterAdded:Connect(function(c) task.wait(0.5) patchRag(c) end)

-- ============================================================
-- CROSSHAIR
-- ============================================================
local ch = {}
local function mkCH()
    for _,l in ipairs(ch) do l:Remove() end ch={}
    if not cfg.crosshair then return end
    for i=1,4 do
        local l=Drawing.new("Line") l.Thickness=cfg.crosshair_thick
        l.Color=cfg.crosshair_color l.Transparency=1 l.Visible=true ch[i]=l
    end
end
mkCH()

-- ============================================================
-- MAIN LOOP
-- ============================================================
local conn
conn = RunService.RenderStepped:Connect(function()
    if _G.Hub and not _G.Hub.Running then
        conn:Disconnect()
        for _,o in pairs(esp) do for _,v in pairs(o) do if v.Remove then v:Remove() end end end
        for _,l in ipairs(ch) do l:Remove() end
        return
    end

    local vp = Camera.ViewportSize
    local cx, cy = vp.X/2, vp.Y/2
    local myChar = getChar(LP)
    local myRoot = getRoot(myChar)

    -- ---- ESP ----
    for plr, o in pairs(esp) do
        local ok = cfg.esp_enabled and alive(plr) and (not cfg.esp_enemy_only or enemy(plr))
        local ch2 = getChar(plr)
        local root = getRoot(ch2)

        if not ok or not ch2 or not root then hide_esp(o) continue end

        local dist = myRoot and (myRoot.Position - root.Position).Magnitude or 0
        if dist > cfg.esp_max_dist then hide_esp(o) continue end

        -- Calculate screen bounding box from head + root
        local head = ch2:FindFirstChild("Head")
        if not head then hide_esp(o) continue end

        local rootSP, rootOn = w2s(root.Position)
        local headSP, headOn = w2s(head.Position + Vector3.new(0, 1, 0))

        if not rootOn or not headOn then hide_esp(o) continue end

        local h = math.abs(rootSP.Y - headSP.Y)
        local w = h * 0.55
        local topY = headSP.Y
        local botY = rootSP.Y + 5
        h = botY - topY
        w = h * 0.55
        local midX = (headSP.X + rootSP.X) / 2

        local x1 = midX - w/2
        local x2 = midX + w/2
        local y1 = topY
        local y2 = botY

        -- Box
        if cfg.esp_boxes then
            o.top.From   = Vector2.new(x1,y1) o.top.To   = Vector2.new(x2,y1)
            o.bot.From   = Vector2.new(x1,y2) o.bot.To   = Vector2.new(x2,y2)
            o.left.From  = Vector2.new(x1,y1) o.left.To  = Vector2.new(x1,y2)
            o.right.From = Vector2.new(x2,y1) o.right.To = Vector2.new(x2,y2)
            for _,l in pairs({o.top,o.bot,o.left,o.right}) do l.Color=cfg.esp_box_color l.Visible=true end
        else
            o.top.Visible=false o.bot.Visible=false o.left.Visible=false o.right.Visible=false
        end

        -- Name
        if cfg.esp_names then
            o.name.Position = Vector2.new(midX, y1 - 16)
            o.name.Text     = plr.DisplayName
            o.name.Color    = cfg.esp_name_color
            o.name.Visible  = true
        else o.name.Visible = false end

        -- Health + distance text
        local hum = getHum(ch2)
        local hp = hum and math.floor(hum.Health) or 0
        local mhp = hum and math.floor(hum.MaxHealth) or 100
        local ratio = math.clamp(hp/math.max(mhp,1), 0, 1)

        if cfg.esp_health or cfg.esp_distance then
            local txt = ""
            if cfg.esp_health then txt = hp.."/"..mhp end
            if cfg.esp_distance then txt = txt.." ["..math.floor(dist).."m]" end
            o.info.Position = Vector2.new(midX, y2 + 2)
            o.info.Text     = txt
            o.info.Color    = Color3.fromRGB(math.floor(255*(1-ratio)), math.floor(255*ratio), 0)
            o.info.Visible  = true
        else o.info.Visible = false end

        -- Health bar (left side)
        if cfg.esp_health then
            o.hpbg.From   = Vector2.new(x1-5, y2)  o.hpbg.To   = Vector2.new(x1-5, y1)
            o.hpbg.Visible = true
            local fillY = y2 - (y2-y1)*ratio
            o.hpfill.From  = Vector2.new(x1-5, y2) o.hpfill.To  = Vector2.new(x1-5, fillY)
            o.hpfill.Color = Color3.fromRGB(math.floor(255*(1-ratio)), math.floor(255*ratio), 0)
            o.hpfill.Visible = true
        else o.hpbg.Visible=false o.hpfill.Visible=false end
    end

    -- ---- AIMBOT ----
    if cfg.aimbot and aimHeld then
        local t = closest(cfg.aimbot_fov)
        if t then
            local ch2=getChar(t) local pt=ch2 and ch2:FindFirstChild(cfg.aimbot_part)
            if pt then
                local dir=(pt.Position-Camera.CFrame.Position).Unit
                Camera.CFrame = Camera.CFrame:Lerp(
                    CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position+dir),
                    cfg.aimbot_smooth
                )
            end
        end
    end

    -- ---- CROSSHAIR ----
    if cfg.crosshair and #ch==4 then
        local s=cfg.crosshair_size
        ch[1].From=Vector2.new(cx-s,cy) ch[1].To=Vector2.new(cx-3,cy)
        ch[2].From=Vector2.new(cx+3,cy) ch[2].To=Vector2.new(cx+s,cy)
        ch[3].From=Vector2.new(cx,cy-s) ch[3].To=Vector2.new(cx,cy-3)
        ch[4].From=Vector2.new(cx,cy+3) ch[4].To=Vector2.new(cx,cy+s)
        for _,l in ipairs(ch) do l.Color=cfg.crosshair_color l.Thickness=cfg.crosshair_thick l.Visible=true end
    end
end)

notify("Arsenal", "Loaded ✓ | Q=Aimbot | Silent Aim ON", 5)
return cfg
