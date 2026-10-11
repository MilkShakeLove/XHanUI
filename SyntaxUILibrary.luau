-- Syntax UI library: Neverlose layout, Opai typography and ArrayList motion.
-- Loaded by SyntaxExecutor.luau from a local file or child ModuleScript.
local UI=(function()
-- Syntax Roblox UI: Neverlose ClickGUI, Opai typography, independent XHan ArrayList.
-- Shared layout coordinates for painting, clipping and hit testing.
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Http=game:GetService("HttpService")
local Lighting=game:GetService("Lighting")
local GuiService=game:GetService("GuiService")
local TextService=game:GetService("TextService")
local UI={}
local language="English"
local translations={
  ["Combat"]="战斗",["Targets"]="目标",["Movement"]="移动",["Player"]="玩家",["Visual"]="视觉",["Visuals"]="视觉",["Misc"]="杂项",["Miscellaneous"]="杂项",["HUD Editor"]="界面编辑",["Configs"]="配置",["Enabled"]="启用",["Disabled"]="禁用",["Save"]="保存",["Load"]="载入",["Delete"]="删除",["Apply"]="应用",["Search"]="搜索",["Appearance"]="外观",["UI scale"]="界面缩放",["HUD scale"]="HUD缩放",["Accent color"]="强调色",["Source colors"]="原始配色",["Flowing colors"]="流光配色",["Animations: On"]="动画：开",["Animations: Off"]="动画：关",["Animation speed"]="动画速度",["Island shadow"]="灵动岛阴影",["Island Shadow Strength"]="灵动岛阴影强度",["Local blur"]="局部模糊",["Saved configurations"]="已保存配置",["Create configuration"]="新建配置",["No modules found"]="未找到模块",["Background"]="背景",["Shadow"]="阴影",["Categories"]="分类",["Lowercase"]="小写",["Show suffix"]="显示后缀",["Right line"]="右侧线条",["Widgets"]="组件",["Array List mode"]="功能列表样式",["Range"]="范围",["Speed"]="速度",["Mode"]="模式",["Color"]="颜色",["Scale"]="缩放",["Players"]="玩家",["Items"]="物品",["Health bar"]="生命条",["Outline"]="描边",["Opacity"]="不透明度",["Width"]="宽度",["Height"]="高度",["Size"]="大小",["Distance"]="距离",["Rotation"]="旋转",["Theme"]="主题",["Style"]="样式",["Language"]="语言",["None"]="无",["Default"]="默认",["Opai"]="Opai",["XHan"]="XHan",["Click GUI"]="点击界面",["Full Bright"]="全亮",["Name Tags"]="名称标签",["Target HUD"]="目标面板",["Dynamic Island"]="灵动岛",["ArrayList"]="功能列表"
}
local words={Max="最大",Min="最小",Auto="自动",Target="目标",Targets="目标",Show="显示",Hide="隐藏",Health="生命",Armor="护甲",Effect="效果",Effects="效果",Rendering="渲染",Render="渲染",Mode="模式",Speed="速度",Range="范围",Strength="强度",Background="背景",Shadow="阴影",Size="大小",Width="宽度",Height="高度",Color="颜色",Colors="颜色",Glow="发光",Text="文字",Font="字体",Scale="缩放",Island="灵动岛",Delay="延迟",Distance="距离",Duration="时长",Time="时间",Damage="伤害",Chance="概率",Count="数量",Amount="数量",Interval="间隔",Radius="半径",Angle="角度",Offset="偏移",Vertical="垂直",Horizontal="水平",Threshold="阈值",Priority="优先级",Players="玩家",Player="玩家",Blocks="方块",Block="方块",Items="物品",Item="物品",Inventory="背包",Potion="药水",Session="会话",Movement="移动",Combat="战斗",Visual="视觉",Enabled="启用",Disabled="禁用",Apply="应用",Lowercase="小写",Suffix="后缀",Categories="分类",Animation="动画",Animations="动画",Right="右",Left="左",None="无",Default="默认"}
local function localize(value)
 if language~="中文" then return value end
 if translations[value] then return translations[value] end
 local changed=false
 local result=value:gsub("%a+",function(word) if words[word] then changed=true;return words[word] end;return word end)
 return changed and result or value
end
local W,H,R,P=152,21,19.6,10
local palettes={
 Lavender={header=0x1C1F29,body=0x151315,enabled=0xA8B0E7,enabledHover=0xB0B8EF,accent=0xBBC3FF,enabledText=0x172778,text=0xE4E1E6,field=0x2D2D38,line=0xC4C0CC,track=0x484858,scrollbar=0x636472,selected=0x414253,outline=0x938F99},
 ["Light Pink"]={header=0x161110,body=0x1A1413,enabled=0xDF9D95,enabledHover=0xE5A59D,accent=0xFFB4AA,enabledText=0x5F150F,text=0xEDE0DE,field=0x2E2625,line=0xCDB7B4,track=0x56413E,scrollbar=0x69534D,selected=0x483A37,outline=0x9E8D8B}}
local function rgb(n) return Color3.fromRGB(math.floor(n/65536)%256,math.floor(n/256)%256,n%256) end
local function opaiFont(plain) return plain and Enum.Font.Gotham or Enum.Font.GothamMedium end
local function copy(v) if type(v)~="table" then return v end;local t={} for k,x in pairs(v) do t[k]=copy(x) end return t end
local function new(class,parent,props) local o=Instance.new(class);if class=="Frame" or class=="TextButton" or class=="TextBox" or class=="TextLabel" or class=="ImageLabel" then o.AutoLocalize=false end;if class=="Frame" or class=="TextButton" or class=="TextBox" then o.BorderSizePixel=0 end;for k,v in pairs(props or {}) do o[k]=v end;o.Parent=parent;return o end
local function ease(a,b,dt,rate) local v=b+(a-b)*math.exp(-dt*(rate or 30));return math.abs(v-b)<.0005 and b or v end
local function rect(x,y,w,h) return {x=x,y=y,w=w,h=h} end
local function inside(r,x,y) return x>=r.x and y>=r.y and x<r.x+r.w and y<r.y+r.h end
local function intersection(a,b) local x,y=math.max(a.x,b.x),math.max(a.y,b.y);return rect(x,y,math.max(0,math.min(a.x+a.w,b.x+b.w)-x),math.max(0,math.min(a.y+a.h,b.y+b.h)-y)) end
local function condition(c,values)
 if not c then return true end
 if c.op=="eq" then return values[c.name]==c.value end
 if c.op=="contains" then return type(values[c.name])=="table" and table.find(values[c.name],c.value)~=nil end
 if c.op=="not" then return not condition(c.a,values) end
 if c.op=="and" then return condition(c.a,values) and condition(c.b,values) end
 if c.op=="or" then return condition(c.a,values) or condition(c.b,values) end
 return false
end
local function precision(step) for n=0,6 do if math.abs(step*10^n-math.round(step*10^n))<.000001 then return n end end return 6 end
local function numberText(value,step) return string.format("%."..precision(step).."f",value) end
local function toggleDetail(detail,enabled)
 detail=tostring(detail):gsub("%s+$","")
 return (detail~="" and detail.." " or "")..(enabled and "Enabled" or "Disabled").."."
end
-- A camera-facing, nearly transparent Glass plane gives DepthOfFieldEffect a
-- local depth surface. The tint below remains as a fallback on unsupported GPUs.
local function updateRegionalBlur(pane,anchor,enabled)
 local camera=workspace.CurrentCamera
 if not enabled or not camera or anchor.AbsoluteSize.X<8 or anchor.AbsoluteSize.Y<8 then
  pane.active=false
   if pane.part then pcall(function() pane.part.Transparency=1 end) end
   if pane.effect then pcall(function() pane.effect.Enabled=false end) end
  return
 end
 if pane.unsupported then return end
  -- A replaced camera may have destroyed its children. Rebuild the plane so
  -- the blur keeps following the new camera instead of using a dead Part.
  if pane.part and (pane.camera~=camera or pane.part.Parent~=pane.camera) then
   pcall(function() pane.part:Destroy() end)
   if pane.effect then pcall(function() pane.effect:Destroy() end) end
   pane.part=nil;pane.mesh=nil;pane.effect=nil;pane.camera=nil
  end
 if not pane.part then
   local effect,part
  local ok=pcall(function()
    effect=Instance.new("DepthOfFieldEffect")
   effect.Name="SyntaxLocalBackdropBlur";effect.FarIntensity=0;effect.NearIntensity=.9;effect.InFocusRadius=0;effect.FocusDistance=.25-camera.NearPlaneZ
    part=Instance.new("Part")
   part.Name="SyntaxLocalBackdropPlane";part.Size=Vector3.new(.01,.01,.01);part.Anchored=true
   part.CanCollide=false;part.CanTouch=false;part.CanQuery=false;part.CastShadow=false
    part.Material=Enum.Material.Glass;part.Transparency=1-1e-7
   local mesh=Instance.new("BlockMesh");mesh.Parent=part
   part.Parent=camera;effect.Parent=Lighting
   pane.part=part;pane.mesh=mesh;pane.effect=effect;pane.camera=camera
  end)
   if not ok then
    if part then pcall(function() part:Destroy() end) end
    if effect then pcall(function() effect:Destroy() end) end
    pane.part=nil;pane.mesh=nil;pane.effect=nil;pane.camera=nil
    pane.unsupported=true;pane.active=false;return
   end
 end
 local position=anchor.AbsolutePosition+Vector2.new(4,4)
 local size=anchor.AbsoluteSize-Vector2.new(8,8)
 local normal=camera.CFrame.LookVector
 local planePoint=camera.CFrame.Position+normal*(.05-camera.NearPlaneZ)
 local function project(x,y)
  local ray=camera:ViewportPointToRay(x,y,1)
  local divisor=ray.Direction:Dot(normal)
  if math.abs(divisor)<.00001 then return nil end
  local distance=(planePoint-ray.Origin):Dot(normal)/divisor
  return camera.CFrame:PointToObjectSpace(ray.Origin+ray.Direction*distance)
 end
 local upper=project(position.X,position.Y)
 local lower=project(position.X+size.X,position.Y+size.Y)
 if not upper or not lower then pane.part.Transparency=1;pane.effect.Enabled=false;pane.active=false;return end
 pane.mesh.Offset=(upper+lower)*.5
 pane.mesh.Scale=Vector3.new(math.abs(lower.X-upper.X)/.01,math.abs(lower.Y-upper.Y)/.01,1)
 pane.part.CFrame=camera.CFrame
 pane.part.Transparency=1-1e-7
 pane.effect.FocusDistance=.25-camera.NearPlaneZ
 pane.effect.Enabled=true;pane.active=true
end
local function destroyRegionalBlur(pane)
  if pane.part then pcall(function() pane.part:Destroy() end);pane.part=nil end
  if pane.effect then pcall(function() pane.effect:Destroy() end);pane.effect=nil end
  pane.mesh=nil;pane.camera=nil
 pane.active=false
end
function UI.new(options)
 options=options or {}
 for _,name in ipairs({"Scale","HUDScale"}) do local value=options[name];assert(value==nil or (type(value)=="number" and value==value and value>=.5 and value<=4),name.." must be between 0.5 and 4") end
 local parent=options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
 -- Shutdown is owned by this UI, so repeat execution also works without writable globals.
 local old=parent:FindFirstChild("SamsaraOpaiV2")
 if old then local shutdown=old:FindFirstChild("Shutdown");if shutdown and shutdown:IsA("BindableEvent") then shutdown:Fire() end;old:Destroy() end
 local gui=new("ScreenGui",parent,{Name="SamsaraOpaiV2",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=90,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
 -- Explicit full-screen coordinates: IgnoreGuiInset alone still leaves device safe insets.
 gui.ScreenInsets=Enum.ScreenInsets.None
 gui.ClipToDeviceSafeArea=false
 local shutdown=new("BindableEvent",gui,{Name="Shutdown"})
 local changed=new("BindableEvent",gui,{Name="Changed"})
  local api={Gui=gui,Changed=changed.Event,renderStepName="SyntaxUIRender"..Http:GenerateGUID(false)}
 local root=new("Frame",gui,{Name="Canvas",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=10})
 local scaling=new("UIScale",root,{Scale=2})
 local catcher=new("TextButton",gui,{Name="InputSurface",Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,Modal=true,ZIndex=1})
 root.ZIndex=2
 local blur=new("BlurEffect",Lighting,{Name="SamsaraOpaiV2Blur",Size=0})
 local conns,pools,columns,rows,state,hits={},{},{},{},{},{}
 local theme="Lavender"
 local visible,dead,opacity,opened=true,false,0,os.clock()
 local k,zoom,width,height,mx,my,offsetX,offsetY=2,1,960,540,-100,-100,0,0
 local horizontal=0
 local drag,sliding,binding,dropdown=nil,nil,nil,nil
 local touch=nil
 local gesture=nil
 local ripple=nil
 local themeEffect=options.ThemeEffect or "Source"
 local animations=options.Animations~=false
 local animationSpeed=options.AnimationSpeed or 1
 local glowStrength=options.GlowStrength or .75
 local visualTime=0;local flowTime=0
  local hudScale=options.HUDScale or options.Scale or 2
  local islandShadow=math.clamp(options.IslandShadow or 50,0,100)
  local appearanceT=0
  local aaHoverT=0
 assert(themeEffect=="Source" or themeEffect=="FlowingGlow","Invalid theme effect")
 assert(type(animationSpeed)=="number" and animationSpeed>=.5 and animationSpeed<=3,"Invalid animation speed")
 assert(type(glowStrength)=="number" and glowStrength>=0 and glowStrength<=1,"Invalid glow strength")
 local config={open=false,page="Configurations",x=780,y=40,scroll=0,selected=nil,names={},values={},message="",messageUntil=0}
 local render
 local postNotice
 local nativeDispatch
 local nativeSlots={}
 local diagnostic=false
 local activeStyle="Opai"
 local hudEditing=false
 local hudDrag
 local hudPlacements={}
 local hudBounds={}
 local hudButtons={}
 local function connect(s,f) local c=s:Connect(f);conns[#conns+1]=c;return c end
 local function notify(id,key,value) changed:Fire(id,key,copy(value));if options.OnChanged then task.spawn(options.OnChanged,id,key,copy(value)) end end
 local function message(s) config.message=s;config.messageUntil=os.clock()+3 end
 -- No automatic layout sizes are read back as logical sizes; pools reuse draw objects.
 local function pool(parentObject,independent)
   local p={independent=independent,parent=parentObject,frames={},texts={},images={},glyphs={},fi=0,ti=0,pi=0,gi=0,zi=0,drawScale=1,alpha=1};pools[#pools+1]=p
  function p:begin() self.fi=0;self.ti=0;self.pi=0;self.gi=0;self.zi=0 end
  function p:finish() for i=self.gi+1,#self.glyphs do self.glyphs[i].frame.Visible=false end;for i=self.fi+1,#self.frames do self.frames[i].Visible=false end;for i=self.ti+1,#self.texts do self.texts[i].Visible=false end;for i=self.pi+1,#self.images do self.images[i].Visible=false end end
  function p:box(x,y,w,h,c,a,r)
   if w<=0 or h<=0 then return end
   self.fi+=1;local o=self.frames[self.fi]
   if not o then o=new("Frame",self.parent,{BorderSizePixel=0,Active=false});new("UICorner",o,{Name="Corner",CornerRadius=UDim.new(0,0)});self.frames[self.fi]=o end
    local scale=self.drawScale
    o.Visible=true;o.Position=UDim2.fromOffset((x+(self.offsetX or 0))*scale,(y+(self.offsetY or 0))*scale);o.Size=UDim2.fromOffset(w*scale,h*scale);o.BackgroundColor3=rgb(c);o.BackgroundTransparency=1-(a or 1)*(self.independent and 1 or opacity)*self.alpha;self.zi+=1;o.ZIndex=self.zi;o.Rotation=0
    o.Corner.CornerRadius=UDim.new(0,(r or 0)*scale)
   local gradient=o:FindFirstChild("Gradient");if gradient then gradient.Enabled=false end
   local stroke=o:FindFirstChild("Stroke");if stroke then stroke.Enabled=false end
   return o
  end
  function p:text(s,x,centerY,size,w,c,plain,align)
   if w<=0 then return end
   self.ti+=1;local o=self.texts[self.ti]
   if not o then o=new("TextLabel",self.parent,{BackgroundTransparency=1,TextTruncate=Enum.TextTruncate.AtEnd,TextYAlignment=Enum.TextYAlignment.Center});self.texts[self.ti]=o end
    local scale=self.drawScale
      o.Visible=true;o.RichText=false;o.Text=self.independent and tostring(s) or localize(tostring(s));o.TextScaled=false;o.TextWrapped=false;o.TextTruncate=Enum.TextTruncate.AtEnd;o.TextYAlignment=Enum.TextYAlignment.Center;o.AutomaticSize=Enum.AutomaticSize.None;o.Position=UDim2.fromOffset((x+(self.offsetX or 0))*scale,(centerY-size+(self.offsetY or 0))*scale);o.Size=UDim2.fromOffset(w*scale,size*2*scale);o.TextSize=self.fixedText and math.max(1,math.round(size*scale)) or size*scale;o.Font=self.fontOverride or opaiFont(plain);o.TextColor3=rgb(c);o.TextTransparency=1-(self.independent and 1 or opacity)*self.alpha;o.TextXAlignment=align or Enum.TextXAlignment.Left;self.zi+=1;o.ZIndex=self.zi
   return o
  end
   function p:textBlock(s,x,y,size,w,h,c,plain)
    if w<=0 or h<=0 then return end
    local o=self:text(s,x,y+size,size,w,c,plain)
    local scale=self.drawScale
    o.TextWrapped=true;o.TextTruncate=Enum.TextTruncate.None;o.TextYAlignment=Enum.TextYAlignment.Top
    o.Position=UDim2.fromOffset((x+(self.offsetX or 0))*scale,(y+(self.offsetY or 0))*scale)
    o.Size=UDim2.fromOffset(w*scale,h*scale)
    return o
   end
  function p:image(uri,x,y,w,h,r,c,a,stretch)
   if type(uri)~="string" or uri=="" then return end
   self.pi+=1;local o=self.images[self.pi]
   if not o then o=new("ImageLabel",self.parent,{BackgroundTransparency=1,BorderSizePixel=0,ScaleType=Enum.ScaleType.Crop});new("UICorner",o,{Name="Corner"});self.images[self.pi]=o end
    local scale=self.drawScale
    self.zi+=1;o.ZIndex=self.zi;o.Visible=true;o.Image=uri;o.Position=UDim2.fromOffset((x+(self.offsetX or 0))*scale,(y+(self.offsetY or 0))*scale);o.Size=UDim2.fromOffset(w*scale,h*scale);o.ImageColor3=rgb(c or 0xFFFFFF);o.ScaleType=stretch and Enum.ScaleType.Stretch or Enum.ScaleType.Crop;o.ImageTransparency=1-(a or 1)*(self.independent and 1 or opacity)*self.alpha;o.Corner.CornerRadius=UDim.new(0,(r or 0)*scale);return o
  end

  function p:glyph(name,runs,x,y,size,c)
   self.gi+=1;local slot=self.glyphs[self.gi]
   if not slot then local frame=new("Frame",self.parent,{Name="Glyph",BackgroundTransparency=1,Size=UDim2.fromOffset(48,48)});slot={frame=frame,scale=new("UIScale",frame,{Scale=1}),pixels={}};self.glyphs[self.gi]=slot end
   if slot.name~=name then
    for _,pixel in ipairs(slot.pixels) do pixel:Destroy() end;slot.pixels={};slot.name=name;slot.tint=nil;slot.alpha=nil
    for _,run in ipairs(runs) do slot.pixels[#slot.pixels+1]=new("Frame",slot.frame,{BackgroundColor3=rgb(c),BackgroundTransparency=1-run[5],Position=UDim2.fromOffset(run[1],run[2]),Size=UDim2.fromOffset(run[3],run[4]),Active=false}) end
   end
    local alpha=(self.independent and 1 or opacity)*self.alpha
   if slot.tint~=c or slot.alpha~=alpha then for i,pixel in ipairs(slot.pixels) do pixel.BackgroundColor3=rgb(c);pixel.BackgroundTransparency=1-runs[i][5]*alpha end;slot.tint=c;slot.alpha=alpha end
    self.zi+=1;slot.frame.Visible=true;slot.frame.ZIndex=self.zi;slot.frame.Position=UDim2.fromOffset((x+(self.offsetX or 0))*self.drawScale,(y+(self.offsetY or 0))*self.drawScale);slot.scale.Scale=size*self.drawScale/48
  end

  function p:gradient(x,y,w,h,top,bottom,a,r)
   local o=self:box(x,y,w,h,0xFFFFFF,a,r);if not o then return end
   local g=o:FindFirstChild("Gradient") or new("UIGradient",o,{Name="Gradient",Rotation=90})
   g.Enabled=true;g.Rotation=90;if g:GetAttribute("Top")~=top or g:GetAttribute("Bottom")~=bottom then g.Color=ColorSequence.new(rgb(top),rgb(bottom));g:SetAttribute("Top",top);g:SetAttribute("Bottom",bottom) end;return o
  end
  function p:stroke(x,y,w,h,c,a,r,t)
   local o=self:box(x,y,w,h,0xFFFFFF,0,r);if not o then return end
   local stroke=o:FindFirstChild("Stroke") or new("UIStroke",o,{Name="Stroke",ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
    stroke.Enabled=true;stroke.Color=rgb(c);stroke.Transparency=1-(a or 1)*(self.independent and 1 or opacity)*self.alpha;stroke.Thickness=(t or 1)*self.drawScale;local g=stroke:FindFirstChild("Flow");if g then g.Enabled=false end;return o
  end
  function p:flowStroke(x,y,w,h,c1,c2,a,r,t,phase)
   local o=self:stroke(x,y,w,h,0xFFFFFF,a,r,t);if not o then return end
   local g=o.Stroke:FindFirstChild("Flow") or new("UIGradient",o.Stroke,{Name="Flow"})
   g.Enabled=true;if g:GetAttribute("First")~=c1 or g:GetAttribute("Last")~=c2 then g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,rgb(c1)),ColorSequenceKeypoint.new(.2,rgb(0xAF73FF)),ColorSequenceKeypoint.new(.4,rgb(c2)),ColorSequenceKeypoint.new(.6,rgb(0x73F09B)),ColorSequenceKeypoint.new(.8,rgb(0xFFBE5A)),ColorSequenceKeypoint.new(1,rgb(c1))});g:SetAttribute("First",c1);g:SetAttribute("Last",c2) end;g.Rotation=(phase or 0)%360;return o
  end
  function p:glow(x,y,w,h,c,a)
   local o=self:image("rbxassetid://104482361987216",x,y,w,h,0,c,a,true);if o then o.Name="Glow" end;return o
  end
  return p
 end
 local themeGlowRoot=new("Frame",root,{Name="ThemeGlow",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=1,Active=false})
 local themeGlow=pool(themeGlowRoot)
 local main=pool(root)
 local overlay=new("Frame",root,{Name="Overlay",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=500})
 local front=pool(overlay)
  front.fontOverride=opaiFont(false)
 local nativeLayer=new("Frame",overlay,{Name="NativeControls",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=2000})
  local editor=new("TextBox",overlay,{Name="ConfigName",Text="",PlaceholderText="Name",ClearTextOnFocus=false,BackgroundTransparency=1,BorderSizePixel=0,Font=opaiFont(false),TextSize=8.3,TextXAlignment=Enum.TextXAlignment.Left,Visible=false,ZIndex=3000})
  local jsonEditor=new("TextBox",overlay,{Name="ConfigJSON",Text="",PlaceholderText="Paste / copy JSON",ClearTextOnFocus=false,Font=opaiFont(false),TextSize=7,TextWrapped=true,MultiLine=true,Visible=false,ZIndex=3000})
 for _,m in ipairs(options.Modules or {}) do
  assert(type(m.id)=="string" and not state[m.id],"Unique module id required")
  local values={};local settingNames={}
  for _,s in ipairs(m.settings or {}) do assert(not settingNames[s.name],"Duplicate setting");settingNames[s.name]=true;values[s.name]=copy(s.default) end
  state[m.id]={enabled=m.enabled==true,key="Unknown",settings=values}
  rows[m.id]={def=m,expanded=false,reveal=0,enabled=m.enabled and 1 or 0,hover=0,animations={}}
 end
 local function selectedTheme() local s=state.ClickGUI;if s and palettes[s.settings["Opai Color"]] then return s.settings["Opai Color"] end;return theme end

 local customAccent
 local paletteCache
 local appearanceOpen=false
 local appearanceGeometry
 local appearanceSliding
 local sourceThemes={Default={0xFFFFFF,0xFFFFFF},Flower={0xFFFFFF,0xFFFFFF},Gold={0xFFA500,0xFFFF00},Ocean={0x00C6FF,0x0072FF},Nova={0xFF64C8,0x1996FF},Emerald={0x00E676,0x164D2B},Inferno={0xFF5722,0x7A321F},Sakura={0xFF80AB,0xE040FB},Cherry={0xDD3D69,0xE0B3B7}}
 local function mixColor(a,b,t)
  local r=math.round((math.floor(a/65536)%256)*(1-t)+(math.floor(b/65536)%256)*t)
  local g=math.round((math.floor(a/256)%256)*(1-t)+(math.floor(b/256)%256)*t)
  local blue=math.round((a%256)*(1-t)+(b%256)*t)
  return r*65536+g*256+blue
 end
 local function parseAccent(value)
  if type(value)=="string" then local clean=value:gsub("^#","");if not clean:match("^%x%x%x%x%x%x$") then return nil end;value=tonumber(clean,16) end
  if type(value)~="number" or value~=value or value<0 or value>0xFFFFFF or value%1~=0 then return nil end
  return value
 end
 local flowPalettes={Starlight={0xE9A8BC,0x6EC8F1,0xFFFFFF},Aurora={0xFF78DC,0x8269FF,0x5FDCFF,0xD2FFF5},Rainbow={0xFF6978,0xFFBE5A,0x73F09B,0x5ABEFF,0xAF73FF}}
 local function flowingColor(name,index,period,phase)
  local palette=flowPalettes[name] or flowPalettes.Starlight
   local cycle=(flowTime/math.max(.2,period or 3)+(index or 0)*.115+(phase or 0))%1
  local scaled=cycle*#palette;local at=math.floor(scaled)+1
  return mixColor(palette[at],palette[at%#palette+1],scaled%1)
 end
 local function accentColor(fallback) return themeEffect=="FlowingGlow" and flowingColor("Aurora",0,5) or customAccent or fallback end
 local function rainbowColor(h)
  h=(h%1)*6;local sector=math.floor(h);local t=h-sector;local a=math.round(255*t);local b=255-a
  local channels=({{255,a,0},{b,255,0},{0,255,a},{0,b,255},{a,0,255},{255,0,b}})[sector+1]
  return channels[1]*65536+channels[2]*256+channels[3]
 end
 local function clientColor(offset)
  if themeEffect=="FlowingGlow" then return flowingColor("Rainbow",0,5,(offset or 0)/360) end
  if customAccent then return customAccent end
  local setting=state.Theme and state.Theme.settings or {};local name=setting.Theme or "Default";local speed=setting.Speed or 1
  if name=="Rainbow" then return rainbowColor(visualTime*speed/6+(offset or 0)/360) end
  local pair=sourceThemes[name] or sourceThemes.Default
  return mixColor(pair[1],pair[2],(math.sin(visualTime*speed+(offset or 0))+1)/2)
 end
 local function currentPalette()
  local name=selectedTheme();local original=palettes[name]
  local color=themeEffect=="FlowingGlow" and flowingColor("Aurora",0,5) or customAccent
  if not color then return original end
  if paletteCache and paletteCache.key==name and paletteCache.color==color then return paletteCache end
  local p=copy(original);p.key=name;p.color=color;p.accent=color;p.enabled=mixColor(color,0xFFFFFF,.14);p.enabledHover=mixColor(color,0xFFFFFF,.27)
  p.enabledText=mixColor(color,0x05080C,.83);p.outline=mixColor(color,0x797979,.55);paletteCache=p;return p
 end
 function api:SetAccent(value)
  if value==nil or value==false then customAccent=nil else customAccent=assert(parseAccent(value),"Accent must be #RRGGBB or a RGB integer") end
  themeEffect="Source";paletteCache=nil;notify("Appearance","accent",customAccent or false)
 end
 function api:SetThemeEffect(value) assert(value=="Source" or value=="FlowingGlow","Unknown theme effect");themeEffect=value;paletteCache=nil;notify("Appearance","effect",value) end
 function api:SetAnimations(value) assert(type(value)=="boolean");animations=value;notify("Appearance","animations",value) end
 function api:SetAnimationSpeed(value) assert(type(value)=="number" and value==value and value>=.5 and value<=3);animationSpeed=value;notify("Appearance","animationSpeed",value) end
 function api:SetGlowStrength(value) assert(type(value)=="number" and value==value and value>=0 and value<=1);glowStrength=value;notify("Appearance","glowStrength",value) end
 function api:SetLanguage(value) assert(value=="English" or value=="中文","Unknown language");language=value;notify("Appearance","language",value) end
  function api:SetIslandShadow(value)
   assert(type(value)=="number" and value==value and value>=0 and value<=100)
   islandShadow=value
   if state.HUD and state.HUD.settings["Island Shadow Strength"]~=nil then self:SetSetting("HUD","Island Shadow Strength",value) end
   notify("Appearance","islandShadow",value)
  end
  function api:GetAppearance() return {language=language,islandShadow=islandShadow,scale=options.Scale or k,hudScale=hudScale,accent=customAccent or false,effect=themeEffect,animations=animations,animationSpeed=animationSpeed,glowStrength=glowStrength} end
 function api:OpenAppearance() appearanceOpen=true;dropdown=nil;sliding=nil;binding=nil;drag=nil end

 local function valid(s,v)
  if s.type=="toggle" then return type(v)=="boolean" end
  if s.type=="slider" then return type(v)=="number" and v==v and v>=s.min and v<=s.max end
  if s.type=="select" then return type(v)=="string" and table.find(s.options,v)~=nil end
  if s.type=="multi" then
   if type(v)~="table" then return false end
   local count,seen=0,{};for key,x in pairs(v) do if type(key)~="number" or key%1~=0 or key<1 or not table.find(s.options,x) or seen[x] then return false end;count+=1;seen[x]=true end
   return count==#v and (s.allowEmpty~=false or #v>0)
  end return false
 end
 function api:GetState() return {version=3,theme=selectedTheme(),appearance=api:GetAppearance(),modules=copy(state)} end
 function api:SetEnabled(id,value)
  assert(state[id] and type(value)=="boolean","Invalid module")
  if state[id].enabled==value then return end
  state[id].enabled=value;notify(id,"enabled",value)
  if postNotice and id~="HUD" then postNotice("module:"..id,"Module Toggled",rows[id].def.name.." has been ","toggle",value,.8) end
 end
 function api:SetSetting(id,name,value)
  local row=assert(rows[id],"Invalid module")
   for _,s in ipairs(row.def.settings or {}) do if s.name==name then assert(valid(s,value),"Invalid setting");state[id].settings[name]=copy(value);if id=="HUD" and name=="Island Shadow Strength" then islandShadow=value end;notify(id,name,value);return end end
  error("Unknown setting")
 end
 function api:SetTheme(name) assert(palettes[name],"Unknown palette");theme=name;customAccent=nil;themeEffect="Source";paletteCache=nil;if state.ClickGUI then state.ClickGUI.settings["Opai Color"]=name;notify("ClickGUI","Opai Color",name) end end
 function api:SetVisible(value)
  assert(type(value)=="boolean");visible=value;if value then hudEditing=false;hudDrag=nil end;drag=nil;sliding=nil;binding=nil;dropdown=nil;gesture=nil;touch=nil;editor:ReleaseFocus();jsonEditor:ReleaseFocus()
  appearanceOpen=false;appearanceSliding=nil
  if value then opened=os.clock() end
 end
 function api:ApplyState(snapshot)
  if type(snapshot)~="table" or (snapshot.version~=1 and snapshot.version~=2 and snapshot.version~=3) or type(snapshot.modules)~="table" then return false,"Invalid configuration" end
   snapshot=copy(snapshot)
    local oldGUI=snapshot.modules.ClickGUI
    if type(oldGUI)=="table" and type(oldGUI.settings)=="table" and oldGUI.settings.Style~=nil and oldGUI.settings.Style~="Neverlose" and oldGUI.settings.Style~="Opai" then oldGUI.settings.Style="Neverlose" end
   local incomingHUD=snapshot.modules.HUD
   if type(incomingHUD)=="table" and type(incomingHUD.settings)=="table" then
    local hudSettings=incomingHUD.settings
    for _,name in ipairs({"Target Mode","Target Show Armor","Target Theme Color","Target Outline","Target Show Win Or Loss","Target Health Animation"}) do hudSettings[name]=nil end
    if type(hudSettings.Widgets)=="table" then
     local array=true;for key in pairs(hudSettings.Widgets) do if type(key)~="number" or key%1~=0 or key<1 then array=false;break end end
     if array then
      local kept={};for _,widget in ipairs(hudSettings.Widgets) do if widget~="Potion Status" and widget~="InventoryHUD" and widget~="SessionHUD" then kept[#kept+1]=widget end end
      hudSettings.Widgets=kept
     end
    end
   end
  if snapshot.theme~=nil and not palettes[snapshot.theme] then return false,"Invalid theme" end
  for id,incoming in pairs(snapshot.modules) do
   if not state[id] or type(incoming)~="table" or type(incoming.enabled)~="boolean" or type(incoming.settings)~="table" then return false,"Invalid module: "..tostring(id) end
   if incoming.key~=nil then local ok,key=pcall(function() return Enum.KeyCode[incoming.key] end);if type(incoming.key)~="string" or not ok or not key then return false,"Invalid key" end end
    for name,value in pairs(incoming.settings) do
     local exists,accepted=false,false
     for _,s in ipairs(rows[id].def.settings or {}) do if s.name==name then exists=true;accepted=valid(s,value);break end end
     if (exists and not accepted) or (not exists and not (id=="ClickGUI" and (name=="Style" or name=="Interface")) and not (id=="HUD" and tostring(name):match("^XHan "))) then return false,"Invalid setting: "..tostring(name) end
    end
  end
  local incomingAppearance=snapshot.appearance
  if incomingAppearance~=nil then
   if type(incomingAppearance)~="table" then return false,"Invalid appearance" end
   for _,name in ipairs({"scale","hudScale"}) do local value=incomingAppearance[name];if value~=nil and (type(value)~="number" or value~=value or value<.5 or value>4) then return false,"Invalid appearance scale" end end
   if incomingAppearance.effect~=nil and incomingAppearance.effect~="Source" and incomingAppearance.effect~="FlowingGlow" then return false,"Invalid theme effect" end
   if incomingAppearance.animations~=nil and type(incomingAppearance.animations)~="boolean" then return false,"Invalid animations" end
   for name,range in pairs({animationSpeed={.5,3},glowStrength={0,1},islandShadow={0,100}}) do local v=incomingAppearance[name];if v~=nil and (type(v)~="number" or v~=v or v<range[1] or v>range[2]) then return false,"Invalid "..name end end
   if incomingAppearance.language~=nil and incomingAppearance.language~="English" and incomingAppearance.language~="中文" then return false,"Invalid language" end
    if incomingAppearance.accent~=nil and incomingAppearance.accent~=false and not parseAccent(incomingAppearance.accent) then return false,"Invalid accent" end
  end
  local notifications={}
  for id,incoming in pairs(snapshot.modules) do state[id].enabled=incoming.enabled;state[id].key=incoming.key or "Unknown";notifications[#notifications+1]={id,"enabled",incoming.enabled};for name,value in pairs(incoming.settings) do if state[id].settings[name]~=nil then state[id].settings[name]=copy(value);notifications[#notifications+1]={id,name,value} end end end
  if snapshot.theme then self:SetTheme(snapshot.theme) end
   if state.HUD and state.HUD.settings["Island Shadow Strength"]~=nil then islandShadow=state.HUD.settings["Island Shadow Strength"] end
   if incomingAppearance then self:SetScale(incomingAppearance.scale or k);self:SetHUDScale(incomingAppearance.hudScale or hudScale);self:SetAccent(incomingAppearance.accent);self:SetThemeEffect(incomingAppearance.effect or "Source");self:SetAnimations(incomingAppearance.animations~=false);self:SetAnimationSpeed(incomingAppearance.animationSpeed or 1);self:SetGlowStrength(incomingAppearance.glowStrength or .75);if incomingAppearance.islandShadow~=nil then self:SetIslandShadow(incomingAppearance.islandShadow) end;self:SetLanguage(incomingAppearance.language or "English") end
  for _,entry in ipairs(notifications) do notify(entry[1],entry[2],entry[3]) end
  dropdown=nil;return true
 end
 function api:ExportJSON() return Http:JSONEncode(self:GetState()) end
 function api:ImportJSON(text) local ok,result=pcall(Http.JSONDecode,Http,text);if not ok then return false,"Invalid JSON" end;return self:ApplyState(result) end
 function api:Expand(id,value) local row=assert(rows[id]);row.expanded=value;dropdown=nil end
 local categoryOrder=options.Categories or {"Combat","Movement","Player","Visual","Misc"}
 for _,name in ipairs(categoryOrder) do
  local members={};for _,row in pairs(rows) do if row.def.category==name and not row.def.hidden then members[#members+1]=row end end
  table.sort(members,function(a,b) return a.def.id:lower()<b.def.id:lower() end)
  local panel=new("Frame",root,{Name=name,BackgroundTransparency=1,ClipsDescendants=true})
  local body=new("Frame",panel,{Name="Body",BackgroundTransparency=1,ClipsDescendants=true})
  local c={name=name,rows=members,frame=panel,body=body,pool=pool(panel),content=pool(body),x=0,y=0,scroll=0,target=0,reveal=1,expanded=true,entries={},height=0,bodyH=0}
  for _,row in ipairs(members) do row.section=new("Frame",body,{Name=row.def.id.."Settings",BackgroundTransparency=1,ClipsDescendants=true,ZIndex=500});row.settingsPool=pool(row.section) end
  columns[#columns+1]=c
 end
 local function hit(r,action,data,clip)
  if clip then r=intersection(r,clip) end
  if r.w>0 and r.h>0 then hits[#hits+1]={rect=r,action=action,data=data} end
 end
 local function rebuild(c,dt)
  c.entries={};local top=0
  for _,row in ipairs(c.rows) do
   local st=state[row.def.id];row.reveal=ease(row.reveal,row.expanded and 1 or 0,dt,40);row.enabled=ease(row.enabled,st.enabled and 1 or 0,dt,30)
   c.entries[#c.entries+1]={row=row,top=top,h=R};top+=R
   local section=0
   for _,s in ipairs(row.def.settings or {}) do
    if condition(s.when,st.settings) then
     local h=(s.type=="toggle" and R or s.type=="slider" and 20 or 40)
     c.entries[#c.entries+1]={row=row,setting=s,top=top+section,h=h,sectionTop=top,sectionBottom=0};section+=h
    end
   end
   local bottom=top+section*row.reveal
   for i=#c.entries,1,-1 do local entry=c.entries[i];if entry.row~=row then break end;if entry.setting then entry.sectionBottom=bottom end end
   top=bottom
  end
  c.height=top
  local available=math.max(R,height-c.y-H-8)
  local maxBody=math.min(16*R+7,available,math.max(R,height-height*.112-H-math.max(8,height*.10)))
  c.targetH=math.min(top+7,maxBody)
  c.reveal=ease(c.reveal,c.expanded and 1 or 0,dt,40)
  c.bodyH=c.targetH*c.reveal
  c.maxScroll=math.max(0,top-(c.targetH-7));c.target=math.clamp(c.target,0,c.maxScroll);c.scroll=ease(c.scroll,c.target,dt,14)
 end
 local function drawCheck(p,x,y,size,c)
  local a=p:box(x,y+size*.43,size*.48,1,c,1);if a then a.Rotation=42 end
  local b=p:box(x+size*.28,y+size*.33,size*.85,1,c,1);if b then b.Rotation=-48 end
 end
 local function displayName(text) return tostring(text):gsub("(%u+)(%u%l)","%1 %2"):gsub("([%l%d])(%u)","%1 %2") end
 local function choiceLabel(s,value) if activeStyle=="Neverlose" and s.type=="multi" then local list={};for _,option in ipairs(s.options) do if table.find(value,option) then list[#list+1]=option end end;return #list==0 and "None" or table.concat(list,", ") end;local text=s.type=="multi" and (#value.." Selected") or tostring(value);return activeStyle=="Opai" and displayName(text) or text end
 local function drawSetting(p,s,row,x,y,globalX,globalY,clip,dt)
  local palette=currentPalette();local value=state[row.def.id].settings[s.name]
  local name=s.label or s.name
  if s.type=="toggle" then
   p:text(name,x+P,y+R/2,8.5,W-2*P-30,palette.text,true)
   local t=ease(row.animations[s.name] or (value and 1 or 0),value and 1 or 0,dt,30);row.animations[s.name]=t
   local bg=rgb(palette.outline):Lerp(rgb(palette.accent),t)
   local outer=p:box(x+W-P-26,y+(R-16)/2,26,16,palette.outline,1,8);outer.BackgroundColor3=bg
   if t<.999 then p:box(x+W-P-25,y+(R-14)/2,24,14,palette.field,1-t,7) end
   local elapsed=animations and row.press and row.press[s.name] and (os.clock()-row.press[s.name])*animationSpeed or 10;local stretch=3*math.exp(-18*elapsed)
   local knob=p:box(x+W-P-24+(10-stretch)*t,y+(R-12)/2,12+stretch,12,palette.line,1,6);knob.BackgroundColor3=rgb(palette.line):Lerp(rgb(palette.enabledText),t)
   if t>.5 then drawCheck(p,x+W-P-21+10*t,y+(R-6)/2,6,palette.accent) end
   hit(rect(globalX,globalY,W,R),"toggle",{row=row,s=s},clip)
  elseif s.type=="slider" then
   p:text(name,x+P,y+6.5,8.5,W-2*P-38,palette.text,true)
   p:text(numberText(value,s.step),x+W-P-38,y+6.5,8.5,38,palette.text,false,Enum.TextXAlignment.Right)
   local fraction=(value-s.min)/math.max(.000001,s.max-s.min)
   local t=sliding and sliding.row==row and sliding.s==s and fraction or ease(row.animations[s.name] or fraction,fraction,dt,35);row.animations[s.name]=t
   p:box(x+P,y+14.35,W-2*P,2.5,palette.track,1,1.25);p:box(x+P,y+14.35,(W-2*P)*t,2.5,palette.accent,1,1.25)
   p:box(x+P+(W-2*P)*t-4,y+11.6,8,8,palette.accent,1,4)
   hit(rect(globalX+P-3,globalY+9.6,W-2*P+6,12),"slider",{row=row,s=s,left=globalX+P,width=W-2*P},clip)
  else
   p:text(name,x+P,y+8,8.5,W-2*P,palette.text,true)
   local fieldColor=s.type=="multi" and 0x2A2A2D or palette.field
   p:box(x+P-2,y+16,W-2*P+4,21,fieldColor,1,2)
   p:text(choiceLabel(s,value),x+P+4,y+26.5,8.5,W-2*P-8,palette.text)
   p:box(x+P-1,y+36,W-2*P+2,1,palette.line,1)
   hit(rect(globalX+P-2,globalY+16,W-2*P+4,21),"choice",{row=row,s=s,x=globalX+P-2,y=globalY+37},clip)
  end
 end
 local function fit()
  local view=gui.AbsoluteSize
  k=options.Scale or (view.X<700 and 1.5 or 2)
  width,height=view.X/k,view.Y/k
  if width<=0 or height<=0 then return end
  local margin=math.min(30,width*.0382)
  for i,c in ipairs(columns) do
   if not c.placed then c.x=margin+(i-1)*(W+8);c.y=math.max(8,height*.112);c.placed=true end
   c.y=math.clamp(c.y,4,math.max(4,height-H-R-8))
  end
  config.x=math.clamp(config.x,4,math.max(4,width-W-4));config.y=math.clamp(config.y,4,math.max(4,height-H-86))
  horizontal=math.clamp(horizontal,0,math.max(0,margin*2+#columns*W+(#columns-1)*8-width))
 end
 function api:SetScale(value) assert(type(value)=="number" and value==value and value>=.5 and value<=4);options.Scale=value;drag=nil;sliding=nil;dropdown=nil;fit();notify("Appearance","scale",value) end
  function api:SetHUDScale(value) assert(type(value)=="number" and value==value and value>=.5 and value<=4);hudScale=value;options.HUDScale=value;notify("Appearance","hudScale",value) end
 local function drawColumns(dt)
  local palette=currentPalette()
  for order,c in ipairs(columns) do
   rebuild(c,dt);local x,y=c.x-horizontal,c.y
   c.frame.ZIndex=10+order;c.frame.Position=UDim2.fromOffset(x,y);c.frame.Size=UDim2.fromOffset(W,H+c.bodyH)
   c.body.Position=UDim2.fromOffset(0,H);c.body.Size=UDim2.fromOffset(W,math.max(0,c.bodyH-7));c.body.ZIndex=100
   local p=c.pool;p:begin();p:box(0,0,W,H+c.bodyH,palette.body,.8,7);p:box(0,0,W,H,palette.header,1,7)
   if c.bodyH>0.5 then p:box(0,H-7,W,7,palette.header,1) end
   p:text(c.name,P,H/2,9.2,W-2*P,palette.text)
   hit(rect(x,y,W,H),"header",c)
   hit(rect(x,y+H,W,c.bodyH),"body",c)
   for _,row in ipairs(c.rows) do row.section.Visible=false;row.settingsPool:begin() end
   local content=c.content;content:begin();local bodyClip=rect(x,y+H,W,math.max(0,c.bodyH-7))
   for _,entry in ipairs(c.entries) do
    local ey=entry.top-c.scroll;local row=entry.row;local clip=bodyClip
    if entry.setting then clip=intersection(clip,rect(x,y+H+entry.sectionTop-c.scroll,W,math.max(0,entry.sectionBottom-entry.sectionTop))) end
    if ey+entry.h>0 and ey<c.bodyH-7 and clip.h>0 then
     if not entry.setting then
      local hovered=inside(intersection(rect(x,y+H+ey,W,R),bodyClip),mx,my) and not dropdown and not drag
      row.hover=ease(row.hover,hovered and 1 or 0,dt,30)
      if row.hover>.001 then content:box(0,ey,W,R,palette.text,.047*row.hover*(1-row.enabled)) end
      if row.enabled>.001 then local fill=content:box(0,ey,W,R,palette.enabled,row.enabled);fill.BackgroundColor3=rgb(palette.enabled):Lerp(rgb(palette.enabledHover),row.hover) end
      local title=content:text(binding==row and "Press a key" or row.def.name,P,ey+R/2,8.3,W-2*P,palette.text)
      title.TextColor3=rgb(palette.text):Lerp(rgb(palette.enabledText),row.enabled)
      hit(rect(x,y+H+ey,W,R),"module",row,bodyClip)
     elseif row.reveal>.001 then
      row.section.Visible=true;row.section.Position=UDim2.fromOffset(0,entry.sectionTop-c.scroll);row.section.Size=UDim2.fromOffset(W,entry.sectionBottom-entry.sectionTop)
      drawSetting(row.settingsPool,entry.setting,row,0,entry.top-entry.sectionTop,x,y+H+ey,clip,dt)
     end
    end
   end
   if c.maxScroll>0 and c.bodyH>8 then
    local track=c.bodyH-11;local thumb=math.min(track,math.max(12,track*(c.bodyH-7)/math.max(1,c.height)));local travel=track-thumb
    p:box(W-3.5,H+2+travel*c.scroll/c.maxScroll,2.5,thumb,palette.scrollbar,.8,1.25)
    hit(rect(x+W-6,y+H,6,c.bodyH-7),"scrollbar",{c=c,thumb=thumb,travel=travel,top=y+H+2+travel*c.scroll/c.maxScroll})
   end
   p:finish();content:finish();for _,row in ipairs(c.rows) do row.settingsPool:finish() end
  end
 end
  local function drawIcon(p,name,x,y,size,c)
  local u=size/24
  local function line(ax,ay,bx,by,weight)
   local dx,dy=(bx-ax)*u,(by-ay)*u;local length=math.sqrt(dx*dx+dy*dy);local h=(weight or 2.6)*u
   local o=p:box(x+(ax+bx)*u/2-length/2,y+(ay+by)*u/2-h/2,length,h,c,1,h/2)
   if o then o.Rotation=math.deg(math.atan2(dy,dx)) end
  end
  local function box(ax,ay,w,h,ink,r) p:box(x+ax*u,y+ay*u,w*u,h*u,ink or c,1,(r or 0)*u) end
  if name=="PLUS" then line(12,2,12,22);line(2,12,22,12)
  elseif name=="BACK" then line(15,3,6,12);line(6,12,15,21)
  elseif name=="GEAR" then
   box(3,3,18,18,c,9)
   for i=0,7 do local a=i*math.pi/4;line(12+math.cos(a)*8,12+math.sin(a)*8,12+math.cos(a)*11,12+math.sin(a)*11,5) end
   box(8,8,8,8,currentPalette().header,4)
  elseif name=="SAVE" then box(3,2,19,20,c,1);box(7,3,9,6,currentPalette().field);box(7,13,11,7,currentPalette().field,1)
  elseif name=="LOAD" then box(4,3,16,19,c,2);box(7,1,10,4,c,1);local ink=c;c=currentPalette().field;line(12,8,12,17,1.8);line(8,13,12,17,1.8);line(12,17,16,13,1.8);c=ink
  elseif name=="DELETE" then box(6,7,12,15,c,1);line(4,4,20,4);line(9,1,15,1)
  elseif name=="REFRESH" then
   for _,start in ipairs({-2.75,.39}) do for i=0,11 do local a=start+i*2.4/12;local b=start+(i+1)*2.4/12;line(12+8*math.cos(a),12+8*math.sin(a),12+8*math.cos(b),12+8*math.sin(b)) end end
   line(20,10,15,10);line(20,10,20,5);line(4,14,9,14);line(4,14,4,19)
  end
 end
 local function configNames() config.names={};for name in pairs(config.values) do config.names[#config.names+1]=name end;table.sort(config.names,function(a,b)return a:lower()<b:lower() end) end
 local function configButton(text,x,y,w,action,data)
  local p=currentPalette();front:box(x,y,w,18,p.field,1,3);if text=="REFRESH" or text=="SAVE" or text=="LOAD" or text=="DELETE" then drawIcon(front,text,x+(w-10)/2,y+4,10,p.line) else front:text(text,x,y+9,7.5,w,p.text,false,Enum.TextXAlignment.Center) end;hit(rect(x,y,w,18),action,data)
 end
 local function drawConfig(dt)
  local p=currentPalette();editor.Visible=false;jsonEditor.Visible=false
  if not config.open then
   local chip=rect(width-59,math.max(4,height*.112-2),60,11.75)
   front:box(chip.x,chip.y,chip.w,chip.h,0x131316,1,3.875);front:text("Configurations",chip.x+2,chip.y+chip.h/2,7.25,chip.w-3.75,p.text,true);hit(chip,"configOpen");return
  end
  local x,y=config.x,config.y;local page=config.page
  local listH=math.min(144,math.max(24,#config.names*24),math.max(24,height-y-H-62))
  local body=page=="Configurations" and listH+48 or page=="Add" and 51 or page=="Settings" and 92 or page=="JSON" and 133 or 86
  front:box(x,y,W,H+body,p.body,.8,7);front:box(x,y,W,H,p.header,1,7);front:box(x,y+H-7,W,7,p.header,1)
  front:text(page,x+(page=="Configurations" and P or P+10),y+H/2,9.2,W-50,p.text)
  hit(rect(x,y,W,H),"configHeader")
  if page=="Configurations" then
   drawIcon(front,"PLUS",x+W-37,y+6,10,p.line);hit(rect(x+W-40,y+3,16,16),"configPage","Add")
   drawIcon(front,"GEAR",x+W-21,y+6,10,p.line);hit(rect(x+W-24,y+3,18,16),"configPage","Settings")
   local listTop=y+H+3;front:box(x+8,listTop,W-16,listH,p.field,1,8)
   hit(rect(x+8,listTop,W-16,listH),"configList")
   if #config.names==0 then front:text("No configurations",x+14,listTop+12,8.3,W-28,p.line) end
   config.scroll=math.clamp(config.scroll,0,math.max(0,#config.names*24-listH))
   for i,name in ipairs(config.names) do
    local rowY=listTop+(i-1)*24-config.scroll
    if rowY>=listTop and rowY+24<=listTop+listH+.01 then
     if name==config.selected then front:box(x+8,rowY,W-16,24,p.accent,1,3) end
     front:text(name..".json",x+14,rowY+12,8.3,W-28,name==config.selected and p.enabledText or p.text)
     hit(rect(x+8,rowY,W-16,24),"configSelect",name)
    end
   end
   local by=listTop+listH+5;local cell=(W-16-18)/4
   for i,item in ipairs({{"REFRESH","configRefresh"},{"SAVE","configSave"},{"LOAD","configLoad"},{"DELETE","configDelete"}}) do configButton(item[1],x+8+(i-1)*(cell+6),by,cell,item[2]) end
   configButton("Export",x+8,by+20,65,"configExport");configButton("Import",x+79,by+20,65,"configPage","JSON")
  else
   drawIcon(front,"BACK",x+8,y+6,8,p.line);hit(rect(x+4,y+3,15,16),"configPage",page=="Targets" and "Settings" or "Configurations")
   if page=="Add" then
    front:box(x+8,y+H+3,W-16,21,p.outline,1,1.5);front:box(x+8.8,y+H+3.8,W-17.6,19.4,0x111014,1,1)
    editor.Visible=true;editor.Position=UDim2.fromOffset(x+14,y+H+5);editor.Size=UDim2.fromOffset(W-28,17);editor.TextColor3=rgb(p.text);editor.PlaceholderColor3=rgb(p.line)
    hit(rect(x+8,y+H+3,W-16,21),"configFocus")
    configButton("Create",x+8,y+H+30,65,"configCreate",false);configButton("Blank",x+79,y+H+30,65,"configCreate",true)
   elseif page=="Settings" then
    configButton("Targets",x+8,y+H+6,W-16,"configPage","Targets")
    configButton("Opai Color: "..selectedTheme(),x+8,y+H+29,W-16,"theme")
    configButton("Scale: "..tostring(k),x+8,y+H+52,W-16,"scale")
    configButton("Close",x+8,y+H+75,W-16,"configClose")
   elseif page=="Targets" and rows.Targets then
    for i,s in ipairs(rows.Targets.def.settings) do drawSetting(front,s,rows.Targets,x,y+H+3+(i-1)*40,x,y+H+3+(i-1)*40,nil,dt) end
   elseif page=="JSON" then
    jsonEditor.Visible=true;jsonEditor.Position=UDim2.fromOffset(x+8,y+H+4);jsonEditor.Size=UDim2.fromOffset(W-16,99);jsonEditor.BackgroundColor3=rgb(p.field);jsonEditor.TextColor3=rgb(p.text);jsonEditor.PlaceholderColor3=rgb(p.line)
    hit(rect(x+8,y+H+4,W-16,99),"jsonFocus")
    configButton("Import JSON",x+8,y+H+109,W-16,"configImport")
   end
  end
  if config.message~="" and os.clock()<config.messageUntil then front:box(x+3,y+H+body+3,W-6,15,p.field,1,3);front:text(config.message,x+7,y+H+body+10.5,7,W-14,0xFF9999) end
  hit(rect(x,y+H,W,body),"configBlock")
  -- The block must remain behind page controls in hit testing.
  local block=table.remove(hits);local at=#hits+1;for i,h in ipairs(hits) do if h.action=="configHeader" then at=i;break end end;table.insert(hits,at,block)
 end

  local styleNames={Neverlose=true,Opai=true}
 if options.Style then assert(styleNames[options.Style],"Unknown style") end
  local function selectedStyle() local name=state.ClickGUI and state.ClickGUI.settings.Style or options.Style;return styleNames[name] and name or "Neverlose" end
  function api:SetStyle(name) assert(styleNames[name],"Unknown style");options.Style=name;if state.ClickGUI then state.ClickGUI.settings.Style=name end;notify("ClickGUI","Style",name) end
 local altRoot=new("Frame",root,{Name="StyleWindow",BackgroundTransparency=1,ZIndex=100,Visible=false})
 local altScale=new("UIScale",altRoot,{Scale=1})
   local altGlass=new("Frame",altRoot,{Name="LocalFrost",BackgroundColor3=rgb(0x121924),BackgroundTransparency=.58,Size=UDim2.fromOffset(760,620),ZIndex=0,Visible=false})
  new("UICorner",altGlass,{CornerRadius=UDim.new(0,4)})
   new("UIGradient",altGlass,{Color=ColorSequence.new(rgb(0x1D2A37),rgb(0x090D11)),Rotation=26})
  local altSoftShadow
  pcall(function() altSoftShadow=new("UIShadow",altGlass,{Color=rgb(0x000000),BlurRadius=UDim.new(0,18),Spread=UDim2.fromOffset(4,4),Offset=UDim2.fromOffset(0,5),Transparency=.43}) end)
  local blurPane={active=false,unsupported=false}
   local altPaint=pool(altRoot)
   altPaint.fontOverride=opaiFont(false)
 local altBody=new("Frame",altRoot,{Name="Content",BackgroundTransparency=1,ClipsDescendants=true,ZIndex=100})
   local altContent=pool(altBody)
   altContent.fontOverride=opaiFont(false)
    local searchBox=new("TextBox",overlay,{Name="Search",Text="",PlaceholderText="Search",ClearTextOnFocus=false,BackgroundTransparency=1,Font=opaiFont(false),TextSize=12,TextColor3=rgb(0xBDC3C7),TextXAlignment=Enum.TextXAlignment.Left,Visible=false,ZIndex=3000})
    local altName=new("TextBox",overlay,{Name="PresetName",Text="",PlaceholderText="Configuration name",ClearTextOnFocus=false,BackgroundTransparency=1,Font=opaiFont(false),TextSize=12,TextColor3=rgb(0xBDC3C7),TextXAlignment=Enum.TextXAlignment.Left,Visible=false,ZIndex=3000})
 local appearanceRoot=new("Frame",overlay,{Name="Appearance",BackgroundTransparency=1,Visible=false,ZIndex=1000})
 local appearanceScale=new("UIScale",appearanceRoot,{Scale=1})
 local appearancePaint=pool(appearanceRoot)
  appearancePaint.fontOverride=opaiFont(false)
  local accentBox=new("TextBox",overlay,{Name="AccentHex",Text="",PlaceholderText="#RRGGBB",ClearTextOnFocus=false,BackgroundTransparency=1,Font=opaiFont(false),TextSize=10,TextColor3=rgb(0xE4E1E6),TextXAlignment=Enum.TextXAlignment.Left,Visible=false,ZIndex=3000})
 local appearanceError=""
 connect(accentBox.FocusLost,function()
  if not appearanceOpen then return end
  local color=parseAccent(accentBox.Text)
  if color then api:SetAccent(color);appearanceError="" else appearanceError="Use six hexadecimal digits: #RRGGBB" end
 end)
 local function appearancePoint(x,y,w,h) local a=appearanceGeometry;return rect(a.x+x*a.s,a.y+y*a.s,w*a.s,h*a.s) end
 local appearanceRanges={UI={.5,4},HUD={.5,4},Speed={.5,3},Glow={0,1},Island={0,100}}
 local function appearanceSlide(x)
  if not appearanceSliding then return end;local kind=appearanceSliding;local a=appearanceGeometry;local range=appearanceRanges[kind]
  local f=math.clamp(((x-a.x)/a.s-12)/200,0,1);local value=math.round((range[1]+f*(range[2]-range[1]))*20)/20
  if kind=="UI" then api:SetScale(value) elseif kind=="HUD" then api:SetHUDScale(value) elseif kind=="Speed" then api:SetAnimationSpeed(value) elseif kind=="Island" then api:SetIslandShadow(math.round(value)) else api:SetGlowStrength(value) end
 end
  local function drawAppearance(frameDelta)
   appearanceT=animations and ease(appearanceT,appearanceOpen and 1 or 0,math.min(frameDelta,.1),11) or (appearanceOpen and 1 or 0)
   local reveal=appearanceT*appearanceT*(3-2*appearanceT)
   appearanceRoot.Visible=appearanceOpen or appearanceT>.01;accentBox.Visible=appearanceOpen
  if not appearanceRoot.Visible then return end
  searchBox.Visible=false;altName.Visible=false;editor.Visible=false;jsonEditor.Visible=false
    local h=354;local base=math.max(.05,math.min(2/k,(width-8)/224,(height-8)/h));local s=base*(.94+.06*reveal);local x,y=(width-224*s)/2,(height-h*s)/2
   appearanceGeometry={x=x,y=y,s=s};appearanceRoot.Position=UDim2.fromOffset(x,y);appearanceRoot.Size=UDim2.fromOffset(224,h);appearanceScale.Scale=s
   local p=appearancePaint;p.alpha=reveal;p:begin();local pal=currentPalette();p:box(0,0,224,h,pal.header,1,9)
   p:stroke(0,0,224,h,pal.outline,.45,9,1)
   p:text("Appearance",12,17,11,175,pal.text);p:text("×",200,17,15,14,pal.text);if appearanceOpen then hit(rect(0,0,width,height),"appearanceOutside");hit(appearancePoint(0,0,224,h),"appearanceBlock");hit(appearancePoint(196,6,22,22),"appearanceClose") end
  local function slider(label,value,yy,kind)
   local range=appearanceRanges[kind];p:text(label,12,yy,9,150,pal.text);p:text(kind=="Glow" and tostring(math.round(value*100)).."%" or kind=="Island" and tostring(math.round(value)).."%" or string.format("%.2fx",value),158,yy,9,54,pal.text,false,Enum.TextXAlignment.Right)
   p:box(12,yy+15,200,3,pal.track,1,1.5);local f=(value-range[1])/(range[2]-range[1]);p:box(12,yy+15,200*f,3,pal.accent,1,1.5);p:box(8+200*f,yy+12,8,9,pal.accent,1,4)
    if appearanceOpen then hit(appearancePoint(8,yy+8,208,17),"appearanceScale",kind) end
  end
   slider("UI scale",k,41,"UI");slider("HUD scale",hudScale,82,"HUD")
  p:text("Accent color",12,120,9,175,pal.text)
  local colors={0xBBC3FF,0xFFB4AA,0x3A85E2,0x00C6FF,0x00E676,0xFFA500,0xFF64C8,0xFF5722}
   for i,c in ipairs(colors) do local xx=12+(i-1)*25.5;p:box(xx,133,21,17,c,1,4);if customAccent==c and themeEffect=="Source" then p:stroke(xx,133,21,17,0xFFFFFF,1,4,1.5) end;if appearanceOpen then hit(appearancePoint(xx,133,21,17),"appearanceAccent",c) end end
  p:box(12,158,126,24,pal.field,1,4);p:box(145,158,67,24,pal.field,1,4);p:text("Apply",145,170,9,67,pal.text,false,Enum.TextXAlignment.Center)
  if Input:GetFocusedTextBox()~=accentBox then accentBox.Text=string.format("#%06X",customAccent or pal.accent) end
   accentBox.Position=UDim2.fromOffset(x+18*s,y+162*s);accentBox.Size=UDim2.fromOffset(114*s,16*s);accentBox.TextSize=10*s;accentBox.TextTransparency=1-reveal;accentBox.TextColor3=rgb(pal.text)
   if appearanceOpen then hit(appearancePoint(145,158,67,24),"appearanceApply") end
  local function button(label,xx,yy,w,action,data,selected)
    p:box(xx,yy,w,22,selected and pal.accent or pal.field,1,4);p:text(label,xx,yy+11,8,w,selected and pal.enabledText or pal.text,false,Enum.TextXAlignment.Center);if appearanceOpen then hit(appearancePoint(xx,yy,w,22),action,data) end
  end
  button("Source colors",12,191,96,"appearanceReset",nil,themeEffect=="Source")
   button("Flowing colors",116,191,96,"appearanceEffect","FlowingGlow",themeEffect=="FlowingGlow")
  button("Animations: "..(animations and "On" or "Off"),12,221,200,"appearanceAnimations",nil,animations)
   slider("Animation speed",animationSpeed,257,"Speed");slider("Island shadow",islandShadow,296,"Island")
    if appearanceError~="" then p:text(appearanceError,12,340,6.5,200,0xFF8585) else p:text("F7 · appearance     Ctrl + wheel · UI scale",12,340,6.5,200,pal.line) end
  p:finish()
 end

 local alt={x=0,y=0,s=1,scroll=0,target=0,max=0,nav=1,positions={},windows={},windowOrder={},sectionOffsets={},selection=96}
 local navNames={"Combat","Targets","Movement","Player","Visuals","Misc","HUD Editor","Configs"}
 local navY={96,132,200,236,304,372,408,444}
 local modernNames={"Combat","Movement","Visuals","Player","Other"}
 local modernCats={"Combat","Movement","Visual","Player","Misc"}
 local function altRect(r) return rect(alt.x+r.x*alt.s,alt.y+r.y*alt.s,r.w*alt.s,r.h*alt.s) end
 local function altHit(r,action,data,clip) if clip then r=intersection(r,clip) end;hit(altRect(r),action,data) end
 local function textWidth(text,size) return TextService:GetTextSize(tostring(text),size,Enum.Font.GothamMedium,Vector2.new(10000,10000)).X end
 local function line(p,x,y,xx,yy,c,t)
  local dx,dy=xx-x,yy-y;local len=math.sqrt(dx*dx+dy*dy);local o=p:box((x+xx-len)/2,(y+yy-(t or 1))/2,len,t or 1,c,1,(t or 1)/2);if o then o.Rotation=math.deg(math.atan2(dy,dx)) end
 end
 local function categoryIcon(p,index,x,y,size,c)
  if index==1 or index==2 then
   for i=0,15 do local a=i*math.pi/8;local b=(i+1)*math.pi/8;line(p,x+size/2+math.cos(a)*size*.3,y+size/2+math.sin(a)*size*.3,x+size/2+math.cos(b)*size*.3,y+size/2+math.sin(b)*size*.3,c,.8) end
   line(p,x,y+size/2,x+size,y+size/2,c,.8);line(p,x+size/2,y,x+size/2,y+size,c,.8)
  elseif index==3 then line(p,x,y,x+size*.45,y+size/2,c);line(p,x+size*.45,y+size/2,x,y+size,c);line(p,x+size*.55,y,x+size,y+size/2,c);line(p,x+size,y+size/2,x+size*.55,y+size,c)
  elseif index==4 then p:box(x+size*.35,y,size*.3,size*.3,c,1,size*.15);p:box(x+size*.15,y+size*.45,size*.7,size*.5,c,1,size*.25)
  elseif index==5 then p:box(x,y+size*.2,size,size*.6,c,1,size*.3);p:box(x+size*.35,y+size*.35,size*.3,size*.3,0x080808,1,size*.15)
  else for i=0,2 do p:box(x+i*size*.33,y+size*.4,size*.15,size*.15,c,1,size*.08) end end
 end
 local function checkbox(p,x,y,t,style,glass)
  if style=="Neverlose" then
   local outer=p:box(x,y,28,12,0x111518,1,6);outer.BackgroundColor3=rgb(0x111518):Lerp(rgb(mixColor(accentColor(0x3A85E2),0x000000,.84)),t)
   p:box(x+6+16*t-8.5,y+6-8.5,17,17,accentColor(0x3A85E2),t*.094,8.5)
   local knob=p:box(x+6+16*t-5.5,y+.5,11,11,0x586168,1,5.5);knob.BackgroundColor3=rgb(0x586168):Lerp(rgb(accentColor(0x3A85E2)),t)
  else
   local track=p:box(x,y,13,8,glass and 0x5D687C or 0x565B64,1,4);track.BackgroundColor3=rgb(glass and 0x5D687C or 0x565B64):Lerp(rgb(glass and accentColor(0x6A98E7) or accentColor(0x9747FF)),t)
   p:box(x+1+5*t,y+1,6,6,0xFFFFFF,1,3)
  end
 end
 local function modernPanel(p,x,y,w,h,r,glass)
  for i=3,1,-1 do p:box(x-i*2,y-i*2,w+i*4,h+i*4,0x000000,.086,r+i*2) end
  if glass then p:gradient(x,y,w,h,0xF3F7FF,0xE7D9EF,.22,r);p:stroke(x+.75,y+.75,w-1.5,h-1.5,0xFFFFFF,.52,r-.75,.75)
  else p:box(x,y,w,h,0x0C0D12,.95,r) end
 end
 local function styleField(p,r,label,action,data,clip)
  p:stroke(r.x,r.y,r.w,r.h,0x202325,1,2,1);p:box(r.x+1,r.y+1,r.w-2,r.h-2,0x0E1011,1,1)
  p:text(label,r.x+7,r.y+r.h/2,11.5,r.w-22,0xBDC3C7,true)
  if action=="altConfigs" then line(p,r.x+r.w-13,r.y+r.h/2-1.5,r.x+r.w-10,r.y+r.h/2+1.5,0x8B979F,1.4);line(p,r.x+r.w-10,r.y+r.h/2+1.5,r.x+r.w-7,r.y+r.h/2-1.5,0x8B979F,1.4) end
  if action then altHit(r,action,data,clip) end
 end
  local function drawNeverlose(dt)
   local p=altPaint;local frost=state.ClickGUI and state.ClickGUI.settings["Local Blur"]~=false
    p:gradient(0,0,184,620,0x090A0A,0x0D0E0C,frost and .52 or .82,4);p:box(180,0,580,620,0x080808,frost and .48 or 1,4)
    if frost then p:gradient(182,1,576,63,0x2A3B4A,0x121A22,.17,3);p:stroke(0,0,760,620,0x51585C,.3,4,1) end
   p:box(180,0,1,620,0x242525,1);p:box(180,64,580,1,0x1C1D1D,1)
  p:text("SYNTAX",18,35,24,160,0xF1FAFD)
  for i,name in ipairs({"Combat","Player","Visuals","Miscellaneous"}) do p:text(name,20,({79,183,287,355})[i],10.5,145,0x646B6D) end
  alt.selection=ease(alt.selection,navY[alt.nav],dt,30);p:box(10,alt.selection,160,29,0x3D3D3B,1,3)
  for i,name in ipairs(navNames) do categoryIcon(p,i,21,navY[i]+7.5,14,accentColor(0x3A85E2));p:text(name,47,navY[i]+14.5,12.5,115,i==alt.nav and 0xEDF3F5 or 0xBDC3C7);altHit(rect(10,navY[i],160,29),"altNav",i) end
   p:box(0,558,180,1,0x30322F,1);p:box(13,572,34,34,0x20323F,1,17)
   local avatarId=Players.LocalPlayer.UserId
   if avatarId and avatarId>0 then p:image("rbxthumb://type=AvatarHeadShot&id="..avatarId.."&w=150&h=150",13,572,34,34,17) end
   p:text(options.Username or Players.LocalPlayer.DisplayName or "Player",57,581,12,113,0xEDF3F5);p:text("Syntax",57,597,10.5,113,accentColor(0x3A85E2))
  styleField(p,rect(202,19,330,27),"",nil,nil);styleField(p,rect(544,19,70,27),"Save","altSave");styleField(p,rect(626,19,112,27),config.selected or "Preset","altConfigs")
  searchBox.Visible=true;searchBox.PlaceholderText="Press CTRL+F to search within GUI";searchBox.TextSize=12*alt.s;searchBox.TextColor3=rgb(0xBDC3C7);searchBox.PlaceholderColor3=rgb(0x697277);searchBox.Position=UDim2.fromOffset(alt.x+232*alt.s,alt.y+21*alt.s);searchBox.Size=UDim2.fromOffset(291*alt.s,23*alt.s)
  categoryIcon(p,1,211,26,11,0x677077)
  local cr=rect(202,84,536,516);altBody.Position=UDim2.fromOffset(cr.x,cr.y);altBody.Size=UDim2.fromOffset(cr.w,cr.h)
  local content=altContent
  if alt.nav==8 then
   styleField(p,rect(202,84,344,28),"",nil,nil);styleField(p,rect(558,84,180,28),"Create configuration","altCreate")
   altName.Visible=true;altName.Position=UDim2.fromOffset(alt.x+212*alt.s,alt.y+86*alt.s);altName.Size=UDim2.fromOffset(324*alt.s,24*alt.s);altName.TextSize=12*alt.s
   p:text("Saved configurations",202,135,12,536,0xEDF3F5);p:box(202,149,536,1,0x202222,1)
   alt.max=math.max(0,#config.names*66-444)
   for i,name in ipairs(config.names) do local yy=72+(i-1)*66-alt.scroll
    if yy+56>72 and yy<516 then
     content:box(0,yy,536,56,name==config.selected and 0x101922 or 0x0E1113,1,3);content:text(name,39,yy+18,13,270,0xEDF3F5);content:text("Saved in this session",39,yy+36,10.5,270,0x73828C)
     for j,entry in ipairs({{"Load","altLoad"},{"Save","altUpdate"},{"Delete","altDelete"}}) do local rr=rect(202+318+(j-1)*70,84+yy+15,62,27);content:box(rr.x-202,yy+15,62,27,0x173044,1,2);content:text(entry[1],rr.x-195,yy+28.5,11,50,0xBDC3C7);altHit(rr,entry[2],name,rect(202,156,536,444)) end
    end
   end
  else
   local members={};local needle=searchBox.Text:lower():gsub("%s","")
   local cat=({"Combat","Targets","Movement","Player","Visual","Misc"})[alt.nav]
   if alt.nav==2 then members={rows.Targets} else for _,row in pairs(rows) do if not row.def.hidden and row.def.category==cat and (needle=="" or row.def.name:lower():gsub("%s",""):find(needle,1,true)) then members[#members+1]=row end end end
   table.sort(members,function(a,b)return a.def.name:lower()<b.def.name:lower() end)
   local ids={};for _,row in ipairs(members) do ids[#ids+1]=row.def.id end;local packingKey=table.concat(ids,"|")
   if alt.packingKey~=packingKey then alt.packingKey=packingKey;alt.packing={} end
   local ends={0,0}
   for _,row in ipairs(members) do
    local st=state[row.def.id];local settings={};for _,s in ipairs(row.def.settings or {}) do if condition(s.when,st.settings) then settings[#settings+1]=s end end
    if row.nlExpanded==nil then row.nlExpanded=true;row.nlReveal=1 end
    row.nlReveal=ease(row.nlReveal,row.nlExpanded and 1 or 0,dt,30)
    local height=28+(29*(#settings+(row.def.hidden and 0 or 1)))*row.nlReveal
    local col=alt.packing[row.def.id] or (ends[1]<=ends[2] and 1 or 2);alt.packing[row.def.id]=col;local xx=(col-1)*280;local yy=ends[col]-alt.scroll;ends[col]+=height+18
    local sectionClip=intersection(cr,rect(202+xx,84+yy,256,height))
      if not row.nlFrame then row.nlFrame=new("Frame",altBody,{Name=row.def.id.."Section",BackgroundTransparency=1,ClipsDescendants=true,ZIndex=50});row.nlPool=pool(row.nlFrame);row.nlPool.fontOverride=opaiFont(false) end
    row.nlFrame.Visible=true;row.nlFrame.Position=UDim2.fromOffset(xx,yy);row.nlFrame.Size=UDim2.fromOffset(256,height)
    local content=row.nlPool;content.offsetX=-xx;content.offsetY=-yy;content:begin();content:text(row.def.name,xx+8,yy+10,13,172,0xEDF3F5)
    content:box(xx+189,yy+3,48,18,0x101314,1,2);content:text(binding==row and "PRESS KEY" or (row.def.hidden and "GLOBAL" or st.key=="Unknown" and "NONE" or st.key),xx+194,yy+12,9,39,0x77858E)
    local cx,cy=xx+249,yy+12;if row.nlExpanded then line(content,cx-3,cy-1.5,cx,cy+1.5,0x65717A,1.4);line(content,cx,cy+1.5,cx+3,cy-1.5,0x65717A,1.4) else line(content,cx-1.5,cy-3,cx+1.5,cy,0x65717A,1.4);line(content,cx+1.5,cy,cx-1.5,cy+3,0x65717A,1.4) end;altHit(rect(202+xx,84+yy,256,28),"nlHeader",row,cr)
    altHit(rect(202+xx+189,84+yy+3,48,18),"bind",row,cr)
    content:box(xx+6,yy+24,250,1,0x222425,1)
    local entries={};if not row.def.hidden then entries[#entries+1]={name="Enabled",type="enabled"} end;for _,s in ipairs(settings) do entries[#entries+1]=s end
    for i,s in ipairs(entries) do local ry=yy+28+(i-1)*29;local rr=rect(202+xx,84+ry,256,29)
     if intersection(rr,sectionClip).h>0 then
      local value=s.type=="enabled" and st.enabled or st.settings[s.name];local bool=s.type=="toggle" or s.type=="enabled"
      content:text(s.rawLabel or s.label or s.name,xx+8,ry+14.5,11.5,bool and 216 or 118,0xBDC3C7,true)
      if bool then local t=ease(row.animations[s.name] or (value and 1 or 0),value and 1 or 0,dt,30);row.animations[s.name]=t;checkbox(content,xx+227,ry+8.5,t,"Neverlose");altHit(rr,s.type=="enabled" and "module" or "toggle",s.type=="enabled" and row or {row=row,s=s},sectionClip)
      elseif s.type=="slider" then local f=(value-s.min)/math.max(.000001,s.max-s.min);local tr=rect(202+xx+130,84+ry+8.5,88,12)
       content:box(xx+130,ry+13.5,88,2,0x333A40,1,1);content:box(xx+130,ry+13.5,88*f,2,mixColor(accentColor(0x3A85E2),0x000000,.55),1,1);content:box(xx+130+88*f-5.4,ry+9.1,10.8,10.8,accentColor(0x3A85E2),1,5.4);content:box(xx+225,ry+5,31,19,0x0E1113,1,1);content:text(numberText(value,s.step),xx+228,ry+14.5,10,25,0xBDC3C7)
       local physical=altRect(tr);altHit(tr,"slider",{row=row,s=s,left=physical.x,width=physical.w},sectionClip)
       else
        local field=rect(202+xx+130,84+ry+4.5,126,20)
        local opened=dropdown and dropdown.row==row and dropdown.s==s
        local choiceKey="choiceOpen:"..s.name
        local reveal=animations and ease(row.animations[choiceKey] or 0,opened and 1 or 0,dt,18) or (opened and 1 or 0)
        row.animations[choiceKey]=reveal
        content:box(xx+130,ry+4.5,126,20,mixColor(0x0B0C0D,0x17212A,reveal),1,1.5)
        if reveal>.001 then content:box(xx+131,ry+22.5,124,1,accentColor(0x3A85E2),reveal) end
        content:text(choiceLabel(s,value),xx+137,ry+14.5,11.5,101,mixColor(0xBDC3C7,0xEAF2F6,reveal),true)
        local direction=1-2*reveal;local arrowY=ry+14.5;line(content,xx+243,arrowY-1.5*direction,xx+246,arrowY+1.5*direction,0x8B979F,1.4);line(content,xx+246,arrowY+1.5*direction,xx+249,arrowY-1.5*direction,0x8B979F,1.4)
       local anchor=altRect(field);altHit(field,"choice",{row=row,s=s,x=anchor.x,y=anchor.y+anchor.h,w=anchor.w,style="Neverlose"},sectionClip)
      end
     end
    end
    content:finish()
   end
   alt.max=math.max(0,math.max(ends[1],ends[2])-18-516)
   if #members==0 then content:text("No modules found",12,28,13,300,0xBDC3C7) end
  end
  alt.target=math.clamp(alt.target,0,alt.max)
  if alt.max>0 then local th=math.max(24,516*516/(516+alt.max));p:box(748,84+alt.scroll/alt.max*(516-th),3,th,0x424C54,1,1.5) end
  altHit(rect(180,0,580,16),"altDrag")
  if alt.max>0 then altHit(rect(744,84,11,516),"altScrollbar") end;altHit(cr,"altScroll",nil)
  local blocker=table.remove(hits);table.insert(hits,1,blocker)
 end
 local function drawModernSettings(row,dt,glass)
  local win=alt.windows[row.def.id]
  if not win then local f=new("Frame",root,{Name=row.def.id.."ModernSettings",BackgroundTransparency=1,ZIndex=200});local b=new("Frame",f,{Name="Content",BackgroundTransparency=1,ClipsDescendants=true,ZIndex=100});win={id=row.def.id,frame=f,body=b,p=pool(f),content=pool(b),x=math.clamp((mx>=0 and mx<=width and mx or alt.x+126)+8,4,math.max(4,width-156)),y=math.clamp((my>=0 and my<=height and my or alt.y+34)+8,4,math.max(4,height-204)),scroll=0,target=0,multi={}};alt.windows[row.def.id]=win end
  win.frame.Visible=true;local p=win.p;local content=win.content;p:begin();content:begin()
  local st=state[row.def.id];local entries={{name="Enabled",type="enabled"}};local total=18
  for _,s in ipairs(row.def.settings or {}) do if condition(s.when,st.settings) then entries[#entries+1]=s;total+=s.type=="slider" and 26 or 18;if s.type=="multi" and win.multi[s.name] then for _,option in ipairs(s.options) do entries[#entries+1]={type="option",s=s,option=option};total+=18 end end end end
  local h=math.min(200,total+29);win.h=h;win.max=math.max(0,total-(h-29));win.target=math.clamp(win.target,0,win.max);win.scroll=ease(win.scroll,win.target,dt,14)
  win.frame.Position=UDim2.fromOffset(win.x,win.y);win.frame.Size=UDim2.fromOffset(152,h);win.body.Position=UDim2.fromOffset(0,24);win.body.Size=UDim2.fromOffset(152,h-29)
  if glass then p:box(0,0,152,h,0xDFE6F4,.96,11) end;modernPanel(p,0,0,152,h,11,glass);p:text(row.def.id,9,16,9,125,glass and 0x2A344A or 0xFFFFFF);p:text("×",135,13,13,9,glass and 0x3F4B66 or 0xB3B3B3)
  hit(rect(win.x,win.y,152,24),"modernDrag",win);hit(rect(win.x+131,win.y+5,17,17),"modernClose",row);local clip=rect(win.x,win.y+24,152,h-29);hit(clip,"modernScroll",win)
  local y=-win.scroll;local textColor=glass and 0x3F4B66 or 0xB3B3B3;local accent=glass and accentColor(0x648FE8) or accentColor(0x9747FF)
  for _,s in ipairs(entries) do local rh=s.type=="slider" and 26 or 18;local rr=rect(win.x,win.y+24+y,152,rh)
   if intersection(rr,clip).h>0 then
    local value=s.type=="enabled" and st.enabled or s.type=="option" and table.find(st.settings[s.s.name],s.option)~=nil or st.settings[s.name]
    content:text(s.type=="option" and s.option or s.rawLabel or s.label or s.name,s.type=="option" and 17 or 10,y+12,8,s.type=="slider" and 95 or ((s.type=="select" or s.type=="multi") and 70 or 120),textColor,true)
    if s.type=="toggle" or s.type=="enabled" or s.type=="option" then
     local t=value and 1 or 0;checkbox(content,130,y+5,t,"Modern",glass);hit(rr,s.type=="enabled" and "module" or s.type=="option" and "modernOption" or "toggle",s.type=="enabled" and row or s.type=="option" and {row=row,s=s.s,option=s.option} or {row=row,s=s},clip)
    elseif s.type=="slider" then
     local f=(value-s.min)/math.max(.000001,s.max-s.min);content:text(numberText(value,s.step),105,y+11.5,7,37,textColor,false,Enum.TextXAlignment.Right);content:box(10,y+20,132,2,glass and 0x33425E or 0xFFFFFF,glass and .23 or .18,1);content:box(10,y+20,132*f,2,accent,1,1);content:box(10+132*f-1.5,y+17,3,8,0xFFFFFF,1,1.5);hit(rect(win.x+7,win.y+24+y+15,138,11),"slider",{row=row,s=s,left=win.x+10,width=132},clip)
    else content:text(choiceLabel(s,value),74,y+11.5,7,68,accent,false,Enum.TextXAlignment.Right);hit(rr,s.type=="multi" and "modernMulti" or "modernCycle",{row=row,s=s,win=win},clip) end
    content:box(0,y+rh,152,.5,glass and 0x2D3B55 or 0xFFFFFF,glass and .19 or .04)
   end;y+=rh
  end
  p:finish();content:finish()
 end
 local function drawModern(dt)
  local p=altPaint;local glass=state.ClickGUI and state.ClickGUI.settings.Interface=="LiquidGlass";local text=glass and 0x2A344A or 0xFFFFFF;local muted=glass and 0x3F4B66 or 0xB3B3B3;local accent=glass and accentColor(0x648FE8) or accentColor(0x9747FF)
  modernPanel(p,0,0,500,343,16,glass);if glass then p:gradient(5,5,109,333,0xF6FAFF,0xDDE7F5,.24,12) else p:box(5,5,109,333,0x23252E,.55,12) end
  p:box(13,13,93,14,0xFFFFFF,glass and .27 or .15,3);searchBox.Visible=true;searchBox.PlaceholderText="Search";searchBox.TextSize=6*alt.s;searchBox.TextColor3=rgb(text);searchBox.PlaceholderColor3=rgb(muted);searchBox.Position=UDim2.fromOffset(alt.x+27*alt.s,alt.y+15*alt.s);searchBox.Size=UDim2.fromOffset(75*alt.s,10*alt.s)
  categoryIcon(p,1,16,16,8,muted);p:text("Functions",14,40.5,6,90,muted,true)
  for i,name in ipairs(modernNames) do local y=43+(i-1)*18;if alt.nav==i then p:box(12,y,95,16,accent,1,4) end;categoryIcon(p,({1,3,5,4,6})[i],18,y+4,8,alt.nav==i and 0xFFFFFF or muted);p:text(name,32,y+10.5,7,70,alt.nav==i and 0xFFFFFF or muted);altHit(rect(12,y,95,16),"modernNav",i) end
  p:text("Configs",32,149.5,7,70,muted);altHit(rect(12,139,95,16),"altConfigs");
  altBody.Position=UDim2.fromOffset(120,0);altBody.Size=UDim2.fromOffset(380,341);local content=altContent;local cr=rect(120,1,380,341);local y=0;local needle=searchBox.Text:lower()
  for ci,cat in ipairs(modernCats) do
   local list={};for _,row in pairs(rows) do if row.def.category==cat and not row.def.hidden and (needle=="" or row.def.name:lower():find(needle,1,true)) then list[#list+1]=row end end;table.sort(list,function(a,b)return a.def.name:lower()<b.def.name:lower() end)
   if #list>0 then
    alt.sectionOffsets[ci]=y;local hy=16+y-alt.scroll;categoryIcon(content,({1,3,5,4,6})[ci],9,hy,10,text);content:text(modernNames[ci],23,hy+9,12,220,text)
    for i,row in ipairs(list) do local cx=7+((i-1)%2)*183.5;local cy=y+33+math.floor((i-1)/2)*34-alt.scroll
     if cy+28>0 and cy<343 then
      local st=state[row.def.id];row.enabled=ease(row.enabled,st.enabled and 1 or 0,dt,30)
      if glass then content:gradient(cx,cy,177,28,0xFFFFFF,0xEAF0FF,.24,7);content:stroke(cx,cy,177,28,0xFFFFFF,.18,7,.7) else content:box(cx,cy,177,28,0xFFFFFF,.06,6) end
      local hovered=not appearanceOpen and not dropdown and inside(altRect(rect(120+cx,cy,177,28)),mx,my)
      row.hover=ease(row.hover,hovered and 1 or 0,dt,25)
      if row.hover>.001 then content:box(cx,cy,177,28,accent,.09*row.hover,6) end
      content:text(binding==row and "Press a key" or row.def.id,cx+7,cy+16.5,7,140,text,true);checkbox(content,cx+152,cy+10.5,row.enabled,"Modern",glass)
      altHit(rect(120+cx,cy,177,28),"module",row,cr)
     end
    end;y+=math.ceil(#list/2)*34+42
   end
  end
  alt.max=math.max(0,y-319);alt.target=math.clamp(alt.target,0,alt.max);altHit(cr,"altScroll");local block=table.remove(hits);table.insert(hits,1,block);altHit(rect(114,0,386,14),"altDrag")
  for _,row in pairs(rows) do if row.expanded and not table.find(alt.windowOrder,row.def.id) then alt.windowOrder[#alt.windowOrder+1]=row.def.id end end
  for order,id in ipairs(alt.windowOrder) do local row=rows[id];if row.expanded then drawModernSettings(row,dt,glass);alt.windows[id].frame.ZIndex=200+order end end
 end
 local function drawAlternatives(dt)
  local dimensions=activeStyle=="Modern" and {500,343} or {760,620};local ww,hh=dimensions[1],dimensions[2]
  alt.s=math.max(.05,math.min(1,(width-16)/ww,(height-16)/hh))
  local location=alt.positions[activeStyle];if not location then location={x=(width-ww*alt.s)/2,y=(height-hh*alt.s)/2};alt.positions[activeStyle]=location end
  location.x=math.clamp(location.x,4,math.max(4,width-ww*alt.s-4));location.y=math.clamp(location.y,4,math.max(4,height-hh*alt.s-4));alt.x,alt.y=location.x,location.y
   altRoot.Visible=true;altRoot.Position=UDim2.fromOffset(alt.x,alt.y);altRoot.Size=UDim2.fromOffset(ww,hh);altScale.Scale=alt.s
   local frost=activeStyle=="Neverlose" and state.ClickGUI and state.ClickGUI.settings["Local Blur"]~=false
    altGlass.Visible=frost;altGlass.BackgroundTransparency=1-.18*opacity
   if altSoftShadow then altSoftShadow.Enabled=frost;altSoftShadow.Transparency=1-.57*opacity end
   altPaint:begin();altContent:begin();alt.scroll=ease(alt.scroll,alt.target,dt,14)
  if activeStyle=="Modern" then drawModern(dt) else drawNeverlose(dt) end
  altPaint:finish();altContent:finish()
 end


 local function drawThemeGlow()
   themeGlowRoot.Visible=false;themeGlow:begin();themeGlow:finish()
 end

 local function drawModernConfigs()
  if not config.open then return end
  local x,y=config.x,config.y;local glass=state.ClickGUI and state.ClickGUI.settings.Interface=="LiquidGlass";local text=glass and 0x2A344A or 0xFFFFFF;local accent=glass and accentColor(0x648FE8) or accentColor(0x9747FF)
  local listH=math.min(126,#config.names*18);config.modernList=rect(x,y+24,152,listH);config.modernMax=math.max(0,#config.names*18-listH);config.scroll=math.clamp(config.scroll,0,config.modernMax);local h=math.min(200,29+listH+42)
  if glass then front:box(x,y,152,h,0xDFE6F4,.96,11) end;modernPanel(front,x,y,152,h,11,glass);front:text("Configs",x+9,y+16,9,125,text);front:text("×",x+135,y+13,13,9,text);hit(rect(x,y,152,24),"configHeader");hit(rect(x+131,y+5,17,17),"configClose")
  for i,name in ipairs(config.names) do local yy=y+24+(i-1)*18-config.scroll;if yy>=y+24 and yy+18<=y+24+listH then
   front:text(name,x+10,yy+12,8,83,text);front:text("Save",x+98,yy+11.5,7,24,accent);front:text("Del",x+126,yy+11.5,7,20,0xFF8888);front:box(x,yy+18,152,.5,text,.04)
   hit(rect(x,yy,94,18),"altLoad",name);hit(rect(x+94,yy,31,18),"altUpdate",name);hit(rect(x+125,yy,27,18),"altDelete",name)
  end end
  local yy=y+24+listH+4;front:box(x+8,yy,94,18,text,.06,3);altName.Visible=true;altName.TextColor3=rgb(text);altName.TextSize=7;altName.Position=UDim2.fromOffset(x+12,yy+2);altName.Size=UDim2.fromOffset(86,14)
  front:text("Create",x+110,yy+9,7,32,accent);hit(rect(x+105,yy,39,18),"altCreate")
  hit(rect(x,y+24,152,h-24),"configBlock");local block=table.remove(hits);local idx=#hits+1;for i,v in ipairs(hits) do if v.action=="configHeader" then idx=i;break end end;table.insert(hits,idx,block)
 end

  local function drawAltDropdown(dt)
   local d=dropdown;local anchor
   if d then
    for _,h in ipairs(hits) do if h.action=="choice" and h.data.row==d.row and h.data.s==d.s then anchor=h.data;break end end
    if not anchor or not condition(d.s.when,state[d.row.def.id].settings) then dropdown=nil;d=nil end
   end
   local motion=alt.dropdownVisual
   if d then
    if not motion or motion.row~=d.row or motion.s~=d.s then motion={row=d.row,s=d.s,open=0,selection={}};alt.dropdownVisual=motion end
    motion.anchor=anchor;motion.scroll=d.scroll or 0
   elseif not motion then return end
   motion.open=animations and ease(motion.open,d and 1 or 0,dt,18) or (d and 1 or 0)
   if motion.open<.01 then if not d then alt.dropdownVisual=nil end;return end
   local s=alt.s;local source=motion.anchor;local w=source.w;local fullH=math.min(240,#motion.s.options*25+8)*s
   local x=source.x;local baseY=source.y+4*s;local above=baseY+fullH>alt.y+606*s
   if above then baseY=source.y-20*s-fullH-4*s end
   baseY=math.clamp(baseY,alt.y+70*s,math.max(alt.y+70*s,alt.y+606*s-fullH))
   local reveal=motion.open*motion.open*(3-2*motion.open);local height=math.max(1,fullH*reveal)
   local y=above and baseY+fullH-height or baseY;local optionH=25*s
   if d then d.rect=rect(x,y,w,height);d.optionH=optionH;d.scroll=math.clamp(d.scroll or 0,0,math.max(0,#d.s.options*optionH-(fullH-8*s)));motion.scroll=d.scroll;hit(d.rect,"dropdownBlock") end
   local previousAlpha=front.alpha;front.alpha=previousAlpha*reveal
   front:box(x,y,w,height,0x0B0F12,1,3*s)
   for i,option in ipairs(motion.s.options) do
    local yy=baseY+4*s+(i-1)*optionH-motion.scroll
    if yy>=y+4*s-.01 and yy+optionH<=y+height-4*s+.01 then
     local value=state[motion.row.def.id].settings[motion.s.name]
     local selected=motion.s.type=="multi" and table.find(value,option)~=nil or value==option
     local selection=motion.selection[i]
     if selection==nil then selection=selected and 1 or 0 end
     selection=animations and ease(selection,selected and 1 or 0,dt,18) or (selected and 1 or 0);motion.selection[i]=selection
     if selection>.001 then front:box(x+3*s,yy,w-6*s,optionH,0x16283A,selection,2*s) end
     front:text(option,x+8*s,yy+optionH/2,11.5*s,w-18*s,mixColor(0xBDC3C7,accentColor(0x3A85E2),selection),true)
     if d then hit(rect(x,yy,w,optionH),"option",option) end
    end
   end
   front.alpha=previousAlpha
  end

  local function drawDropdown(dt)
   if activeStyle=="Neverlose" then drawAltDropdown(dt);return end
  if not dropdown then return end
  local d=dropdown;local st=state[d.row.def.id]
  if not condition(d.s.when,st.settings) or (d.row.def.id~="Targets" and not d.row.expanded) then dropdown=nil;return end
  local anchor=nil;for _,h in ipairs(hits) do if h.action=="choice" and h.data.row==d.row and h.data.s==d.s then anchor=h.data;break end end
  if not anchor then dropdown=nil;return end
  local p=currentPalette();local total=#d.s.options*20
  local h=math.min(total,math.max(20,height-8));local y=math.min(anchor.y,height-h-4);local x=math.clamp(anchor.x,4,math.max(4,width-(W-2*P+4)-4));local w=W-2*P+4
  d.rect=rect(x,y,w,h);d.scroll=math.clamp(d.scroll or 0,0,math.max(0,total-h))
  front:box(x,y,w,h,d.s.type=="multi" and 0x2A2A2D or p.field,1,2);hit(d.rect,"dropdownBlock")
  for i,option in ipairs(d.s.options) do local yy=y+(i-1)*20-d.scroll
   if yy>=y and yy+20<=y+h+.01 then
    local value=st.settings[d.s.name];local selected=d.s.type=="multi" and table.find(value,option)~=nil or value==option
    if selected then front:box(x+1,yy,w-2,20,p.selected,1) elseif inside(rect(x,yy,w,20),mx,my) then front:box(x+1,yy,w-2,20,p.text,.047) end
    if selected then drawCheck(front,x+5,yy+7,6,p.text) end
    front:text(displayName(option),x+((selected or d.s.type=="multi") and 17 or 6),yy+10,8.5,w-23,p.text)
    hit(rect(x,yy,w,20),"option",option)
   end
  end
 end
 local function hitAt(x,y) for i=#hits,1,-1 do if inside(hits[i].rect,x,y) then return hits[i] end end end
 local function slide(x)
  if not sliding then return end
  local d=sliding;local s=d.s;local f=math.clamp((x-d.left)/d.width,0,1);local value=math.clamp(s.min+math.round(f*(s.max-s.min)/s.step)*s.step,s.min,s.max)
  value=tonumber(numberText(value,s.step))
  if state[d.row.def.id].settings[s.name]~=value then api:SetSetting(d.row.def.id,s.name,value) end
 end
 local function frontColumn(c) for i,v in ipairs(columns) do if v==c then table.remove(columns,i);columns[#columns+1]=c;return end end end
 local function savePreset(name,blank)
  name=name:match("^%s*(.-)%s*$");if #name<1 or #name>64 then message("Name must be 1–64 bytes");return end
  local snapshot=api:GetState();if blank then for id,m in pairs(snapshot.modules) do m.enabled=false;m.key="Unknown";for _,s in ipairs(rows[id].def.settings or {}) do m.settings[s.name]=copy(s.default) end end end
  config.values[name]=snapshot;config.selected=name;configNames();config.page="Configurations";editor:ReleaseFocus();message("Saved")
 end
 local function click(button,x,y,target)
  if dead or not visible then return end
  local h=target or hitAt(x,y);if not h then dropdown=nil;return end
  local a,d=h.action,h.data
  if a=="appearanceOpen" then api:OpenAppearance();return
  elseif a=="appearanceOutside" or a=="appearanceClose" then appearanceOpen=false;appearanceSliding=nil;accentBox:ReleaseFocus();return
  elseif a=="appearanceBlock" then return
  elseif a=="appearanceScale" and button==0 then appearanceSliding=d;appearanceSlide(x);return
  elseif a=="appearanceAccent" then api:SetAccent(d);appearanceError="";return
  elseif a=="appearanceApply" then local color=parseAccent(accentBox.Text);if color then api:SetAccent(color);appearanceError="" else appearanceError="Use six hexadecimal digits: #RRGGBB" end;return
  elseif a=="appearanceEffect" then api:SetThemeEffect(d);appearanceError="";return
  elseif a=="appearanceAnimations" then api:SetAnimations(not animations);return
  elseif a=="languageToggle" then api:SetLanguage(language=="English" and "中文" or "English");return
   elseif a=="appearanceReset" then api:SetAccent(nil);appearanceError="";return
  elseif a=="altNav" then
   if d==7 then if api.EditHUD then api:EditHUD() end;return end
    alt.nav=d;alt.target=0;alt.scroll=0;dropdown=nil;alt.dropdownVisual=nil;return
   elseif a=="modernNav" then alt.nav=d;alt.target=alt.sectionOffsets[d] or 0;dropdown=nil;alt.dropdownVisual=nil;return
   elseif a=="altConfigs" then if activeStyle=="Neverlose" then alt.nav=8;alt.target=0;alt.scroll=0;dropdown=nil;alt.dropdownVisual=nil else config.open=not config.open;config.x=math.clamp(alt.x+500*alt.s+6,4,math.max(4,width-156));config.y=alt.y end;return
   elseif a=="altSave" then if config.selected then config.values[config.selected]=api:GetState();message("Saved") else if activeStyle=="Neverlose" then alt.nav=8;dropdown=nil;alt.dropdownVisual=nil else config.open=true end end;return
  elseif a=="altCreate" then savePreset(altName.Text,false);return
  elseif a=="altLoad" then config.selected=d;local ok,err=api:ApplyState(config.values[d]);message(ok and "Loaded" or err);return
  elseif a=="altUpdate" then config.selected=d;config.values[d]=api:GetState();message("Saved");return
  elseif a=="altDelete" then config.values[d]=nil;if config.selected==d then config.selected=nil end;configNames();return
  elseif a=="nlHeader" then d.nlExpanded=not d.nlExpanded;dropdown=nil;return
  elseif a=="bind" then binding=d;dropdown=nil;return
  elseif a=="altDrag" and button==0 then drag={kind="alternate",dx=x-alt.x,dy=y-alt.y};return
  elseif a=="altScrollbar" and button==0 then drag={kind="altScrollbar"};alt.target=math.clamp(((y-alt.y)/alt.s-84)/516,0,1)*alt.max;return
  elseif a=="modernDrag" and button==0 then local at=table.find(alt.windowOrder,d.id);if at then table.remove(alt.windowOrder,at) end;alt.windowOrder[#alt.windowOrder+1]=d.id;drag={kind="modern",win=d,dx=x-d.x,dy=y-d.y};return
  elseif a=="modernClose" then d.expanded=false;return
  elseif a=="modernCycle" then local value=state[d.row.def.id].settings[d.s.name];local index=table.find(d.s.options,value) or 1;api:SetSetting(d.row.def.id,d.s.name,d.s.options[index%#d.s.options+1]);return
  elseif a=="modernMulti" then d.win.multi[d.s.name]=not d.win.multi[d.s.name];return
  elseif a=="modernOption" then local values=copy(state[d.row.def.id].settings[d.s.name]);local at=table.find(values,d.option);if at then if d.s.allowEmpty==false and #values==1 then return end;table.remove(values,at) else values[#values+1]=d.option end;api:SetSetting(d.row.def.id,d.s.name,values);return
  elseif a=="hudEdit" then if api.EditHUD then api:EditHUD() end;return
  elseif a=="hudEditRMB" then if button==1 then api:EditHUD() end;return
  end

  if dropdown and a~="option" and a~="dropdownBlock" and a~="choice" then dropdown=nil;return end
  ripple={x=x,y=y,start=os.clock()}
  if a=="module" then
   if button==0 then api:SetEnabled(d.def.id,not state[d.def.id].enabled)
   elseif button==1 then d.expanded=not d.expanded;dropdown=nil;sliding=nil;binding=nil
    if activeStyle=="Modern" and d.expanded then local at=table.find(alt.windowOrder,d.def.id);if at then table.remove(alt.windowOrder,at) end;alt.windowOrder[#alt.windowOrder+1]=d.def.id end
    if activeStyle=="Modern" and d.expanded and alt.windows[d.def.id] then local win=alt.windows[d.def.id];win.x=math.clamp(x+8,4,math.max(4,width-156));win.y=math.clamp(y+8,4,math.max(4,height-204)) end
   elseif button==2 then binding=d;dropdown=nil end
  elseif a=="header" then
   dropdown=nil;frontColumn(d)
   if button==1 then d.expanded=not d.expanded;binding=nil;sliding=nil
   elseif button==0 then drag={kind="column",c=d,dx=x-(d.x-horizontal),dy=y-d.y} end
  elseif a=="scrollbar" and button==0 then drag={kind="scrollbar",c=d.c,travel=d.travel,grab=math.clamp(y-d.top,0,d.thumb)}
  elseif a=="toggle" and button==0 then d.row.press=d.row.press or {};d.row.press[d.s.name]=os.clock();api:SetSetting(d.row.def.id,d.s.name,not state[d.row.def.id].settings[d.s.name])
  elseif a=="slider" and button==0 then sliding=d;slide(x)
  elseif a=="choice" and button==0 then if dropdown and dropdown.row==d.row and dropdown.s==d.s then dropdown=nil else dropdown={row=d.row,s=d.s,scroll=0,style=activeStyle} end
  elseif a=="option" then
   if button==1 then dropdown=nil elseif button==0 then local choice=dropdown;local s=choice.s;local value=state[choice.row.def.id].settings[s.name]
    if s.type=="multi" then local values=copy(value);local index=table.find(values,d);if index then if s.allowEmpty==false and #values==1 then return end;table.remove(values,index) else values[#values+1]=d end;api:SetSetting(choice.row.def.id,s.name,values)
    else api:SetSetting(choice.row.def.id,s.name,d);dropdown=nil end
   end
  elseif a=="configOpen" and button==0 then config.open=true;config.x=math.max(4,width-W-4);config.y=math.max(4,height*.112-2)
  elseif a=="configHeader" then if button==1 then config.open=false elseif button==0 then drag={kind="config",dx=x-config.x,dy=y-config.y} end
  elseif a=="configPage" and button==0 then config.page=d;dropdown=nil;editor:ReleaseFocus();jsonEditor:ReleaseFocus()
  elseif a=="configFocus" and button==0 then editor:CaptureFocus()
  elseif a=="jsonFocus" and button==0 then jsonEditor:CaptureFocus()
  elseif a=="configCreate" and button==0 then savePreset(editor.Text,d)
  elseif a=="configSelect" and button==0 then config.selected=d
  elseif a=="configSave" and button==0 then if config.selected then config.values[config.selected]=api:GetState();message("Updated") else message("Select a configuration") end
  elseif a=="configLoad" and button==0 then if config.selected then local ok,errorText=api:ApplyState(config.values[config.selected]);message(ok and "Loaded" or errorText) end
  elseif a=="configDelete" and button==0 then if config.selected then config.values[config.selected]=nil;config.selected=nil;configNames();message("Deleted") end
  elseif a=="configRefresh" and button==0 then configNames()
  elseif a=="configExport" and button==0 then jsonEditor.Text=api:ExportJSON();config.page="JSON";message("Copy the JSON text")
  elseif a=="configImport" and button==0 then local ok,errorText=api:ImportJSON(jsonEditor.Text);message(ok and "Imported" or errorText)
  elseif a=="configClose" and button==0 then config.open=false;dropdown=nil
  elseif a=="theme" and button==0 then api:SetTheme(selectedTheme()=="Lavender" and "Light Pink" or "Lavender")
  elseif a=="scale" and button==0 then api:SetScale(k==2 and 1.5 or k==1.5 and 2.5 or 2)
  end
 end

 -- HUD lives outside the menu canvas: closing ClickGUI must not hide the island.
 local hudRoot=new("Frame",gui,{Name="HUD",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=1})
 local island=new("Frame",hudRoot,{Name="DynamicIsland",BackgroundTransparency=1,ZIndex=20})
 local shell=pool(island,true)
  local islandBackdrop=new("Frame",island,{Name="Backdrop",BackgroundColor3=rgb(0x000000),BackgroundTransparency=1-0x98/255,BorderSizePixel=0,ZIndex=30})
  local islandCorner=new("UICorner",islandBackdrop,{CornerRadius=UDim.new(0,12)})
  local islandSoftShadow
   pcall(function() islandSoftShadow=new("UIShadow",islandBackdrop,{Color=rgb(0x000000),BlurRadius=UDim.new(0,18),Spread=UDim2.fromOffset(5,5),Offset=UDim2.fromOffset(0,0),Transparency=.5}) end)
 local islandClip=new("Frame",island,{Name="Content",BackgroundTransparency=1,ClipsDescendants=true,ZIndex=100})
 local ink=pool(islandClip,true)
  ink.fixedText=true
 local widgetRoot=new("Frame",hudRoot,{Name="Widgets",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=10})
 local widgets=pool(widgetRoot,true)
 local hudControls=new("Frame",hudRoot,{Name="HUDControls",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5000})
  local hudHint=new("TextButton",hudControls,{Name="Done",Text="HUD Editor · drag panels · Right Shift / click here to finish",Size=UDim2.fromOffset(430,32),Position=UDim2.new(.5,-215,1,-44),BackgroundColor3=rgb(0x1C1F29),TextColor3=rgb(0xE4E1E6),Font=opaiFont(false),TextSize=14,Visible=false,AutoButtonColor=false,ZIndex=100})
 connect(hudHint.Activated,function() api:SetVisible(true) end)
 function api:EditHUD() api:SetVisible(false);hudEditing=true;if state.HUD then state.HUD.enabled=true end end
 function api:GetHUDLayout() return copy(hudPlacements) end
 function api:SetHUDLayout(name,x,y,scale)
   assert(name=="ArrayList" or name=="TargetHUD","Unknown draggable HUD")
  assert(type(x)=="number" and x==x and math.abs(x)<math.huge and type(y)=="number" and y==y and math.abs(y)<math.huge,"Invalid HUD position")
  scale=scale or 1;assert(type(scale)=="number" and scale==scale and scale>=.5 and scale<=2,"Invalid HUD scale")
  hudPlacements[name]={x=x,y=y,scale=scale}
 end
 local function placeWidget(name,x,y,w,h)
  local at=hudPlacements[name];local view=gui.AbsoluteSize
  x=math.clamp(at and at.x or x,2,math.max(2,view.X-w-2));y=math.clamp(at and at.y or y,2,math.max(2,view.Y-h-2))
  hudBounds[name]=rect(x,y,w,h);return x,y
 end
  local hudControlPriority={ArrayList=10,TargetHUD=40}
 local function updateHUDControls()
  hudHint.Visible=hudEditing
  local hintWidth=math.min(430,gui.AbsoluteSize.X-8);hudHint.Size=UDim2.fromOffset(hintWidth,32);hudHint.Position=UDim2.new(.5,-hintWidth/2,1,-44)
  for name,bounds in pairs(hudBounds) do
   local button=hudButtons[name]
   if not button then button=new("TextButton",hudControls,{Name=name,Text="",BackgroundTransparency=1,AutoButtonColor=false,Active=true,ZIndex=hudControlPriority[name] or 10});hudButtons[name]=button
    connect(button.InputBegan,function(input)
     if hudEditing and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then local r=hudBounds[name];hudDrag={name=name,input=input,startX=input.Position.X,startY=input.Position.Y,x=r.x,y=r.y};end
    end)
   end
   button.Visible=hudEditing;button.Position=UDim2.fromOffset(bounds.x,bounds.y);button.Size=UDim2.fromOffset(bounds.w,bounds.h)
  end
  for name,button in pairs(hudButtons) do if not hudBounds[name] then button.Visible=false end end
 end
 local notices={}
 local function spring(value) return {value=value,target=value,velocity=0} end
  local islandState={width=spring(180),height=spring(23),top=spring(21),idle=true,wasIdle=true,fps=0,ping=nil,nextPing=0,start=os.clock(),target=nil}
  local measureCache={};local cacheCount=0
  local function measure(text,size,plain)
   text=tostring(text);local scale=islandState.renderScale or hudScale
   local physicalSize=math.max(1,math.round(size*scale));local key="w:"..physicalSize..":"..scale..":"..tostring(plain)..":"..text
   if measureCache[key] then return measureCache[key] end
   local bounds=TextService:GetTextSize(text,physicalSize,opaiFont(plain),Vector2.new(10000,10000))
   if cacheCount>600 then measureCache={};cacheCount=0 end
   local measured=math.ceil(bounds.X/scale)+3;measureCache[key]=measured;cacheCount+=1;return measured
  end
  local function wrappedHeight(text,size,width,plain)
   if text=="" then return 0 end
   local scale=islandState.renderScale or hudScale
   local physicalSize=math.max(1,math.round(size*scale))
   local physicalWidth=math.max(1,math.floor(width*scale))
   local key="h:"..physicalSize..":"..physicalWidth..":"..scale..":"..tostring(plain)..":"..tostring(text)
   if measureCache[key] then return measureCache[key] end
   local bounds=TextService:GetTextSize(tostring(text),physicalSize,opaiFont(plain),Vector2.new(physicalWidth,10000))
   if cacheCount>600 then measureCache={};cacheCount=0 end
   local measured=math.ceil(bounds.Y/scale)+2;measureCache[key]=measured;cacheCount+=1;return measured
  end
  local function morph(s,destination,dt,impulse)
   if not s.sampled or not animations then s.value=destination;s.target=destination;s.velocity=0;s.sampled=true;return s.value end
   local displacement=s.value-s.target;local a=(s.velocity+8.7*displacement)/8
   local co,si,decay=math.cos(8*dt),math.sin(8*dt),math.exp(-8.7*dt)
   local offset=displacement*co+a*si
   s.value=s.target+decay*offset;s.velocity=decay*(-8.7*offset+8*(-displacement*si+a*co))
   if destination~=s.target then
    s.target=destination
    if math.abs(s.velocity)<math.max(.1,math.abs(destination-s.value)*.1) then s.velocity=(destination-s.value)*(impulse or 0) end
   end
   if math.abs(s.value-s.target)<.01 and math.abs(s.velocity)<.1 then s.value=s.target;s.velocity=0 end
   return s.value
  end
 local function expireNotices()
  for i=#notices,1,-1 do if os.clock()>=notices[i].untilTime then table.remove(notices,i) end end
 end
 postNotice=function(key,title,detail,kind,value,duration)
  if dead then return end;expireNotices()
  local n;for _,v in ipairs(notices) do if v.key==key then n=v;break end end
  if not n then n={key=key,width=0,started=os.clock(),toggle=value and 0 or 1};notices[#notices+1]=n end
  n.title=tostring(title);n.detail=tostring(detail or "");n.kind=kind;n.value=value;n.untilTime=os.clock()+duration
    if kind=="toggle" then n.started=os.clock();n.toggleFrom=n.toggle end
    local detailText=kind=="toggle" and toggleDetail(n.detail,value) or n.detail
    local titleSize=kind=="breaking" and 9 or 10;local detailSize=kind=="breaking" and 8 or 9
    n.width=(kind=="toggle" and 54 or 46)+math.max(measure(n.title,titleSize),measure(detailText,detailSize))
  while #notices>3 do table.remove(notices,1) end
 end
 local noticeCounter=0
 function api:Notify(title,detail,kind,duration)
  kind=kind or "info";assert(kind=="info" or kind=="success" or kind=="warning","Invalid notice kind")
  duration=duration or (kind=="warning" and 3 or 2.6);assert(type(duration)=="number" and duration>0 and duration<math.huge)
  noticeCounter+=1;postNotice("notice:"..noticeCounter,title,detail,kind,nil,duration)
 end
 function api:UpdateProgress(key,title,detail,value,kind,duration)
  assert(type(key)=="string" and type(value)=="number" and value==value,"Invalid progress")
  kind=kind or "breaking";assert(kind=="breaking" or kind=="scaffold","Invalid progress kind")
  duration=duration or .5;assert(type(duration)=="number" and duration>0 and duration<math.huge)
  -- Dedicated progress state replaces ordinary notices, as in the source.
  for i=#notices,1,-1 do if notices[i].key~=key then table.remove(notices,i) end end
  postNotice(key,title,detail,kind,math.clamp(value,0,1),duration)
 end
 function api:ClearNotices() table.clear(notices) end
 function api:SetTarget(target) assert(target==nil or type(target)=="table","Target must be a table or nil");islandState.target=target and copy(target) end
 local function widgetEnabled(name)
  local st=state.HUD
  if not st then return options.HUD~=false end
  return st.enabled and type(st.settings.Widgets)=="table" and table.find(st.settings.Widgets,name)~=nil
 end
 if state.HUD and options.HUD~=false then state.HUD.enabled=true;rows.HUD.enabled=1 end
 -- Filled contours adapted from DynamicIslandNanoSurface.java; supersampled once at build time.
local hudGlyphs={
CHROME={{17,0,2,1,0.25},{19,0,1,1,0.5},{20,0,2,1,0.75},{22,0,5,1,1.0},{27,0,2,1,0.75},{29,0,1,1,0.5},{30,0,1,1,0.25},{14,1,1,1,0.25},{15,1,1,1,0.5},{16,1,1,1,0.75},{17,1,14,1,1.0},{31,1,1,1,0.75},{32,1,1,1,0.5},{12,2,1,1,0.25},{13,2,1,1,0.75},{14,2,20,1,1.0},{34,2,1,1,0.5},{35,2,1,1,0.25},{11,3,1,1,0.5},{12,3,24,1,1.0},{36,3,1,1,0.5},{9,4,1,1,0.25},{10,4,1,1,0.75},{11,4,26,1,1.0},{37,4,1,1,0.75},{38,4,1,1,0.25},{8,5,1,1,0.5},{9,5,30,1,1.0},{39,5,1,1,0.5},{7,6,1,1,0.5},{8,6,32,1,1.0},{40,6,1,1,0.5},{6,7,1,1,0.5},{7,7,34,1,1.0},{41,7,1,1,0.5},{5,8,1,1,0.25},{6,8,36,1,1.0},{42,8,1,1,0.5},{6,9,37,1,1.0},{43,9,1,1,0.25},{6,10,1,1,0.5},{7,10,36,1,1.0},{43,10,1,1,0.75},{7,11,1,1,0.75},{8,11,36,1,1.0},{44,11,1,1,0.5},{2,12,1,1,0.25},{3,12,1,1,0.75},{7,12,1,1,0.25},{8,12,11,1,1.0},{19,12,1,1,0.75},{20,12,1,1,0.5},{21,12,24,1,0.25},{2,13,1,1,0.5},{3,13,1,1,1.0},{4,13,1,1,0.25},{8,13,1,1,0.75},{9,13,9,1,1.0},{18,13,1,1,0.5},{2,14,3,2,1.0},{8,14,1,1,0.25},{9,14,7,1,1.0},{16,14,1,1,0.75},{1,15,1,1,0.5},{5,15,1,1,0.5},{9,15,1,1,0.5},{10,15,5,1,1.0},{15,15,1,1,0.5},{33,15,14,1,0.25},{1,16,1,1,0.75},{2,16,4,1,1.0},{6,16,1,1,0.25},{10,16,4,1,1.0},{14,16,1,1,0.75},{20,16,1,1,0.25},{21,16,1,1,0.5},{22,16,1,1,0.75},{23,16,2,1,1.0},{25,16,1,1,0.75},{26,16,1,1,0.5},{27,16,1,1,0.25},{33,16,1,1,0.75},{34,16,12,1,1.0},{46,16,1,1,0.75},{0,17,1,1,0.25},{1,17,5,1,1.0},{6,17,1,1,0.75},{10,17,1,1,0.25},{11,17,3,1,1.0},{19,17,1,1,0.5},{20,17,8,1,1.0},{28,17,1,1,0.75},{34,17,13,1,1.0},{47,17,1,1,0.25},{0,18,1,1,0.5},{1,18,6,2,1.0},{7,18,1,1,0.25},{11,18,1,1,0.75},{12,18,1,2,1.0},{13,18,1,1,0.5},{18,18,1,1,0.75},{19,18,10,1,1.0},{29,18,1,1,0.75},{34,18,1,1,0.5},{35,18,12,2,1.0},{47,18,1,1,0.5},{0,19,1,2,0.75},{7,19,1,1,0.75},{11,19,1,1,0.25},{17,19,1,1,0.5},{18,19,12,1,1.0},{30,19,1,1,0.75},{47,19,1,2,0.75},{1,20,7,1,1.0},{8,20,1,1,0.5},{12,20,1,1,0.25},{16,20,1,1,0.25},{17,20,14,2,1.0},{31,20,1,1,0.25},{35,20,1,1,0.75},{36,20,11,1,1.0},{0,21,9,2,1.0},{16,21,1,1,0.5},{31,21,1,1,0.75},{35,21,1,6,0.25},{36,21,12,6,1.0},{9,22,1,1,0.5},{16,22,1,1,0.75},{17,22,15,1,1.0},{0,23,10,2,1.0},{10,23,1,1,0.25},{16,23,16,2,1.0},{32,23,1,2,0.25},{10,24,1,1,0.75},{0,25,11,2,1.0},{11,25,1,1,0.25},{16,25,1,1,0.75},{17,25,15,1,1.0},{11,26,1,1,0.75},{16,26,1,1,0.5},{17,26,14,2,1.0},{31,26,1,1,0.75},{0,27,1,2,0.75},{1,27,11,1,1.0},{12,27,1,1,0.5},{16,27,1,1,0.25},{31,27,1,1,0.25},{35,27,1,1,0.5},{36,27,11,1,1.0},{47,27,1,2,0.75},{1,28,12,2,1.0},{17,28,1,1,0.75},{18,28,12,1,1.0},{30,28,1,1,0.75},{35,28,12,2,1.0},{0,29,1,1,0.5},{13,29,1,1,0.5},{18,29,1,1,0.75},{19,29,10,1,1.0},{29,29,1,1,0.75},{34,29,1,1,0.5},{47,29,1,1,0.5},{0,30,1,1,0.25},{1,30,13,1,1.0},{19,30,1,1,0.75},{20,30,8,1,1.0},{28,30,1,1,0.75},{34,30,13,1,1.0},{47,30,1,1,0.25},{1,31,1,1,0.75},{2,31,12,1,1.0},{14,31,1,1,0.75},{20,31,1,1,0.25},{21,31,1,1,0.75},{22,31,4,1,1.0},{26,31,1,1,0.75},{27,31,1,1,0.25},{33,31,1,1,0.75},{34,31,12,1,1.0},{46,31,1,1,0.75},{1,32,1,1,0.5},{2,32,13,1,1.0},{15,32,1,1,0.5},{23,32,2,1,0.25},{32,32,1,1,0.5},{33,32,13,1,1.0},{46,32,1,1,0.5},{1,33,1,1,0.25},{2,33,14,1,1.0},{16,33,1,1,0.75},{32,33,14,1,1.0},{2,34,1,1,0.75},{3,34,15,1,1.0},{18,34,1,1,0.5},{31,34,1,1,0.5},{32,34,13,1,1.0},{45,34,1,1,0.75},{2,35,1,1,0.25},{3,35,16,1,1.0},{19,35,1,1,0.75},{20,35,1,1,0.5},{21,35,6,1,0.25},{30,35,1,1,0.25},{31,35,14,1,1.0},{45,35,1,1,0.25},{3,36,1,1,0.5},{4,36,22,1,1.0},{26,36,1,1,0.5},{30,36,1,1,0.75},{31,36,13,1,1.0},{44,36,1,1,0.5},{4,37,1,1,0.75},{5,37,20,2,1.0},{25,37,1,1,0.75},{29,37,1,1,0.25},{30,37,13,2,1.0},{43,37,1,1,0.75},{4,38,1,1,0.25},{25,38,1,1,0.25},{29,38,1,1,0.75},{43,38,1,1,0.25},{5,39,1,1,0.5},{6,39,18,1,1.0},{24,39,1,1,0.75},{28,39,1,1,0.5},{29,39,13,1,1.0},{42,39,1,1,0.5},{6,40,1,1,0.5},{7,40,17,1,1.0},{24,40,1,1,0.25},{28,40,13,1,1.0},{41,40,1,1,0.5},{7,41,1,1,0.5},{8,41,15,1,1.0},{23,41,1,1,0.5},{27,41,1,1,0.75},{28,41,12,1,1.0},{40,41,1,1,0.5},{8,42,1,1,0.5},{9,42,14,1,1.0},{26,42,1,1,0.25},{27,42,12,1,1.0},{39,42,1,1,0.5},{9,43,1,1,0.25},{10,43,1,1,0.75},{11,43,11,1,1.0},{22,43,1,1,0.5},{26,43,1,1,0.75},{27,43,10,1,1.0},{37,43,1,1,0.75},{38,43,1,1,0.25},{11,44,1,1,0.5},{12,44,9,1,1.0},{21,44,1,1,0.75},{25,44,1,1,0.5},{26,44,10,1,1.0},{36,44,1,1,0.5},{12,45,1,1,0.25},{13,45,1,1,0.5},{14,45,7,1,1.0},{21,45,1,1,0.25},{25,45,9,1,1.0},{34,45,1,1,0.75},{35,45,1,1,0.25},{15,46,1,1,0.5},{16,46,1,1,0.75},{17,46,3,1,1.0},{20,46,1,1,0.75},{24,46,1,1,0.5},{25,46,6,1,1.0},{31,46,1,1,0.75},{32,46,1,1,0.5},{33,46,1,1,0.25},{17,47,2,1,0.25},{19,47,1,1,0.75},{20,47,1,1,0.25},{23,47,1,1,0.25},{24,47,2,1,1.0},{26,47,2,1,0.75},{28,47,1,1,0.5},{29,47,2,1,0.25}},
USER={{20,5,1,1,0.25},{21,5,2,1,0.75},{23,5,2,1,1.0},{25,5,2,1,0.75},{27,5,1,1,0.5},{18,6,1,1,0.25},{19,6,1,1,0.75},{20,6,8,1,1.0},{28,6,1,1,0.75},{29,6,1,1,0.5},{17,7,1,1,0.5},{18,7,12,1,1.0},{30,7,1,1,0.5},{16,8,1,1,0.5},{17,8,14,1,1.0},{31,8,1,1,0.75},{15,9,1,1,0.25},{16,9,16,1,1.0},{32,9,1,1,0.5},{15,10,1,1,0.75},{16,10,17,1,1.0},{14,11,1,1,0.25},{15,11,18,2,1.0},{33,11,1,1,0.5},{14,12,1,2,0.75},{33,12,1,1,0.75},{15,13,19,1,1.0},{14,14,20,2,1.0},{34,14,1,2,0.25},{14,16,1,2,0.75},{15,16,19,1,1.0},{15,17,18,3,1.0},{33,17,1,1,0.75},{14,18,1,1,0.5},{33,18,1,1,0.5},{15,20,1,1,0.25},{16,20,16,1,1.0},{32,20,1,1,0.5},{16,21,1,1,0.75},{17,21,14,1,1.0},{31,21,1,1,0.75},{17,22,1,1,0.75},{18,22,12,1,1.0},{30,22,1,1,0.75},{18,23,1,1,0.5},{19,23,10,1,1.0},{29,23,1,1,0.5},{20,24,1,1,0.5},{21,24,1,1,0.75},{22,24,4,1,1.0},{26,24,1,1,0.75},{27,24,1,1,0.5},{28,24,1,1,0.25},{23,25,2,1,0.25},{15,29,1,1,0.25},{16,29,1,1,0.5},{17,29,1,1,0.75},{18,29,12,1,1.0},{30,29,1,1,0.75},{31,29,1,1,0.5},{32,29,1,1,0.25},{13,30,1,1,0.5},{14,30,1,1,0.75},{15,30,18,1,1.0},{33,30,1,1,0.75},{34,30,1,1,0.5},{11,31,1,1,0.25},{12,31,1,1,0.75},{13,31,22,1,1.0},{35,31,1,1,0.75},{36,31,1,1,0.25},{10,32,1,1,0.25},{11,32,26,1,1.0},{37,32,1,1,0.25},{9,33,1,1,0.25},{10,33,28,2,1.0},{38,33,1,1,0.25},{9,34,1,1,0.75},{38,34,1,1,0.75},{8,35,1,1,0.5},{9,35,30,1,1.0},{39,35,1,1,0.5},{8,36,32,4,1.0},{7,37,1,1,0.5},{40,37,1,1,0.5},{7,38,1,2,0.75},{40,38,1,2,0.75},{7,40,34,3,1.0},{7,43,1,1,0.5},{8,43,32,1,1.0},{40,43,1,1,0.5},{9,44,30,1,0.25}},
LINK={{9,12,2,1,0.25},{11,12,11,1,0.5},{22,12,2,1,0.25},{31,12,2,1,0.5},{33,12,1,1,0.25},{34,12,3,1,0.5},{37,12,2,1,0.25},{7,13,1,1,0.25},{8,13,1,1,0.75},{9,13,15,1,1.0},{24,13,1,1,0.75},{25,13,1,1,0.25},{30,13,1,1,0.75},{31,13,8,1,1.0},{39,13,1,1,0.75},{40,13,1,1,0.25},{5,14,1,1,0.25},{6,14,1,1,0.75},{7,14,19,1,1.0},{26,14,1,1,0.75},{29,14,1,2,0.5},{30,14,11,1,1.0},{41,14,1,1,0.75},{42,14,1,1,0.25},{4,15,1,1,0.25},{5,15,22,1,1.0},{27,15,1,1,0.75},{30,15,13,2,1.0},{43,15,1,1,0.25},{4,16,1,1,0.75},{5,16,23,1,1.0},{28,16,1,1,0.75},{43,16,1,1,0.75},{3,17,1,1,0.5},{4,17,7,1,1.0},{11,17,3,1,0.75},{14,17,4,1,0.5},{18,17,1,1,0.75},{19,17,2,1,0.5},{21,17,1,1,0.75},{22,17,7,1,1.0},{29,17,1,1,0.25},{31,17,3,1,0.5},{34,17,3,1,0.75},{37,17,7,1,1.0},{44,17,1,1,0.5},{3,18,6,1,1.0},{9,18,1,1,0.5},{23,18,1,1,0.5},{24,18,5,1,1.0},{29,18,1,1,0.75},{38,18,1,1,0.5},{39,18,6,1,1.0},{2,19,1,1,0.5},{3,19,5,1,1.0},{8,19,1,1,0.25},{18,19,1,1,0.5},{19,19,2,1,1.0},{21,19,1,1,0.5},{24,19,1,1,0.5},{25,19,5,2,1.0},{39,19,1,1,0.25},{40,19,5,1,1.0},{45,19,1,1,0.5},{2,20,1,2,0.75},{3,20,4,2,1.0},{7,20,1,1,0.75},{17,20,1,1,0.25},{18,20,4,7,1.0},{22,20,1,1,0.5},{30,20,1,1,0.25},{40,20,1,1,0.75},{41,20,4,2,1.0},{45,20,1,2,0.75},{7,21,1,1,0.5},{17,21,1,6,0.5},{22,21,1,1,0.75},{25,21,1,1,0.75},{26,21,4,7,1.0},{30,21,1,3,0.5},{40,21,1,1,0.5},{2,22,5,4,1.0},{7,22,1,5,0.25},{22,22,1,2,0.5},{25,22,1,3,0.5},{40,22,1,5,0.25},{41,22,5,4,1.0},{22,24,1,1,0.75},{30,24,1,1,0.75},{46,24,1,1,0.25},{22,25,1,1,0.5},{25,25,1,1,0.25},{30,25,1,1,0.5},{2,26,1,2,0.75},{3,26,4,2,1.0},{22,26,1,1,0.75},{25,26,1,1,0.5},{30,26,1,1,0.75},{41,26,4,2,1.0},{45,26,1,2,0.75},{7,27,1,1,0.75},{17,27,1,1,0.25},{18,27,5,2,1.0},{25,27,1,1,0.25},{30,27,1,1,0.5},{40,27,1,1,0.75},{2,28,1,1,0.5},{3,28,5,1,1.0},{8,28,1,1,0.25},{23,28,1,1,0.5},{26,28,1,1,0.5},{27,28,2,1,1.0},{29,28,1,1,0.75},{39,28,1,1,0.25},{40,28,5,1,1.0},{45,28,1,1,0.5},{3,29,6,1,1.0},{9,29,1,1,0.25},{18,29,1,1,0.75},{19,29,5,1,1.0},{24,29,1,1,0.5},{38,29,1,1,0.5},{39,29,6,1,1.0},{3,30,1,1,0.5},{4,30,7,1,1.0},{11,30,1,1,0.75},{12,30,5,1,0.5},{18,30,1,1,0.25},{19,30,7,1,1.0},{26,30,1,1,0.75},{27,30,9,1,0.5},{36,30,1,1,0.75},{37,30,7,1,1.0},{44,30,1,1,0.5},{4,31,1,1,0.75},{5,31,13,2,1.0},{19,31,1,1,0.75},{20,31,23,1,1.0},{43,31,1,1,0.75},{4,32,1,1,0.25},{18,32,1,2,0.5},{20,32,1,1,0.75},{21,32,22,1,1.0},{43,32,1,1,0.25},{5,33,1,1,0.25},{6,33,1,1,0.75},{7,33,11,1,1.0},{21,33,1,1,0.75},{22,33,19,1,1.0},{41,33,1,1,0.75},{42,33,1,1,0.25},{7,34,1,1,0.5},{8,34,1,1,0.75},{9,34,9,1,1.0},{18,34,1,1,0.25},{22,34,1,1,0.5},{23,34,1,1,0.75},{24,34,15,1,1.0},{39,34,1,1,0.75},{40,34,1,1,0.5},{9,35,1,1,0.25},{10,35,7,1,0.5},{17,35,1,1,0.25},{24,35,1,1,0.25},{25,35,13,1,0.5},{38,35,1,1,0.25}},
REFRESH={{24,2,1,1,0.5},{25,2,1,1,1.0},{22,3,1,1,0.25},{23,3,1,1,0.75},{24,3,2,1,1.0},{26,3,1,7,0.25},{21,4,1,1,0.5},{22,4,4,1,1.0},{19,5,1,1,0.25},{20,5,1,1,0.75},{21,5,5,1,1.0},{18,6,1,1,0.5},{19,6,7,1,1.0},{16,7,1,1,0.25},{17,7,1,1,0.75},{18,7,8,1,1.0},{15,8,1,1,0.5},{16,8,10,1,1.0},{14,9,1,1,0.75},{15,9,11,1,1.0},{12,10,1,1,0.25},{13,10,13,1,1.0},{26,10,3,1,0.75},{29,10,1,1,0.5},{30,10,1,1,0.25},{11,11,1,1,0.75},{12,11,20,1,1.0},{32,11,1,1,0.5},{33,11,1,1,0.25},{9,12,1,1,0.25},{10,12,24,1,1.0},{34,12,1,1,0.75},{35,12,1,1,0.25},{9,13,1,1,0.5},{10,13,26,1,1.0},{36,13,1,1,0.5},{10,14,1,1,0.25},{11,14,1,1,0.75},{12,14,25,1,1.0},{37,14,1,1,0.5},{12,15,1,1,0.5},{13,15,25,1,1.0},{38,15,1,1,0.5},{13,16,1,1,0.25},{14,16,1,1,0.75},{15,16,24,1,1.0},{39,16,1,1,0.25},{5,17,1,1,0.25},{15,17,1,1,0.5},{16,17,24,1,1.0},{4,18,1,1,0.25},{5,18,1,1,0.5},{16,18,1,1,0.25},{17,18,1,1,0.75},{18,18,8,1,1.0},{26,18,4,1,0.25},{30,18,1,1,0.5},{31,18,1,1,0.75},{32,18,8,1,1.0},{40,18,1,1,0.5},{5,19,1,1,0.75},{18,19,1,1,0.5},{19,19,7,1,1.0},{33,19,1,1,0.5},{34,19,1,1,0.75},{35,19,6,1,1.0},{41,19,1,1,0.25},{5,20,1,1,1.0},{6,20,1,1,0.25},{19,20,1,1,0.25},{20,20,6,1,1.0},{26,20,1,3,0.25},{35,20,1,1,0.5},{36,20,5,1,1.0},{41,20,1,1,0.5},{5,21,2,1,0.75},{21,21,1,1,0.75},{22,21,4,1,1.0},{36,21,1,1,0.25},{37,21,1,1,0.75},{38,21,3,1,1.0},{41,21,1,1,0.75},{5,22,1,1,0.75},{6,22,1,1,1.0},{7,22,1,1,0.25},{22,22,1,1,0.25},{23,22,3,1,1.0},{38,22,1,1,0.75},{39,22,3,1,1.0},{42,22,1,2,0.25},{5,23,1,1,0.5},{6,23,2,2,1.0},{24,23,1,1,0.75},{25,23,1,1,1.0},{39,23,1,1,0.75},{40,23,2,2,1.0},{5,24,1,2,0.25},{8,24,1,1,0.75},{22,24,1,1,1.0},{23,24,1,1,0.75},{42,24,1,1,0.5},{6,25,3,1,1.0},{9,25,1,1,0.75},{22,25,3,1,1.0},{25,25,1,1,0.25},{40,25,1,1,0.25},{41,25,1,1,1.0},{42,25,1,1,0.75},{6,26,1,1,0.75},{7,26,3,1,1.0},{10,26,1,1,0.75},{11,26,1,1,0.25},{22,26,4,1,1.0},{26,26,1,1,0.5},{41,26,2,1,0.75},{6,27,1,1,0.5},{7,27,5,1,1.0},{12,27,1,1,0.5},{22,27,5,1,1.0},{27,27,1,1,0.75},{28,27,1,1,0.25},{41,27,1,1,0.25},{42,27,1,1,1.0},{6,28,1,1,0.25},{7,28,6,1,1.0},{13,28,1,1,0.75},{14,28,1,1,0.5},{22,28,7,1,1.0},{29,28,1,1,0.5},{42,28,1,1,0.75},{7,29,1,1,0.5},{8,29,8,1,1.0},{16,29,1,1,0.75},{17,29,1,1,0.5},{18,29,4,1,0.25},{22,29,8,1,1.0},{30,29,1,1,0.75},{31,29,1,1,0.25},{42,29,1,1,0.5},{43,29,1,1,0.25},{8,30,24,1,1.0},{32,30,1,1,0.5},{42,30,2,1,0.25},{8,31,1,1,0.25},{9,31,24,1,1.0},{33,31,1,1,0.75},{34,31,1,1,0.25},{9,32,1,1,0.5},{10,32,25,1,1.0},{35,32,1,1,0.5},{10,33,1,1,0.5},{11,33,25,1,1.0},{36,33,1,1,0.75},{37,33,1,1,0.25},{11,34,1,1,0.5},{12,34,26,1,1.0},{38,34,1,2,0.5},{12,35,1,1,0.25},{13,35,1,1,0.75},{14,35,24,1,1.0},{14,36,1,1,0.25},{15,36,1,1,0.5},{16,36,20,1,1.0},{36,36,1,1,0.75},{37,36,1,1,0.25},{17,37,1,1,0.25},{18,37,1,1,0.5},{19,37,2,1,0.75},{21,37,14,1,1.0},{35,37,1,1,0.5},{22,38,11,1,1.0},{33,38,1,1,0.75},{34,38,1,1,0.25},{22,39,10,1,1.0},{32,39,1,1,0.5},{22,40,9,1,1.0},{31,40,1,1,0.25},{22,41,7,1,1.0},{29,41,1,1,0.75},{22,42,6,1,1.0},{28,42,1,1,0.5},{22,43,4,1,1.0},{26,43,1,1,0.75},{27,43,1,1,0.25},{22,44,3,1,1.0},{25,44,1,1,0.5},{22,45,1,1,1.0},{23,45,1,1,0.75},{24,45,1,1,0.25},{22,46,1,1,0.25}},
BED={{0,0,1,1,0.75},{1,0,4,1,1.0},{5,0,1,1,0.75},{0,1,6,17,1.0},{6,2,1,8,0.25},{11,4,1,1,0.5},{12,4,1,1,0.75},{13,4,2,1,1.0},{15,4,1,1,0.75},{16,4,1,1,0.5},{10,5,1,1,0.75},{11,5,7,1,1.0},{18,5,1,1,0.25},{9,6,1,1,0.75},{10,6,9,1,1.0},{19,6,1,1,0.25},{21,6,1,11,0.5},{22,6,18,1,1.0},{40,6,1,1,0.75},{41,6,1,1,0.5},{42,6,1,1,0.25},{8,7,1,1,0.5},{9,7,10,1,1.0},{19,7,1,1,0.75},{22,7,22,1,1.0},{44,7,1,1,0.5},{8,8,1,1,0.75},{9,8,11,1,1.0},{22,8,23,1,1.0},{45,8,1,1,0.75},{8,9,12,3,1.0},{20,9,1,3,0.25},{22,9,24,1,1.0},{46,9,1,1,0.5},{7,10,1,1,0.25},{22,10,25,2,1.0},{47,10,1,1,0.25},{6,11,1,7,0.25},{47,11,1,1,0.75},{8,12,1,1,0.75},{9,12,11,1,1.0},{22,12,26,4,1.0},{8,13,1,1,0.25},{9,13,10,1,1.0},{19,13,1,1,0.5},{9,14,1,1,0.5},{10,14,8,1,1.0},{18,14,1,1,0.75},{10,15,1,1,0.5},{11,15,6,1,1.0},{17,15,1,1,0.5},{12,16,4,1,0.5},{16,16,1,1,0.25},{22,16,26,1,0.75},{0,18,48,6,1.0},{0,24,6,6,1.0},{6,24,36,1,0.25},{42,24,6,6,1.0},{6,26,1,4,0.25},{0,30,6,1,0.25},{42,30,6,1,0.25}},
}
 local function hudIcon(p,name,x,y,size,color)
  local glyph=hudGlyphs[name]
  if glyph then p:glyph(name,glyph,x,y,size,color);return end
  local unit=size/24
  local function circle(cx,cy,r) p:box(x+(cx-r)*unit,y+(cy-r)*unit,r*2*unit,r*2*unit,color,1,r*unit) end
  local function line(ax,ay,bx,by,weight)
   local dx,dy=(bx-ax)*unit,(by-ay)*unit;local length=math.sqrt(dx*dx+dy*dy);local h=(weight or 2)*unit
   local o=p:box(x+(ax+bx)*unit/2-length/2,y+(ay+by)*unit/2-h/2,length,h,color,1,h/2);if o then o.Rotation=math.deg(math.atan2(dy,dx)) end
  end
  if name=="SYNTAX" then line(5,7,19,7,2.3);line(5,7,12,12,2.3);line(12,12,5,17,2.3);line(5,17,19,17,2.3);line(19,7,19,17,2.3)
   elseif name=="USER" then circle(12,7,4);p:box(x+3*unit,y+14*unit,18*unit,8*unit,color,1,5*unit)
  elseif name=="LINK" then
   for _,cx in ipairs({7,17}) do for i=0,15 do local a=i*math.pi/8;local b=(i+1)*math.pi/8;line(cx+5*math.cos(a),12+5*math.sin(a),cx+5*math.cos(b),12+5*math.sin(b),1.6) end end;line(8,12,16,12,2)
  elseif name=="CHROME" then circle(12,12,10);p:box(x+7*unit,y+7*unit,10*unit,10*unit,0x000000,1,5*unit);circle(12,12,3);line(13,3,20,15,1.8);line(4,14,17,14,1.8);line(8,20,13,7,1.8)
  elseif name=="SUCCESS" then line(5,12,10,17,2);line(10,17,19,6,2)
  elseif name=="WARNING" then line(12,5,12,14,2);circle(12,18,1)
  elseif name=="INFO" then line(12,9,12,19,2);circle(12,5,1)
  elseif name=="BED" then line(2,7,2,21,2);line(22,11,22,21,2);line(2,13,22,13,3);line(2,17,22,17,2);circle(7,8,3);line(11,10,22,10,3)
  elseif name=="CUBE" then line(12,3,22,8);line(22,8,22,18);line(22,18,12,23);line(12,23,2,18);line(2,18,2,8);line(2,8,12,3);line(2,8,12,13);line(12,13,22,8);line(12,13,12,23)
  end
 end

 local arrayEntries={}
 local arrayMode
 local arrayMetrics={}
 local suffixOverrides={}
 function api:SetModuleSuffix(id,value) assert(rows[id],"Unknown module");assert(value==nil or type(value)=="string");suffixOverrides[id]=value end
 local function arraySpring(s,target,dt,rate,immediate)
  if target~=s.target then if immediate then s.velocity=rate*(target-s.value) end;s.target=target end
   local offset=s.value-s.target;local linear=s.velocity+rate*offset;local decay=math.exp(-rate*dt)
  s.value=s.target+(offset+linear*dt)*decay;s.velocity=(s.velocity-rate*linear*dt)*decay
  return math.clamp(s.value,0,1)
 end
 local arrayTextCache={};local arrayTextCount=0
 local function arrayMeasure(t,size,font)
  if t=="" then return 0 end
  local key=font.Name..":"..tostring(size)..":"..t;if arrayTextCache[key] then return arrayTextCache[key] end
  if arrayTextCount>=800 then arrayTextCache={};arrayTextCount=0 end
  local w=TextService:GetTextSize(t,size,font,Vector2.new(10000,10000)).X;arrayTextCache[key]=w;arrayTextCount+=1;return w
 end
 local function moduleSuffix(row)
  local id=row.def.id;if suffixOverrides[id]~=nil then return suffixOverrides[id] end
  if id=="HUD" or id=="ClickGUI" or id=="Theme" then return "" end
  if id=="KillAura" then return tostring(state[id].settings.AutoBlock or "") end
  for _,s in ipairs(row.def.settings or {}) do if s.type=="select" then return tostring(state[id].settings[s.name] or "") end end
  return ""
 end
 local function bottomLeftShape(x,y,w,h,r,c,a)
  r=math.min(r,w,h);if r<=.001 then widgets:box(x,y,w,h,c,a,0);return end
  widgets:box(x+r,y,w-r,h,c,a,0);widgets:box(x,y,r,h-r,c,a,0)
  local steps=math.max(1,math.ceil(r*4));local unit=r/steps
  for i=0,steps-1 do local dy=(i+.5)*unit;local left=r-math.sqrt(math.max(0,r*r-dy*dy));widgets:box(x+left,y+h-r+i*unit,r-left,unit,c,a,0) end
 end

   -- XHan's original None presentation, with Opai spring motion.
 local xhan={buttons={},entries={},widths={},queue={},working=false,widthCount=0}
 xhan.root=new("Frame",hudRoot,{Name="StarlightArrayList",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=7000,Visible=false,Active=false})
 xhan.paint=pool(xhan.root,true)
 xhan.controls=new("Frame",xhan.root,{Name="Rows",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5000})
 pcall(function() xhan.font=Font.new("rbxassetid://12187365364",Enum.FontWeight.Medium) end)
 local function xhanMeasure(text,size)
  if text=="" then return 0 end
  local key=tostring(size)..":"..text;if xhan.widths[key] then return xhan.widths[key] end
  local fallback=arrayMeasure(text,size,Enum.Font.GothamMedium)
  if xhan.widthCount>512 and not xhan.working then xhan.widths={};xhan.widthCount=0 end
  xhan.widths[key]=fallback;xhan.widthCount+=1
  if xhan.font then
   xhan.queue[#xhan.queue+1]={key=key,text=text,size=size}
   if not xhan.working then
    xhan.working=true
    task.spawn(function()
     while #xhan.queue>0 and not dead do
      local job=table.remove(xhan.queue,1);local params
      local ok,bounds=pcall(function() params=Instance.new("GetTextBoundsParams");params.Text=job.text;params.Size=job.size;params.Width=10000;params.Font=xhan.font;return TextService:GetTextBoundsAsync(params) end)
      if params then params:Destroy() end
      if not dead and ok and bounds and type(bounds.X)=="number" and bounds.X>0 then xhan.widths[job.key]=bounds.X end
     end
     xhan.queue={};xhan.working=false
    end)
   end
  end
  return xhan.widths[key]
 end
  local function drawXHan(dt,view,factor,st,display)
  xhan.root.Visible=true;xhan.paint:begin()
    local mode=display=="BloomFlow" and "BloomFlow" or "None";local bloom=mode=="BloomFlow";local colors=st["XHan Colors"] or "Starlight"
  local strength=(st["XHan Shadow Strength"] or 78)/100;local size=st["XHan Text size"] or 15
     local rowH=bloom and math.max(size+2,(st["XHan Row height"] or 22)-3) or size+2
   local gap=0;local extra=0
  local allowed=st["XHan Categories"] or categoryOrder;local candidates={}
  for order,def in ipairs(options.Modules or {}) do
   local id=def.id;local row=rows[id];local target=state[id].enabled and not def.hidden and table.find(allowed,def.category)~=nil
   local item=xhan.entries[id]
    if target and not item then item={id=id,enabled=false,motion=spring(0),occupied=spring(0),changedAt=-100};xhan.entries[id]=item end
   if item then
     local now=os.clock()
     if item.enabled~=target then item.enabled=target;item.changedAt=now end
     if not animations then item.motion=spring(target and 1 or 0);item.occupied=spring(target and 1 or 0) end
     item.progress=arraySpring(item.motion,target and 1 or 0,dt,25,false)
     item.contribution=arraySpring(item.occupied,(target or now-item.changedAt<.065) and 1 or 0,dt,12.7,true)
     item.alpha=item.progress
     if target or item.progress>.001 or item.contribution>.001 then
      item.name=def.name or displayName(id);item.suffix=st["XHan Show suffix"]~=false and moduleSuffix(row) or "";item.mode=item.suffix~="" and " "..item.suffix or ""
       item.nameWidth=xhanMeasure(item.name,size);item.modeWidth=xhanMeasure(item.mode,size);item.width=math.ceil(item.nameWidth+item.modeWidth+(bloom and 12 or 13)+extra);item.order=order
      candidates[#candidates+1]=item
     elseif not target then xhan.entries[id]=nil end
   end
  end
  table.sort(candidates,function(a,b)
   if math.abs(a.width-b.width)>.5 then return a.width>b.width end
   if math.abs(a.nameWidth-b.nameWidth)>.5 then return a.nameWidth>b.nameWidth end
   if a.name:lower()~=b.name:lower() then return a.name:lower()<b.name:lower() end;return a.order<b.order
  end)
   local occupied=0
   for _,item in ipairs(candidates) do item.y=occupied;occupied+=item.contribution*(rowH+gap) end
    local widest=#candidates>0 and candidates[1].width or 0;local listH=math.max(0,occupied-gap)
  -- Reference defaults are in pixels; Samsara HUDScale=2 maps to the original 15/22px typography.
  local q=factor/2*(hudPlacements.ArrayList and hudPlacements.ArrayList.scale or 1)
   local fullHeight=math.max(1,#candidates*(rowH+gap)-gap)
   q=math.min(q,(view.X-36)/math.max(1,widest),(view.Y-32)/fullHeight)
  local at=hudPlacements.ArrayList;local right=at and at.x+widest*q or view.X-18*q;local top=at and at.y or 28*q
  right=math.clamp(right,widest*q+2,math.max(widest*q+2,view.X-2));top=math.clamp(top,2,math.max(2,view.Y-listH*q-2))
   arrayMetrics={mode=bloom and "BloomFlow" or "XHan",display=mode,palette=colors,glow=st["XHan Glow"]~=false,width=widest*q,height=listH*q,rows={}}
  if #candidates>0 then hudBounds.ArrayList=rect(right-widest*q,top,widest*q,listH*q) end
  local p=xhan.paint
  local function text(value,x,y,w,color,alpha)
   if value=="" then return end
   local label=p:text(value,x,y,size*q,w*q+1,color,false,Enum.TextXAlignment.Right)
   if label then if xhan.font then label.FontFace=xhan.font end;label.TextTransparency=1-alpha end
  end
   local total=math.max(1,#candidates)
    local flowPeriod=math.max(.5,st["XHan Flow speed"] or 3)
   for i,item in ipairs(candidates) do
    local offset=(item.width+8)*(1-item.progress)
    item.drawX=right-item.width*q+offset*q;item.drawY=top+item.y*q
     item.drawW=item.width*q;item.drawH=rowH*q;item.edgeH=math.max(0,item.contribution*rowH*q)
    item.topColor=bloom and flowingColor(colors,0,flowPeriod,((i-1)/total)*.92) or nil
    item.bottomColor=bloom and flowingColor(colors,0,flowPeriod,(i/total)*.92) or nil
    item.color=bloom and flowingColor(colors,0,flowPeriod,((i-.5)/total)*.92) or flowingColor(colors,i,st["XHan Flow speed"] or 3)
    arrayMetrics.rows[i]={id=item.id,name=item.name,suffix=item.suffix,x=item.drawX,y=item.drawY,width=item.drawW,height=item.drawH,offset=offset*q,alpha=item.alpha,color=item.color,progress=item.progress,contribution=item.contribution,radius=bloom and 0 or 4,enabled=item.enabled}
   end
   if bloom then
    -- The uploaded XHanUI's BloomFlow has no row gap: one gradient field and
    -- a continuous outer staircase, with no horizontal lines inside the list.
    for _,item in ipairs(candidates) do
      local x,y,w,h=item.drawX,item.drawY,item.drawW,item.edgeH+q
     if h>.5 and item.alpha>.001 then
      local fade=item.alpha
      if st["XHan Glow"]~=false then
       p:image("rbxassetid://104490578391522",x-19*q,y-13*q,w+38*q,h+26*q,0,item.color,.22*strength*fade,true)
       p:image("rbxassetid://102472648910048",x-11*q,y-8*q,w+22*q,h+16*q,0,item.color,.34*strength*fade,true)
      end
      p:box(x,y,w,h,0x0F1016,.76*fade,0)
      p:gradient(x,y,w,h,item.topColor,item.bottomColor,.13*fade,0)
     end
    end
    local function edge(x,y,w,h,first,last,fade)
     if w<=0 or h<=0 or fade<=.001 then return end
     if st["XHan Glow"]~=false then
      p:gradient(x-5*q,y-5*q,w+10*q,h+10*q,first,last,.045*strength*fade,2*q)
      p:gradient(x-2*q,y-2*q,w+4*q,h+4*q,first,last,.11*strength*fade,q)
     end
     p:gradient(x,y,w,h,first,last,.94*fade,0)
    end
    for i,item in ipairs(candidates) do
      local x,y,w,h=item.drawX,item.drawY,item.drawW,item.edgeH+q
     local fade=item.alpha;local line=math.min(2*q,h)
     if h>.5 then
      edge(x,y,line,h,item.topColor,item.bottomColor,fade)
      edge(x+w-line,y,line,h,item.topColor,item.bottomColor,fade)
      local prior=candidates[i-1]
      local priorPresence=prior and math.clamp(prior.alpha*prior.contribution,0,1) or 0
      edge(x,y,w,line,item.topColor,item.topColor,fade*(1-priorPresence))
      local nextItem=candidates[i+1]
      if nextItem then
       local nextPresence=math.clamp(nextItem.alpha*nextItem.contribution,0,1)
       edge(x,y+h-line,w,line,item.bottomColor,item.bottomColor,fade*(1-nextPresence))
       local step=math.max(0,nextItem.drawX-x)
       if step>.5 then edge(x,y+h-line,step,line,item.bottomColor,item.bottomColor,fade*nextPresence) end
      else edge(x,y+h-line,w,line,item.bottomColor,item.bottomColor,fade) end
     end
    end
   end
   for i,item in ipairs(candidates) do
    local x,y,w,h=item.drawX,item.drawY,item.drawW,item.drawH
    local color,fade=item.color,item.alpha
    if not bloom and st["XHan Glow"]~=false then
     local alpha=1-math.clamp(.94-.78*strength,.12,.94);p:glow(x-18*q,y-5*q,w+36*q,h+10*q,color,alpha*fade)
    end
    local rightPad=5+extra;local modeX=x+(item.width-rightPad-item.modeWidth)*q;local nameX=modeX-item.nameWidth*q
    local cy=y+h/2
    if st["XHan Text shadow"]~=false then
     local a=bloom and .36*fade or (1-math.clamp(.94-.66*strength,.22,.94))*fade
     text(item.name,nameX,cy+q,item.nameWidth,bloom and color or mixColor(color,0x000000,.75),a)
     text(item.mode,modeX,cy+q,item.modeWidth,0x34343A,math.max(0,a-.06*fade))
    end
    text(item.name,nameX,cy,item.nameWidth,color,fade);text(item.mode,modeX,cy,item.modeWidth,0xE6E6E8,fade)
   local slot=xhan.buttons[i]
   if not slot then
    local button=new("TextButton",xhan.controls,{Name="Feature",Text="",BackgroundTransparency=1,AutoButtonColor=false,Active=true,Selectable=false})
    slot={button=button};xhan.buttons[i]=slot
    connect(button.InputBegan,function(input)
      if not dead and not visible and not hudEditing and not appearanceOpen and slot.id and state[slot.id].enabled and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then api:SetEnabled(slot.id,false) end
    end)
   end
    slot.id=item.id;slot.button.Name=item.id;slot.button.Visible=item.enabled and fade>.03 and not visible and not hudEditing and not appearanceOpen;slot.button.Position=UDim2.fromOffset(x,y);slot.button.Size=UDim2.fromOffset(w,h);slot.button.ZIndex=i
  end
  for i=#candidates+1,#xhan.buttons do xhan.buttons[i].id=nil;xhan.buttons[i].button.Visible=false end
  p:finish()
 end
local function drawArrayList(dt,view,factor,st,p)
   local mode=st["ArrayList mode"] or "XHan";local opai=mode=="Opai";xhan.root.Visible=false
  if not widgetEnabled("ArrayList") then arrayEntries={};xhan.entries={};arrayMode=nil;arrayMetrics={};return end
  if arrayMode~=mode then arrayEntries={};xhan.entries={};arrayMode=mode end
    if mode=="XHan" or mode=="BloomFlow" then drawXHan(dt,view,factor,st,mode);return end
    local lower=st[opai and "Opai Lowercase" or "Lowercase"]
  local showSuffix=st[opai and "Opai Show suffix" or "Show suffix"]
  local allowed=st[opai and "Opai Categories" or "Categories"] or categoryOrder
  local font=opai and Enum.Font.GothamBold or Enum.Font.GothamMedium;local size=opai and 9.08 or 8;local candidates={}
  for id,row in pairs(rows) do
   local item=arrayEntries[id]
   if not item then item={id=id,motion=spring(0),occupied=spring(0),enabled=false,changedAt=-100};arrayEntries[id]=item end
   local label=opai and displayName(id) or id;local suffix=showSuffix and moduleSuffix(row) or ""
   if lower then label=label:lower();suffix=suffix:lower() end
   item.name=label;item.suffix=suffix;item.font=font;item.nameWidth=arrayMeasure(label,size,font);item.gap=suffix~="" and arrayMeasure(" ",size,font) or 0
   item.text=label..(suffix~="" and " "..suffix or "");item.width=opai and (3+item.nameWidth+item.gap+arrayMeasure(suffix,size,font)+2+1) or arrayMeasure(item.text,size,font)
   item.target=state[id].enabled and not row.def.hidden and table.find(allowed,row.def.category)~=nil;candidates[#candidates+1]=item
  end
  table.sort(candidates,function(a,b)if a.width==b.width then return a.id<b.id end;return a.width>b.width end)
  local occupied=0;local visible={};local now=os.clock()
  for _,item in ipairs(candidates) do
   if item.enabled~=item.target then item.enabled=item.target;item.changedAt=now end
   if not animations then item.motion=spring(item.enabled and 1 or 0);item.occupied=spring(item.enabled and 1 or 0) end
   item.progress=arraySpring(item.motion,item.enabled and 1 or 0,dt,25,false)
   item.contribution=arraySpring(item.occupied,(item.enabled or now-item.changedAt<.065) and 1 or 0,dt,12.7,true)
   item.y=occupied
   if item.enabled or item.progress>.001 or item.contribution>.001 then visible[#visible+1]=item;occupied+=item.contribution*12 end
  end
  local scale=factor*(hudPlacements.ArrayList and hudPlacements.ArrayList.scale or 1)
  local widest=#visible>0 and visible[1].width or 0;local at=hudPlacements.ArrayList
  local right=at and at.x+widest*scale or (view.X-(opai and .5*scale or 0));local top=at and at.y or 0
  right=math.clamp(right,widest*scale+1,math.max(widest*scale+1,view.X));top=math.clamp(top,0,math.max(0,view.Y-occupied*scale))
  arrayMetrics={mode=opai and "Opai" or "Default",rows={},width=widest*scale,height=occupied*scale}
  if #visible>0 then hudBounds.ArrayList=rect(math.max(0,right-widest*scale),top,widest*scale,math.max(12,occupied)*scale) end
  local background=st[opai and "Opai Background" or "Background"]~=false
  for i,item in ipairs(visible) do
    item.x=right-item.width*scale+(item.width+8)*(1-item.progress)*scale;item.py=top+item.y*scale
   item.radius=math.min(5,math.max(0,item.width-(visible[i+1] and visible[i+1].width or 0)))
   arrayMetrics.rows[i]={id=item.id,name=item.name,suffix=item.suffix,x=item.x,y=item.py,width=item.width*scale,progress=item.progress,contribution=item.contribution,radius=item.radius}
  end
  if opai then
   if st["Opai Shadow"]~=false then
    for _,item in ipairs(visible) do for layer=3,1,-1 do local spread=layer*1.7*scale;widgets:box(item.x-spread,item.py-spread,item.width*scale+spread*2,12*scale+spread*2,0x000000,.028,math.min(5,item.radius)*scale+spread) end end
   end
   if background then for _,item in ipairs(visible) do bottomLeftShape(item.x,item.py,item.width*scale,12*scale,item.radius*scale,0x101010,.8) end end
   for _,item in ipairs(visible) do
    local label=widgets:text(item.name,item.x+3*scale,item.py+6*scale,9.08*scale,item.nameWidth*scale+1,0xFFFFFF);if label then label.Font=font end
    if item.suffix~="" then local label=widgets:text(item.suffix,item.x+(3+item.nameWidth+item.gap)*scale,item.py+6*scale,9.08*scale,math.max(1,(item.width-6-item.nameWidth-item.gap)*scale+1),p.accent);if label then label.Font=font end end
   end
   if st["Opai Right line"]~=false then for _,item in ipairs(visible) do widgets:box(item.x+(item.width-1)*scale,item.py,scale,12*scale,p.accent,1,0) end end
  else
   local bar=st["Bar mode"] or "Left"
   for i,item in ipairs(visible) do
    local color=clientColor((i-1)*20);local x,y=item.x,item.py;local w=item.width*scale
    if background then widgets:box(x-6.5*scale,y,w+6.5*scale,12*scale,0x090909,.5,0) end
    if bar~="None" then local bx=bar=="Left" and x-4.5*scale or x+w-2.5*scale;widgets:box(bx+.5*scale,y+2.5*scale,scale,8*scale,0x000000,.55,scale);widgets:box(bx,y+2*scale,scale,8*scale,color,1,scale) end
    local offset=bar=="Left" and 2 or bar=="None" and 3.5 or 4.25
    widgets:text(item.text,x-offset*scale+.5*scale,y+6.5*scale+.5*scale,8*scale,w+1,0x000000)
    widgets:text(item.text,x-offset*scale,y+6.5*scale,8*scale,w+1,color)
   end
  end
 end

 local function drawHUDWidgets(dt)
   widgets:begin();hudBounds={};local view=gui.AbsoluteSize;local factor=hudScale
  local p=currentPalette();local st=state.HUD and state.HUD.settings or {}
  factor=math.min(factor,math.max(.1,(view.X-4)/182),math.max(.1,(view.Y-4)/166))
  local function text(t,x,y,size,w,color) widgets:text(t,x,y,size,w,color or p.text) end
  drawArrayList(dt,view,factor,st,p)

  local target=islandState.target
  if not target and (visible or hudEditing) then local humanoid=Players.LocalPlayer.Character and Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid");if humanoid then target={name=Players.LocalPlayer.DisplayName or Players.LocalPlayer.Name or "Player",health=humanoid.Health,maxHealth=humanoid.MaxHealth,userId=Players.LocalPlayer.UserId} end end

  if target and widgetEnabled("TargetHUD") then
   local factor=factor*(hudPlacements.TargetHUD and hudPlacements.TargetHUD.scale or 1)
   local health=math.clamp(tonumber(target.health) or 0,0,math.max(1,tonumber(target.maxHealth) or 100));local maximum=math.max(1,tonumber(target.maxHealth) or 100)
   local key=tostring(target.userId or target.name);local sample=islandState.healthSample
   if not sample or sample.key~=key then sample={key=key,goal=health,maximum=maximum,fill=health,trail=health,fillFrom=health,trailFrom=health,at=os.clock(),damage=false};islandState.healthSample=sample end
   local elapsed=(os.clock()-sample.at)*1000
   sample.fill=sample.goal+(sample.fillFrom-sample.goal)*math.exp(-elapsed/65)
   sample.trail=sample.damage and math.max(sample.fill,sample.goal+(sample.trailFrom-sample.goal)*math.exp(-math.max(0,elapsed-100)/220)) or sample.fill
   if sample.goal~=health or sample.maximum~=maximum then sample.fillFrom=sample.fill;sample.trailFrom=math.max(sample.fill,sample.trail);sample.damage=health<sample.fill;sample.goal=health;sample.maximum=maximum;sample.at=os.clock() end
    -- One XHanUI-inspired target card replaces the old Classic and Opai modes.
    local name=tostring(target.name or "Target")
    local logicalWidth=math.clamp(60+arrayMeasure(name,9.5,Enum.Font.GothamMedium),142,240)
    factor=math.min(factor,(view.X-8)/logicalWidth,(view.Y-8)/52)
    local w,h=logicalWidth*factor,52*factor
    local x,y=placeWidget("TargetHUD",view.X/2+8*factor,view.Y/2+4*factor,w,h)
    local accent=flowingColor("Starlight",1,3.3)
    local accent2=flowingColor("Starlight",2,3.3)
    for layer=3,1,-1 do local spread=layer*2*factor;widgets:box(x-spread,y-spread,w+2*spread,h+2*spread,0x000000,.035,9*factor+spread) end
    widgets:glow(x-7*factor,y-6*factor,w+14*factor,h+12*factor,accent,.11)
    widgets:gradient(x,y,w,h,0x151C25,0x090D12,.96,9*factor)
    widgets:stroke(x,y,w,h,0x303A47,.75,9*factor,factor)
    widgets:gradient(x+7*factor,y+3*factor,w-14*factor,1.5*factor,accent,accent2,.85,.75*factor)
    widgets:box(x+8*factor,y+9*factor,34*factor,34*factor,0x111820,.95,7*factor)
    widgets:stroke(x+8*factor,y+9*factor,34*factor,34*factor,accent,.5,7*factor,.75*factor)
    hudIcon(widgets,"USER",x+17*factor,y+17*factor,16*factor,accent)
    local userId=tonumber(target.userId)
    if userId and userId>0 then
     widgets:image("rbxthumb://type=AvatarHeadShot&id="..math.floor(userId).."&w=150&h=150",x+8*factor,y+9*factor,34*factor,34*factor,7*factor)
    end
    text("TARGET",x+49*factor,y+10*factor,5.5*factor,w-60*factor,0x929EAC)
    text(name,x+48*factor,y+21*factor,9.5*factor,w-59*factor,0xF2F5F8)
    local rounded=math.round(sample.fill*10)/10
    local current=rounded%1==0 and tostring(math.round(rounded)) or string.format("%.1f",rounded)
    local healthText=current.." / "..tostring(math.round(maximum)).." HP"
    text(healthText,x+49*factor,y+32*factor,7*factor,w-60*factor,0xB7C0CB)
    local bx,by,bw=x+49*factor,y+40*factor,w-60*factor
    widgets:box(bx,by,bw,5*factor,0x283340,.9,2.5*factor)
    widgets:box(bx,by,bw*math.clamp(sample.trail/maximum,0,1),5*factor,0xE9A8BC,.55,2.5*factor)
    widgets:gradient(bx,by,bw*math.clamp(sample.fill/maximum,0,1),5*factor,accent,accent2,1,2.5*factor)
  end
  widgets:finish();updateHUDControls()
 end
 local function renderHUD(dt,frameDelta)
  expireNotices();local view=gui.AbsoluteSize
  if view.X<=36 or view.Y<=32 then island.Visible=false;widgetRoot.Visible=false;xhan.root.Visible=false;hudControls.Visible=false;return end
  widgetRoot.Visible=true;hudControls.Visible=true
    local scale=math.min(hudScale,(view.X-8)/70)
    islandState.renderScale=scale
    -- Render the island in physical pixels so shell morphing does not scale text.
    shell.drawScale=scale;ink.drawScale=scale
   island.Visible=widgetEnabled("Dynamic Island");drawHUDWidgets(dt)
  local delta=frameDelta or dt
  if delta>0 then islandState.fps=ease(islandState.fps>0 and islandState.fps or 1/delta,1/delta,dt,3) end
  if os.clock()>=islandState.nextPing then islandState.nextPing=os.clock()+1;local ok,ping=pcall(function() return Players.LocalPlayer:GetNetworkPing() end);islandState.ping=ok and type(ping)=="number" and math.max(0,math.round(ping*1000)) or nil end
  if not island.Visible then return end
  local palette=currentPalette();local ping=islandState.ping
  local pingColor=ping and (ping<100 and 0x80C810 or ping<=400 and 0xC87D28 or 0xCA3E2E) or palette.text
  local segments={{icon="SYNTAX",text="Syntax",color=palette.accent},{icon="USER",text=options.Username or Players.LocalPlayer.DisplayName or Players.LocalPlayer.Name or "Player",color=palette.text},{icon="LINK",text=(ping and tostring(ping).."ms to " or "")..(options.ServerName or "Roblox"),color=pingColor},{icon="REFRESH",text=tostring(math.round(islandState.fps)).." fps",color=palette.text}}
    local maximum=view.X/scale-8
    local idleWidth=21.5;for i,s in ipairs(segments) do s.w=measure(s.text,8);idleWidth+=14+s.w+(i<4 and measure("  ·  ",8) or 0) end
    local idle=#notices==0
    if idle then islandState.stacked=islandState.stacked and idleWidth>maximum-12 or idleWidth>maximum end
    local stacked=idle and islandState.stacked
   local destWidth,destHeight,destTop=math.min(idleWidth,maximum),23,21
   if stacked then
    destWidth=0;for _,s in ipairs(segments) do destWidth=math.max(destWidth,s.w+32) end
    destWidth=math.min(maximum,math.max(70,destWidth));destHeight=8
     for _,s in ipairs(segments) do s.textHeight=wrappedHeight(s.text,8,math.max(12,destWidth-30));s.rowHeight=math.max(16,s.textHeight+4);destHeight+=s.rowHeight end
   elseif not idle then
    destWidth=0;for _,n in ipairs(notices) do
       local detail=n.kind=="toggle" and toggleDetail(n.detail,n.value) or n.detail
       local titleSize=n.kind=="breaking" and 9 or 10;local detailSize=n.kind=="breaking" and 8 or 9
       n.width=(n.kind=="toggle" and 54 or 46)+math.max(measure(n.title,titleSize),measure(detail,detailSize))
     destWidth=math.max(destWidth,n.width);if n.kind=="scaffold" then destTop=15 end
    end
    destWidth=math.min(maximum,math.max(52,destWidth));destHeight=0
    local available=math.max(8,destWidth-42)
    for _,n in ipairs(notices) do
     local progress=n.kind=="breaking" or n.kind=="scaffold"
      local titleSize=n.kind=="breaking" and 9 or 10;local detailSize=n.kind=="breaking" and 8 or 9
      local titleHeight=wrappedHeight(n.title,titleSize,available)
      local detail=n.kind=="toggle" and tostring(n.detail):gsub("%s+$","") or n.detail
      local suffix=n.value and "Enabled" or "Disabled"
      local prefix=n.kind=="toggle" and (detail~="" and detail.." " or "") or detail
      local prefixWidth=n.kind=="toggle" and (prefix~="" and measure(prefix,detailSize) or 0) or 0
      local suffixWidth=n.kind=="toggle" and measure(suffix,detailSize) or 0
      local periodWidth=n.kind=="toggle" and measure(".",detailSize) or 0
      local inline=n.kind=="toggle" and prefixWidth+suffixWidth+periodWidth<=available
      local prefixHeight=n.kind=="toggle" and (detail~="" and wrappedHeight(detail,detailSize,available) or 0) or 0
      local suffixHeight=n.kind=="toggle" and wrappedHeight(suffix..".",detailSize,available) or 0
      local detailHeight=n.kind=="toggle" and (inline and suffixHeight or prefixHeight+(prefixHeight>0 and 2 or 0)+suffixHeight) or wrappedHeight(detail,detailSize,available)
      local baseHeight=n.kind=="breaking" and 48 or n.kind=="scaffold" and 50 or 36
      local rowHeight=math.max(baseHeight,3+titleHeight+1+detailHeight+(progress and 18 or 6))
      n.layout={detail=detail,prefix=prefix,suffix=suffix,inline=inline,prefixWidth=prefixWidth,suffixWidth=suffixWidth,periodWidth=periodWidth,prefixHeight=prefixHeight,suffixHeight=suffixHeight,titleSize=titleSize,detailSize=detailSize,titleHeight=titleHeight,detailHeight=detailHeight,rowHeight=rowHeight}
     destHeight+=rowHeight
    end
   end
   local impulse=idle~=islandState.wasIdle and (idle and 5.5 or 7.25) or 0
     local w=math.min(maximum,math.max(1,morph(islandState.width,destWidth,delta,impulse)))
     local h=math.max(1,morph(islandState.height,destHeight,delta,impulse));local top=morph(islandState.top,destTop,delta,impulse)
    islandState.idle=idle;islandState.wasIdle=idle;island.Position=UDim2.fromOffset((view.X-w*scale)/2,top);island.Size=UDim2.fromOffset(w*scale,h*scale)
  local radius=idle and h/2 or 8.5
   shell:begin();ink:begin()
   islandBackdrop.Size=UDim2.fromOffset(w*scale,h*scale);islandCorner.CornerRadius=UDim.new(0,radius*scale)
   local shadowStrength=islandShadow/100
   if islandSoftShadow then
    islandSoftShadow.Enabled=shadowStrength>0
    islandSoftShadow.BlurRadius=UDim.new(0,(8+22*shadowStrength)*scale)
    islandSoftShadow.Spread=UDim2.fromOffset((2+7*shadowStrength)*scale,(2+7*shadowStrength)*scale)
     islandSoftShadow.Offset=UDim2.fromOffset(0,0)
    islandSoftShadow.Transparency=1-.8*shadowStrength
   elseif shadowStrength>0 then
    local spread=9+10*shadowStrength
    shell:glow(-spread,-spread,w+spread*2,h+spread*2,0x000000,.2+.52*shadowStrength)
    for layer=9,1,-1 do local distance=layer*(.75+shadowStrength*.8);shell:box(-distance,-distance,w+distance*2,h+distance*2,0x000000,(.012+.04*(1-layer/9))*shadowStrength*2,radius+distance) end
   end
   islandClip.Position=UDim2.fromOffset(2*scale,scale);islandClip.Size=UDim2.fromOffset(math.max(0,w-4)*scale,math.max(0,h-2)*scale)
    if idle then
    if stacked then
      local y=4
     for _,s in ipairs(segments) do
      hudIcon(ink,s.icon,7,y+(s.rowHeight-10.5)/2,10.5,s.color)
        ink:textBlock(s.text,23,y+(s.rowHeight-s.textHeight)/2,8,math.max(12,destWidth-30),s.textHeight,s.color)
      y+=s.rowHeight
     end
    else
     local x=7
     for i,s in ipairs(segments) do
       hudIcon(ink,s.icon,x,23/2-6.25,10.5,s.color);x+=14
        ink:text(s.text,x,23/2-1,8,s.w,s.color);x+=s.w
        if i<4 then local sep=measure("  ·  ",8);ink:text("  ·  ",x,23/2-1,8,sep,palette.text);x+=sep end
     end
     end
  else
    local y=0
   for _,n in ipairs(notices) do
     local progress=n.kind=="breaking" or n.kind=="scaffold";local rowHeight=n.layout.rowHeight
    if n.kind=="toggle" then
     local t=not animations and 1 or math.clamp((os.clock()-n.started)*animationSpeed/.2,0,1);if n.value then t=t==1 and 1 or 1-2^(-10*t) end
     n.toggle=(n.toggleFrom or 0)+((n.value and 1 or 0)-(n.toggleFrom or 0))*t
     local v=n.toggle;local outer=ink:box(3,y+10,26,16,palette.outline,1,8);outer.BackgroundColor3=rgb(palette.outline):Lerp(rgb(palette.accent),v)
     local inner=ink:box(4,y+11,24,14,0x36343B,1,7);inner.BackgroundColor3=rgb(0x36343B):Lerp(rgb(palette.accent),v)
     local knob=ink:box(6.5+8.5*v,y+13.5-1.25*v,8+3.5*v,8+3.5*v,0x858488,1,6)
     knob.BackgroundColor3=rgb(0x858488):Lerp(rgb(selectedTheme()=="Light Pink" and 0x7C5752 or 0x5B5F7C),v)
    elseif progress then ink:box(2,y+5,n.kind=="breaking" and 27 or 28,n.kind=="breaking" and 27 or 28,0x141616,200/255,7);hudIcon(ink,n.kind=="breaking" and "BED" or "CUBE",8,y+11,16,palette.accent)
    else
     local color=n.kind=="success" and 0x5F8F50 or n.kind=="warning" and 0x8F5050 or 0x307593
     ink:box(5,y+8,24,24,color,200/255,7);hudIcon(ink,n.kind:upper(),10,y+12,14,0xFFFFFF)
    end
       local layout=n.layout;local textWidth=math.max(8,destWidth-42);local detailY=y+3+layout.titleHeight+1
      ink:textBlock(n.title,34,y+3,layout.titleSize,textWidth,layout.titleHeight,0xFFFFFF)
      if n.kind=="toggle" then
       local statusColor=n.value and 0x55FF55 or 0xFF5555
       if layout.inline then
        if layout.prefix~="" then ink:textBlock(layout.prefix,34,detailY,layout.detailSize,layout.prefixWidth,layout.suffixHeight,0xFFFFFF) end
        ink:textBlock(layout.suffix,34+layout.prefixWidth,detailY,layout.detailSize,layout.suffixWidth,layout.suffixHeight,statusColor)
        ink:textBlock(".",34+layout.prefixWidth+layout.suffixWidth,detailY,layout.detailSize,layout.periodWidth,layout.suffixHeight,0xFFFFFF)
       else
         if layout.detail~="" then ink:textBlock(layout.detail,34,detailY,layout.detailSize,textWidth,layout.prefixHeight,0xFFFFFF) end
        local statusY=detailY+layout.prefixHeight+(layout.prefixHeight>0 and 2 or 0)
         if layout.suffixWidth+layout.periodWidth<=textWidth then
          ink:textBlock(layout.suffix,34,statusY,layout.detailSize,layout.suffixWidth,layout.suffixHeight,statusColor)
          ink:textBlock(".",34+layout.suffixWidth,statusY,layout.detailSize,layout.periodWidth,layout.suffixHeight,0xFFFFFF)
          else
           local status=ink:textBlock(layout.suffix..".",34,statusY,layout.detailSize,textWidth,layout.suffixHeight,0xFFFFFF)
           status.RichText=true;status.Text='<font color="'..(n.value and "#55FF55" or "#FF5555")..'">'..layout.suffix..'</font>.'
          end
       end
      elseif layout.detail~="" then ink:textBlock(layout.detail,34,detailY,layout.detailSize,textWidth,layout.detailHeight,0xFFFFFF) end
     if progress then local yy=y+rowHeight-11;local barH=n.kind=="breaking" and 7.5 or 8
     ink:box(2,yy,math.max(0,w-8),barH,0x34343D,n.kind=="breaking" and 112/255 or 1,barH/2)
     ink:box(2,yy,math.max(0,w-8)*n.value,barH,accentColor(selectedTheme()=="Light Pink" and 0xD19997 or 0x9CA5DA),1,barH/2)
    end
     y+=rowHeight
   end
   end
  shell:finish();ink:finish()
 end

 -- Read the actual native canvas transform, including UIScale and screen origin.
 local function localPoint(position)
  local origin,size=root.AbsolutePosition,root.AbsoluteSize
  local sx=size.X/math.max(1,root.Size.X.Offset);local sy=size.Y/math.max(1,root.Size.Y.Offset)
  if sx<=0 or sy<=0 then return -100,-100 end
  return (position.X-origin.X)/sx,(position.Y-origin.Y)/sy
 end
 local function pointerPoint(input)
  -- InputObject.Position and AbsolutePosition share Core UI Safe Inset coordinates.
  if input and input.UserInputType~=Enum.UserInputType.MouseWheel then return localPoint(input.Position) end
  -- GetMouseLocation is in physical screen coordinates: reconcile the origin first.
  local position=Input:GetMouseLocation();local inset=GuiService:GetGuiInset()
  return localPoint(Vector2.new(position.X-inset.X,position.Y-inset.Y))
 end
 local function syncNativeHits()
  for i,h in ipairs(hits) do
   local slot=nativeSlots[i]
   if not slot then
    local object=new("TextButton",nativeLayer,{Name="Hit",Text="",BackgroundTransparency=1,AutoButtonColor=false,Active=true,Selectable=false})
    slot={object=object};nativeSlots[i]=slot
    connect(object.InputBegan,function(input) if nativeDispatch and slot.hit and object.Visible then nativeDispatch(slot.hit,input) end end)
   end
   slot.hit=h;local r=h.rect;local object=slot.object
   object.Name=tostring(h.action);object.Position=UDim2.fromOffset(r.x,r.y);object.Size=UDim2.fromOffset(r.w,r.h);object.ZIndex=i;object.Visible=visible
   object.BackgroundTransparency=diagnostic and .8 or 1;object.BackgroundColor3=rgb(i%2==0 and accentColor(0x3A85E2) or 0xFFB4AA)
  end
  for i=#hits+1,#nativeSlots do nativeSlots[i].hit=nil;nativeSlots[i].object.Visible=false end
 end
 function api:SetDiagnostics(value) assert(type(value)=="boolean");diagnostic=value end
 nativeDispatch=function(h,input)
  if dead or not visible then return end
  local kind=input.UserInputType
  local button=kind==Enum.UserInputType.MouseButton1 and 0 or kind==Enum.UserInputType.MouseButton2 and 1 or kind==Enum.UserInputType.MouseButton3 and 2 or kind==Enum.UserInputType.Touch and 0 or nil
  if button==nil then return end
  local x,y=pointerPoint(input)
  if kind==Enum.UserInputType.Touch then
   if touch then return end;touch=input
   if h.action=="appearanceScale" or h.action=="slider" or h.action=="scrollbar" or h.action=="configHeader" or h.action=="altDrag" or h.action=="modernDrag" then click(0,x,y,h)
   else gesture={x=x,y=y,lastX=x,lastY=y,start=os.clock(),used=false,moved=false,hit=h};mx,my=x,y end
  else click(button,x,y,h) end
 end
 connect(catcher.InputBegan,function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.Touch then dropdown=nil end
 end)
 local function move(x,y)
  mx,my=x,y;if appearanceSliding then appearanceSlide(x);return end;slide(x)
  if not drag then return end
  if drag.kind=="alternate" then local at=alt.positions[activeStyle];at.x=x-drag.dx;at.y=y-drag.dy
  elseif drag.kind=="altScrollbar" then alt.target=math.clamp(((y-alt.y)/alt.s-84)/516,0,1)*alt.max;alt.scroll=alt.target
  elseif drag.kind=="modern" then local win=drag.win;win.x=math.clamp(x-drag.dx,4,math.max(4,width-156));win.y=math.clamp(y-drag.dy,4,math.max(4,height-204))
  elseif drag.kind=="column" then local c=drag.c;c.x=math.clamp(x-drag.dx+horizontal,4,math.max(4,width-W-4+horizontal));c.y=math.clamp(y-drag.dy,4,math.max(4,height-H-c.bodyH-8))
  elseif drag.kind=="config" then config.x=math.clamp(x-drag.dx,4,math.max(4,width-W-4));config.y=math.clamp(y-drag.dy,4,math.max(4,height-H-86))
  elseif drag.kind=="scrollbar" then local c=drag.c;c.scroll=math.clamp((y-c.y-H-2-drag.grab)/math.max(1,drag.travel)*c.maxScroll,0,c.maxScroll);c.target=c.scroll end
 end
 render=function(dt)
  if dead then return end;local frameDelta=dt or 0;local motionDelta=math.min(frameDelta,.1)*animationSpeed
   if animations then visualTime+=motionDelta;flowTime+=math.min(frameDelta,.1) end
  dt=animations and motionDelta or 10
  opacity=animations and ease(opacity,visible and 1 or 0,dt,30) or (visible and 1 or 0);catcher.Visible=visible;root.Visible=opacity>.005
   local localBlur=state.ClickGUI and state.ClickGUI.settings["Local Blur"]~=false
   blur.Size=(options.Blur==false or localBlur) and 0 or 10*opacity
  local nextStyle=selectedStyle()
  if activeStyle~=nextStyle then activeStyle=nextStyle;dropdown=nil;sliding=nil;binding=nil;drag=nil;gesture=nil;touch=nil;config.open=false;alt.nav=1;alt.target=0;alt.scroll=0;searchBox:ReleaseFocus();searchBox.Text="";altName:ReleaseFocus() end
  renderHUD(dt,frameDelta)
   if not root.Visible then updateRegionalBlur(blurPane,altGlass,false);appearanceRoot.Visible=false;accentBox.Visible=false;hits={};syncNativeHits();return end
  local elapsed=(os.clock()-opened)*animationSpeed;zoom=not animations and 1 or visible and (elapsed>=.32 and 1 or 1+.18*math.exp(-17*elapsed)*math.cos(23*elapsed)) or 1+.6*(1-opacity)
  offsetX=(gui.AbsoluteSize.X-width*k*zoom)/2;offsetY=(gui.AbsoluteSize.Y-height*k*zoom)/2
  root.Position=UDim2.fromOffset(offsetX,offsetY);root.Size=UDim2.fromOffset(width,height);scaling.Scale=k*zoom
  if not touch then mx,my=pointerPoint(nil) end
  hits={};main:begin();front:begin();searchBox.Visible=false;altName.Visible=false;editor.Visible=false;jsonEditor.Visible=false
  for _,row in pairs(rows) do if row.nlFrame then row.nlFrame.Visible=false end end
  for _,win in pairs(alt.windows) do win.frame.Visible=false end
  for _,c in ipairs(columns) do c.frame.Visible=activeStyle=="Opai" end
  altRoot.Visible=false
  if activeStyle=="Opai" then drawColumns(dt);drawConfig(dt) else drawAlternatives(dt);if activeStyle=="Modern" and config.open then drawModernConfigs() end end
   updateRegionalBlur(blurPane,altGlass,visible and localBlur and activeStyle=="Neverlose")
  drawThemeGlow()
   drawDropdown(dt)
  if animations and ripple then local t=(os.clock()-ripple.start)*animationSpeed/.32;if t<1 then local r=4+18*(1-(1-t)^3);front:stroke(ripple.x-r,ripple.y-r,r*2,r*2,currentPalette().accent,.45*(1-t),r,1) else ripple=nil end end
  if activeStyle~="Neverlose" then
   local x,y=width-34.7,height-34.7;front:box(x,y,26.7,26.7,currentPalette().accent,1,5)
   line(front,x+7,y+18,x+18,y+7,0x101014,5);line(front,x+6,y+22.8,x+22,y+22.8,0x101014,1.6);hit(rect(x,y,26.7,26.7),"hudEditRMB")
  end
   local ax,ay=width-67,height-34.7;local aaHover=inside(rect(ax,ay,26.7,26.7),mx,my)
   aaHoverT=animations and ease(aaHoverT,(aaHover or appearanceOpen) and 1 or 0,math.min(frameDelta,.1),12) or ((aaHover or appearanceOpen) and 1 or 0)
   local aaExpand=aaHoverT*1.2;local aaBox=front:box(ax-aaExpand,ay-aaExpand,26.7+aaExpand*2,26.7+aaExpand*2,currentPalette().field,1,5+aaExpand)
   aaBox.BackgroundColor3=rgb(currentPalette().field):Lerp(rgb(currentPalette().selected),aaHoverT)
   front:text("Aa",ax,ay+13,10,26.7,currentPalette().accent,false,Enum.TextXAlignment.Center);hit(rect(ax,ay,26.7,26.7),"appearanceOpen")
   local lx=width-99.3;front:box(lx,ay,26.7,26.7,currentPalette().field,1,5);front:text(language=="English" and "中" or "EN",lx,ay+13,9,26.7,currentPalette().accent,false,Enum.TextXAlignment.Center);hit(rect(lx,ay,26.7,26.7),"languageToggle")
   drawAppearance(frameDelta)
  main:finish();front:finish();syncNativeHits()
  if gesture and not gesture.used and not gesture.moved and os.clock()-gesture.start>.45 then
   local h=gesture.hit;if h and (h.action=="module" or h.action=="header" or h.action=="hudEditRMB") then gesture.used=true;click(1,gesture.x,gesture.y,gesture.hit);if h.action=="header" then drag={kind="column",c=h.data,dx=gesture.x-(h.data.x-horizontal),dy=gesture.y-h.data.y} end end
  end
 end
 connect(Input.InputBegan,function(input,processed)
  if dead then return end
  local key=input.KeyCode;local kind=input.UserInputType
  if kind==Enum.UserInputType.Keyboard then
   if Input:GetFocusedTextBox() then return end
   if binding then state[binding.def.id].key=(key==Enum.KeyCode.Escape or key==Enum.KeyCode.Backspace) and "Unknown" or key.Name;notify(binding.def.id,"key",state[binding.def.id].key);binding=nil;return end
   if key==Enum.KeyCode.F7 then if visible then appearanceOpen=not appearanceOpen;dropdown=nil end;return end
   if key==Enum.KeyCode.F8 then api:SetDiagnostics(not diagnostic);return end
   if key==Enum.KeyCode.F and activeStyle~="Opai" and (Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)) then searchBox:CaptureFocus();return end
   if key==Enum.KeyCode.RightShift then api:SetVisible(not visible);return end
   if key==Enum.KeyCode.Escape and visible then if appearanceOpen then appearanceOpen=false;appearanceSliding=nil;accentBox:ReleaseFocus() elseif dropdown then dropdown=nil elseif config.open then config.open=false else api:SetVisible(false) end;return end
   if not processed then for id,st in pairs(state) do if st.key~="Unknown" and st.key==key.Name then api:SetEnabled(id,not st.enabled) end end end
  end
 end)
 connect(Input.InputChanged,function(input)
  if hudEditing and hudDrag and (input==hudDrag.input or input.UserInputType==Enum.UserInputType.MouseMovement) then
   local d=hudDrag;local old=hudPlacements[d.name];api:SetHUDLayout(d.name,d.x+input.Position.X-d.startX,d.y+input.Position.Y-d.startY,old and old.scale or 1);return
  end
  if not visible then return end
  if input.UserInputType==Enum.UserInputType.MouseMovement or input==touch then local x,y=pointerPoint(input)
   if input==touch and gesture then
    local g=gesture;mx,my=x,y
    if math.abs(x-g.x)+math.abs(y-g.y)>5 then g.moved=true end
    if g.moved and not g.used then
     if activeStyle~="Opai" then alt.target=math.clamp(alt.target-(y-g.lastY)/alt.s,0,alt.max);g.lastX=x;g.lastY=y;return end
     local c;for _,item in ipairs(columns) do if inside(rect(item.x-horizontal,item.y,W,H+item.bodyH),g.x,g.y) then c=item end end
     if c and math.abs(y-g.y)>=math.abs(x-g.x) then c.target=math.clamp(c.target-(y-g.lastY),0,c.maxScroll)
     else horizontal=math.clamp(horizontal-(x-g.lastX),0,math.max(0,math.min(30,width*.0382)*2+#columns*W+(#columns-1)*8-width)) end
    end
    g.lastX=x;g.lastY=y
   else move(x,y) end
  elseif input.UserInputType==Enum.UserInputType.MouseWheel then
   mx,my=pointerPoint(nil)
   local delta=input.Position.Z
    if Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl) then if appearanceOpen and appearanceSliding=="HUD" then api:SetHUDScale(math.clamp(hudScale+delta*.1,.5,4)) else api:SetScale(math.clamp(k+delta*.1,.5,4)) end;return end
   if appearanceOpen then return end
   if dropdown and dropdown.rect and inside(dropdown.rect,mx,my) then dropdown.scroll=math.clamp(dropdown.scroll-delta*40,0,math.max(0,#dropdown.s.options*(dropdown.optionH or 20)-dropdown.rect.h));return end
   local h=hitAt(mx,my)
   if activeStyle=="Modern" then for i=#alt.windowOrder,1,-1 do local win=alt.windows[alt.windowOrder[i]];if win and win.frame.Visible and inside(rect(win.x,win.y,152,win.h),mx,my) then win.target=math.clamp(win.target-delta*36,0,win.max);return end end end
   if activeStyle=="Modern" and config.open and config.modernList and inside(config.modernList,mx,my) then config.scroll=math.clamp(config.scroll-delta*36,0,config.modernMax);return end
   if h and h.action=="modernScroll" then h.data.target=math.max(0,h.data.target-delta*36);return end
   if activeStyle~="Opai" and (not h or (h.action~="configList" and h.action~="configSelect")) then alt.target=math.clamp(alt.target-delta*(activeStyle=="Neverlose" and 58 or 40),0,alt.max);return end
   if h and (h.action=="configList" or h.action=="configSelect") then config.scroll=math.max(0,config.scroll-delta*48);return end
   if sliding or drag then return end
   dropdown=nil
   local column
   for i=#columns,1,-1 do local c=columns[i];if inside(rect(c.x-horizontal,c.y,W,H+c.bodyH),mx,my) then column=c;break end end
   if column and not Input:IsKeyDown(Enum.KeyCode.LeftShift) and not Input:IsKeyDown(Enum.KeyCode.RightShift) then column.target=math.clamp(column.target-delta*R*2,0,column.maxScroll)
   else horizontal=math.clamp(horizontal-delta*R*2,0,math.max(0,math.min(30,width*.0382)*2+#columns*W+(#columns-1)*8-width)) end
  end
 end)
 connect(Input.InputEnded,function(input)
  if hudDrag and (input==hudDrag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then hudDrag=nil end
  if input==touch and gesture then local g=gesture;if not g.used and not g.moved then click(0,g.x,g.y,g.hit) end;gesture=nil end
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input==touch then drag=nil;sliding=nil;appearanceSliding=nil;if input==touch then touch=nil end end
 end)
 connect(Input.WindowFocusReleased,function() hudDrag=nil;drag=nil;sliding=nil;touch=nil;gesture=nil;binding=nil end)
 connect(editor.FocusLost,function(enter) if enter and config.open and config.page=="Add" then savePreset(editor.Text,false) end end)
 connect(gui:GetPropertyChangedSignal("AbsoluteSize"),fit)
 -- Mobile shortcut preserves the desktop design; long press a row expands settings.
 local mobile=new("TextButton",gui,{Name="TouchMenu",Text="S",Visible=Input.TouchEnabled,Position=UDim2.new(1,-48,1,-48),Size=UDim2.fromOffset(34,34),BackgroundColor3=rgb(0x1C1F29),TextColor3=rgb(0xE4E1E6),ZIndex=1000,AutoButtonColor=false})
 new("UICorner",mobile,{CornerRadius=UDim.new(0,17)})
 connect(mobile.Activated,function() api:SetVisible(not visible) end)
 function api:Destroy()
    if dead then return end;dead=true;Run:UnbindFromRenderStep(api.renderStepName);for _,c in ipairs(conns) do c:Disconnect() end;destroyRegionalBlur(blurPane);blur:Destroy();gui:Destroy()
 end
 connect(shutdown.Event,function() api:Destroy() end)
   connect(gui.Destroying,function() if not dead then dead=true;Run:UnbindFromRenderStep(api.renderStepName);for _,c in ipairs(conns) do c:Disconnect() end;destroyRegionalBlur(blurPane);blur:Destroy() end end)
 if options.Accent~=nil then api:SetAccent(options.Accent) end
 fit();render(0)
  Run:BindToRenderStep(api.renderStepName,Enum.RenderPriority.Camera.Value+1,render)
 -- Inspection is useful in Studio and automated renderer verification.
  function api:Inspect() local result={appearance=api:GetAppearance(),appearanceOpen=appearanceOpen,arrayList=copy(arrayMetrics),hudEditing=hudEditing,hudBounds=copy(hudBounds),style=activeStyle,nativeControls=#hits,alternate={x=alt.x,y=alt.y,scale=alt.s,scroll=alt.scroll,maxScroll=alt.max,nav=alt.nav},inset=GuiService:GetGuiInset(),island={visible=island.Visible,width=islandState.width.value,height=islandState.height.value,notices=#notices},localBlur={active=blurPane.active,unsupported=blurPane.unsupported},scale=k,width=width,height=height,columns={},dropdown=dropdown~=nil,visible=visible};for _,c in ipairs(columns) do result.columns[#result.columns+1]={name=c.name,x=c.x-horizontal,y=c.y,height=c.bodyH,scroll=c.scroll,maxScroll=c.maxScroll,entries=#c.entries} end;return result end
 return api
end
return UI

end)()
return UI
