_=0;repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PathfindingService = game:GetService("PathfindingService")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local Mouse = LocalPlayer:GetMouse()

local okUI, WindUI = pcall(function()
 return loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()
end)
if not okUI or not WindUI then return end

local function safeDrawing(c)
 local ok, o = pcall(function()
  if type(Drawing) == "table" and type(Drawing.new) == "function" then return Drawing.new(c) end
 end)
 if ok and o then return o end
 return {Visible=false,Color=Color3.new(1,1,1),Radius=150,Position=Vector2.zero,From=Vector2.zero,To=Vector2.zero,Thickness=1.5,Transparency=1,Filled=false,NumSides=64,Remove=function()end}
end

local THEMES = {
 Black = {Accent=Color3.fromRGB(150,150,150),Outline=Color3.fromRGB(50,50,60),Background=Color3.fromRGB(16,16,20),ButtonTop=Color3.fromRGB(30,30,35),ButtonBot=Color3.fromRGB(15,15,20)},
 Purple = {Accent=Color3.fromRGB(185,85,255),Outline=Color3.fromRGB(120,50,180),Background=Color3.fromRGB(28,14,42),ButtonTop=Color3.fromRGB(130,45,200),ButtonBot=Color3.fromRGB(55,18,95)},
 Red = {Accent=Color3.fromRGB(255,65,80),Outline=Color3.fromRGB(170,40,50),Background=Color3.fromRGB(42,12,16),ButtonTop=Color3.fromRGB(190,35,50),ButtonBot=Color3.fromRGB(85,15,22)}
}

pcall(function()
 for n, d in pairs(THEMES) do
  WindUI:AddTheme({Name="ProHub_"..n,Accent=d.Accent,Outline=d.Outline,Background=d.Background,Text=Color3.fromRGB(245,245,250),PlaceholderText=Color3.fromRGB(150,150,160)})
 end
 WindUI:SetTheme("ProHub_Black")
end)

local Window = WindUI:CreateWindow({Title="ProHub",Icon="zap",Author="Murder Mystery 2",Folder="ProHub",Size=UDim2.fromOffset(520,360),Theme="ProHub_Black",Transparent=true,Acrylic=false})

local function applyMenuTheme(themeName)
 local t = THEMES[themeName] or THEMES.Black
 pcall(function() WindUI:SetTheme("ProHub_"..themeName) end)
 pcall(function()
  Window:EditOpenButton({Title="ProHub",Icon="zap",CornerRadius=UDim.new(1,0),StrokeThickness=2,Color=ColorSequence.new(t.ButtonTop,t.ButtonBot),Draggable=true})
 end)
 pcall(function()
  local conts = {CoreGui, LocalPlayer:FindFirstChild("PlayerGui")}
  if type(gethui) == "function" then pcall(function() table.insert(conts, gethui()) end) end
  for _, c in ipairs(conts) do
   for _, g in ipairs(c:GetDescendants()) do
    if g:IsA("Frame") and g.Size.X.Offset == 520 and g.Size.Y.Offset == 360 then
     g.BackgroundColor3 = t.Background
     g.BackgroundTransparency = 0.15
    end
   end
  end
 end)
end
applyMenuTheme("Black")

local Tabs = {
 Teleports = Window:Tab({Title="Teleports",Icon="map-pin"}),
 Movement = Window:Tab({Title="Movement",Icon="move"}),
 Combat = Window:Tab({Title="Combat",Icon="sword"}),
 Visuals = Window:Tab({Title="Visuals",Icon="eye"}),
 AutoFarm = Window:Tab({Title="AutoFarm",Icon="coins"}),
 Fling = Window:Tab({Title="Fling",Icon="wind"}),
 Misc = Window:Tab({Title="Misc",Icon="wrench"}),
 Settings = Window:Tab({Title="Settings",Icon="settings"})
}

local S = {
 ClickTP=false,TouchFling=false,TouchFlingPower=50000,AntiFling=false,SelectedFlingPlayer="",
 KillAllMode=1,AutoGun=false,Trail=false,TrailLifetime=0.4,JumpCircle=false,Aura=false,
 FovSize=70,ESP_Roles=false,ESP_Tracers=false,ESP_Candyes=false,ThirdPerson=false,
 UserTag=false,EnableCamlock=false,CamlockMode="Head",CamlockSmoothness=2,
 EnableNight=false,Fly=false,FlySpeed=50,
 WalkSpeed=16,JumpPower=50,EnableAirJump=false,EnableNoclip=false,SpeedGlitch=false,SpinBot=false,SpinSpeed=20,
 EnableShaders=false,Theme="Black",AutoFarm=false,AutoFarmMode=2,FarmPosition=2,
 WalkFarmSpeed=26,FlyFarmSpeed=24,AntiAfk=false,
 EnableAimbot=false,AimbotMode="Head",ShowFovAimbot=true,RainbowAimbotCircle=false,AimbotRadius=150,AimbotSmoothness=3
}

local COLORS = {
 Murderer=Color3.fromRGB(255,70,90),
 Sheriff=Color3.fromRGB(70,160,255),
 Innocent=Color3.fromRGB(70,230,130),
 Candy=Color3.fromRGB(255,220,0)
}

local commRemote = ReplicatedStorage:FindFirstChild("SakuraHub_UserSync")
if not commRemote and ReplicatedStorage then pcall(function() commRemote = Instance.new("RemoteEvent", ReplicatedStorage) commRemote.Name = "SakuraHub_UserSync" end) end
local activeUsers = {[LocalPlayer.UserId] = true}
if commRemote then
 pcall(function() commRemote.OnClientEvent:Connect(function(u) activeUsers[u] = true end) end)
 task.spawn(function() while true do pcall(function() commRemote:FireServer(LocalPlayer.UserId) end) task.wait(5) end end)
end

local function spawnJumpCircle()
 local ch = LocalPlayer.Character
 local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
 if not hrp then return end
 pcall(function()
  local rp = RaycastParams.new()
  rp.FilterType = Enum.RaycastFilterType.Exclude
  rp.FilterDescendantsInstances = {ch}
  local res = workspace:Raycast(hrp.Position, Vector3.new(0, -6, 0), rp)
  local pos = res and res.Position or (hrp.Position - Vector3.new(0, 2.8, 0))
  local p = Instance.new("Part", workspace)
  p.Anchored = true p.CanCollide = false p.CanQuery = false p.CanTouch = false
  p.Transparency = 1 p.Size = Vector3.new(1.2, 0.05, 1.2)
  p.CFrame = CFrame.new(pos + Vector3.new(0, 0.05, 0))
  for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
   local sg = Instance.new("SurfaceGui", p)
   sg.Face = face sg.CanvasSize = Vector2.new(256, 256) sg.LightInfluence = 0
   local fr = Instance.new("Frame", sg)
   fr.AnchorPoint = Vector2.new(0.5, 0.5) fr.Position = UDim2.fromScale(0.5, 0.5)
   fr.Size = UDim2.fromScale(0.88, 0.88) fr.BackgroundColor3 = Color3.fromRGB(220, 245, 255)
   fr.BackgroundTransparency = 0.72
   Instance.new("UICorner", fr).CornerRadius = UDim.new(1, 0)
   local st = Instance.new("UIStroke", fr)
   st.Color = Color3.fromRGB(245, 252, 255) st.Thickness = 8 st.Transparency = 0.05
   TweenService:Create(fr, TweenInfo.new(0.55), {BackgroundTransparency = 1}):Play()
   TweenService:Create(st, TweenInfo.new(0.55), {Transparency = 1, Thickness = 1}):Play()
  end
  TweenService:Create(p, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = Vector3.new(8.2, 0.05, 8.2)}):Play()
  task.delay(0.6, function() if p and p.Parent then p:Destroy() end end)
 end)
end

local auraObjs = {}
local function clearAura()
 for _, v in ipairs(auraObjs) do pcall(function() v:Destroy() end) end
 table.clear(auraObjs)
end

local function ensureAura(ch)
 local hrp = ch:FindFirstChild("HumanoidRootPart")
 local head = ch:FindFirstChild("Head")
 if not hrp or not head then return end
 if hrp:FindFirstChild("ProHub_AuraLight") and ch:FindFirstChild("ProHub_AuraFloor") then return end
 clearAura()
 pcall(function()
  local pl = Instance.new("PointLight", hrp)
  pl.Name = "ProHub_AuraLight" pl.Color = Color3.fromRGB(130, 220, 255) pl.Brightness = 2.5 pl.Range = 11
  pl.Enabled = not S.JumpCircle
  table.insert(auraObjs, pl)

  local fp = Instance.new("Part", ch)
  fp.Name = "ProHub_AuraFloor" fp.Anchored = false fp.CanCollide = false fp.CanQuery = false fp.Massless = true
  fp.Transparency = 1 fp.Size = Vector3.new(6.8, 0.05, 6.8)
  fp.CFrame = hrp.CFrame * CFrame.new(0, -2.85, 0)
  local fw = Instance.new("WeldConstraint", fp) fw.Part0 = hrp fw.Part1 = fp
  for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
   local fsg = Instance.new("SurfaceGui", fp)
   fsg.Face = face fsg.CanvasSize = Vector2.new(320, 320) fsg.LightInfluence = 0
   local glw = Instance.new("Frame", fsg)
   glw.Name = "AuraGlow"
   glw.AnchorPoint = Vector2.new(0.5, 0.5) glw.Position = UDim2.fromScale(0.5, 0.5)
   glw.Size = UDim2.fromScale(0.65, 0.65) glw.BackgroundColor3 = Color3.fromRGB(130, 225, 255) glw.BackgroundTransparency = 0.62
   glw.Visible = not S.JumpCircle
   Instance.new("UICorner", glw).CornerRadius = UDim.new(1, 0)
   for i = 1, 4 do
    local r = Instance.new("Frame", fsg)
    r.AnchorPoint = Vector2.new(0.5, 0.5) r.Position = UDim2.fromScale(0.5, 0.5)
    local sc = 0.94 - (i - 1) * 0.19
    r.Size = UDim2.fromScale(sc, sc) r.BackgroundTransparency = 1
    Instance.new("UICorner", r).CornerRadius = UDim.new(1, 0)
    local rst = Instance.new("UIStroke", r)
    rst.Thickness = 7 - i rst.Color = Color3.fromRGB(185, 240, 255)
    local gr = Instance.new("UIGradient", rst)
    gr.Color = ColorSequence.new(Color3.fromRGB(95, 205, 255), Color3.fromRGB(255, 255, 255))
    gr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.45, 0.15), NumberSequenceKeypoint.new(0.8, 0.75), NumberSequenceKeypoint.new(1, 0.95)})
   end
  end
  table.insert(auraObjs, fp)

  local hp = Instance.new("Part", ch)
  hp.Name = "ProHub_AuraHalo" hp.Anchored = false hp.CanCollide = false hp.CanQuery = false hp.Massless = true
  hp.Transparency = 1 hp.Size = Vector3.new(3.1, 0.05, 3.1)
  hp.CFrame = head.CFrame * CFrame.new(0, 1.15, 0) * CFrame.Angles(math.rad(15), 0, math.rad(-15))
  local hw = Instance.new("WeldConstraint", hp) hw.Part0 = head hw.Part1 = hp
  for _, face in ipairs({Enum.NormalId.Top, Enum.NormalId.Bottom}) do
   local hsg = Instance.new("SurfaceGui", hp)
   hsg.Face = face hsg.AlwaysOnTop = true hsg.CanvasSize = Vector2.new(240, 240) hsg.LightInfluence = 0
   for i = 1, 2 do
    local hr = Instance.new("Frame", hsg)
    hr.AnchorPoint = Vector2.new(0.5, 0.5) hr.Position = UDim2.fromScale(0.5, 0.5)
    local sc = i == 1 and 0.84 or 0.72
    hr.Size = UDim2.fromScale(sc, sc) hr.BackgroundTransparency = 1
    Instance.new("UICorner", hr).CornerRadius = UDim.new(1, 0)
    local hst = Instance.new("UIStroke", hr)
    hst.Thickness = i == 1 and 8 or 4
    hst.Color = i == 1 and Color3.fromRGB(240, 252, 255) or Color3.fromRGB(125, 220, 255)
    local hgr = Instance.new("UIGradient", hst)
    hgr.Color = ColorSequence.new(Color3.fromRGB(130, 225, 255), Color3.fromRGB(255, 255, 255))
    hgr.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.7, 0.1), NumberSequenceKeypoint.new(1, 0.65)})
   end
  end
  table.insert(auraObjs, hp)
 end)
end

local function getLobbyCFrame()
 local lobby = workspace:FindFirstChild("Lobby") or workspace:FindFirstChild("LobbyMap") or workspace:FindFirstChild("LobbyModel")
 if lobby then
  local sp = lobby:FindFirstChild("Spawns") or lobby:FindFirstChild("SpawnLocation") or lobby:FindFirstChild("Spawn")
  local p = (sp and (sp:IsA("BasePart") and sp or sp:FindFirstChildWhichIsA("BasePart"))) or (lobby:IsA("BasePart") and lobby or lobby:FindFirstChildWhichIsA("BasePart"))
  if p then return p.CFrame end
 end
 for _, o in ipairs(workspace:GetDescendants()) do
  if (o.Name == "Lobby" or o.Name == "LobbySpawn") and o:IsA("BasePart") then return o.CFrame end
 end
 return nil
end

local function getMapCFrame()
 local c = workspace:FindFirstChild("CoinContainer", true)
 if c and c.Parent then
  local p = c.Parent:FindFirstChildWhichIsA("BasePart", true)
  if p then return p.CFrame end
 end
 for _, o in ipairs(workspace:GetChildren()) do
  local n = o.Name:lower()
  if o:IsA("Model") and n ~= "lobby" and n ~= "camera" and not n:find("lobby") then
   local p = o:FindFirstChildWhichIsA("BasePart", true)
   if p then return p.CFrame end
  end
 end
 return nil
end

local function isInLobby(ch)
 local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
 if not hrp then return false end
 local lcf = getLobbyCFrame()
 return (lcf and (hrp.Position - lcf.Position).Magnitude < 120) or false
end

local predictedRoles = {}

local function parseRoleTable(tbl)
 if type(tbl) ~= "table" then return end
 local nextRoles = {}
 local foundAnyRole = false
 for k, v in pairs(tbl) do
  if type(v) == "table" and type(v.Role) == "string" then
   foundAnyRole = true
   local r = (v.Role == "Hero") and "Sheriff" or v.Role
   if v.Dead or v.Killed or r == "Innocent" then
    nextRoles[tostring(k)] = "Innocent"
   else
    nextRoles[tostring(k)] = r
   end
  elseif type(v) == "string" and (v == "Murderer" or v == "Sheriff" or v == "Hero" or v == "Innocent") then
   foundAnyRole = true
   local pName = typeof(k) == "Instance" and k.Name or tostring(k)
   nextRoles[pName] = (v == "Hero") and "Sheriff" or v
  end
 end
 if foundAnyRole then
  predictedRoles = nextRoles
 end
end

pcall(function()
 for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
  if obj:IsA("RemoteEvent") then
   local n = obj.Name:lower()
   if n:find("playerdata") or n:find("role") or n:find("round") or n:find("start") or n:find("update") or n:find("end") then
    obj.OnClientEvent:Connect(function(a, b)
     if n:find("end") or n:find("victory") or n:find("gameover") then
      table.clear(predictedRoles)
      return
     end
     if type(a) == "table" then parseRoleTable(a)
     elseif type(b) == "table" then parseRoleTable(b)
     elseif type(a) == "string" and (a == "Murderer" or a == "Sheriff" or a == "Hero" or a == "Innocent") then
      predictedRoles[LocalPlayer.Name] = (a == "Hero") and "Sheriff" or a
     end
    end)
   end
  end
 end
end)

local function hookRespawnReset(p)
 p.CharacterAdded:Connect(function()
  predictedRoles[p.Name] = nil
 end)
end
for _, p in ipairs(Players:GetPlayers()) do hookRespawnReset(p) end
Players.PlayerAdded:Connect(hookRespawnReset)

task.spawn(function()
 local getDataRemote = nil
 while true do
  task.wait(0.4)
  pcall(function()
   local allInLobby = true
   for _, p in ipairs(Players:GetPlayers()) do
    if p.Character and not isInLobby(p.Character) then
     allInLobby = false
     break
    end
   end
   if allInLobby and not workspace:FindFirstChild("CoinContainer", true) then
    table.clear(predictedRoles)
   end
   if not getDataRemote or not getDataRemote.Parent then
    getDataRemote = ReplicatedStorage:FindFirstChild("GetPlayerData", true)
   end
   if getDataRemote and getDataRemote:IsA("RemoteFunction") then
    local ok, data = pcall(function() return getDataRemote:InvokeServer() end)
    if ok and type(data) == "table" then
     parseRoleTable(data)
    end
   end
  end)
 end
end)

local function getRoleSafe(p)
 if not p or not p.Character then return "Innocent" end
 local ch, bp = p.Character, p:FindFirstChild("Backpack")
 local hum = ch:FindFirstChildOfClass("Humanoid")
 if not hum or hum.Health <= 0 or isInLobby(ch) then
  return "Innocent"
 end
 local function has(n) return (ch:FindFirstChild(n) or (bp and bp:FindFirstChild(n))) ~= nil end
 if has("Knife") then return "Murderer"
 elseif has("Gun") or has("Revolver") then return "Sheriff" end
 local atRole = p:GetAttribute("Role") or ch:GetAttribute("Role")
 if type(atRole) == "string" then
  if atRole == "Murderer" then return "Murderer"
  elseif atRole == "Sheriff" or atRole == "Hero" then return "Sheriff" end
 end
 local pred = predictedRoles[p.Name]
 if pred == "Murderer" or pred == "Sheriff" then
  return pred
 end
 return "Innocent"
end

local function getTargetPartByMode(ch, mode)
 if not ch then return nil end
 if mode == "Torso" then
  return ch:FindFirstChild("HumanoidRootPart") or ch:FindFirstChild("Torso") or ch:FindFirstChild("UpperTorso") or ch:FindFirstChild("Head")
 end
 return ch:FindFirstChild("Head") or ch:FindFirstChild("HumanoidRootPart")
end

local function getMurderer()
 if getRoleSafe(LocalPlayer) == "Murderer" then return nil end
 for _, p in ipairs(Players:GetPlayers()) do
  if p ~= LocalPlayer and p.Character and getRoleSafe(p) == "Murderer" then
   local hrp, hum = p.Character:FindFirstChild("HumanoidRootPart"), p.Character:FindFirstChildOfClass("Humanoid")
   if hrp and hum and hum.Health > 0 then return p.Character end
  end
 end
 return nil
end

local function getSheriff()
 for _, p in ipairs(Players:GetPlayers()) do
  if p ~= LocalPlayer and p.Character and getRoleSafe(p) == "Sheriff" then
   local hrp, hum = p.Character:FindFirstChild("HumanoidRootPart"), p.Character:FindFirstChildOfClass("Humanoid")
   if hrp and hum and hum.Health > 0 then return p.Character end
  end
 end
 return nil
end

local aimbotCircle = safeDrawing("Circle")
aimbotCircle.Visible = false
aimbotCircle.Thickness = 1.5
aimbotCircle.NumSides = 64
aimbotCircle.Radius = S.AimbotRadius
aimbotCircle.Filled = false
aimbotCircle.Color = Color3.fromRGB(255, 255, 255)
aimbotCircle.Transparency = 0.8

local function isVisible(tp)
 local ch = LocalPlayer.Character
 if not ch or not tp then return false end
 local orig = (Camera and Camera.CFrame.Position) or (ch:FindFirstChild("Head") and ch.Head.Position)
 if not orig then return false end
 local flt = {ch, tp.Parent}
 local rp = RaycastParams.new()
 rp.FilterType = Enum.RaycastFilterType.Exclude
 rp.IgnoreWater = true
 for _ = 1, 10 do
  rp.FilterDescendantsInstances = flt
  local res = workspace:Raycast(orig, tp.Position - orig, rp)
  if not res or res.Instance:IsDescendantOf(tp.Parent) then return true end
  if res.Instance.Transparency >= 0.9 or not res.Instance.CanCollide then table.insert(flt, res.Instance) else return false end
 end
 return true
end

local function applyShaders()
 pcall(function()
  local cc = Lighting:FindFirstChild("ProHub_CC")
  local bl = Lighting:FindFirstChild("ProHub_Bloom")
  if S.EnableShaders then
   if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) cc.Name = "ProHub_CC" end
   cc.Saturation = 0.28 cc.Contrast = 0.22
   if not bl then bl = Instance.new("BloomEffect", Lighting) bl.Name = "ProHub_Bloom" end
   bl.Intensity = 1.15 bl.Size = 28 bl.Threshold = 1.65
  else
   if cc then cc:Destroy() end if bl then bl:Destroy() end
  end
 end)
end

local function SafeTeleport(cf)
 local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if hrp then hrp.AssemblyLinearVelocity = Vector3.zero hrp.CFrame = cf + Vector3.new(0, 3, 0) end
end

UserInputService.InputBegan:Connect(function(i, gp)
 if not gp and S.ClickTP and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch) and Mouse and Mouse.Hit then
  SafeTeleport(CFrame.new(Mouse.Hit.Position))
 end
end)

local isKillingAll, isFlingingTarget = false, false

local function runFlingOnTargets(list)
 if isFlingingTarget or #list == 0 then return end
 local ch = LocalPlayer.Character
 local hrp, hum = ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
 if not hrp or not hum or hum.Health <= 0 then return end
 isFlingingTarget = true
 task.spawn(function()
  local origCF = hrp.CFrame
  local oldFH = workspace.FallenPartsDestroyHeight
  pcall(function()
   workspace.FallenPartsDestroyHeight = 0/0
   hum:SetStateEnabled(Enum.HumanoidStateType.Seated, false)
  end)

  for _, tp in ipairs(list) do
   ch = LocalPlayer.Character
   hrp = ch and ch:FindFirstChild("HumanoidRootPart")
   hum = ch and ch:FindFirstChildOfClass("Humanoid")
   if not ch or not hrp or not hum or hum.Health <= 0 then break end
   local tCh = tp and tp.Character
   local tHrp, tHum = tCh and tCh:FindFirstChild("HumanoidRootPart"), tCh and tCh:FindFirstChildOfClass("Humanoid")
   if tp and tp ~= LocalPlayer and tCh and tHrp and (not tHum or tHum.Health > 0) and tHrp.Position.Y > -45 then
    local startPos = tHrp.Position
    local t0, ang = tick(), 0
    while (tick() - t0) < 1.5 and hrp.Parent and tHrp.Parent do
     if hum.Health <= 0 or (tHum and tHum.Health <= 0) then break end
     if tHrp.AssemblyLinearVelocity.Magnitude > 320 or tHrp.Position.Y < -45 or (tHrp.Position - startPos).Magnitude > 180 then
      break
     end
     for _, pt in ipairs(ch:GetDescendants()) do if pt:IsA("BasePart") then pt.CanCollide = false end end
     ang = (ang + 65) % 360
     local tVel = tHrp.AssemblyLinearVelocity
     local off = (tVel.Magnitude > 1 and tVel.Magnitude < 50) and (tVel.Unit * math.min(tVel.Magnitude * 0.1, 3)) or Vector3.zero
     local fCF = CFrame.new(tHrp.Position + off) * CFrame.Angles(math.rad(ang), math.rad(ang * 1.4), 0)
     hrp.CFrame = fCF
     hrp.Velocity = Vector3.new(9e7, 9e7, 9e7)
     hrp.AssemblyLinearVelocity = Vector3.new(9e7, 9e7, 9e7)
     hrp.RotVelocity = Vector3.new(9e7, 9e7, 9e7)
     hrp.AssemblyAngularVelocity = Vector3.new(9e7, 9e7, 9e7)
     RunService.RenderStepped:Wait()
     if hrp and hrp.Parent then
      hrp.CFrame = origCF
      hrp.Velocity = Vector3.zero
      hrp.AssemblyLinearVelocity = Vector3.zero
      hrp.RotVelocity = Vector3.zero
      hrp.AssemblyAngularVelocity = Vector3.zero
     end
     RunService.Heartbeat:Wait()
    end
   end
  end

  pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Seated, true) end)
  if hrp and hrp.Parent then
   pcall(function() hrp.Anchored = true end)
   for _ = 1, 15 do
    if not hrp or not hrp.Parent then break end
    hrp.CFrame = origCF
    for _, pt in ipairs(ch:GetDescendants()) do
     if pt:IsA("BasePart") then
      pt.Velocity = Vector3.zero
      pt.AssemblyLinearVelocity = Vector3.zero
      pt.RotVelocity = Vector3.zero
      pt.AssemblyAngularVelocity = Vector3.zero
     end
    end
    RunService.Heartbeat:Wait()
    pcall(function() hrp.Anchored = false end)
   end
   pcall(function()
    hrp.Anchored = false
    hum:ChangeState(Enum.HumanoidStateType.GettingUp)
   end)
  end
  pcall(function() workspace.FallenPartsDestroyHeight = oldFH end)
  isFlingingTarget = false
 end)
end

local function executeInstantKillAll()
 if isKillingAll then return end
 local ch = LocalPlayer.Character
 local hum, bp, hrp = ch and ch:FindFirstChildOfClass("Humanoid"), LocalPlayer:FindFirstChild("Backpack"), ch and ch:FindFirstChild("HumanoidRootPart")
 local knife = ch and (ch:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")))
 if not knife or not hrp or not hum then return end
 local stab = knife:FindFirstChild("Stab") or knife:FindFirstChildWhichIsA("RemoteEvent", true)
 local function sendKill(tHrp)
  pcall(function() knife:Activate() end)
  if stab then pcall(function() stab:FireServer("Down") stab:FireServer("Slash") end) end
  local h = knife:FindFirstChild("Handle") or knife:FindFirstChildWhichIsA("BasePart")
  if tHrp and h then
   pcall(function()
    tHrp.CanCollide = false
    if S.KillAllMode ~= 3 then tHrp.CFrame = h.CFrame end
    if type(firetouchinterest) == "function" then firetouchinterest(tHrp, h, 0) firetouchinterest(tHrp, h, 1) end
   end)
  end
 end
 if S.KillAllMode == 3 then
  isKillingAll = true
  task.spawn(function()
   pcall(function()
    local skip = {}
    while isKillingAll do
     ch = LocalPlayer.Character hrp = ch and ch:FindFirstChild("HumanoidRootPart") hum = ch and ch:FindFirstChildOfClass("Humanoid")
     bp = LocalPlayer:FindFirstChild("Backpack") knife = ch and (ch:FindFirstChild("Knife") or (bp and bp:FindFirstChild("Knife")))
     if not hrp or not hum or hum.Health <= 0 or not knife then break end
     if knife.Parent == ch and bp then pcall(function() hum:UnequipTools() knife.Parent = bp end) end
     local near, sDist = nil, math.huge
     for _, p in ipairs(Players:GetPlayers()) do
      if p ~= LocalPlayer and not skip[p] and p.Character then
       local tHum, tHrp = p.Character:FindFirstChildOfClass("Humanoid"), p.Character:FindFirstChild("HumanoidRootPart")
       if tHum and tHum.Health > 0 and tHrp and not isInLobby(p.Character) then
        local d = (hrp.Position - tHrp.Position).Magnitude
        if d < sDist then sDist = d near = p end
       end
      end
     end
     if not near then break end
     local tCh = near.Character
     local tHum, tHrp = tCh:FindFirstChildOfClass("Humanoid"), tCh:FindFirstChild("HumanoidRootPart")
     local f0 = tick()
     while tCh.Parent and tHum.Health > 0 and tHrp.Parent and not isInLobby(tCh) do
      if not hrp.Parent or hum.Health <= 0 then break end
      local d = (hrp.Position - tHrp.Position).Magnitude
      if d <= 3.5 or (tick() - f0) > 8 then break end
      local dt = RunService.Heartbeat:Wait()
      hrp.AssemblyLinearVelocity = Vector3.zero
      local step = math.min(d, math.max(tonumber(S.FlySpeed) or 50, 10) * dt)
      local np = hrp.Position + (tHrp.Position - hrp.Position).Unit * step
      hrp.CFrame = CFrame.lookAt(np, Vector3.new(tHrp.Position.X, np.Y, tHrp.Position.Z))
     end
     if tHum.Health > 0 and tHrp.Parent and not isInLobby(tCh) then
      if knife.Parent ~= ch then pcall(function() hum:EquipTool(knife) knife.Parent = ch end) task.wait(0.05) end
      local k0 = tick()
      while tHum.Health > 0 and tHrp.Parent and (tick() - k0) < 0.55 do
       hrp.AssemblyLinearVelocity = Vector3.zero
       hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 1.2)
       sendKill(tHrp)
       RunService.Heartbeat:Wait()
      end
      if tHum.Health > 0 then skip[near] = true end
      if bp and knife.Parent == ch then pcall(function() hum:UnequipTools() knife.Parent = bp end) end
      task.wait(0.05)
     else skip[near] = true end
    end
   end)
   isKillingAll = false
  end)
  return
 end
 if knife.Parent == bp then hum:EquipTool(knife) task.wait(0.05) end
 local orig = hrp.CFrame
 for _, p in ipairs(Players:GetPlayers()) do
  if p ~= LocalPlayer and p.Character then
   local tHum, tHrp = p.Character:FindFirstChildOfClass("Humanoid"), p.Character:FindFirstChild("HumanoidRootPart")
   if tHum and tHum.Health > 0 and tHrp and not isInLobby(p.Character) then
    if S.KillAllMode == 1 then
     hrp.CFrame = tHrp.CFrame * CFrame.new(0, 0, 1.5)
     RunService.Heartbeat:Wait() sendKill(tHrp) task.wait(0.06)
    else task.spawn(function() sendKill(tHrp) end) end
   end
  end
 end
 if S.KillAllMode == 1 and hrp.Parent then hrp.CFrame = orig end
end

LocalPlayer.Idled:Connect(function()
 if S.AntiAfk then pcall(function() VirtualUser:CaptureController() VirtualUser:ClickButton2(Vector2.zero) end) end
end)

local activeTrail, spinAngle, wasSpinning = nil, 0, false
local tracerLines = {}
Players.PlayerRemoving:Connect(function(p)
 predictedRoles[p.Name] = nil
 if tracerLines[p] then pcall(function() tracerLines[p]:Remove() end) tracerLines[p] = nil end
end)

RunService.RenderStepped:Connect(function()
 Camera = workspace.CurrentCamera
 if not Camera then return end
 if S.EnableNight then Lighting.ClockTime = 0 Lighting.Brightness = 0.3 end
 Camera.FieldOfView = S.FovSize

 if S.ThirdPerson then
  pcall(function()
   LocalPlayer.CameraMode = Enum.CameraMode.Classic
   LocalPlayer.CameraMaxZoomDistance = 400
   LocalPlayer.CameraMinZoomDistance = 0.5
  end)
 end

 local ch = LocalPlayer.Character
 if ch and ch:FindFirstChild("HumanoidRootPart") and ch:FindFirstChild("Head") then
  local hrp, hum = ch.HumanoidRootPart, ch:FindFirstChildOfClass("Humanoid")
  if S.SpinBot and not S.AutoFarm and not S.Fly and not isKillingAll and not isFlingingTarget then
   wasSpinning = true
   if hum then hum.AutoRotate = false end
   pcall(function() UserSettings():GetService("UserGameSettings").RotationType = Enum.RotationType.MovementRelative end)
   spinAngle = (spinAngle + S.SpinSpeed) % 360
   hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
  elseif wasSpinning then
   wasSpinning = false
   if hum then hum.AutoRotate = true end
  end
  if S.Trail then
   if not activeTrail then
    activeTrail = Instance.new("Trail", hrp)
    activeTrail.Attachment0 = Instance.new("Attachment", ch.Head)
    activeTrail.Attachment1 = Instance.new("Attachment", hrp)
   end
   activeTrail.Color = ColorSequence.new(COLORS[getRoleSafe(LocalPlayer)] or COLORS.Innocent)
   activeTrail.Lifetime = S.TrailLifetime
  elseif activeTrail then
   activeTrail.Attachment0:Destroy() activeTrail.Attachment1:Destroy() activeTrail:Destroy() activeTrail = nil
  end
  if S.Aura then
   ensureAura(ch)
   local pl = hrp:FindFirstChild("ProHub_AuraLight")
   if pl then pl.Enabled = not S.JumpCircle end
   for _, partName in ipairs({"ProHub_AuraFloor", "ProHub_AuraHalo"}) do
    local ap = ch:FindFirstChild(partName)
    if ap then
     for i, d in ipairs(ap:GetDescendants()) do
      if d:IsA("UIGradient") then
       d.Rotation = (tick() * (150 + i * 40)) % 360
      elseif d.Name == "AuraGlow" then
       d.Visible = not S.JumpCircle
      end
     end
    end
   end
  elseif #auraObjs > 0 then
   clearAura()
  end
 end

 if S.ESP_Tracers then
  local sb = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
  for _, p in ipairs(Players:GetPlayers()) do
   if p ~= LocalPlayer and p.Character then
    local tHrp, tHum = p.Character:FindFirstChild("HumanoidRootPart"), p.Character:FindFirstChildOfClass("Humanoid")
    if tHrp and tHum and tHum.Health > 0 then
     local pos, onS = Camera:WorldToViewportPoint(tHrp.Position)
     if onS and pos.Z > 0.1 then
      local ln = tracerLines[p] or safeDrawing("Line")
      tracerLines[p] = ln
      ln.Thickness = 1.5 ln.Transparency = 1
      ln.Color = COLORS[getRoleSafe(p)] or COLORS.Innocent
      ln.From = sb ln.To = Vector2.new(pos.X, pos.Y) ln.Visible = true
     elseif tracerLines[p] then tracerLines[p].Visible = false end
    elseif tracerLines[p] then tracerLines[p].Visible = false end
   elseif tracerLines[p] then tracerLines[p].Visible = false end
  end
 else
  for _, ln in pairs(tracerLines) do ln.Visible = false end
 end

 if S.EnableCamlock then
  local mCh = getMurderer()
  local targetPart = getTargetPartByMode(mCh, S.CamlockMode)
  if targetPart then
   Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPart.Position), math.clamp(1 / S.CamlockSmoothness, 0.05, 1))
  end
 end

 local sc = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
 aimbotCircle.Color = S.RainbowAimbotCircle and Color3.fromHSV((tick()*0.4)%1, 1, 1) or Color3.fromRGB(255,255,255)
 if S.EnableAimbot and S.ShowFovAimbot then
  aimbotCircle.Visible = true aimbotCircle.Radius = S.AimbotRadius aimbotCircle.Position = sc
 else aimbotCircle.Visible = false end

 if S.EnableAimbot then
  local best, sDist = nil, S.AimbotRadius
  for _, p in ipairs(Players:GetPlayers()) do
   if p ~= LocalPlayer and p.Character then
    local hum = p.Character:FindFirstChildOfClass("Humanoid")
    local tp = getTargetPartByMode(p.Character, S.AimbotMode)
    if hum and hum.Health > 0 and tp then
     local sp, onS = Camera:WorldToViewportPoint(tp.Position)
     if onS and sp.Z > 0.1 then
      local d = (Vector2.new(sp.X, sp.Y) - sc).Magnitude
      if d <= S.AimbotRadius and d < sDist and isVisible(tp) then sDist = d best = tp end
     end
    end
   end
  end
  if best then
   Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, best.Position), math.clamp(1 / S.AimbotSmoothness, 0.05, 1))
  end
 end
end)

RunService.Heartbeat:Connect(function()
 local ch = LocalPlayer.Character
 local hrp, hum = ch and ch:FindFirstChild("HumanoidRootPart"), ch and ch:FindFirstChildOfClass("Humanoid")
 if not hrp or not hum then return end
 if S.SpinBot and not S.AutoFarm and not S.Fly and not isKillingAll and not isFlingingTarget and hum.Health > 0 then
  hum.AutoRotate = false
  hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, math.rad(spinAngle), 0)
 end
 if not isFlingingTarget then
  for _, p in ipairs(Players:GetPlayers()) do
   if p ~= LocalPlayer and p.Character then
    for _, pt in ipairs(p.Character:GetDescendants()) do
     if pt:IsA("BasePart") and pt.Name ~= "HumanoidRootPart" then pt.CanCollide = not S.AntiFling end
    end
   end
  end
 end
 if S.TouchFling and not isFlingingTarget then
  pcall(function()
   local vel = hrp.Velocity
   hrp.Velocity = vel * S.TouchFlingPower + Vector3.new(0, S.TouchFlingPower, 0)
   RunService.RenderStepped:Wait()
   if hrp and hrp.Parent then hrp.Velocity = vel end
  end)
 end
end)

local ignoredCoins = setmetatable({}, {__mode = "k"})
local coinCache = {}
local wasAutoFarming, collectedCoinsCount = false, 0
LocalPlayer.CharacterAdded:Connect(function() collectedCoinsCount = 0 end)

local function isValidCoin(part)
 return part and part.Parent and (not ignoredCoins[part] or (tick() - ignoredCoins[part] >= 3)) and part.Transparency < 0.9
end

local function refreshCoinCache()
 local newCache = {}
 local container = workspace:FindFirstChild("CoinContainer", true)
 if not container then collectedCoinsCount = 0 end
 for _, obj in ipairs((container or workspace):GetDescendants()) do
  if obj:IsA("BasePart") then
   local name = obj.Name:lower()
   if (name == "coin_server" or name == "coin" or name == "candy" or name:find("coin") or name:find("candy") or name:find("geschenk")) and isValidCoin(obj) then
    table.insert(newCache, obj)
   end
  end
 end
 coinCache = newCache
end

task.spawn(function()
 while true do
  if S.AutoFarm then refreshCoinCache() task.wait(0.2)
  else table.clear(coinCache) task.wait(0.5) end
 end
end)

local function getNearestCandy()
 local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not hrp then return nil end
 if #coinCache == 0 then refreshCoinCache() end
 local nearest, shortestDist = nil, math.huge
 for i = 1, #coinCache do
  local part = coinCache[i]
  if isValidCoin(part) then
   local dist = (hrp.Position - part.Position).Magnitude
   if dist < shortestDist then shortestDist = dist nearest = part end
  end
 end
 return nearest
end

local walkTargetCoin, walkWaypoints, walkWpIdx, lastPathTime = nil, nil, 1, 0

local function hasWallBetween(p1, p2, ch)
 local rp = RaycastParams.new()
 rp.FilterType = Enum.RaycastFilterType.Exclude
 local container = workspace:FindFirstChild("CoinContainer", true)
 rp.FilterDescendantsInstances = container and {ch, container} or {ch}
 rp.IgnoreWater = true
 local dir = p2 - p1
 local res = workspace:Raycast(p1, Vector3.new(dir.X, 0, dir.Z), rp)
 return res ~= nil and res.Instance.CanCollide and res.Instance.Transparency < 0.9
end

RunService.RenderStepped:Connect(function(dt)
 local char = LocalPlayer.Character
 local hrp, hum = char and char:FindFirstChild("HumanoidRootPart"), char and char:FindFirstChildOfClass("Humanoid")
 if not S.AutoFarm or isFlingingTarget then
  if wasAutoFarming then wasAutoFarming = false walkWaypoints = nil if hum then hum.PlatformStand = false end end
  return
 end
 if not hrp or not hum or hum.Health <= 0 then return end
 wasAutoFarming = true
 local candy = getNearestCandy()
 if not candy then
  if S.AutoFarmMode == 2 then hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero end
  return
 end
 local currentPos, targetPos = hrp.Position, candy.Position
 local dist = (currentPos - targetPos).Magnitude
 local farmAngles = (S.FarmPosition == 1) and CFrame.Angles(0, 0, 0) or CFrame.Angles(math.rad(90), 0, 0)

 if S.AutoFarmMode == 1 then
  hum.PlatformStand = false
  hum.WalkSpeed = S.WalkFarmSpeed
  if dist < 2.8 then
   if type(firetouchinterest) == "function" then pcall(function() firetouchinterest(hrp, candy, 0) firetouchinterest(hrp, candy, 1) end) end
   if not ignoredCoins[candy] then collectedCoinsCount = collectedCoinsCount + 1 end
   ignoredCoins[candy] = tick()
   walkWaypoints = nil walkTargetCoin = nil
   return
  end
  local blocked = hasWallBetween(currentPos, targetPos, char)
  if not blocked and math.abs(targetPos.Y - currentPos.Y) < 5 then
   walkWaypoints = nil
   hum:MoveTo(targetPos)
  else
   if walkTargetCoin ~= candy or not walkWaypoints or (tick() - lastPathTime) > 0.6 then
    walkTargetCoin = candy
    lastPathTime = tick()
    task.spawn(function()
     local path = PathfindingService:CreatePath({AgentRadius = 1.8, AgentHeight = 4.5, AgentCanJump = true, WaypointSpacing = 4})
     local ok = pcall(function() path:ComputeAsync(currentPos, targetPos) end)
     if ok and path.Status == Enum.PathStatus.Success then
      walkWaypoints = path:GetWaypoints()
      walkWpIdx = 2
     else
      walkWaypoints = nil
     end
    end)
   end
   if walkWaypoints and walkWaypoints[walkWpIdx] then
    local wp = walkWaypoints[walkWpIdx]
    if wp.Action == Enum.PathWaypointAction.Jump then hum.Jump = true end
    hum:MoveTo(wp.Position)
    if Vector2.new(currentPos.X - wp.Position.X, currentPos.Z - wp.Position.Z).Magnitude < 3.2 then
     walkWpIdx = walkWpIdx + 1
    end
   else
    hum:MoveTo(targetPos)
   end
  end
  if targetPos.Y - currentPos.Y > 2.5 and dist < 8 then hum.Jump = true end
 else
  hum.PlatformStand = true hrp.AssemblyLinearVelocity = Vector3.zero hrp.AssemblyAngularVelocity = Vector3.zero
  local step = S.FlyFarmSpeed * dt
  if dist <= math.max(step, 2.2) then
   hrp.CFrame = CFrame.new(targetPos) * farmAngles
   if type(firetouchinterest) == "function" then pcall(function() firetouchinterest(hrp, candy, 0) firetouchinterest(hrp, candy, 1) end) end
   if not ignoredCoins[candy] then collectedCoinsCount = collectedCoinsCount + 1 end
   ignoredCoins[candy] = tick()
  else
   hrp.CFrame = CFrame.new(currentPos + (targetPos - currentPos).Unit * step) * farmAngles
  end
 end
end)

local isPickingUpGun = false
task.spawn(function()
 while true do
  task.wait(0.3)
  if S.AutoGun and getRoleSafe(LocalPlayer) ~= "Murderer" and not isPickingUpGun and not isFlingingTarget then
   local ch = LocalPlayer.Character
   local hum, hrp = ch and ch:FindFirstChildOfClass("Humanoid"), ch and ch:FindFirstChild("HumanoidRootPart")
   if hrp and hum and hum.Health > 0 and not isInLobby(ch) then
    for _, obj in ipairs(workspace:GetDescendants()) do
     if obj.Name:lower():find("gundrop") then
      local gp = obj:IsA("BasePart") and obj or (obj:IsA("Model") and (obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart")))
      if gp and gp.Parent and gp.Position.Y > -10 then
       isPickingUpGun = true
       local orig = hrp.CFrame
       hrp.CFrame = gp.CFrame + Vector3.new(0, 2, 0)
       task.wait(0.3)
       if hrp and hrp.Parent and hum.Health > 0 then hrp.CFrame = orig end
       task.wait(1)
       isPickingUpGun = false
       break
      end
     end
    end
   end
  end
 end
end)

task.spawn(function()
 while true do
  task.wait(0.4)
  pcall(function()
   for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
     local character = player.Character
     local hum, head = character:FindFirstChildOfClass("Humanoid"), character:FindFirstChild("Head")
     if hum and hum.Health > 0 and head then
      local role = getRoleSafe(player)
      local color = COLORS[role] or COLORS.Innocent
      local existingTag = head:FindFirstChild("SakuraUserTag")
      if S.UserTag and activeUsers[player.UserId] then
       if not existingTag then
        local bb = Instance.new("BillboardGui", head)
        bb.Name = "SakuraUserTag" bb.Size = UDim2.new(0, 200, 0, 50) bb.StudsOffset = Vector3.new(0, 2.5, 0) bb.AlwaysOnTop = true
        local txt = Instance.new("TextLabel", bb)
        txt.Name = "TagText" txt.Size = UDim2.new(1, 0, 1, 0) txt.BackgroundTransparency = 1 txt.Font = Enum.Font.GothamBold txt.Text = "User" txt.TextSize = 16 txt.TextStrokeTransparency = 0.2 txt.TextStrokeColor3 = Color3.fromRGB(20, 20, 20)
        existingTag = bb
       end
       if existingTag and existingTag:FindFirstChild("TagText") then existingTag.TagText.TextColor3 = color end
      elseif existingTag then existingTag:Destroy() end

      local highlight = character:FindFirstChild("MM2_ChamsHighlight")
      if S.ESP_Roles then
       if not highlight then highlight = Instance.new("Highlight", character) highlight.Name = "MM2_ChamsHighlight" end
       highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
       highlight.FillTransparency = 0.35
       highlight.OutlineTransparency = 0.1
       highlight.FillColor = color
       highlight.OutlineColor = color
       for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") then
         local tn = tool.Name:lower()
         if (role == "Murderer" and tn:find("knife")) or (role == "Sheriff" and (tn:find("gun") or tn:find("revolver"))) then
          local th = tool:FindFirstChild("Tool_Chams") or Instance.new("Highlight", tool)
          th.Name = "Tool_Chams" th.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop th.FillColor = color th.OutlineColor = color th.FillTransparency = 0.35
         end
        end
       end
      else
       if highlight then highlight:Destroy() end
       for _, tool in ipairs(character:GetChildren()) do
        if tool:IsA("Tool") and tool:FindFirstChild("Tool_Chams") then tool.Tool_Chams:Destroy() end
       end
      end
     else
      local highlight = character:FindFirstChild("MM2_ChamsHighlight")
      if highlight then highlight:Destroy() end
     end
    end
   end
   if S.ESP_Candyes then
    for _, obj in ipairs(workspace:GetDescendants()) do
     local n = obj.Name:lower()
     if (n == "candy" or n == "coin" or n:find("candy") or n:find("coin") or n:find("geschenk")) and not obj:FindFirstChild("Candy_ESP") and (obj:IsA("BasePart") or obj:IsA("Model")) then
      local hl = Instance.new("Highlight", obj)
      hl.Name = "Candy_ESP" hl.FillColor = COLORS.Candy hl.OutlineColor = COLORS.Candy hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
     end
    end
   else
    for _, obj in ipairs(workspace:GetDescendants()) do
     local hl = obj:FindFirstChild("Candy_ESP")
     if hl then hl:Destroy() end
    end
   end
  end)
 end
end)

local flyBV, flyBG
RunService.Stepped:Connect(function()
 local ch = LocalPlayer.Character
 if ch and (S.EnableNoclip or (S.AutoFarm and S.AutoFarmMode == 2) or isKillingAll) and not isFlingingTarget then
  for _, pt in ipairs(ch:GetDescendants()) do
   if pt:IsA("BasePart") and pt.CanCollide then pt.CanCollide = false end
  end
 end
end)

RunService.RenderStepped:Connect(function()
 local ch = LocalPlayer.Character
 if S.Fly and not S.AutoFarm and not isKillingAll and not isFlingingTarget and ch and ch:FindFirstChild("HumanoidRootPart") then
  local hrp, hum = ch.HumanoidRootPart, ch:FindFirstChildOfClass("Humanoid")
  if hum then hum.PlatformStand = true end
  if not flyBV or flyBV.Parent ~= hrp then
   if flyBV then flyBV:Destroy() end
   flyBV = Instance.new("BodyVelocity", hrp) flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
  end
  if not flyBG or flyBG.Parent ~= hrp then
   if flyBG then flyBG:Destroy() end
   flyBG = Instance.new("BodyGyro", hrp) flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9) flyBG.P = 9e4
  end
  flyBG.CFrame = Camera.CFrame
  local md = hum and hum.MoveDirection or Vector3.zero
  local cf = Camera.CFrame
  local fd = md.Magnitude > 0 and ((cf.LookVector * md:Dot(cf.LookVector)) + (cf.RightVector * md:Dot(cf.RightVector)) + (cf.UpVector * md.Y)) or Vector3.zero
  local up = (UserInputService:IsKeyDown(Enum.KeyCode.Space) or UserInputService:IsKeyDown(Enum.KeyCode.E)) and S.FlySpeed or ((UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.Q)) and -S.FlySpeed or 0)
  flyBV.Velocity = fd.Magnitude > 0 and (fd.Unit * S.FlySpeed + Vector3.new(0, up, 0)) or Vector3.new(0, up, 0)
 else
  if flyBV then flyBV:Destroy() flyBV = nil end
  if flyBG then flyBG:Destroy() flyBG = nil end
  if ch and not S.AutoFarm and not isKillingAll and not isFlingingTarget and ch:FindFirstChildOfClass("Humanoid") then ch:FindFirstChildOfClass("Humanoid").PlatformStand = false end
 end
end)

local lastJumpCircle, wasInAir = 0, false
UserInputService.JumpRequest:Connect(function()
 local ch = LocalPlayer.Character
 local hum = ch and ch:FindFirstChildOfClass("Humanoid")
 if hum and hum.Health > 0 and S.EnableAirJump then
  hum:ChangeState("Jumping")
 end
end)

RunService.RenderStepped:Connect(function()
 local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
 if hum then
  hum.UseJumpPower = true hum.JumpPower = S.JumpPower
  local st = hum:GetState()
  local inAir = (st == Enum.HumanoidStateType.Jumping or st == Enum.HumanoidStateType.Freefall or hum.FloorMaterial == Enum.Material.Air)
  if wasInAir and not inAir and S.JumpCircle and (tick() - lastJumpCircle) > 0.15 then
   lastJumpCircle = tick()
   spawnJumpCircle()
  end
  wasInAir = inAir
  if not S.Fly and not isKillingAll and not isFlingingTarget then
   if S.AutoFarm and S.AutoFarmMode == 1 then hum.WalkSpeed = S.WalkFarmSpeed
   elseif S.SpeedGlitch and inAir and hum.MoveDirection.Magnitude > 0 then hum.WalkSpeed = 55
   else hum.WalkSpeed = S.WalkSpeed end
  end
 end
end)

Tabs.Teleports:Toggle({Title="Enable Click Tp",Value=S.ClickTP,Callback=function(v) S.ClickTP=v end})
Tabs.Teleports:Button({Title="Teleport In Lobby",Callback=function() local c=getLobbyCFrame() if c then SafeTeleport(c) end end})
Tabs.Teleports:Button({Title="Teleport In Map",Callback=function() local c=getMapCFrame() if c then SafeTeleport(c) end end})
Tabs.Teleports:Button({Title="Teleport To Murder",Callback=function() local m=getMurderer() if m then SafeTeleport(m.HumanoidRootPart.CFrame) end end})
Tabs.Teleports:Button({Title="Teleport To Sheriff",Callback=function() local s=getSheriff() if s then SafeTeleport(s.HumanoidRootPart.CFrame) end end})
Tabs.Teleports:Button({Title="Teleport To Candy",Callback=function() local c=getNearestCandy() if c then SafeTeleport(c.CFrame) end end})

Tabs.Movement:Toggle({Title="Enable Fly",Value=S.Fly,Callback=function(v) S.Fly=v end})
Tabs.Movement:Slider({Title="FlySpeed",Step=1,Value={Min=10,Max=500,Default=S.FlySpeed},Callback=function(v) S.FlySpeed=tonumber(v) or v end})
Tabs.Movement:Toggle({Title="Enable Air Jump",Value=S.EnableAirJump,Callback=function(v) S.EnableAirJump=v end})
Tabs.Movement:Toggle({Title="Enable Noclip",Value=S.EnableNoclip,Callback=function(v) S.EnableNoclip=v end})
Tabs.Movement:Toggle({Title="Enable Speed Glitch",Value=S.SpeedGlitch,Callback=function(v) S.SpeedGlitch=v end})
Tabs.Movement:Slider({Title="WalkSpeed",Step=1,Value={Min=16,Max=200,Default=S.WalkSpeed},Callback=function(v) S.WalkSpeed=tonumber(v) or v end})
Tabs.Movement:Slider({Title="JumpPower",Step=1,Value={Min=50,Max=300,Default=S.JumpPower},Callback=function(v) S.JumpPower=tonumber(v) or v end})

Tabs.Combat:Button({Title="Kill All",Callback=function() executeInstantKillAll() end})
Tabs.Combat:Dropdown({Title="Kill All Mode",Values={"Teleport","Distance","Flying"},Value="Teleport",Callback=function(v) S.KillAllMode=(v=="Teleport" and 1) or (v=="Distance" and 2) or 3 end})
Tabs.Combat:Toggle({Title="Enable Camlock",Value=S.EnableCamlock,Callback=function(v) S.EnableCamlock=v end})
Tabs.Combat:Dropdown({Title="Camlock Mode",Values={"Head","Torso"},Value="Head",Callback=function(v) if type(v)=="table" then v=v[1] end S.CamlockMode=tostring(v) end})
Tabs.Combat:Slider({Title="Camlock Smoothness",Step=1,Value={Min=1,Max=20,Default=S.CamlockSmoothness},Callback=function(v) S.CamlockSmoothness=tonumber(v) or v end})
Tabs.Combat:Toggle({Title="Enable Aimbot",Value=S.EnableAimbot,Callback=function(v) S.EnableAimbot=v end})
Tabs.Combat:Dropdown({Title="Aimbot Mode",Values={"Head","Torso"},Value="Head",Callback=function(v) if type(v)=="table" then v=v[1] end S.AimbotMode=tostring(v) end})
Tabs.Combat:Toggle({Title="Show Fov Aimbot",Value=S.ShowFovAimbot,Callback=function(v) S.ShowFovAimbot=v end})
Tabs.Combat:Toggle({Title="Rainbow Aimbot Circle",Value=S.RainbowAimbotCircle,Callback=function(v) S.RainbowAimbotCircle=v end})
Tabs.Combat:Slider({Title="Aimbot Circle Radius",Step=5,Value={Min=30,Max=400,Default=S.AimbotRadius},Callback=function(v) S.AimbotRadius=tonumber(v) or v aimbotCircle.Radius=S.AimbotRadius end})
Tabs.Combat:Slider({Title="Aimbot Smoothness",Step=1,Value={Min=1,Max=20,Default=S.AimbotSmoothness},Callback=function(v) S.AimbotSmoothness=tonumber(v) or v end})

Tabs.Visuals:Toggle({Title="Enable Esp",Value=S.ESP_Roles,Callback=function(v) S.ESP_Roles=v end})
Tabs.Visuals:Toggle({Title="Enable Esp Tracers",Value=S.ESP_Tracers,Callback=function(v) S.ESP_Tracers=v end})
Tabs.Visuals:Toggle({Title="Enable Esp Candyes",Value=S.ESP_Candyes,Callback=function(v) S.ESP_Candyes=v end})
Tabs.Visuals:Toggle({Title="Enable Jump Circle",Value=S.JumpCircle,Callback=function(v) S.JumpCircle=v end})
Tabs.Visuals:Toggle({Title="Enable Aura",Value=S.Aura,Callback=function(v) S.Aura=v if not v then clearAura() end end})
Tabs.Visuals:Toggle({Title="Enable Trail",Value=S.Trail,Callback=function(v) S.Trail=v end})
Tabs.Visuals:Toggle({Title="Enable Night",Value=S.EnableNight,Callback=function(v) S.EnableNight=v if not v then Lighting.ClockTime=12 Lighting.Brightness=2 end end})
Tabs.Visuals:Toggle({Title="Enable 3 Face",Value=S.ThirdPerson,Callback=function(v) S.ThirdPerson=v if not v then pcall(function() LocalPlayer.CameraMaxZoomDistance=128 end) end end})
Tabs.Visuals:Slider({Title="Fov Size",Step=1,Value={Min=40,Max=120,Default=S.FovSize},Callback=function(v) S.FovSize=tonumber(v) or v end})
Tabs.Visuals:Toggle({Title="Enable User Tag",Value=S.UserTag,Callback=function(v) S.UserTag=v end})

Tabs.AutoFarm:Toggle({Title="Enable AutoFarm",Value=S.AutoFarm,Callback=function(v) S.AutoFarm=v end})
Tabs.AutoFarm:Dropdown({Title="AutoFarmMode",Values={"Walking","Flying"},Value="Flying",Callback=function(v) S.AutoFarmMode=(v=="Walking") and 1 or 2 end})
Tabs.AutoFarm:Dropdown({Title="Character Positions While Farming",Values={"Standing","On The Back"},Value="On The Back",Callback=function(v) S.FarmPosition=(v=="Standing") and 1 or 2 end})
Tabs.AutoFarm:Slider({Title="WalkFarmSpeed",Step=1,Value={Min=16,Max=26,Default=S.WalkFarmSpeed},Callback=function(v) S.WalkFarmSpeed=tonumber(v) or v end})
Tabs.AutoFarm:Slider({Title="FlyFarmSpeed",Step=1,Value={Min=15,Max=24,Default=S.FlyFarmSpeed},Callback=function(v) S.FlyFarmSpeed=tonumber(v) or v end})
Tabs.AutoFarm:Toggle({Title="Anti Afk",Value=S.AntiAfk,Callback=function(v) S.AntiAfk=v end})

local function getOtherNames()
 local l = {}
 for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then table.insert(l, p.Name) end end
 if #l == 0 then table.insert(l, "No Players") end
 return l
end
local initList = getOtherNames()
if initList[1] ~= "No Players" then S.SelectedFlingPlayer = initList[1] end

local selDrop = Tabs.Fling:Dropdown({
 Title="Select Player",Values=initList,Value=initList[1],
 Callback=function(v) if type(v)=="table" then v=v[1] end if v and v~="No Players" then S.SelectedFlingPlayer=tostring(v) end end
})
local function updFlingList()
 local n = getOtherNames()
 if not table.find(n, S.SelectedFlingPlayer) then S.SelectedFlingPlayer = (n[1]~="No Players" and n[1]) or "" end
 pcall(function() if selDrop.Refresh then selDrop:Refresh(n) elseif selDrop.SetValues then selDrop:SetValues(n) end end)
end
Players.PlayerAdded:Connect(function() task.wait(0.2) updFlingList() end)
Players.PlayerRemoving:Connect(function() task.wait(0.2) updFlingList() end)

Tabs.Fling:Button({Title="Fling Select Player",Callback=function()
 local p = Players:FindFirstChild(S.SelectedFlingPlayer)
 if p and p ~= LocalPlayer then runFlingOnTargets({p}) end
end})
Tabs.Fling:Button({Title="Fling Murder",Callback=function()
 for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and getRoleSafe(p)=="Murderer" then runFlingOnTargets({p}) return end end
end})
Tabs.Fling:Button({Title="Fling Sheriff",Callback=function()
 for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and getRoleSafe(p)=="Sheriff" then runFlingOnTargets({p}) return end end
end})
Tabs.Fling:Button({Title="Fling All",Callback=function()
 local t = {}
 for _, p in ipairs(Players:GetPlayers()) do if p~=LocalPlayer and p.Character then table.insert(t, p) end end
 runFlingOnTargets(t)
end})
Tabs.Fling:Toggle({Title="Enable Touch Fling",Value=S.TouchFling,Callback=function(v) S.TouchFling=v end})
Tabs.Fling:Slider({Title="TouchFlingPower",Step=500,Value={Min=1000,Max=50000,Default=S.TouchFlingPower},Callback=function(v) S.TouchFlingPower=tonumber(v) or v end})
Tabs.Fling:Toggle({Title="Enable Antifling",Value=S.AntiFling,Callback=function(v) S.AntiFling=v end})

Tabs.Misc:Button({Title="Infinite Yield",Callback=function() pcall(function() loadstring(game:HttpGet("https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source"))() end) end})
Tabs.Misc:Toggle({Title="Enable Spinbot",Value=S.SpinBot,Callback=function(v) S.SpinBot=v if not v and LocalPlayer.Character then local h=LocalPlayer.Character:FindFirstChildOfClass("Humanoid") if h then h.AutoRotate=true end end end})
Tabs.Misc:Slider({Title="SpinSpeed",Step=1,Value={Min=1,Max=100,Default=S.SpinSpeed},Callback=function(v) S.SpinSpeed=tonumber(v) or v end})
Tabs.Misc:Toggle({Title="Enable Auto Grab Gun",Value=S.AutoGun,Callback=function(v) S.AutoGun=v end})

Tabs.Settings:Dropdown({Title="Theme",Values={"Black","Purple","Red"},Value="Black",Callback=function(v)
 if type(v)=="table" then v=v[1] end
 S.Theme=tostring(v) applyMenuTheme(S.Theme)
end})
Tabs.Settings:Toggle({Title="Enable Shaders",Value=S.EnableShaders,Callback=function(v) S.EnableShaders=v applyShaders() end})
Tabs.Settings:Button({Title="Leave",Callback=function() pcall(function() TeleportService:Teleport(185655149, LocalPlayer) LocalPlayer:Kick("Leaving...") end) end})
Tabs.Settings:Button({Title="Rejoin",Callback=function() pcall(function() TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end) end})
Tabs.Settings:Button({Title="Respawn",Callback=function() if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health=0 end end})
