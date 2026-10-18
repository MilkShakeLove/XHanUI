-- Syntax UI library: Neverlose layout, Opai typography and ArrayList motion.
-- Loaded by SyntaxExecutor.luau from a local file or child ModuleScript.
-- Jackal renderer: AGPL-3.0-or-later. See LICENSE-Jackal and NOTICE.txt.
local uiDiagnostics={Version="2026-10-18.V9.13",Stage="声明 Jackal UI"}
_G.SyntaxUIDiagnostics=uiDiagnostics
local JackalRenderer=(function()
-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Jackal UI Roblox port, based on supplied JackalClient 1.1.9 UI sources.
-- Native client UI. No HTTP, loadstring, Windows APIs, or external assets required.
local Players=game:GetService("Players")
local Input=game:GetService("UserInputService")
local Run=game:GetService("RunService")
local Tween=game:GetService("TweenService")
local Http=game:GetService("HttpService")
local GuiService=game:GetService("GuiService")
local TextService=game:GetService("TextService")
local Stats=game:GetService("Stats")
local Lighting=game:GetService("Lighting")
local SoundService=game:GetService("SoundService")
local UI={Version="2.1.1",SourceVersion="1.1.9",DefaultScale=1.05,JackalStylesVersion="2026-10-16.3",Styles={"Neverlose","Opai","Jackal Neverlose","Jackal Opai"}}
local Window={};Window.__index=Window
local Group={};Group.__index=Group
local T={Window=0x151515,Header=0x1C1C1C,HeaderTop=0x191919,Divider=0x111111,Group=0x1C1C1C,Border=0x222222,Field=0x161616,Hover=0x191919,Selected=0x222222,Popup=0x1C1C1C,Title=0xEDEDED,Label=0xE4E4E4,LabelHover=0xF4F4F4,Muted=0x95909F,Icon=0x9C91A6,IconHover=0xD2D2D2,FieldText=0xD3CCD9,FieldTextHover=0xD8D8D8,Accent=0x34A5F8,AccentDim=0x315675,Privileged=0xF5A35D}
local function color(hex) return Color3.fromRGB(math.floor(hex/65536)%256,math.floor(hex/256)%256,hex%256) end
local function clone(v) if type(v)~="table" then return v end;local t={} for k,x in pairs(v) do t[k]=clone(x) end;return t end
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function create(class,parent,props)
 local o=Instance.new(class)
 if o:IsA("GuiObject") then o.BorderSizePixel=0;o.AutoLocalize=false end
 for k,v in pairs(props or {}) do o[k]=v end
 if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
  -- Text stays in the native glyph renderer, never in a CanvasGroup texture.
  o.TextScaled=false;o.TextStrokeTransparency=1
  o.TextSize=math.max(14,math.round(o.TextSize))
  if o.Font==Enum.Font.Gotham then o.Font=Enum.Font.BuilderSans elseif o.Font==Enum.Font.GothamBold then o.Font=Enum.Font.BuilderSansBold end
 end
 o.Parent=parent;return o
end
local function corner(o,r) return create("UICorner",o,{CornerRadius=UDim.new(0,r or 3)}) end
local function stroke(o,hex,width) return create("UIStroke",o,{Color=color(hex),Thickness=width or .7,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}) end
local function text(parent,value,x,y,w,h,size,hex,bold,align)
 return create("TextLabel",parent,{BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Text=tostring(value),Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,TextSize=math.max(14,math.round(size or 14)),TextColor3=color(hex or T.Label),TextXAlignment=align or Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,TextWrapped=false})
end
local function field(parent,x,y,w,h)
 local b=create("TextButton",parent,{Text="",AutoButtonColor=false,BackgroundColor3=color(T.Field),Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Active=true});corner(b,2.5);return b
end
local function icon(parent,name,size,hex)
 local root=create("Frame",parent,{Name="Icon_"..name,BackgroundTransparency=1,Size=UDim2.fromOffset(size,size),Active=false})
 local parts={};local tone=color(hex or T.Muted)
-- Keep each icon's geometry, using Roblox's native Bezier stroke renderer.
-- Older clients retain the existing rounded-frame fallback.
 local function path(points,closed)
  if not Path2DControlPoint then return false end
  local object
  local ok=pcall(function()
   object=Instance.new("Path2D");object.Name="VectorStroke";object.Color3=tone;object.Thickness=math.max(1.2,size*.075);object.Closed=closed==true;object.ZIndex=1
   local controls={}
   for _,v in ipairs(points) do controls[#controls+1]=Path2DControlPoint.new(UDim2.fromScale(v[1]/24,v[2]/24),UDim2.fromScale((v[3] or 0)/24,(v[4] or 0)/24),UDim2.fromScale((v[5] or 0)/24,(v[6] or 0)/24)) end
   object:SetControlPoints(controls);object.Parent=root
   local opacity=create("UIGradient",object,{Name="VectorOpacity",Transparency=NumberSequence.new(0)})
   opacity:SetAttribute("IconAlpha",1);parts[#parts+1]={object,"Color3","VectorOpacity",opacity}
  end)
  if not ok and object then object:Destroy() end
  return ok
 end

 local function line(x1,y1,x2,y2)
  if path({{x1,y1},{x2,y2}},false) then return end
  local dx,dy=x2-x1,y2-y1
  local part=create("Frame",root,{BackgroundColor3=tone,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale((x1+x2)/48,(y1+y2)/48),Size=UDim2.new(math.sqrt(dx*dx+dy*dy)/24,0,0,math.max(1.2,size*.075)),Rotation=math.deg(math.atan2(dy,dx))})
  corner(part,2);parts[#parts+1]={part,"BackgroundColor3","BackgroundTransparency"}
 end
 local function ring(x,y,w,h,r)
  local radius=math.min(r or math.min(w,h)/2,w/2,h/2);local k=radius*.5522847498
  local raw={{x+radius,y,-k,0,0,0},{x+w-radius,y,0,0,k,0},{x+w,y+radius,0,-k,0,0},{x+w,y+h-radius,0,0,0,k},{x+w-radius,y+h,k,0,0,0},{x+radius,y+h,0,0,-k,0},{x,y+h-radius,0,k,0,0},{x,y+radius,0,0,0,-k}}
  local points={}
  for _,v in ipairs(raw) do local last=points[#points];if last and last[1]==v[1] and last[2]==v[2] then last[5]=v[5];last[6]=v[6] else points[#points+1]=v end end
  if path(points,true) then return end
  local part=create("Frame",root,{BackgroundTransparency=1,Position=UDim2.fromScale(x/24,y/24),Size=UDim2.fromScale(w/24,h/24)})
  corner(part,(r or math.min(w,h)/2)*size/24)
  local edge=create("UIStroke",part,{Color=tone,Thickness=math.max(1.2,size*.075),ApplyStrokeMode=Enum.ApplyStrokeMode.Border})
  parts[#parts+1]={edge,"Color","Transparency"}
 end
 if name=="down" or name=="up" then local a=name=="down" and 9 or 15;local b=name=="down" and 15 or 9;line(5,a,12,b);line(12,b,19,a)
 elseif name=="check" then line(4,12,9,17);line(9,17,20,6)
 elseif name=="close" then line(5,5,19,19);line(19,5,5,19)
 elseif name=="plus" then line(12,4,12,20);line(4,12,20,12)
 elseif name=="search" then ring(3,3,12,12);line(14,14,21,21)
 elseif name=="key" then ring(3,3,9,9);line(11,11,21,21);line(17,17,20,14);line(19,19,22,16)
 elseif name=="info" then ring(3,3,18,18);line(12,10,12,17);line(12,6,12,7)
 elseif name=="eye" or name=="eyeOff" or name=="render" then
  line(2,12,7,6);line(7,6,17,6);line(17,6,22,12);line(22,12,17,18);line(17,18,7,18);line(7,18,2,12);ring(9,9,6,6)
  if name=="eyeOff" then line(3,3,21,21) end
 elseif name=="folder" then line(3,7,9,7);line(9,7,11,10);line(11,10,21,10);line(21,10,21,20);line(21,20,3,20);line(3,20,3,7)
 elseif name=="player" then ring(8,3,8,8);line(5,21,5,17);line(5,17,9,14);line(9,14,15,14);line(15,14,19,17);line(19,17,19,21)
 elseif name=="world" then ring(3,3,18,18);ring(8,3,8,18);line(3,12,21,12)
 elseif name=="copy" then ring(8,8,13,13,2);line(3,16,3,3);line(3,3,16,3)
 elseif name=="paste" then ring(5,5,15,17,2);ring(9,2,7,5,1);line(9,12,16,12);line(9,16,16,16)
 elseif name=="save" then ring(3,3,18,18,2);ring(7,13,10,8,1);line(7,3,7,8);line(7,8,16,8);line(16,8,16,3)
 elseif name=="combat" then line(4,20,20,4);line(12,4,20,4);line(20,4,20,12);line(3,14,10,21);line(4,16,8,20)
 elseif name=="movement" then line(4,16,9,9);line(9,9,15,15);line(15,15,21,6);line(16,6,21,6);line(21,6,21,11)
 elseif name=="reset" then line(5,8,10,3);line(10,3,18,5);line(18,5,21,12);line(21,12,18,19);line(18,19,10,21);line(10,21,4,17);line(5,3,5,9);line(5,9,11,9)
 else
  ring(7,7,10,10,3)
  for i=0,7 do local a=i*math.pi/4;line(12+8*math.cos(a),12+8*math.sin(a),12+10*math.cos(a),12+10*math.sin(a)) end
 end
 return {Root=root,SetColor=function(_,v) local c=color(v);for _,part in ipairs(parts) do part[1][part[2]]=c end end,SetOpacity=function(_,alpha) for _,part in ipairs(parts) do if part[3]=="VectorOpacity" then part[4]:SetAttribute("IconAlpha",alpha);part[4].Transparency=NumberSequence.new(1-alpha) else part[1][part[3]]=1-alpha end end end}
end
local Scope={};Scope.__index=Scope
function Scope.new(parent)
 local s=setmetatable({connections={},children={},disposals={},parent=parent,alive=true},Scope)
 if parent then parent.children[s]=true end;return s
end
function Scope:On(signal,callback) local c=signal:Connect(callback);self.connections[#self.connections+1]=c;return c end
function Scope:Clean()
 if not self.alive then return end;self.alive=false
 for child in pairs(self.children) do child:Clean() end;table.clear(self.children)
 for _,c in ipairs(self.connections) do c:Disconnect() end;table.clear(self.connections)
 for _,fn in ipairs(self.disposals) do pcall(fn) end;table.clear(self.disposals)
 if self.root then self.root:Destroy();self.root=nil end
 if self.parent then self.parent.children[self]=nil end
end
local function decimals(step) for n=0,6 do if math.abs(step*10^n-math.round(step*10^n))<1e-6 then return n end end;return 6 end
local function formatNumber(v,step)
 if (step or 1)>=1 then return string.format("%.0f",v) end
 return (string.format("%."..decimals(step or .01).."f",v):gsub("0+$",""):gsub("%.$",""))
end
local function measured(value,size,bold)
 return TextService:GetTextSize(tostring(value),math.max(14,math.round(size)),bold and Enum.Font.BuilderSansBold or Enum.Font.BuilderSans,Vector2.new(10000,100)).X
end
local function softShadow(parent,radius,spread,opacity)
 for i=spread,1,-1 do
  local shadow=create("Frame",parent,{Name="SoftShadow",BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=1-.075*((opacity or .7)/.7)*(1-i/(spread+1)),Position=UDim2.fromOffset(-i,-i),Size=UDim2.new(1,i*2,1,i*2),ZIndex=0})
  corner(shadow,radius+i)
 end
end
local function snap(v,min,max,step)
 if not finite(v) then return nil end
 step=step or 1;if step>0 then v=min+math.round((v-min)/step)*step end
 return math.clamp(math.round(v*1e6)/1e6,min,max)
end
local function colorValue(v)
 if typeof(v)=="Color3" then return {Hex="#"..v:ToHex():upper(),Alpha=1} end
 if type(v)=="string" then v={Hex=v,Alpha=1} end
 if type(v)~="table" then return nil end
 local hex=tostring(v.Hex or ""):gsub("#",""):upper()
 if #hex~=6 or not hex:match("^%x+$") or not finite(v.Alpha or 1) then return nil end
 if v.Rainbow~=nil and type(v.Rainbow)~="boolean" then return nil end
 return {Hex="#"..hex,Alpha=math.clamp(v.Alpha or 1,0,1),Rainbow=v.Rainbow==true}
end
local function kindOf(def) return string.lower(def.type or def.Type or "toggle") end
local function nameOf(def) return tostring(def.name or def.Name or def.id or def.Id or "Setting") end
local function shortText(value,length)
 local count=utf8.len(value);if not count then return "?" end
 return count>length and value:sub(1,utf8.offset(value,length+1)-1) or value
end
local function normalized(def,v)
 local kind=kindOf(def)
 if kind=="toggle" or kind=="checkbox" then if type(v)=="boolean" then return v end;return nil
 elseif kind=="slider" or kind=="range" or kind=="number" or kind=="progress" then
  local min,max,step=def.min or def.Min or 0,def.max or def.Max or 100,def.step or def.Step or 1
  if not finite(min) or not finite(max) or max<min or not finite(step) or step<=0 then return nil end
  if kind=="range" then
   if type(v)~="table" then return nil end
   local lo,hi=snap(v[1],min,max,step),snap(v[2],min,max,step)
   if not lo or not hi then return nil end;return {math.min(lo,hi),math.max(lo,hi)}
  end
  return snap(v,min,max,step)
 elseif kind=="select" or kind=="dropdown" then
  if table.find(def.options or def.Options or {},v) then return v end;return nil
 elseif kind=="multi" then
  if type(v)~="table" then return nil end
  local result={};local options=def.options or def.Options or {}
  for _,option in ipairs(options) do if table.find(v,option) then result[#result+1]=option end end;return result
 elseif kind=="color" then return colorValue(v)
 elseif kind=="key" or kind=="keybind" then
  if typeof(v)=="EnumItem" then v=v.Name end
  if type(v)~="string" then return nil end
  if v=="None" or v=="Unknown" then return "None" end
  if v:find("+",1,true) then
   if v:sub(1,1)=="+" or v:sub(-1)=="+" or v:find("++",1,true) then return nil end
   local parts={};for part in v:gmatch("[^+]+") do parts[#parts+1]=part end
   local modifiers={LeftControl=true,RightControl=true,LeftShift=true,RightShift=true,LeftAlt=true,RightAlt=true,LeftMeta=true,RightMeta=true}
   local used={}
   for i,part in ipairs(parts) do local ok,item=pcall(function() return Enum.KeyCode[part] end);if not ok or not item or used[part] or i<#parts and not modifiers[part] then return nil end;used[part]=true end
   return table.concat(parts,"+")
  end
  local ok,key=pcall(function() return Enum.KeyCode[v] end);if ok and key then return v end;return nil
 elseif kind=="text" or kind=="textarea" or kind=="readout" then
  if type(v)~="string" then return nil end
  local length=utf8.len(v);if not length then return nil end
  local limit=def.maxLength or (kind=="textarea" and 4096 or 256)
  if length>limit then return v:sub(1,utf8.offset(v,limit+1)-1) end;return v
 elseif kind=="slots" then
  if type(v)~="table" then return nil end
  local allowed=def.options or def.Options or {"None","Sword","Tool","Blocks","Food","Utility"};local result={}
  for i=1,10 do local role=v[i] or "None";if not table.find(allowed,role) then return nil end;result[i]=role end;return result
 elseif kind=="json" then
  if type(v)~="table" then return nil end
  local ok,result=pcall(Http.JSONEncode,Http,v);if ok and #result<=(def.maxBytes or 32768) then return clone(v) end;return nil
 elseif kind=="list" then
  if type(v)~="table" or #v>(def.maxItems or 100) then return nil end
  local out={};for _,item in ipairs(v) do if type(item)~="string" or not utf8.len(item) then return nil end;out[#out+1]=shortText(item,def.itemMaxLength or 256) end;return out
 elseif kind=="gear" or kind=="section" or kind=="button" or kind=="label" or kind=="separator" or kind=="paragraph" then return true end
 return nil
end
local function matches(condition,values)
 if condition==nil then return true end
 if type(condition)=="function" then local ok,result=pcall(condition,clone(values));return ok and result==true end
 if type(condition)~="table" then return condition==true end
 local key=condition.name or condition.Setting;local v=values[key];local expected=condition.value
 if expected==nil then expected=condition.Equals end
 if condition.op=="and" then return matches(condition.a,values) and matches(condition.b,values) end
 if condition.op=="or" then return matches(condition.a,values) or matches(condition.b,values) end
 if condition.op=="not" then return not matches(condition.a,values) end
 if condition.op=="contains" then return type(v)=="table" and table.find(v,expected)~=nil end
 return v==expected
end
function Window:_on(signal,callback,scope)
 local owner=scope or self._scope
 return owner:On(signal,function(...) if owner.alive then return callback(...) end end)
end
function Window:_motion(owner,callback,scope)
 self._motions[owner]=callback
 local s=scope or self._scope;s.disposals[#s.disposals+1]=function() self._motions[owner]=nil end
end
function Window:_checkbox(button,scope)
 corner(button,2)
 local tick=icon(button,"check",10,0xF6F6F6);tick.Root.AnchorPoint=Vector2.new(.5,.5);tick.Root.Position=UDim2.fromScale(.5,.5)
 local scale=create("UIScale",tick.Root,{Scale=.7});local amount,target=0,0;local initialized=false;tick.Root.Visible=false
 self:_motion(tick.Root,function(dt)
  if amount==target then return end
  amount+= (target-amount)*(1-math.exp(-dt*22));if math.abs(target-amount)<.001 then amount=target end
  tick.Root.Visible=amount>.001;scale.Scale=.7+.3*amount;tick:SetOpacity(amount)
 end,scope)
 return function(value)
  target=value and 1 or 0
  if not initialized then initialized=true;amount=target;scale.Scale=.7+.3*amount;tick.Root.Visible=value;tick:SetOpacity(amount) end
 end,tick
end
function Window:_fieldHover(control,caption,scope)
 local hovered=false;local opened=false
 local function refresh()
  self:_animate(control,{BackgroundColor3=color((hovered or opened) and T.Hover or T.Field)})
  if caption then self:_animate(caption,{TextColor3=color((hovered or opened) and T.FieldTextHover or T.FieldText)}) end
 end
 control:SetAttribute("PopupOpen",false)
 self:_on(control.MouseEnter,function() hovered=true;refresh() end,scope)
 self:_on(control.MouseLeave,function() hovered=false;refresh() end,scope)
 self:_on(control:GetAttributeChangedSignal("PopupOpen"),function() opened=control:GetAttribute("PopupOpen")==true;refresh() end,scope)
end
function Window:_animate(o,props,duration)
 if self._dead or not o.Parent then return end
 self._channels=self._channels or setmetatable({},{__mode="k"})
 local channels=self._channels[o]
 if not channels then
  channels={};self._channels[o]=channels
  self._tweens[o]={Cancel=function() for _,tw in pairs(channels) do tw:Cancel() end;table.clear(channels) end}
 end
 local result
 for key,value in pairs(props) do
  if channels[key] then channels[key]:Cancel() end
  local tw=Tween:Create(o,TweenInfo.new(self.ReducedMotion and 0 or duration or .18,Enum.EasingStyle.Quint,Enum.EasingDirection.Out),{[key]=value})
  channels[key]=tw;tw.Completed:Once(function() if channels[key]==tw then channels[key]=nil end end);tw:Play();result=tw
 end
 return result
end
function Window:_stopTween(object)
 local tween=self._tweens[object];self._tweens[object]=nil;if tween then tween:Cancel() end
 if self._channels then self._channels[object]=nil end
end
function Window:_button(parent,label,x,y,w,h,callback,scope)
 local b=field(parent,x,y,w,h);b.Text=label;b.Font=Enum.Font.BuilderSans;b.TextSize=14;b.TextColor3=color(T.Label);b.TextTruncate=Enum.TextTruncate.AtEnd
 self:_on(b.MouseEnter,function() self:_animate(b,{BackgroundColor3=color(T.Hover)}) end,scope)
 self:_on(b.MouseLeave,function() self:_animate(b,{BackgroundColor3=color(T.Field)}) end,scope)
 self:_pressFeedback(b,scope)
 self:_on(b.Activated,function() if not self._dead and self.Visible then callback() end end,scope)
 if scope then scope.disposals[#scope.disposals+1]=function() if b.Parent then b:Destroy() end end end
 return b
end
function Window:_iconButton(parent,name,x,y,w,h,callback,scope)
 local b=create("TextButton",parent,{Name=name,Text="",AutoButtonColor=false,BackgroundTransparency=1,Position=UDim2.fromOffset(x,y),Size=UDim2.fromOffset(w,h),Active=true})
 local iconSize=math.min(20,math.max(14,math.min(w,h)-10));local image=icon(b,name,iconSize,T.Icon);image.Root.Position=UDim2.new(.5,-iconSize/2,.5,-iconSize/2)
 self:_on(b.MouseEnter,function() image:SetColor(T.IconHover) end,scope);self:_on(b.MouseLeave,function() image:SetColor(b:GetAttribute("PopupOpen") and self:_accentHex() or T.Icon) end,scope)
 self:_on(b:GetAttributeChangedSignal("PopupOpen"),function() image:SetColor(b:GetAttribute("PopupOpen") and self:_accentHex() or T.Icon) end,scope)
 self:_on(b.Activated,function() if self.Visible and not self._dead then callback() end end,scope)
 return b,image
end
function Window:_listen(group,key,fn,scope)
 group._listeners[key]=group._listeners[key] or {};group._listeners[key][fn]=true
 scope.disposals[#scope.disposals+1]=function() if group._listeners[key] then group._listeners[key][fn]=nil end end
end
function Window:_notify(group,key,value)
 for fn in pairs(group._listeners[key] or {}) do fn(clone(value)) end
 if self._componentChanged then self:_componentChanged(group,key,value) end
 self._changed:Fire(group.Id,key,clone(value))
 local def=group._definitions[key]
 local callback=key=="enabled" and group.Definition.OnToggle or def and (def.callback or def.Callback)
 if callback then task.spawn(function() local ok,err=pcall(callback,clone(value),group);if not ok then warn("[JackalUI] callback: "..tostring(err)) end end) end
 if self.Options.OnChanged then task.spawn(self.Options.OnChanged,group.Id,key,clone(value),self) end
 if self._batch then self._needsLayout=true else self:_layout() end
 if self._preview then self:_refreshPreview() end
end
function Group:SetEnabled(value)
 assert(type(value)=="boolean","Enabled must be boolean")
 if self.Enabled~=value then self.Enabled=value;self.Window:_notify(self,"enabled",value) end;return self
end
function Group:Set(name,value)
 local def=assert(self._definitions[name],"Unknown setting: "..tostring(name))
 local result=normalized(def,value);assert(result~=nil,"Invalid value for "..name)
 if Http:JSONEncode(self.Values[name])~=Http:JSONEncode(result) then self.Values[name]=clone(result);self.Window:_notify(self,name,result) end;return self
end
function Group:Get(name) return clone(self.Values[name]) end
function Group:AddSetting(def)
 self.Window:_registerSettings(self,{def});self.Definition.settings=self.Definition.settings or {};table.insert(self.Definition.settings,def)
 self.Defaults[nameOf(def)]=clone(self.Values[nameOf(def)])
 self.Window:_invalidate();return self
end
function Group:Reset()
 for key,value in pairs(self.Defaults) do self:Set(key,clone(value)) end
 return self
end
function Group:GetState() return {enabled=self.Enabled,key=self.Key,hidden=self.Hidden,settings=clone(self.Values)} end
function Window:SetEnabled(id,value) return assert(self._byId[id],"Unknown module"):SetEnabled(value) end
function Window:SetSetting(id,name,value) return assert(self._byId[id],"Unknown module"):Set(name,value) end
function Window:GetSetting(id,name) return assert(self._byId[id],"Unknown module"):Get(name) end
function Window:_registerSettings(group,defs,prefix)
 for _,def in ipairs(defs) do
  local key=(prefix or "")..nameOf(def);assert(not group._definitions[key],"Duplicate setting: "..key)
  group._definitions[key]=def;local kind=kindOf(def)
  local initial=def.default;if initial==nil then initial=def.Default end
  if initial==nil then
   if kind=="range" then initial={def.min or 0,def.max or 100}
   elseif kind=="slider" or kind=="number" or kind=="progress" then initial=def.min or 0
   elseif kind=="select" or kind=="dropdown" then initial=(def.options or def.Options or {})[1]
   elseif kind=="color" then initial="#34A5F8"
   elseif kind=="key" or kind=="keybind" then initial="None"
   elseif kind=="multi" or kind=="slots" or kind=="list" or kind=="json" then initial={}
   elseif kind=="text" or kind=="textarea" or kind=="readout" then initial="" else initial=false end
  end
  local result=normalized(def,initial);assert(result~=nil,"Invalid definition/default: "..key);group.Values[key]=result
  if kind=="gear" or kind=="section" then self:_registerSettings(group,def.settings or def.Settings or {},key.."/") end
 end
end

function Window:_inputPoint(input)
 local p=input.Position;return Vector2.new(p.X-self.Gui.AbsolutePosition.X,p.Y-self.Gui.AbsolutePosition.Y)
end
function Window:_startDrag(input,apply,scope)
 if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
 self._drag={input=input,apply=apply,scope=scope};apply(self:_inputPoint(input))
end
function Window:_accentHex() return self.Layout=="Neverlose" and 0xD968A2 or self.Layout=="Imgui" and 0x4296FA or self.Accent or 0x34A5F8 end
function Window:_activeScale() return self._scale or 1 end
function Group:SetHidden(value)
 assert(type(value)=="boolean","Hidden must be boolean")
 if self.Hidden~=value then self.Hidden=value;self.Window:_notify(self,"hidden",value) end;return self
end
function Group:SetKey(value)
 local result=normalized({type="key"},value);assert(result,"Invalid binding")
 if self.Key~=result then self.Key=result;self.Window:_notify(self,"key",result) end;return self
end
function Window:_rowBase(parent,scope,label)
 local window=self
 local row={Scope=scope,Height=32,Root=create("Frame",parent,{Name="SettingRow",BackgroundTransparency=1,Size=UDim2.fromOffset(240,32)})}
 row.Label=text(row.Root,self:_tr(label),12,0,112,32,14,T.Label)
 self:_on(row.Root.MouseEnter,function() self:Describe(label);self:_animate(row.Label,{TextColor3=color(T.LabelHover)}) end,scope)
 self:_on(row.Root.MouseLeave,function() self:_animate(row.Label,{TextColor3=color(T.Label)}) end,scope)
 function row:Place(width,y,shown)
  self.Root.Position=UDim2.fromOffset(0,y);self.Root.Size=UDim2.fromOffset(width,self.Height);self.Root.Visible=shown
  if self.Resize then self.Resize(width) end
  self.Root.Size=UDim2.fromOffset(width,self.Height)
 end
 return row
end

-- All opacity transitions touch native object properties. No offscreen text surface.
local FADE_PROPS={Frame={"BackgroundTransparency"},TextLabel={"BackgroundTransparency","TextTransparency","TextStrokeTransparency"},TextButton={"BackgroundTransparency","TextTransparency","TextStrokeTransparency"},TextBox={"BackgroundTransparency","TextTransparency","TextStrokeTransparency"},ImageLabel={"BackgroundTransparency","ImageTransparency"},ImageButton={"BackgroundTransparency","ImageTransparency"},ScrollingFrame={"BackgroundTransparency","ScrollBarImageTransparency"},UIStroke={"Transparency"}}
function Window:_cancelTransition(root,restore)
 local state=self._transitions and self._transitions[root]
 if not state then return end
 self._transitions[root]=nil
 if restore then
  for object,props in pairs(state.values) do if object.Parent then for key,value in pairs(props) do object[key]=value end end end
  for gradient,alpha in pairs(state.pathValues or {}) do if gradient.Parent then gradient.Transparency=NumberSequence.new(1-alpha) end end
  if root.Parent then root.Position=state.position end
  if state.scaleObject and state.scaleObject.Parent then state.scaleObject.Scale=state.baseScale end
 end
end
function Window:_transition(root,from,to,duration,scope,done,motion)
 if self._dead or not root.Parent then return end
 local overlaps={}
 for other,state in pairs(self._transitions) do
  if other~=root and (other:IsDescendantOf(root) or root:IsDescendantOf(other)) then overlaps[#overlaps+1]={other,state} end
 end
 for _,entry in ipairs(overlaps) do self:_cancelTransition(entry[1],true);if entry[2].done then entry[2].done() end end
 local previous=self._transitions[root];local amount=previous and previous.amount or from
 self:_cancelTransition(root,true)
 local state={root=root,scope=scope,amount=amount,from=amount,to=to,time=0,duration=self.ReducedMotion and 0 or duration,values={},pathValues={},position=root.Position,done=done,motion=motion or {}}
 if motion and motion.Zoom and root==self.Main then state.scaleObject=self.ScaleObject;state.baseScale=self._scale end
 self._transitions[root]=state
 self._transitionOwners=self._transitionOwners or setmetatable({},{__mode="k"})
 if scope and self._transitionOwners[root]~=scope then self._transitionOwners[root]=scope;scope.disposals[#scope.disposals+1]=function() self:_cancelTransition(root,true);self._transitionOwners[root]=nil end end
end
function Window:_tickTransitions(dt)
 for root,state in pairs(self._transitions) do
  if not root.Parent or not state.scope.alive then self:_cancelTransition(root,false)
  else
   state.time+=dt
   local delay=state.motion.Delay or 0
   local t=state.duration==0 and 1 or math.clamp((state.time-delay)/state.duration,0,1)
   local eased=1-(1-t)^3
   state.amount=state.from+(state.to-state.from)*eased
   if not state.captured then
    self:_snapText(root,self:_activeScale())
    state.captured=true
    local nodes={}
    local function collect(object)
     if object:IsA("GuiObject") and not object.Visible then return end
     nodes[#nodes+1]=object;for _,child in ipairs(object:GetChildren()) do collect(child) end
    end
    collect(root)
    for _,object in ipairs(nodes) do
     if object:IsA("Path2D") then
      local gradient=object:FindFirstChild("VectorOpacity")
      if gradient then local sequence=gradient.Transparency;local points=sequence.Keypoints;state.pathValues[gradient]=points and (1-points[1].Value) or (type(sequence[1])=="number" and 1-sequence[1] or gradient:GetAttribute("IconAlpha") or 1) end
     end
     local keys=FADE_PROPS[object.ClassName]
     if keys then
      local values={};for _,key in ipairs(keys) do local value=object[key];if value and value<1 then values[key]=value end end
      if next(values) then state.values[object]=values end
     end
    end
   end
   for object,values in pairs(state.values) do if object.Parent then for key,value in pairs(values) do object[key]=1-(1-value)*state.amount end end end
   for gradient,alpha in pairs(state.pathValues or {}) do if gradient.Parent then gradient.Transparency=NumberSequence.new(1-alpha*state.amount) end end
   local offset=1-state.amount
   root.Position=state.position+UDim2.fromOffset((state.motion.X or 0)*offset,(state.motion.Y or 0)*offset)
   if state.scaleObject and state.scaleObject.Parent then
    local zoom=1-(1-state.motion.Zoom)*(1-state.amount)
    state.scaleObject.Scale=state.baseScale*zoom
    root.Position=state.position+UDim2.fromOffset(self._width*state.baseScale*(1-zoom)/2,self._height*state.baseScale*(1-zoom)/2)
   end
   if t>=1 then
    self._transitions[root]=nil
    for object,props in pairs(state.values) do if object.Parent then for key,value in pairs(props) do object[key]=value end end end
    for gradient,alpha in pairs(state.pathValues or {}) do if gradient.Parent then gradient.Transparency=NumberSequence.new(1-alpha) end end
  if root.Parent then root.Position=state.position end
    if state.scaleObject and state.scaleObject.Parent then state.scaleObject.Scale=state.baseScale end
    if state.done then state.done() end
   end
  end
 end
end
function Window:_pressFeedback(button,scope)
 local border=stroke(button,self:_accentHex(),1);border.Transparency=1
 self:_on(button.InputBegan,function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then self:_animate(border,{Transparency=.2},.07) end
 end,scope)
 self:_on(button.InputEnded,function(input)
  if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then self:_animate(border,{Transparency=1},.2) end
 end,scope)
end
function Window:SetReducedMotion(value)
 self.ReducedMotion=value==true
 for root,state in pairs(self._transitions) do state.duration=0 end
 return self
end

function Window:_snapText(root,scale)
 self._textMetrics=self._textMetrics or setmetatable({},{__mode="k"})
 for _,o in ipairs(root:GetDescendants()) do
  if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
   local metric=self._textMetrics[o]
   if not metric or math.abs(o.TextSize-metric.last)>.001 then metric={base=o.TextSize};self._textMetrics[o]=metric end
   metric.last=math.round(metric.base*scale)/scale;o.TextSize=metric.last
   if self.Options.FontFace and o.Font~=Enum.Font.Code and o.Font~=Enum.Font.Arcade then o.FontFace=self.Options.FontFace end
  end
 end
end

-- Generated from JackalClient 1.1.9 DefaultSettings/default_settings.h.
local PRESETS={["Default"]={["Round Corners"]=false,["Outline"]=false,["Module Name Alignment"]="Left",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="Rainbow",["Module Background Color"]="Black",["Module Background Blackness (0~1)"]=0,["Module Background Opacity (0~1)"]=1,["Module Option Style"]="Integration",["Menu Toggle Animation"]="Slide (Top)",["Module Font Size"]=23,["Module Height"]=37,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="200;200;200",["Tab Theme Color"]="10;10;10",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Left",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=290,["Top Tab Text Color"]="253;249;0",["Tab Expand Arrow"]=true,["Tab Icons"]=true,["Tab Icon Color"]="White",["Tab Shadows"]=true,["Module Left Bar"]=false,["Module Keybind Display"]=true,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Dots",["Show Module Description"]=true,["Remove Spaces in Module Names"]=false},["Old"]={["Round Corners"]=true,["Outline"]=true,["Module Name Alignment"]="Left",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="Rainbow",["Module Background Color"]="Black",["Module Background Blackness (0~1)"]=0.8,["Module Background Opacity (0~1)"]=0.9,["Module Option Style"]="Old",["Menu Toggle Animation"]="Slide (Top)",["Module Font Size"]=28,["Module Height"]=33,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="200;200;200",["Tab Theme Color"]="40;40;50",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Left",["Tab Width Mode"]="Auto",["Tab Width (Fixed)"]=290,["Top Tab Text Color"]="230;230;230",["Tab Expand Arrow"]=false,["Tab Icons"]=false,["Tab Icon Color"]="White",["Tab Shadows"]=true,["Module Left Bar"]=false,["Module Keybind Display"]=false,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Off",["Show Module Description"]=true,["Remove Spaces in Module Names"]=false,["Font"]="GoogleSans.ttf",["Module Text Color (Unavailable)"]="150;150;150",["Tab Width Addition (Auto)"]=50,["Tab Shadows Thickness"]=10.0,["Tab Shadows Opacity (0~1)"]=0.7},["Modern"]={["Round Corners"]=true,["Outline"]=true,["Module Name Alignment"]="Left",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="White",["Module Background Color"]="Transparent",["Module Background Blackness (0~1)"]=0.0,["Module Background Opacity (0~1)"]=1.0,["Module Option Style"]="Integration",["Menu Toggle Animation"]="Slide (Bottom)",["Module Font Size"]=23,["Module Height"]=37,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="200;200;200",["Tab Theme Color"]="10;10;10;10",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Left",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=290,["Top Tab Text Color"]="230;230;230",["Tab Expand Arrow"]=true,["Tab Icons"]=true,["Tab Icon Color"]="White",["Tab Shadows"]=true,["Module Left Bar"]=false,["Module Keybind Display"]=true,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Arrow",["Show Module Description"]=false,["Remove Spaces in Module Names"]=false,["Font"]="GoogleSans.ttf",["Module Text Color (Unavailable)"]="150;150;150",["Module Option Background Color"]="Transparent",["Module Option Background Darkness (0~1)"]=0.0,["Tab Shadows Thickness"]=20.0,["Tab Shadows Opacity (0~1)"]=0.7},["Vape"]={["Round Corners"]=false,["Outline"]=false,["Module Name Alignment"]="Left",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="Rainbow",["Module Background Color"]="Black",["Module Background Blackness (0~1)"]=0.0,["Module Background Opacity (0~1)"]=1.0,["Module Option Style"]="Integration",["Menu Toggle Animation"]="Fade",["Module Font Size"]=23,["Module Height"]=37,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="200;200;200",["Tab Theme Color"]="10;10;10",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Left",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=290,["Top Tab Text Color"]="230;230;230",["Tab Expand Arrow"]=true,["Tab Icons"]=true,["Tab Icon Color"]="White",["Tab Shadows"]=true,["Module Left Bar"]=false,["Module Keybind Display"]=true,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Dots",["Show Module Description"]=false,["Remove Spaces in Module Names"]=true,["Font"]="GoogleSans.ttf",["Module Text Color (Unavailable)"]="150;150;150",["Tab Shadows Thickness"]=20.0,["Tab Shadows Opacity (0~1)"]=0.7},["Opai"]={["Round Corners"]=true,["Outline"]=false,["Module Name Alignment"]="Left",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="Gold",["Module Background Color"]="Black",["Module Background Blackness (0~1)"]=0.0,["Module Background Opacity (0~1)"]=1.0,["Module Option Style"]="Integration",["Menu Toggle Animation"]="Enlarge II",["Module Font Size"]=23,["Module Height"]=50,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="20;20;20",["Tab Theme Color"]="10;10;10",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Left",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=320,["Top Tab Text Color"]="230;230;230",["Tab Expand Arrow"]=false,["Tab Icons"]=false,["Tab Icon Color"]="White",["Tab Shadows"]=true,["Module Left Bar"]=false,["Module Keybind Display"]=false,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Off",["Show Module Description"]=false,["Remove Spaces in Module Names"]=false,["Font"]="GoogleSans.ttf",["Module Text Color (Unavailable)"]="150;150;150",["Tab Shadows Thickness"]=30.0,["Tab Shadows Opacity (0~1)"]=0.8},["LiquidBounce"]={["Round Corners"]=false,["Outline"]=false,["Module Name Alignment"]="Left",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="Aqua",["Module Background Color"]="Black",["Module Background Blackness (0~1)"]=0.0,["Module Background Opacity (0~1)"]=0.7,["Module Option Style"]="Integration",["Menu Toggle Animation"]="Fade",["Module Font Size"]=27,["Module Height"]=32,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="200;200;200",["Tab Theme Color"]="58;71;94",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Center",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=270,["Top Tab Text Color"]="200;200;200",["Tab Expand Arrow"]=false,["Tab Icons"]=true,["Tab Icon Color"]="Blue",["Tab Shadows"]=false,["Module Left Bar"]=false,["Module Keybind Display"]=false,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Off",["Show Module Description"]=true,["Remove Spaces in Module Names"]=true,["Font"]="GoogleSans.ttf",["Module Text Color (Unavailable)"]="150;150;150"},["LiquidBounce NextGen"]={["Round Corners"]=false,["Outline"]=false,["Module Name Alignment"]="Center",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="Black",["Module Background Color"]="Black",["Module Background Blackness (0~1)"]=0.0,["Module Background Opacity (0~1)"]=1.0,["Module Option Style"]="Integration",["Menu Toggle Animation"]="Fade",["Module Font Size"]=21,["Module Height"]=39,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="89;118;247",["Tab Theme Color"]="32;34;37;190",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Left",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=280,["Top Tab Text Color"]="aqua",["Tab Expand Arrow"]=true,["Tab Icons"]=true,["Tab Icon Color"]="White",["Tab Shadows"]=true,["Module Left Bar"]=false,["Module Keybind Display"]=false,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Arrow",["Show Module Description"]=true,["Remove Spaces in Module Names"]=false,["Font"]="GoogleSans.ttf",["Requirement Icon"]="Off",["Module Text Color (Unavailable)"]="150;150;150",["Tab Shadows Thickness"]=20.0,["Tab Shadows Opacity (0~1)"]=0.6},["Raven"]={["Round Corners"]=true,["Outline"]=true,["Module Name Alignment"]="Center",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Lower Case",["Module Background Color (Enabled)"]="Black",["Module Background Color"]="Black",["Module Background Blackness (0~1)"]=0.0,["Module Background Opacity (0~1)"]=0.6,["Module Option Style"]="Integration",["Menu Toggle Animation"]="Fade",["Module Font Size"]=15,["Module Height"]=40,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="89;118;247",["Tab Theme Color"]="32;34;37;210",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Left",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=270,["Top Tab Text Color"]="180;180;180",["Tab Expand Arrow"]=true,["Tab Icons"]=false,["Tab Icon Color"]="White",["Tab Shadows"]=false,["Module Left Bar"]=false,["Module Keybind Display"]=false,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Off",["Show Module Description"]=true,["Remove Spaces in Module Names"]=true,["Font"]="Minecraft AE Pixel.ttf",["Module Text Color (Unavailable)"]="150;150;150"},["Meteor"]={["Round Corners"]=false,["Outline"]=false,["Module Name Alignment"]="Center",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="Gray",["Module Background Color"]="Black",["Module Background Blackness (0~1)"]=0.0,["Module Background Opacity (0~1)"]=1.0,["Module Option Style"]="Old",["Menu Toggle Animation"]="Fade",["Module Font Size"]=25,["Module Height"]=30,["Module Text Color"]="200;200;200",["Module Text Color (Enabled)"]="200;200;200",["Tab Theme Color"]="124;30;235",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Center",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=280,["Top Tab Text Color"]="180;180;180",["Tab Expand Arrow"]=true,["Tab Icons"]=false,["Tab Icon Color"]="White",["Tab Shadows"]=false,["Module Left Bar"]=true,["Module Keybind Display"]=false,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Off",["Show Module Description"]=true,["Remove Spaces in Module Names"]=false,["Font"]="GoogleSans.ttf",["Module Text Color (Unavailable)"]="150;150;150"},["Future"]={["Round Corners"]=false,["Outline"]=false,["Module Name Alignment"]="Left",["Module Name Case Style"]="Normal",["Tab Name Case Style"]="Normal",["Module Background Color (Enabled)"]="Red",["Module Background Color"]="Red",["Module Background Blackness (0~1)"]=0.9,["Module Background Opacity (0~1)"]=0.6,["Module Option Style"]="Integration",["Menu Toggle Animation"]="Slide (Top)",["Module Font Size"]=25,["Module Height"]=30,["Module Text Color"]="153;153;153",["Module Text Color (Enabled)"]="250;250;250",["Tab Theme Color"]="129;31;23",["Tab Theme Color Mode"]="Single",["Tab Name Alignment"]="Left",["Tab Width Mode"]="Fixed",["Tab Width (Fixed)"]=280,["Top Tab Text Color"]="180;180;180",["Tab Expand Arrow"]=false,["Tab Icons"]=false,["Tab Icon Color"]="White",["Tab Shadows"]=false,["Module Left Bar"]=true,["Module Keybind Display"]=false,["Module Keybind Color"]="Gray",["Module Option Open Button"]="Future",["Show Module Description"]=true,["Remove Spaces in Module Names"]=false,["Font"]="GoogleSans.ttf",["Module Text Color (Unavailable)"]="90;90;90"}}
local PRESET_NAMES={"Default","Old","Modern","Vape","LiquidBounce","LiquidBounce NextGen","Raven","Meteor","Future","Opai"}
local LAYOUT_NAMES={"Dropdown","Neverlose","Imgui"}
local LAUNCHER_NAMES={"Default","Vape","Jackal","Neon","Matrix","Aurora","Random"}

local ZH={["AntiCapture"]="反捕获",["AntiClose"]="反关闭",["AntiDebug"]="反调试",["AntiInject"]="反注入",["AntiIntercept"]="反拦截",["AntiMalware"]="反恶意软件",["AntiTaskkill"]="反进程杀手",["AntiMouseHook"]="反鼠标钩子",["AntiKeyHook"]="反键盘钩子",["AutoStart"]="开机自启",["AutoUAC"]="自动管理员",["AutoLogin"]="自动登录",["Admin"]="管理员",["System"]="系统",["UIAccess"]="界面特权",["SuperTopmost"]="超级置顶",["UACBypass"]="管理员绕过",["Taskmgr"]="任务管理器",["Cmd"]="命令提示符",["SuperCmd"]="超级CMD",["Gpedit"]="组策略",["Regedit"]="注册表",["Perfmon"]="资源监视器",["Calc"]="计算器",["Osk"]="屏幕键盘",["Mrt"]="恶意软件删除工具",["ClearPin"]="清除PIN",["CrackPassword"]="破解密码",["SetPassword"]="篡改密码",["Uninstaller"]="一键卸载",["Interceptor"]="拦截器",["Gatekeeper"]="看门人",["NoFirewall"]="关闭防火墙",["FreezeWinlogon"]="冻结 Winlogon",["MagnifyReplace"]="放大镜替换",["SethcBackdoor"]="粘滞键后门",["Privileges"]="特权",["Protection"]="自保护",["MachineLock"]="锁机",["LockUser"]="锁定用户",["Logoff"]="注销",["Shutdown"]="关机",["Reboot"]="重启",["MythwareKiller"]="极域杀手",["Crash"]="蓝屏",["ListTrays"]="列举托盘",["WindowManager"]="窗口管理器",["WindowTags"]="窗口标签",["WindowHighlight"]="窗口高亮",["WindowESP"]="窗口透视",["WindowKill"]="窗口击杀",["WindowFreeze"]="窗口冻结",["Tracers"]="追踪线",["OpacityChanger"]="透明度调节",["ConsoleESP"]="控制台透视",["Messenger"]="消息通信",["MsgBlocker"]="消息阻塞",["WindowMaster"]="窗口大师",["PrivateWindow"]="隐私窗口",["BandSetter"]="Z序段设置",["Topmost"]="窗口置顶",["TitleChanger"]="标题修改",["BetterAnimation"]="更好的动画",["AntiBrowser"]="反浏览器",["AntiPopups"]="反弹窗",["AntiTopmost"]="反置顶",["AutoTranslate"]="自动翻译",["AutoFocus"]="自动聚焦",["HoverFocus"]="悬停聚焦",["CloseEnhance"]="关闭增强",["DialogEscape"]="对话框关闭",["DialogPhysics"]="物理弹窗",["HideTaskbar"]="隐藏任务栏",["TargetHUD"]="目标显示",["ToastESP"]="通知透视",["TargetESP"]="目标透视",["KeywordESP"]="关键词透视",["UncrossAura"]="抗关闭光环",["FreezeAura"]="冻结光环",["AimAssist"]="自动瞄准",["TriggerBot"]="触发点击",["KillAuraLegit"]="合法杀戮光环",["KillAura"]="杀戮光环",["MaxAura"]="最大化光环",["MinAura"]="最小化光环",["Ruler"]="标尺",["AntiProcCreate"]="禁止创建进程",["Elevator"]="电梯",["ForceTerminator"]="暴力送终",["ListModules"]="枚举模块",["ListDrivers"]="枚举驱动",["ListServices"]="枚举服务",["ListTasks"]="枚举计划任务",["Injector"]="注入器",["RemoteRun"]="远程执行",["Speedhack"]="变速齿轮",["GenshinImpact"]="原神启动",["Tasklist"]="进程列表",["QuickRun"]="快捷运行",["Run"]="运行",["DebugESP"]="调试透视",["ProcessESP"]="进程透视",["CompileESP"]="编译透视",["ProcessKill"]="进程击杀",["ProcessKeep"]="进程保持",["ProcessFreeze"]="进程冻结",["FileManager"]="文件管理器",["ProcessManager"]="进程管理器",["Everything"]="Everything",["LongPath"]="长路径",["TopFiles"]="大文件",["PeParser"]="PE解析",["HexViewer"]="十六进制查看",["DiskMissing"]="磁盘丢失",["FileDelete"]="文件删除",["FileCreate"]="文件创建",["FileMonitor"]="文件监视",["FolderClear"]="目录清空",["TempClear"]="临时清空",["RubbishClean"]="垃圾清理",["RecyclerClear"]="回收站清空",["RootProgram"]="根目录程序",["PrivacySpy"]="隐私密探",["PrivacyDatabase"]="隐私数据库",["SelfBackup"]="自我备份",["SelfRestore"]="自我还原",["AutoRestore"]="自动还原",["RegManager"]="注册表管理",["RegMonitor"]="注册表监视",["SecureLogin"]="安全登录",["ListHijacks"]="劫持调查",["KillHijacks"]="清除劫持",["CrashKey"]="快捷蓝屏",["NoCmd"]="禁命令提示符",["NoPowerShell"]="禁PowerShell",["NoTaskmgr"]="禁任务管理器",["NoRegedit"]="禁注册表编辑器",["NoDesktopIcons"]="隐藏桌面图标",["NoDesktopMenu"]="隐藏桌面菜单",["NoTaskbarMenu"]="隐藏任务栏菜单",["NoStartMenuChange"]="禁开始菜单改变",["NoRun"]="禁运行框",["NoPowerOptions"]="隐藏电源选项",["NoLogOff"]="隐藏注销",["NoDwm"]="禁用DWM",["NoConsoleAltF4"]="禁控制台Alt+F4",["NoSetFolders"]="禁开始菜单目录",["NoFolderOptions"]="禁目录选项",["HideWindowsUpdate"]="隐藏系统更新",["UpdateDisabler"]="更新禁用器",["NoWinKeys"]="禁Win快捷键",["NoLockUser"]="禁Win+L",["RestrictRun"]="限制运行",["NoMSDos"]="禁MSDOS",["NoSmartScreen"]="禁SmartScreen",["NoRemovableDev"]="禁可移动设备",["NoUAC"]="禁UAC",["NoDefender"]="禁用实时保护",["NoHibernate"]="禁休眠",["NoFastStartup"]="禁快启",["NoRemoteDesktop"]="禁远程桌面",["Arraylist"]="模块列表",["Ambience"]="环境气氛",["AutoDanmaku"]="自动弹幕",["AutoTitle"]="自动标题",["AutoTotem"]="自动图腾",["HighContrast"]="高对比度",["BlackCapture"]="黑屏捕获",["BetterLyrics"]="更好的歌词",["MusicOverlay"]="音乐信息",["LyricsPhysics"]="物理歌词",["ScreenSaver"]="屏保程序",["CloseMonitor"]="关闭显示器",["Crosshair"]="准星线",["MouseTrails"]="鼠标轨迹",["Keystrokes"]="按键显示",["Keystrokes2"]="按键显示II",["LetterGraph"]="字母图",["ChatBar"]="聊天栏",["HudEditor"]="HUD编辑器",["NoAnimation"]="禁用动画",["NoScreenSaver"]="关闭屏保",["PerformanceHUD"]="性能显示",["DownloadHUD"]="下载显示",["SessionHUD"]="会话显示",["PPLESP"]="保护进程透视",["SecurityESP"]="安全透视",["ClipboardESP"]="剪贴板透视",["MCDisplay"]="MC显示",["MotionBlur"]="动态模糊",["Background"]="背景",["WarpUI"]="空间变形",["GUIBlur"]="界面模糊",["HUDBlur"]="HUD模糊",["CustomHUD"]="自定义显示",["Scoreboard"]="计分板",["ChatQueue"]="聊天队列",["Clock"]="时钟",["TimeDisplay"]="时间显示",["Island"]="灵动岛",["Karaoke"]="卡拉OK",["Title"]="标题显示",["FancyTexts"]="花式文字",["Actionbar"]="行为栏",["Totem"]="不死图腾",["Tint"]="染色",["Stuck"]="冻结",["Watermark"]="水印",["BlackoutSense"]="停电感知",["PowerSaving"]="节能",["WeakView"]="节电模式",["Bright"]="亮度修改",["Gamma"]="伽马覆写",["Spotlight"]="聚光灯",["Shaders"]="着色器",["Night"]="夜间",["TcpMonitor"]="TCP监视",["TcpKiller"]="TCP杀手",["OnlineTime"]="在线时间",["IPTracker"]="IP追踪",["IPAddress"]="IP地址",["IPHorror"]="IP恐惧",["PhoneArea"]="手机归属地",["WallCheck"]="墙壁检测",["WeatherInfo"]="天气信息",["QuakeWarning"]="地震预警",["Encryptor"]="加密器",["Memeizer"]="生草机",["BiliCookies"]="B站曲奇",["BiliChatter"]="B站弹幕",["BiliConsole"]="B站控制台",["BiliFans"]="B站粉丝",["BiliFeed"]="B站推荐",["BiliHot"]="B站热搜",["BiliNotifier"]="B站通知",["BiliComponents"]="B友成分",["BiliProfile"]="B友档案",["BiliSettings"]="B站设定",["WebSettings"]="网络设定",["AISettings"]="AI设定",["ApiHzSettings"]="翻译接口盒子设定",["Agent"]="AI代理",["Translator"]="翻译器",["BiliVideo"]="B站视频",["BiliVideoCover"]="B站视频封面",["BiliVideoHelper"]="B站视频助手",["LiveStream"]="直播间",["Streamer"]="主播模式",["SystemProxy"]="系统代理",["QQBot"]="QQ机器人",["QQInspect"]="QQ窥探",["QQBindQuery"]="QQ查绑",["Flight"]="飞行",["IRC"]="聊天室",["IRCLegacy"]="旧版聊天室",["AntiWebpage"]="反网页",["AntiAFK"]="反挂机",["AntiRickroll"]="反诈骗",["AntiSpy"]="反间谍",["AntiMicrophone"]="反麦克风",["LiveChatter"]="直播弹幕",["AutoClicker"]="连点器",["AutoSpeak"]="自动讲述",["ColorPicker"]="取色器",["BridgeAssist"]="搭路辅助",["ChestStealer"]="箱子小偷",["ChatAsk"]="AI回答",["ChatTranslate"]="AI翻译",["ChatBilingual"]="AI双语",["ChatRestruct"]="AI重构",["AutoCopy"]="自动复制",["ClipboardTweaks"]="剪贴板功能",["MinecraftUtils"]="MC功能",["AutoText"]="自动文本",["AutoL"]="自动嘲讽",["MemeTrigger"]="梗触发",["MouseESP"]="鼠标透视",["MouseTeleport"]="鼠标传送",["MouseWatcher"]="鼠标监视",["MouseSwap"]="鼠标交换",["NoDoubleClick"]="禁止双击",["NoClipboard"]="禁止复制",["MouseDisabler"]="禁用鼠标",["BHop"]="兔子跳",["SnapTap"]="急停键",["ToggleKey"]="切换键",["Typewriter"]="打字机",["CapsGuard"]="大写守护",["Spammer"]="刷屏器",["KeyDisabler"]="禁用键盘",["KeyMapper"]="按键映射",["KeyLogger"]="键盘记录",["KeySound"]="按键音效",["KeyReaction"]="按键反应",["TypingEffects"]="打字效果",["TypingPractice"]="打字练习",["CaretBrowser"]="光标浏览",["MacroRecorder"]="宏录制",["MacroPlayer"]="宏播放",["NoBeep"]="禁止蜂鸣",["RestartExplorer"]="重启资源管理器",["QuickIME"]="快捷输入法",["DisableIME"]="关闭输入法",["NoIME"]="禁止输入法",["Panic"]="恐慌",["Musics"]="音乐",["Speaker"]="讲述人",["Volume"]="音量",["Mixer"]="混音器",["AudioIsolation"]="音频隔离",["CloudMusic"]="云音乐",["Mute"]="静音",["Active"]="活动",["AudioVisualizer"]="音频可视化",["ModuleEditor"]="模块编辑器",["GUIStyler"]="GUI风格",["ForceTopmost"]="强制置顶",["NotificationModule"]="通知",["Reminder"]="提醒",["Triggers"]="触发器",["NickGenerator"]="昵称生成",["IQBooster"]="智商提升",["TaskbarIcon"]="任务栏图标",["ScreenCapture"]="屏幕捕获",["AsciiArtConvert"]="字符画转换",["TimeManager"]="时间管理",["QuickCommand"]="快速命令",["Shell"]="命令行",["OpenUrl"]="打开链接",["Screenshot"]="截图工具",["Console"]="控制台",["Developer"]="开发者",["Hidden"]="隐藏至托盘",["Restart"]="重新启动",["Exit"]="退出",["Anti360Ad"]="反数字广告",["Anti360VT"]="反数字核晶",["ScaredUAC"]="恐惧UAC",["KillEveryone"]="全员击杀",["KillAV"]="击杀杀软",["KillHuorong"]="杀火绒",["CloseAV"]="关闭杀软",["Kill360"]="杀数字",["Kill360Test"]="杀数字测试",["Kill360Test2"]="杀数字测试II",["Kill360AdProc"]="杀数字广告进程",["KillMalware"]="击杀病毒",["FreezeExplorer"]="冻结资源管理器",["FreezeEveryone"]="全员冻结",["UnfreezeEveryone"]="全员解冻",["PPLButcher"]="解除进程保护",["TrustedInstaller"]="受信任安装者",["RemoteKillHR"]="远程杀火绒",["Masquerade"]="伪装",["NoNotification"]="关闭通知",["RuinAura"]="毁灭光环",["SelfDestruct"]="自我删除",["SelfUninstall"]="自我卸载",["HideProcess"]="隐藏进程",["Vape"]="电子烟",["Kernel1"]="内核1",["Sirius"]="天狼星",["Portal"]="传送门",["Combat"]="战斗",["Window"]="窗口",["Process"]="进程",["Registry"]="注册表",["File"]="文件",["Control"]="控制",["Render"]="渲染",["Web"]="网络",["Misc"]="杂项",["Driver"]="驱动",["Modules"]="模块",["Config"]="配置",["GUI"]="界面",["HUD"]="显示",["Sound"]="声音",["Search"]="搜索",["Profiles"]="配置文件",["Apps"]="应用",["About"]="关于",["Language"]="语言",["ClickGUI Layout"]="界面布局",["Style Preset"]="样式预设",["Global Scale"]="整体缩放",["Launcher Style"]="启动器风格",["Reset panel positions"]="重置面板位置",["Enabled"]="开启",["Reset"]="重置",["Save"]="保存",["Results"]="项结果",["Search modules and settings"]="搜索模块和设置",["No matching modules"]="没有匹配的模块",["No saved profiles"]="尚无配置文件",["Advanced"]="高级选项"}
for key,value in pairs({["Dynamic Island"]="灵动岛",["Demo"]="示例",["Progress"]="进度",["Cancelled"]="已取消",["Completed"]="已完成",["Notification received"]="收到通知",["Disabled"]="关闭",["Cancel"]="取消"}) do ZH[key]=value end
function Window:_tr(value) if self.Options.Translate then return self.Options.Translate(value) end;return self.Language=="中文" and (ZH[value] or ZH[value:gsub("%s","")] or value) or value end

function Window:_beginBinding(group,key,button,scope)
 local function set(value)
  if key=="key" then group.Key=value;self:_notify(group,"key",value) else group:Set(key,value) end
 end
 if Input.TouchEnabled and not Input.KeyboardEnabled then
  self:_listPopup(button,{"None","Q","E","R","F","G","V","B","N","RightShift"},nil,false,set);return
 end
 if self._binding then local same=self._binding.button==button;self._binding.cancel();self._binding=nil;if same then return end end
 local original=button.Text;button.Text="...";button.TextColor3=color(self:_accentHex())
 local originalBackground=button.BackgroundTransparency;local originalSize=button.Size;local originalPosition=button.Position
 if button:IsA("TextButton") then button.BackgroundTransparency=0;local width=math.max(18,originalSize.X.Offset);button.Size=UDim2.fromOffset(width,originalSize.Y.Offset);button.Position=UDim2.fromOffset(originalPosition.X.Offset+originalSize.X.Offset-width,originalPosition.Y.Offset) end
 local hiddenIcons={}
 for _,child in ipairs(button:GetChildren()) do if child:IsA("Frame") and child.Name=="Icon_key" then hiddenIcons[#hiddenIcons+1]={child,child.Visible};child.Visible=false end end
 self._binding={scope=scope,button=button,set=set,cancel=function()
  if button.Parent then button.Text=original;button.TextColor3=color(T.FieldText);button.BackgroundTransparency=originalBackground;button.Size=originalSize;button.Position=originalPosition;for _,entry in ipairs(hiddenIcons) do if entry[1].Parent then entry[1].Visible=entry[2] end end end
 end}
 self:Notify("Press a key · Escape clears")
end
function Window:_wheelField(control,scope,step)
 local locked
 local function unlock() if locked and locked.Parent then locked.ScrollingEnabled=true end;locked=nil end
 self:_on(control.MouseEnter,function()
  if Input.MouseEnabled then locked=control:FindFirstAncestorWhichIsA("ScrollingFrame");if locked then locked.ScrollingEnabled=false end end
 end,scope)
 self:_on(control.MouseLeave,unlock,scope)
 self:_on(control.InputChanged,function(input) if input.UserInputType==Enum.UserInputType.MouseWheel then step(input.Position.Z>0 and 1 or -1) end end,scope)
 scope.disposals[#scope.disposals+1]=unlock
end
function Window:_makeRow(group,def,key,parent,scope)
 local kind=kindOf(def)
 if kind=="number" or kind=="textarea" or kind=="section" or kind=="separator" or kind=="paragraph" or kind=="list" or kind=="json" or kind=="readout" or kind=="progress" then return self:_richRow(group,def,key,parent,scope) end
 local row=self:_rowBase(parent,scope,def.label or def.Label or nameOf(def));row.Key=key;row.Definition=def
 row.Privileged=def.privileged==true or def.Privileged==true or (def.group~=nil and def.group~="User")
 if row.Privileged then row.Label.TextColor3=color(T.Privileged) end
 local fw,fh=112,26
 if kind=="toggle" or kind=="checkbox" then fw=self.Layout=="Neverlose" and 34 or 20;fh=20 end
 if kind=="color" then fw=72;fh=20 end
 if kind=="gear" then fw=14;fh=16 end
 if kind=="label" then fw=0 end
 local control=field(row.Root,110,(32-fh)/2,fw,fh)
 local caption=text(control,"",4,0,math.max(1,fw-8),fh,14,T.FieldText,false,Enum.TextXAlignment.Center)
 caption.Active=false
 row.Control=control;row.Caption=caption
 control.Name="Field_"..key
 self:_pressFeedback(control,scope)
 row.Resize=function(width)
  control.Position=UDim2.fromOffset(width-15-fw,(32-fh)/2)
  row.Label.Size=UDim2.fromOffset(math.max(1,width-36-fw),32)
 end
 local function set(value) group:Set(key,value) end
 local refresh
 if kind=="toggle" or kind=="checkbox" then
  corner(control,1.5);caption.Visible=false
  
  local mark
  if self.Layout=="Neverlose" then
   corner(control,10);mark=create("Frame",control,{Name="SwitchKnob",BackgroundColor3=color(T.Title),Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(2,2)});corner(mark,8)
   local tick=icon(mark,"check",11,self:_accentHex());tick.Root.Position=UDim2.fromOffset(2.5,2.5);row.Tick=tick
  else
   stroke(control,0x72707D,1);mark=icon(control,"check",15,0xFFFFFF).Root;mark.Name="CheckedSquare";mark.Position=UDim2.fromOffset(2.5,2.5)
  end
  local hit=create("TextButton",row.Root,{BackgroundTransparency=1,Text="",Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=0})
  refresh=function(value)
   if self.Layout=="Neverlose" then self:_animate(control,{BackgroundColor3=color(value and self:_accentHex() or 0x46414E)});self:_animate(mark,{Position=UDim2.fromOffset(value and 16 or 2,2)},.22);row.Tick.Root.Visible=value
   else self:_animate(control,{BackgroundColor3=color(value and self:_accentHex() or T.Field)});mark.Visible=value end
  end
  self:_on(control.Activated,function() set(not group.Values[key]) end,scope);self:_on(hit.Activated,function() set(not group.Values[key]) end,scope)
 elseif kind=="slider" or kind=="range" then
  local min,max,step=def.min or def.Min or 0,def.max or def.Max or 100,def.step or def.Step or 1
  control.BackgroundTransparency=1
  local track=create("Frame",control,{Name="Track",BackgroundColor3=color(0x48404B),Position=UDim2.fromOffset(0,19),Size=UDim2.fromOffset(fw,4)});corner(track,2.5)
  local fill=create("Frame",track,{Name="Fill",BackgroundColor3=color(self:_accentHex()),Position=UDim2.fromOffset(0,0),Size=UDim2.fromOffset(0,4)});corner(fill,1.5);caption.ZIndex=3
  row.Track=track;row.Fill=fill
  caption.Position=UDim2.fromOffset(0,-3);caption.Size=UDim2.fromOffset(fw,20);caption.TextSize=14;caption.TextColor3=color(T.Title)
  local handles={}
  for i=1,kind=="range" and 2 or 1 do local handle=create("Frame",track,{Name="Handle"..i,BackgroundColor3=color(0xF5EDF5),AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(0,0,.5,0),Size=UDim2.fromOffset(10,10),ZIndex=2});corner(handle,5);handles[i]=handle end
  row.Handles=handles
  local editor=create("TextBox",control,{BackgroundColor3=color(T.Field),Size=UDim2.fromScale(1,1),ClearTextOnFocus=false,Text="",Font=Enum.Font.Gotham,TextSize=14,TextColor3=color(T.Label),Visible=false,ZIndex=5})
  corner(editor,2.5);stroke(editor,self:_accentHex(),.7)
  refresh=function(value)
   local a,b
   if kind=="range" then a=(value[1]-min)/math.max(1e-9,max-min);b=(value[2]-min)/math.max(1e-9,max-min)
    local function rangeNumber(n) return formatNumber(n,step) end
    caption.Text=rangeNumber(value[1]).." - "..rangeNumber(value[2])
   else a=0;b=(value-min)/math.max(1e-9,max-min);caption.Text=formatNumber(value,step) end
   local start=fw*a;local finish=fw*b
   local fillWidth=math.max(0,finish-start)
   self:_animate(fill,{Position=UDim2.fromOffset(start,0),Size=UDim2.fromOffset(fillWidth,4)},self._drag and .03 or .12)
   local cover=kind=="range" and math.min(fw*.5-start,finish-fw*.5) or finish-(fw-measured(caption.Text,12,false))*.5
   caption.TextColor3=color(T.Title)
   for i,handle in ipairs(handles) do self:_animate(handle,{Position=UDim2.new(kind=="range" and (i==1 and a or b) or b,0,.5,0)},self._drag and .03 or .16) end
  end
  local function edit()
   self._drag=nil;caption.Visible=false;editor.Visible=true;editor.Text=caption.Text;editor:CaptureFocus();editor.CursorPosition=#editor.Text+1;editor.SelectionStart=1
  end
  self:_on(control.MouseButton2Click,edit,scope)
  self:_on(control.TouchLongPress,function(_,state) if state==Enum.UserInputState.Begin then edit() end end,scope)
  self:_on(editor.FocusLost,function()
   local raw=editor.Text;editor.Visible=false;caption.Visible=true
   self._editCancel=nil
   if kind=="range" then
    local a,b=raw:match("^%s*([%+%-]?[%d%.]+)%s*[:;%-]%s*([%+%-]?[%d%.]+)%s*$")
    if tonumber(a) and tonumber(b) then set({tonumber(a),tonumber(b)}) else refresh(group.Values[key]) end
   else local value=tonumber((raw:gsub(",",".")));if value then set(value) else refresh(group.Values[key]) end end
  end,scope)
  self:_on(editor.Focused,function() local original=editor.Text;self._editCancel=function() editor.Text=original end end,scope)
  self:_on(control.InputBegan,function(input)
   if editor.Visible then return end
   local chosen
   self:_startDrag(input,function(point)
    local usedScale=control.AbsoluteSize.X/fw
    local left=control.AbsolutePosition.X-self.Gui.AbsolutePosition.X+1.5*usedScale
    local width=math.max(1,control.AbsoluteSize.X-3*usedScale)
    local value=min+math.clamp((point.X-left)/width,0,1)*(max-min)
    if kind=="range" then
     local current=clone(group.Values[key]);chosen=chosen or (math.abs(value-current[1])<=math.abs(value-current[2]) and 1 or 2)
     current[chosen]=chosen==1 and math.min(value,current[2]) or math.max(value,current[1]);set(current)
    else set(value) end
   end,scope)
  end,scope)
  self:_wheelField(control,scope,function(direction)
   local value=group.Values[key]
   if kind=="range" then set({value[1]+direction*step,value[2]+direction*step}) else set(value+direction*step) end
  end)
 elseif kind=="select" or kind=="dropdown" or kind=="multi" then
  caption.Position=UDim2.fromOffset(7,0);caption.TextXAlignment=Enum.TextXAlignment.Left;caption.Size=UDim2.fromOffset(fw-24,fh)
  local chevron=icon(control,"down",9.5,0xCACACA);chevron.Root.Position=UDim2.fromOffset(fw-13.75,(fh-9.5)/2)
  local up=icon(control,"up",9.5,0xCACACA);up.Root.Position=chevron.Root.Position;up.Root.Visible=false
  self:_fieldHover(control,caption,scope)
  self:_on(control:GetAttributeChangedSignal("PopupOpen"),function() local open=control:GetAttribute("PopupOpen")==true;chevron.Root.Visible=not open;up.Root.Visible=open end,scope)
  refresh=function(value) caption.Text=kind=="multi" and (#value==0 and self:_tr("None") or table.concat(value,", ")) or tostring(value) end
  self:_on(control.Activated,function()
   self:_listPopup(control,def.options or def.Options or {},group.Values[key],kind=="multi",set)
  end,scope)
 elseif kind=="text" then
  caption.Visible=false
  local box=create("TextBox",control,{BackgroundTransparency=1,Position=UDim2.fromOffset(6,0),Size=UDim2.fromOffset(fw-12,fh),ClearTextOnFocus=false,Text=group.Values[key],PlaceholderText="Empty",PlaceholderColor3=color(T.FieldText),TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Center,Font=Enum.Font.Gotham,TextSize=14,TextColor3=color(T.FieldText)})
  local focusStroke=stroke(control,T.AccentDim,.5);focusStroke.Enabled=false;local original;local updating=false
  refresh=function(value) if Input:GetFocusedTextBox()~=box then box.Text=value end end
  self:_on(box.Focused,function()
   original=group.Values[key];focusStroke.Enabled=true;box.TextXAlignment=Enum.TextXAlignment.Left;box.TextColor3=color(T.Label)
   self._editCancel=function() updating=true;box.Text=original;set(original);updating=false end
  end,scope)
  self:_on(box:GetPropertyChangedSignal("Text"),function() if not updating and Input:GetFocusedTextBox()==box then set(box.Text) end end,scope)
  self:_on(box.FocusLost,function() set(box.Text);self._editCancel=nil;focusStroke.Enabled=false;box.TextXAlignment=Enum.TextXAlignment.Center;box.TextColor3=color(T.FieldText) end,scope)
 elseif kind=="color" then
  caption.Visible=false
  for y=0,1 do for x=0,1 do create("Frame",control,{BackgroundColor3=color((x+y)%2==0 and 0x3A3A3A or 0x5A5A5A),Position=UDim2.fromScale(x/2,y/2),Size=UDim2.fromScale(.5,.5)}) end end
  local swatch=create("Frame",control,{Size=UDim2.fromScale(1,1),ZIndex=2});corner(swatch,1.5)
  local outline=stroke(control,0xFFFFFF,.6);outline.Transparency=1
  self:_fieldHover(control,nil,scope)
  self:_on(control.MouseEnter,function() outline.Transparency=.6 end,scope)
  self:_on(control.MouseLeave,function() outline.Transparency=control:GetAttribute("PopupOpen") and .6 or 1 end,scope)
  self:_on(control:GetAttributeChangedSignal("PopupOpen"),function() outline.Transparency=control:GetAttribute("PopupOpen") and .6 or 1 end,scope)
  refresh=function(value) swatch.BackgroundColor3=Color3.fromHex(value.Hex);swatch.BackgroundTransparency=1-value.Alpha end
  self:_motion(swatch,function() if group.Values[key].Rainbow then swatch.BackgroundColor3=Color3.fromHSV(os.clock()*.12%1,1,1) end end,scope)
  self:_on(control.Activated,function() self:_colorPopup(control,group,key) end,scope)
 elseif kind=="gear" then
  caption.Visible=false;control.BackgroundTransparency=1
  local gear=icon(control,"gear",10.5,T.Muted);gear.Root.Position=UDim2.new(.5,-5.25,.5,-5.25)
  local hit=create("TextButton",row.Root,{Name="GearRowHit",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,-35,1,0)})
  self:_on(hit.Activated,function() self:_gearPopup(control,group,key,def.settings or def.Settings or {}) end,scope)
  local function gearHover(on) gear:SetColor(on and T.IconHover or T.Icon) end
  self:_on(row.Root.MouseEnter,function() gearHover(true) end,scope);self:_on(row.Root.MouseLeave,function() gearHover(control:GetAttribute("PopupOpen")==true) end,scope)
  self:_fieldHover(control,nil,scope);control.BackgroundTransparency=1
  self:_on(control:GetAttributeChangedSignal("PopupOpen"),function() gearHover(control:GetAttribute("PopupOpen")==true) end,scope)
  refresh=function() end
  self:_on(control.Activated,function() self:_gearPopup(control,group,key,def.settings or def.Settings or {}) end,scope)
 elseif kind=="slots" then
  caption.Position=UDim2.fromOffset(7,0);caption.Size=UDim2.fromOffset(fw-24,fh);caption.TextXAlignment=Enum.TextXAlignment.Left
  local down=icon(control,"down",9,0xCACACA);down.Root.Position=UDim2.fromOffset(fw-12.5,5)
  local up=icon(control,"up",9,0xCACACA);up.Root.Position=down.Root.Position;up.Root.Visible=false
  self:_fieldHover(control,caption,scope)
  self:_on(control:GetAttributeChangedSignal("PopupOpen"),function() local open=control:GetAttribute("PopupOpen")==true;down.Root.Visible=not open;up.Root.Visible=open end,scope)
  refresh=function(value) local n=0;for _,role in ipairs(value) do if role~="None" then n+=1 end end;caption.Text=n==0 and "None" or tostring(n)..(n==1 and " slot" or " slots") end
  self:_on(control.Activated,function() self:_slotsPopup(control,group,key,def.options or def.Options or {"None","Sword","Tool","Blocks","Food","Utility"}) end,scope)
 elseif kind=="key" or kind=="keybind" then
  self:_fieldHover(control,caption,scope)
  refresh=function(value) caption.Text=value=="None" and self:_tr("None") or value;fw=math.max(50,math.min(160,measured(caption.Text,14,false)+18));control.Size=UDim2.fromOffset(fw,fh);caption.Size=UDim2.fromOffset(fw-8,fh) end
  self:_on(control.Activated,function() self:_beginBinding(group,key,caption,scope) end,scope)
  self:_on(control.MouseButton2Click,function() if self._binding then self._binding.cancel();self._binding=nil end;set("None") end,scope)
 elseif kind=="button" then
  refresh=function() caption.Text=def.buttonText or "Run" end
  self:_on(control.Activated,function()
   local callback=def.callback or def.Callback;if callback then task.spawn(callback,group) end
   self._changed:Fire(group.Id,key,true)
  end,scope)
 else control.Visible=false;refresh=function() end end
 local paint=refresh
 refresh=function(value)
  paint(value)
  local modified=group.Defaults and Http:JSONEncode(value)~=Http:JSONEncode(group.Defaults[key])
  local highlight=not self.Models or not self.Models.Config or self.Models.Config.Values["Highlight modified options"]
  row.Label.TextColor3=color(modified and highlight and 0xE4C28A or row.Privileged and T.Privileged or T.Label)
 end
 self:_on(row.Root.MouseEnter,function()
  local defaults=group.Defaults and group.Defaults[key]
  if defaults~=nil and self.Models.Config.Values["Display default values"] then self:Describe((def.label or nameOf(def)).." · Default: "..Http:JSONEncode(defaults)) end
 end,scope)
 self:_on(row.Root.MouseLeave,function() self:_stopTween(row.Label);refresh(group.Values[key]) end,scope)
 row.Refresh=function() refresh(group.Values[key]) end
 self:_listen(group,key,refresh,scope);row.Refresh();return row
end

-- Structured settings and editors, shared by all three layouts.
function Window:_richRow(group,def,key,parent,scope)
 local kind=kindOf(def);local row=self:_rowBase(parent,scope,def.label or nameOf(def));row.Definition=def;row.Key=key
 if kind=="separator" then
  row.Height=26;row.Label.TextSize=14;row.Label.TextColor3=color(self:_accentHex());row.Label.Font=Enum.Font.BuilderSansBold
  local rule=create("Frame",row.Root,{Name="SectionRule",BackgroundColor3=color(0x574455),Size=UDim2.new(1,-24,0,1),Position=UDim2.fromOffset(12,25)})
  row.Resize=function(width) row.Label.Size=UDim2.fromOffset(width-24,24) end
 elseif kind=="paragraph" then
  row.Height=def.height or 80;row.Label.Visible=false
  local title=text(row.Root,self:_tr(def.label or nameOf(def)),12,0,200,26,15,T.Title,true)
  local body=text(row.Root,def.text or def.description or "",12,28,200,row.Height-32,14,T.FieldText);body.TextWrapped=true;body.TextYAlignment=Enum.TextYAlignment.Top;body.TextTruncate=Enum.TextTruncate.None
  row.Resize=function(width) title.Size=UDim2.fromOffset(width-24,26);body.Size=UDim2.fromOffset(width-24,row.Height-32) end
 elseif kind=="section" then
  row.Root.ClipsDescendants=true;row.Height=32
  local header=create("TextButton",row.Root,{Name="SectionToggle",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.new(1,0,0,32)})
  local arrow=icon(header,"down",14,self:_accentHex());arrow.Root.Position=UDim2.fromOffset(11,9)
  row.Label.Position=UDim2.fromOffset(34,0);row.Label.Font=Enum.Font.BuilderSansBold
  local body=create("Frame",row.Root,{Name="SectionContent",BackgroundTransparency=1,Position=UDim2.fromOffset(10,32),Size=UDim2.fromOffset(220,100)})
  create("Frame",body,{Name="SectionGuide",BackgroundColor3=color(0x76506D),Position=UDim2.fromOffset(3,0),Size=UDim2.new(0,1,1,-4)})
  local children={};for _,child in ipairs(def.settings or def.Settings or {}) do children[#children+1]=self:_makeRow(group,child,key.."/"..nameOf(child),body,scope) end
  local expanded=def.expanded~=false;row._fraction=expanded and 1 or 0;local target=row._fraction;row.Children=children
  self:_motion(row.Root,function(dt)
   if row._fraction~=target then row._fraction+=(target-row._fraction)*(1-math.exp(-dt*18));if math.abs(target-row._fraction)<.001 then row._fraction=target end;self._layoutDirty=true end
  end,scope)
  self:_on(header.Activated,function() expanded=not expanded;target=expanded and 1 or 0;self:_animate(arrow.Root,{Rotation=expanded and 0 or -90},.2);self._layoutDirty=true end,scope)
  row.Resize=function(width)
   row.Label.Size=UDim2.fromOffset(width-50,32)
   local full=self:_placeRows(group,children,width-18,0);row.Height=32+full*row._fraction;body.Size=UDim2.fromOffset(width-18,full);row.Root.Size=UDim2.fromOffset(width,row.Height)
  end
 elseif kind=="number" then
  local min,max,step=def.min or 0,def.max or 100,def.step or 1
  local control=field(row.Root,0,3,132,26);control.Name="Field_"..key;row.Control=control
  local box=create("TextBox",control,{Name="NumberInput",BackgroundTransparency=1,Position=UDim2.fromOffset(26,0),Size=UDim2.fromOffset(80,26),Text="",ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=14,TextColor3=color(T.Title)})
  local minus=self:_button(control,"−",0,0,26,26,function() group:Set(key,group.Values[key]-step) end,scope)
  self:_button(control,"+",106,0,26,26,function() group:Set(key,group.Values[key]+step) end,scope)
  local function refresh(v) if Input:GetFocusedTextBox()~=box then box.Text=formatNumber(v,step) end end
  self:_on(box.Focused,function() local original=group.Values[key];self._editCancel=function() box.Text=tostring(original) end end,scope)
  self:_on(box.FocusLost,function() self._editCancel=nil;local value=tonumber((box.Text:gsub(",",".")));if value then group:Set(key,value) end;refresh(group.Values[key]) end,scope)
  self:_wheelField(control,scope,function(direction) group:Set(key,group.Values[key]+direction*step) end)
  row.Resize=function(width) control.Position=UDim2.fromOffset(width-144,3);row.Label.Size=UDim2.fromOffset(math.max(1,width-166),32) end
  self:_listen(group,key,refresh,scope);refresh(group.Values[key])
 elseif kind=="textarea" then
  row.Height=def.height or 128
  local box=create("TextBox",row.Root,{Name="Field_"..key,BackgroundColor3=color(T.Field),Position=UDim2.fromOffset(12,32),Size=UDim2.fromOffset(200,row.Height-40),Text=group.Values[key],ClearTextOnFocus=false,MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Font=def.code and Enum.Font.Code or Enum.Font.BuilderSans,TextSize=14,TextColor3=color(T.Title),PlaceholderText=def.placeholder or "Type here…"});corner(box,4)
  create("UIPadding",box,{PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),PaddingTop=UDim.new(0,6)})
  local edge=stroke(box,0x544152,1);local original;local reverting=false;row.Control=box
  self:_on(box.Focused,function() original=group.Values[key];self:_animate(edge,{Color=color(self:_accentHex())});self._editCancel=function() reverting=true;box.Text=original;group:Set(key,original);reverting=false end end,scope)
  self:_on(box:GetPropertyChangedSignal("Text"),function() if not reverting and Input:GetFocusedTextBox()==box then group:Set(key,box.Text) end end,scope)
  self:_on(box.FocusLost,function() self._editCancel=nil;group:Set(key,box.Text);self:_animate(edge,{Color=color(0x544152)}) end,scope)
  self:_listen(group,key,function(v) if Input:GetFocusedTextBox()~=box then box.Text=v end end,scope)
  row.Resize=function(width) row.Label.Size=UDim2.fromOffset(width-24,30);box.Size=UDim2.fromOffset(width-24,row.Height-40) end
 elseif kind=="readout" then
  local value=text(row.Root,"",0,0,120,32,14,def.color or self:_accentHex(),false,Enum.TextXAlignment.Right)
  self:_listen(group,key,function(v) value.Text=v end,scope);value.Text=group.Values[key]
  row.Resize=function(width) row.Label.Size=UDim2.fromOffset(math.max(1,width-160),32);value.Position=UDim2.fromOffset(width-152,0);value.Size=UDim2.fromOffset(140,32) end
 elseif kind=="progress" then
  row.Height=52
  local value=text(row.Root,"",0,0,100,28,14,T.Title,false,Enum.TextXAlignment.Right)
  local rail=create("Frame",row.Root,{Name="ProgressRail",BackgroundColor3=color(0x4E404F),Position=UDim2.fromOffset(12,35),Size=UDim2.fromOffset(200,5)});corner(rail,3)
  local fill=create("Frame",rail,{Name="ProgressFill",BackgroundColor3=color(self:_accentHex()),Size=UDim2.fromScale(0,1)});corner(fill,3)
  local function refresh(v) local fraction=(v-(def.min or 0))/math.max(1e-9,(def.max or 100)-(def.min or 0));value.Text=formatNumber(v,def.step or 1)..(def.suffix or "%");self:_animate(fill,{Size=UDim2.fromScale(fraction,1)},.25) end
  self:_listen(group,key,refresh,scope);refresh(group.Values[key])
  row.Resize=function(width) row.Label.Size=UDim2.fromOffset(math.max(1,width-130),28);value.Position=UDim2.fromOffset(width-112,0);rail.Size=UDim2.fromOffset(width-24,5) end
 elseif kind=="json" then
  local control=self:_button(row.Root,"{ … }",0,3,112,26,function()
   self:_textDialog(self:_tr(nameOf(def)),Http:JSONEncode(group.Values[key]),function(raw)
    local ok,value=pcall(Http.JSONDecode,Http,raw);if not ok then return false,"Invalid JSON" end
    local result=normalized(def,value);if not result then return false,"Expected object or array" end
    group:Set(key,result);return true
   end)
  end,scope);control.Name="Field_"..key;row.Control=control
  row.Resize=function(width) control.Position=UDim2.fromOffset(width-124,3);row.Label.Size=UDim2.fromOffset(math.max(1,width-150),32) end
 elseif kind=="list" then
  local control=self:_button(row.Root,"",0,3,112,26,function() end,scope);control.Name="Field_"..key;row.Control=control
  local function refresh(v) control.Text=tostring(#v).." items  …" end
  self:_listen(group,key,refresh,scope);refresh(group.Values[key])
  self:_on(control.Activated,function() self:_listEditor(control,group,key,def) end,scope)
  row.Resize=function(width) control.Position=UDim2.fromOffset(width-124,3);row.Label.Size=UDim2.fromOffset(math.max(1,width-148),32) end
 end
 row.Refresh=row.Refresh or function() end
 return row
end
function Window:_listEditor(owner,group,key,def)
 local popup=self:_popup(owner,owner,360,340,false,"beside");if not popup then return end
 local frame,scope=popup.Frame,popup.Scope
 text(frame,self:_tr(nameOf(def)),14,8,popup.Width-28,28,17,T.Title,true)
 local input=create("TextBox",frame,{Name="NewItem",Position=UDim2.fromOffset(12,43),Size=UDim2.fromOffset(popup.Width-100,30),BackgroundColor3=color(T.Field),Text="",PlaceholderText="New entry…",TextColor3=color(T.Title),ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=14});corner(input,4)
 local rowsScope
 local scroll=create("ScrollingFrame",frame,{Name="ListItems",BackgroundTransparency=1,Position=UDim2.fromOffset(12,85),Size=UDim2.fromOffset(popup.Width-24,popup.Height-130),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,Active=true})
 local function render()
  if rowsScope then rowsScope:Clean() end;rowsScope=Scope.new(scope)
  for i,value in ipairs(group.Values[key]) do
   local label=text(scroll,value,5,(i-1)*36,popup.Width-82,32,14,T.Label);rowsScope.disposals[#rowsScope.disposals+1]=function() if label.Parent then label:Destroy() end end
   self:_button(scroll,"×",popup.Width-66,(i-1)*36,32,30,function() local values=group:Get(key);table.remove(values,i);group:Set(key,values) end,rowsScope)
  end
  scroll.CanvasSize=UDim2.fromOffset(0,#group.Values[key]*36)
 end
 local function add() if input.Text~="" then local values=group:Get(key);if #values>=(def.maxItems or 100) then self:Notify("List limit reached");return end;values[#values+1]=input.Text;group:Set(key,values);input.Text="" end end
 self:_button(frame,"Add",popup.Width-78,43,66,30,add,scope)
 self:_on(input.FocusLost,function(enter) if enter then add() end end,scope)
 self:_button(frame,"Clear",12,popup.Height-36,80,26,function() group:Set(key,{}) end,scope)
 self:_button(frame,"Done",popup.Width-92,popup.Height-36,80,26,function() self:_closePopups(table.find(self._popups,popup)) end,scope)
 self:_listen(group,key,render,scope);render()
end

function Window:_closePopups(from,immediate)
 from=math.max(1,from or 1)
 for i=#self._popups,from,-1 do
  local p=table.remove(self._popups,i)
  if self._drag and self._drag.scope==p.Scope then self._drag=nil end
  if self._binding and self._binding.scope==p.Scope then self._binding.cancel();self._binding=nil end
  if p.Anchor and p.Anchor.Parent then p.Anchor:SetAttribute("PopupOpen",false) end
  for object,tw in pairs(self._tweens) do if object==p.Frame or object:IsDescendantOf(p.Scope.root) then tw:Cancel();self._tweens[object]=nil end end
  self:_cancelTransition(p.Surface,true)
  if not immediate and not self._dead and not self.ReducedMotion then
   local ghost=p.Scope.root:Clone();ghost.Name="ClosingPopup";ghost.Parent=self.Gui
   for _,o in ipairs(ghost:GetDescendants()) do if o:IsA("GuiButton") or o:IsA("TextBox") then o.Active=false;o.Interactable=false end end
   local exit=Scope.new(self._scope);exit.root=ghost
   self:_transition(ghost,1,0,.12,exit,function() exit:Clean() end,{Y=-5})
  end
  p.Scope:Clean()
 end
end
function Window:_popup(owner,anchor,width,height,modal,placement)
 for i,p in ipairs(self._popups) do if p.Owner==owner then self:_closePopups(i);return nil end end
 local s=self:_activeScale();local view=self.Gui.AbsoluteSize
 local contentHeight=height
 width=math.min(width,view.X/s-12);height=math.min(height,view.Y/s-12)
 local x,y=(view.X-width*s)/2,(view.Y-height*s)/2
 if anchor then
  local pos=anchor.AbsolutePosition-self.Gui.AbsolutePosition
  x=pos.X;y=pos.Y+anchor.AbsoluteSize.Y+3*s
  if placement=="beside" then
   x=pos.X+anchor.AbsoluteSize.X+6*s;if x+width*s>view.X-2 then x=pos.X-width*s-6*s end;y=pos.Y-4*s
  elseif placement=="above" then y=pos.Y-height*s-4*s
  elseif y+height*s>view.Y-6 then y=pos.Y-height*s-3*s end
 end
 x=math.clamp(x,6,math.max(6,view.X-width*s-6));y=math.clamp(y,6,math.max(6,view.Y-height*s-6))
 local scope=Scope.new(self._scope)
 local overlay=create("Frame",self.Gui,{Name="PopupLayer",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=100+#self._popups*20});scope.root=overlay
 local blocker=create("TextButton",overlay,{Name="Dismiss",Text="",AutoButtonColor=false,BackgroundColor3=Color3.new(0,0,0),BackgroundTransparency=modal and .65 or 1,Size=UDim2.fromScale(1,1),Active=true,ZIndex=1})
 local surface=create("Frame",overlay,{Name="PopupSurface",BackgroundTransparency=1,Position=UDim2.fromOffset(math.round(x),math.round(y)),Size=UDim2.fromOffset(width,height),ZIndex=2})
 create("UIScale",surface,{Scale=s});softShadow(surface,2.5,8)
 local frame=create("Frame",surface,{Name="Popup",BackgroundColor3=color(T.Popup),Size=UDim2.fromOffset(width,height),ZIndex=2,Active=true})
 corner(frame,7);stroke(frame,0x685163,1)
 local chrome=frame
 if contentHeight>height then
  frame=create("ScrollingFrame",chrome,{Name="PopupContent",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.fromOffset(0,contentHeight),ScrollBarThickness=3,ScrollBarImageColor3=color(self:_accentHex()),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true})
 end
 local popup={Owner=owner,Anchor=anchor,Scope=scope,Frame=frame,Surface=surface,Width=width,Height=contentHeight,ViewportHeight=height,Chrome=chrome}
 self._popups[#self._popups+1]=popup
 if anchor then anchor:SetAttribute("PopupOpen",true) end
 self:_transition(surface,0,1,.16,scope,nil,{Y=-6})
 self:_on(blocker.Activated,function() self:_closePopups(table.find(self._popups,popup) or #self._popups) end,scope)
 return popup
end
function Window:_listPopup(owner,options,selected,multi,callback)
 local widest=0;for _,option in ipairs(options) do widest=math.max(widest,measured(option,14,false)) end
 local searchable=#options>8 or multi
 local header=searchable and 44 or 6;local footer=multi and 42 or 6
 local popup=self:_popup(owner,owner,math.max(190,owner.AbsoluteSize.X/self:_activeScale()+20,math.min(360,widest+58)),math.min(8,#options)*32+header+footer);if not popup then return end
 local frame,scope=popup.Frame,popup.Scope;local current=clone(selected);local rows={};local visible={};local focus=1
 frame.BackgroundColor3=color(0x211D27)
 local scroll=create("ScrollingFrame",frame,{Name="Options",BackgroundTransparency=1,Position=UDim2.fromOffset(5,header),Size=UDim2.new(1,-10,1,-header-footer),CanvasSize=UDim2.fromOffset(0,#options*32),ScrollBarThickness=3,ScrollBarImageColor3=color(self:_accentHex()),ScrollingDirection=Enum.ScrollingDirection.Y,Active=true})
 local function refresh()
  for _,entry in ipairs(rows) do
   local chosen=multi and table.find(current or {},entry.Value)~=nil or not multi and current==entry.Value
   local hot=entry.Hover or visible[focus]==entry
   self:_animate(entry.Button,{BackgroundTransparency=hot and .1 or chosen and .7 or 1})
   self:_animate(entry.Label,{TextColor3=color(chosen and self:_accentHex() or hot and T.Title or T.FieldText)})
   entry.Check.Root.Visible=chosen
  end
 end
 local function choose(entry)
  if not entry then return end
  if multi then
   current=current or {};local index=table.find(current,entry.Value);if index then table.remove(current,index) else current[#current+1]=entry.Value end
   callback(clone(current));refresh()
  else local index=table.find(self._popups,popup);callback(entry.Value);if index then self:_closePopups(index) end end
 end
 for i,option in ipairs(options) do
  local b=create("TextButton",scroll,{Name="Option_"..tostring(option),Text="",BackgroundColor3=color(0x4D3A4D),BackgroundTransparency=1,Position=UDim2.fromOffset(0,(i-1)*32),Size=UDim2.new(1,0,0,32),AutoButtonColor=false});corner(b,4)
  local label=text(b,tostring(option),10,0,popup.Width-54,32,14,T.FieldText)
  local check=icon(b,"check",14,self:_accentHex());check.Root.Position=UDim2.new(1,-23,0,9)
  local entry={Value=option,Label=label,Button=b,Check=check,Hover=false};rows[#rows+1]=entry;visible[#visible+1]=entry
  self:_on(b.MouseEnter,function() entry.Hover=true;focus=table.find(visible,entry) or focus;refresh() end,scope)
  self:_on(b.MouseLeave,function() entry.Hover=false;refresh() end,scope)
  self:_on(b.Activated,function() choose(entry) end,scope)
 end
 if searchable then
  local search=create("TextBox",frame,{Name="OptionSearch",BackgroundColor3=color(T.Field),Position=UDim2.fromOffset(10,8),Size=UDim2.new(1,-20,0,28),Text="",PlaceholderText=self:_tr("Search").."…",PlaceholderColor3=color(T.Muted),ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=14,TextColor3=color(T.Title),TextXAlignment=Enum.TextXAlignment.Left});corner(search,4)
  create("UIPadding",search,{PaddingLeft=UDim.new(0,8)})
  self:_on(search:GetPropertyChangedSignal("Text"),function()
   visible={};local query=search.Text:lower()
   for _,entry in ipairs(rows) do local show=tostring(entry.Value):lower():find(query,1,true)~=nil;entry.Button.Visible=show;if show then entry.Button.Position=UDim2.fromOffset(0,#visible*32);visible[#visible+1]=entry end end
   focus=1;scroll.CanvasPosition=Vector2.new(0,0);scroll.CanvasSize=UDim2.fromOffset(0,#visible*32);refresh()
  end,scope)
 end
 if multi then
  self:_button(frame,self:_tr("All"),10,popup.Height-34,(popup.Width-28)/2,26,function()
   current=current or {};for _,entry in ipairs(visible) do if not table.find(current,entry.Value) then current[#current+1]=entry.Value end end;callback(clone(current));refresh()
  end,scope)
  self:_button(frame,self:_tr("Clear"),popup.Width/2+4,popup.Height-34,(popup.Width-28)/2,26,function() current={};callback({});refresh() end,scope)
 end
 self:_on(Input.InputBegan,function(input)
  if self._popups[#self._popups]~=popup or self._binding or input.UserInputType~=Enum.UserInputType.Keyboard then return end
  local key=input.KeyCode
  if key==Enum.KeyCode.Down or key==Enum.KeyCode.Up then
   focus=math.clamp(focus+(key==Enum.KeyCode.Down and 1 or -1),1,math.max(1,#visible));refresh()
   local top=(focus-1)*32*self:_activeScale();local bottom=top+32*self:_activeScale()
   if top<scroll.CanvasPosition.Y then scroll.CanvasPosition=Vector2.new(0,top) elseif bottom>scroll.CanvasPosition.Y+scroll.AbsoluteSize.Y then scroll.CanvasPosition=Vector2.new(0,bottom-scroll.AbsoluteSize.Y) end
  elseif key==Enum.KeyCode.Return or key==Enum.KeyCode.KeypadEnter then choose(visible[focus]) end
 end,scope)
 refresh()
end
function Window:_gearPopup(owner,group,key,defs)
 local popup=self:_popup(owner,owner,320,math.max(36,28+#defs*32),false,"beside");if not popup then return end
 text(popup.Frame,nameOf(group._definitions[key]),10,1,popup.Width-20,20,10,T.Title)
 local scroll=create("ScrollingFrame",popup.Frame,{BackgroundTransparency=1,Position=UDim2.fromOffset(-2,20),Size=UDim2.new(1,4,1,-24),CanvasSize=UDim2.fromOffset(0,#defs*25.5),ScrollBarThickness=1.5,ScrollBarImageColor3=color(0x3A3A3A),Active=true})
 local rows={}
 for _,def in ipairs(defs) do rows[#rows+1]=self:_makeRow(group,def,key.."/"..nameOf(def),scroll,popup.Scope) end
 local function layout()
  local y=0;for _,row in ipairs(rows) do local shown=matches(row.Definition.when or row.Definition.VisibleIf,group.Values);row:Place(popup.Width+4,y,shown);if shown then y+=row.Height end end
  scroll.CanvasSize=UDim2.fromOffset(0,y);popup.Height=math.min(math.max(32,28+y),self.Gui.AbsoluteSize.Y/self:_activeScale()-12);popup.Frame.Size=UDim2.fromOffset(popup.Width,popup.Height);popup.Surface.Size=popup.Frame.Size
 end
 popup.Reflow=layout
 for setting in pairs(group._definitions) do self:_listen(group,setting,layout,popup.Scope) end
 layout()
end
function Window:_colorPopup(owner,group,key)
 local def=group._definitions[key];local rainbow=def.allowRainbow==true or def.rainbow==true
 local popup=self:_popup(owner,owner,324,rainbow and 390 or 354);if not popup then return end
 local frame,scope=popup.Frame,popup.Scope;local h,s,v,a=0,1,1,1;local mode="RGB";local committing=false
 local width=popup.Width;local svW=width-62;local svH=164
 text(frame,self:_tr("Color"),14,7,width-110,28,17,T.Title,true)
 local modeButton
 modeButton=self:_button(frame,"RGB",width-78,9,64,25,function() mode=mode=="RGB" and "HSV" or "RGB";modeButton.Text=mode;popup.Refresh(group.Values[key]) end,scope)
 local sv=field(frame,14,45,svW,svH);sv.Name="SaturationValue"
 local white=create("Frame",sv,{BackgroundColor3=Color3.new(1,1,1),Size=UDim2.fromScale(1,1)})
 create("UIGradient",white,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})})
 local black=create("Frame",sv,{BackgroundColor3=Color3.new(0,0,0),Size=UDim2.fromScale(1,1),ZIndex=2})
 create("UIGradient",black,{Rotation=90,Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})})
 local cursor=create("Frame",sv,{BackgroundTransparency=1,Name="SVCursor",Size=UDim2.fromOffset(10,10),AnchorPoint=Vector2.new(.5,.5),ZIndex=3});corner(cursor,5);stroke(cursor,0xFFFFFF,2)
 local hue=field(frame,width-32,45,18,svH);hue.Name="Hue";hue.BackgroundColor3=Color3.new(1,1,1)
 local stops={};for i=0,6 do stops[#stops+1]=ColorSequenceKeypoint.new(i/6,Color3.fromHSV(i/6,1,1)) end
 create("UIGradient",hue,{Color=ColorSequence.new(stops),Rotation=90})
 local hueTick=create("Frame",hue,{Name="HueCursor",Size=UDim2.new(1,4,0,3),Position=UDim2.fromOffset(-2,0),BackgroundColor3=color(T.Title),ZIndex=2})
 local alpha=field(frame,14,222,width-28,14);alpha.Name="Alpha"
 for y=0,1 do for x=0,math.ceil((width-28)/7)-1 do create("Frame",alpha,{BackgroundColor3=color((x+y)%2==0 and 0x45404B or 0x77717C),Size=UDim2.fromOffset(7,7),Position=UDim2.fromOffset(x*7,y*7)}) end end;alpha.ClipsDescendants=true
 local alphaFill=create("Frame",alpha,{Size=UDim2.fromScale(1,1),ZIndex=2})
 create("UIGradient",alphaFill,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})})
 local alphaTick=create("Frame",alpha,{Size=UDim2.fromOffset(3,14),BackgroundColor3=color(T.Title),ZIndex=3})
 local boxes,labels={},{}
 local cell=(width-46)/4
 for i=1,4 do
  labels[i]=text(frame,({"R","G","B","A"})[i],14+(i-1)*(cell+6),244,cell,18,14,T.Muted)
  boxes[i]=create("TextBox",frame,{Name=({"Red","Green","Blue","Opacity"})[i],BackgroundColor3=color(T.Field),Position=UDim2.fromOffset(14+(i-1)*(cell+6),265),Size=UDim2.fromOffset(cell,28),Text="",ClearTextOnFocus=false,Font=Enum.Font.BuilderSans,TextSize=14,TextColor3=color(T.Title)});corner(boxes[i],4)
 end
 local hex=create("TextBox",frame,{BackgroundColor3=color(T.Field),Name="HexRGBA",Position=UDim2.fromOffset(14,309),Size=UDim2.fromOffset(width-100,30),ClearTextOnFocus=false,Font=Enum.Font.Code,TextSize=14,TextColor3=color(T.Title),Text=""});corner(hex,4)
 local refresh
 local function commit()
  committing=true;group:Set(key,{Hex="#"..Color3.fromHSV(h,s,v):ToHex(),Alpha=a,Rainbow=group.Values[key].Rainbow});refresh(group.Values[key]);committing=false
 end
 refresh=function(value)
  local rgb=Color3.fromHex(value.Hex)
  if not committing then local nh,ns,nv=rgb:ToHSV();if ns>0 then h=nh end;s=ns;v=nv end;a=value.Alpha
  sv.BackgroundColor3=Color3.fromHSV(h,1,1);cursor.Position=UDim2.fromScale(s,1-v);hueTick.Position=UDim2.new(0,-2,h,-1);alphaFill.BackgroundColor3=rgb;alphaTick.Position=UDim2.new(a,-1,0,0)
  if Input:GetFocusedTextBox()~=hex then hex.Text=value.Hex..string.format("%02X",math.round(a*255)) end
  local channels=mode=="RGB" and {rgb.R*255,rgb.G*255,rgb.B*255,a*255} or {h*360,s*100,v*100,a*100}
  local names=mode=="RGB" and {"R","G","B","A"} or {"H°","S%","V%","A%"}
  for i,box in ipairs(boxes) do labels[i].Text=names[i];if Input:GetFocusedTextBox()~=box then box.Text=tostring(math.round(channels[i])) end end
 end
 popup.Refresh=refresh;self:_listen(group,key,refresh,scope)
 self:_on(sv.InputBegan,function(input) self:_startDrag(input,function(p)
  s=math.clamp((p.X-(sv.AbsolutePosition.X-self.Gui.AbsolutePosition.X))/math.max(1,sv.AbsoluteSize.X),0,1)
  v=1-math.clamp((p.Y-(sv.AbsolutePosition.Y-self.Gui.AbsolutePosition.Y))/math.max(1,sv.AbsoluteSize.Y),0,1);commit()
 end,scope) end,scope)
 self:_on(hue.InputBegan,function(input) self:_startDrag(input,function(p) h=math.clamp((p.Y-(hue.AbsolutePosition.Y-self.Gui.AbsolutePosition.Y))/math.max(1,hue.AbsoluteSize.Y),0,.999999);commit() end,scope) end,scope)
 self:_on(alpha.InputBegan,function(input) self:_startDrag(input,function(p) a=math.clamp((p.X-(alpha.AbsolutePosition.X-self.Gui.AbsolutePosition.X))/math.max(1,alpha.AbsoluteSize.X),0,1);commit() end,scope) end,scope)
 local function parse(value)
  value=value:gsub("#",""):gsub("%s","")
  if #value==3 and value:match("^%x+$") then value=value:gsub(".",function(c) return c..c end) end
  if (#value==6 or #value==8) and value:match("^%x+$") then group:Set(key,{Hex="#"..value:sub(1,6),Alpha=#value==8 and tonumber(value:sub(7,8),16)/255 or 1,Rainbow=group.Values[key].Rainbow}) else self:Notify("Use RGB / RRGGBB / RRGGBBAA") end
  refresh(group.Values[key])
 end
 self:_on(hex.Focused,function() local original=hex.Text;self._editCancel=function() hex.Text=original end end,scope)
 self:_on(hex.FocusLost,function() self._editCancel=nil;parse(hex.Text) end,scope)
 for i,box in ipairs(boxes) do
  self:_on(box.Focused,function() local original=box.Text;self._editCancel=function() box.Text=original end end,scope)
  self:_on(box.FocusLost,function()
   self._editCancel=nil;local n=tonumber(box.Text)
   if n then
    if mode=="RGB" then local rgb=Color3.fromHSV(h,s,v);local values={rgb.R*255,rgb.G*255,rgb.B*255};if i==4 then a=math.clamp(n/255,0,1) else values[i]=math.clamp(n,0,255);local result=Color3.fromRGB(values[1],values[2],values[3]);local nh,ns,nv=result:ToHSV();if ns>0 then h=nh end;s=ns;v=nv end
    else if i==1 then h=(n%360)/360 elseif i==2 then s=math.clamp(n/100,0,1) elseif i==3 then v=math.clamp(n/100,0,1) else a=math.clamp(n/100,0,1) end end
    commit()
   end;refresh(group.Values[key])
  end,scope)
 end
 self:_iconButton(frame,"copy",width-78,309,28,30,function() self._colorClipboard=hex.Text;hex:CaptureFocus();hex.CursorPosition=#hex.Text+1;hex.SelectionStart=1;self:Notify("Color selected · Ctrl+C") end,scope)
 self:_iconButton(frame,"paste",width-44,309,28,30,function() if self._colorClipboard then parse(self._colorClipboard) else hex:CaptureFocus() end end,scope)
 if rainbow then
  text(frame,"Rainbow",14,350,width-75,28,14,T.Label)
  local check=field(frame,width-37,354,20,20);local setCheck=self:_checkbox(check,scope)
  local function update(value) setCheck(value.Rainbow==true) end;self:_listen(group,key,update,scope);update(group.Values[key])
  self:_on(check.Activated,function() local value=group:Get(key);value.Rainbow=not value.Rainbow;group:Set(key,value) end,scope)
 end
 refresh(group.Values[key])
end
function Window:_slotsPopup(owner,group,key,roles)
 local popup=self:_popup(owner,owner,324,140+math.ceil(#roles/2)*34);if not popup then return end
 local frame,scope=popup.Frame,popup.Scope;local selected=1;local cells,roleButtons={},{}
 text(frame,self:_tr("Slots"),14,7,popup.Width-28,28,17,T.Title,true)
 local status=text(frame,"",14,94,popup.Width-28,28,14,T.FieldText)
 local cell=math.floor((popup.Width-28-8*4)/9)
 local function refresh()
  local values=group.Values[key];status.Text=(selected==10 and "Offhand" or "Slot "..selected).."  ·  "..values[selected]
  for i,b in ipairs(cells) do
   b.Text=i==10 and "Offhand" or tostring(i)
   self:_animate(b,{BackgroundColor3=color(i==selected and self:_accentHex() or values[i]~="None" and 0x5B3B58 or T.Field)})
   b.TextColor3=color(i==selected and 0xFFFFFF or T.FieldText)
  end
  for i,b in ipairs(roleButtons) do b.TextColor3=color(roles[i]==values[selected] and self:_accentHex() or T.FieldText) end
 end
 for i=1,10 do
  local index=i;local b=self:_button(frame,tostring(i),i==10 and 14 or 14+(i-1)*(cell+4),i==10 and 82 or 44,i==10 and 95 or cell,30,function() selected=index;refresh() end,scope);cells[i]=b
  if i==10 then b.Position=UDim2.fromOffset(popup.Width-109,84);b.Size=UDim2.fromOffset(95,28) end
  self:_on(b.MouseButton2Click,function() local value=group:Get(key);value[index]="None";group:Set(key,value) end,scope)
 end
 for i,role in ipairs(roles) do
  local bw=(popup.Width-36)/2
  local b=self:_button(frame,role,14+((i-1)%2)*(bw+8),132+math.floor((i-1)/2)*34,bw,28,function() local values=group:Get(key);values[selected]=role;group:Set(key,values) end,scope)
  b.TextXAlignment=Enum.TextXAlignment.Center;roleButtons[i]=b
 end
 self:_listen(group,key,refresh,scope);refresh()
end
function Window:_textDialog(title,value,submit)
 local popup=self:_popup(title,nil,520,400,true);if not popup then return end
 text(popup.Frame,title,12,7,popup.Width-24,24,17,T.Title,true)
 local box=create("TextBox",popup.Frame,{Position=UDim2.fromOffset(12,42),Size=UDim2.new(1,-24,1,-88),BackgroundColor3=color(T.Field),Text=value or "",ClearTextOnFocus=false,MultiLine=true,TextWrapped=true,TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Top,Font=Enum.Font.Code,TextSize=14,TextColor3=color(T.Label)});corner(box,3)
 self:_button(popup.Frame,submit and self:_tr("Import") or "Select all",12,popup.Height-36,120,28,function()
  if submit then local index=table.find(self._popups,popup);local ok,err=submit(box.Text);if ok then if index and self._popups[index]==popup then self:_closePopups(index) end;self:Notify("Applied") else self:Notify(tostring(err)) end
  else box:CaptureFocus();box.CursorPosition=#box.Text+1;box.SelectionStart=1 end
 end,popup.Scope)
 self:_button(popup.Frame,"Close",popup.Width-92,popup.Height-36,80,28,function() self:_closePopups(table.find(self._popups,popup) or #self._popups) end,popup.Scope)
end

local CATEGORY_NAMES={"Combat","Window","Process","Registry","File","Control","Render","Web","Misc","Driver"}
local CATEGORY_GLYPHS={Combat="combat",Window="player",Process="misc",Registry="gear",File="folder",Control="movement",Render="render",Web="world",Misc="misc",Driver="gear"}
local PAGES={"Modules","Config","GUI","HUD","Sound","Search","Profiles","Apps","About"}
local NAMED={Black=0x010101,White=0xFFFFFF,Gray=0x777777,Red=0xF33436,Gold=0xFFD700,Aqua=0x00DDDF,Blue=0x3478E8,Green=0x49DA5B,Orange=0xFFA84A,Purple=0x9D58F6,Pink=0xDA6DA6}
function UI.GetLayouts() return clone(LAYOUT_NAMES) end
function UI.GetPresets() return clone(PRESET_NAMES) end
function UI.GetLauncherStyles() return clone(LAUNCHER_NAMES) end
function UI.GetSourcePreset(name) return clone(assert(PRESETS[name],"Unknown preset")) end
function Window:GetLayouts() return UI.GetLayouts() end
function Window:GetPresets() return UI.GetPresets() end
function Window:GetLayout() return self.Layout end
function Window:GetPreset() return self.Preset end
function Window:Describe(message) if self.Hint then self.Hint.Text=tostring(message) end end
function Window:Notify(message,options)
 if self._dead then return nil end
 options=options or {}
 if self.DynamicIsland and self.DynamicIsland.Options.Enabled and self.DynamicIsland.Options.SyncNotifications and options.Island~=false then
  return self.DynamicIsland:Notify({Title=options.Title or "Jackal",Text=tostring(message),Level=options.Level or "info",Duration=options.Duration or 3})
 end
 self._toastAt=os.clock();self.Toast.Text=tostring(message);self.Toast.TextTransparency=0;self.Toast.BackgroundTransparency=.18;self.Toast.Visible=true
end
local function rgba(value,fallback)
 if type(value)=="string" then
  local r,g,b,a=value:match("^(%d+);(%d+);(%d+);?(%d*)$")
  if r then return Color3.fromRGB(tonumber(r),tonumber(g),tonumber(b)),a~="" and tonumber(a)/255 or 1 end
  if NAMED[value] then return color(NAMED[value]),1 end
  for name,hex in pairs(NAMED) do if name:lower()==value:lower() then return color(hex),1 end end
 end
 return color(fallback or 0xC8C8C8),1
end
function Window:_named(value,index)
 if value=="Rainbow" or value=="Flow" then return Color3.fromHSV((os.clock()*.025+.24+(index or 0)*.041)%1,.94,.82) end
 return rgba(value,0x34A5F8)
end
function Window:_moduleName(group)
 local name=self:_tr(group.Name)
 if self.Theme["Remove Spaces in Module Names"] then name=name:gsub("%s","") end
 local case=self.Theme["Module Name Case Style"]
 if case=="Lower Case" then name=name:lower() elseif case=="Upper Case" then name=name:upper() end
 return name
end
function Window:_newGroup(def)
 local id=def.id or def.Id or def.Name or def.name
 assert(type(id)=="string" and not self._byId[id],"Unique module id required")
 def.settings=def.settings or def.Settings or {}
 local group=setmetatable({Window=self,Id=id,Name=def.name or def.Name or id,Category=def.category or def.Category or "Misc",Enabled=def.enabled==true or def.Enabled==true,Key=def.key or def.Key or "None",Hidden=false,Values={},Definition=def,Defaults={},_definitions={},_listeners={}},Group)
 group.Scope=Scope.new(self._scope);local key=normalized({type="key"},group.Key);assert(key,"Invalid module key");group.Key=key
 self:_registerSettings(group,def.settings);group.Defaults=clone(group.Values);self._byId[id]=group
 return group
end
function Window:AddCategory(name)
 assert(type(name)=="string" and name~="","Category name required")
 if not table.find(self._categories,name) then table.insert(self._categories,name) end
 return self
end
function Window:AddModule(def)
 local group=self:_newGroup(def);self:AddCategory(group.Category);table.insert(self._modules,group)
 if self._built then self:_invalidate() end;return group
end
function Window:_settingsRows(group,parent,scope)
 local rows={}
 for _,def in ipairs(group.Definition.settings or {}) do rows[#rows+1]=self:_makeRow(group,def,nameOf(def),parent,scope) end
 return rows
end
function Window:_placeRows(group,rows,width,y)
 y=y or 4
 for _,row in ipairs(rows) do
  local shown=matches(row.Definition.when or row.Definition.VisibleIf,group.Values)
  if row.Fraction==nil then
   row.Fraction=shown and 1 or 0;row.TargetFraction=row.Fraction
   self:_motion(row.Label,function(dt)
    if row.Fraction~=row.TargetFraction then
     row.Fraction+=(row.TargetFraction-row.Fraction)*(1-math.exp(-dt*20))
     if math.abs(row.Fraction-row.TargetFraction)<.001 then row.Fraction=row.TargetFraction end
     self._layoutDirty=true
    end
   end,row.Scope)
  end
  row.TargetFraction=shown and 1 or 0
  if self.ReducedMotion then row.Fraction=row.TargetFraction end
  row:Place(width,y,shown or row.Fraction>.001)
  local occupied=row.Height*row.Fraction
  row.Root.ClipsDescendants=true;row.Root.Size=UDim2.fromOffset(width,occupied)
  y+=occupied
 end
 return y+4
end
function Window:_moduleTools(group,parent,scope)
 if self.Options.SyntaxKeybind then return {} end
 local rows={}
 local binding=self:_rowBase(parent,scope,self:_tr("Bind"));binding.Definition={};binding.Height=34
 local bind=self:_button(binding.Root,group.Key,0,4,126,26,function() end,scope);bind.Name="ModuleBind"
 self:_on(bind.Activated,function() self:_beginBinding(group,"key",bind,scope) end,scope)
 self:_on(bind.MouseButton2Click,function() group:SetKey("None") end,scope)
 self:_listen(group,"key",function(v) bind.Text=v end,scope)
 binding.Resize=function(width) bind.Position=UDim2.fromOffset(width-138,4);binding.Label.Size=UDim2.fromOffset(width-160,34) end
 rows[#rows+1]=binding
 local hidden=self:_rowBase(parent,scope,self:_tr("Hidden"));hidden.Definition={};hidden.Height=34
 local switch=self:_button(hidden.Root,"",0,7,34,20,function() group:SetHidden(not group.Hidden) end,scope);switch.Name="ModuleHidden";corner(switch,10)
 local knob=create("Frame",switch,{BackgroundColor3=color(T.Title),Size=UDim2.fromOffset(16,16),Position=UDim2.fromOffset(2,2)});corner(knob,8)
 local function refresh(v) self:_animate(switch,{BackgroundColor3=color(v and self:_accentHex() or 0x49414F)});self:_animate(knob,{Position=UDim2.fromOffset(v and 16 or 2,2)},.22) end
 self:_listen(group,"hidden",refresh,scope);refresh(group.Hidden)
 hidden.Resize=function(width) switch.Position=UDim2.fromOffset(width-46,7);hidden.Label.Size=UDim2.fromOffset(width-72,34) end
 if not self.Options.Embedded then rows[#rows+1]=hidden else hidden.Root:Destroy() end
 return rows
end
function Window:_resetModule(group,owner)
 local confirm=not self.Models.Config or self.Models.Config.Values["Confirm reset"]~=false
 if not confirm then group:Reset();self:Notify("Options reset");return end
 local popup=self:_popup("Reset:"..group.Id,owner,300,142,true);if not popup then return end
 text(popup.Frame,self:_tr("Reset").." · "..self:_moduleName(group),14,8,popup.Width-28,28,17,T.Title,true)
 text(popup.Frame,self:_tr("Restore default values?"),14,42,popup.Width-28,30,14,T.FieldText)
 self:_button(popup.Frame,self:_tr("Cancel"),14,98,120,28,function() self:_closePopups(table.find(self._popups,popup)) end,popup.Scope)
 self:_button(popup.Frame,self:_tr("Reset"),popup.Width-134,98,120,28,function() group:Reset();self:_closePopups(table.find(self._popups,popup));self:Notify("Options reset") end,popup.Scope)
end
function Window:_entry(parent,group,scope,card)
 local radius=self.Layout=="Neverlose" and 8 or self.Layout=="Imgui" and 0 or self.Theme["Round Corners"] and 4 or 0
 local height=self.Layout=="Neverlose" and 44 or self.Layout=="Imgui" and 32 or math.max(25,self.Theme["Module Height"])
 local frame=create("Frame",parent,{Name=group.Id,BackgroundTransparency=1,Size=UDim2.fromOffset(240,height)})
 local button=create("TextButton",frame,{Name="ModuleHeader",Text="",AutoButtonColor=false,BackgroundColor3=color(0x010101),Size=UDim2.fromOffset(240,height)});corner(button,radius)
 local fontSize=self.Layout=="Neverlose" and 17 or self.Layout=="Imgui" and 15 or self.Theme["Module Font Size"]
 local label=text(button,self:_moduleName(group),10,0,180,height,fontSize,0xC8C8C8)
 label.Font=self.Theme.Font=="Minecraft AE Pixel.ttf" and Enum.Font.Arcade or Enum.Font.BuilderSans
 local entry={Group=group,Frame=frame,Header=button,Label=label,Height=height,Width=240,Rows={},Expanded=self._expanded[group.Id]==true,Index=#self._entries+1}
 local body=create("ScrollingFrame",frame,{Name="Options",BackgroundColor3=color(self.Layout=="Neverlose" and 0x201923 or 0x090B0E),BackgroundTransparency=self.Theme["Module Option Background Color"]=="Transparent" and .65 or .08,Position=UDim2.fromOffset(0,height),Size=UDim2.fromOffset(240,0),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=2,ScrollBarImageColor3=color(self:_accentHex()),ScrollingDirection=Enum.ScrollingDirection.Y,Visible=false,ClipsDescendants=true,Active=true});corner(body,radius)
 entry.Body=body;entry.Rows=self:_settingsRows(group,body,scope)
 local meta=self:_moduleTools(group,body,scope);for _,row in ipairs(meta) do entry.Rows[#entry.Rows+1]=row end
 local mark=create("Frame",button,{Name="EnabledBar",BackgroundColor3=color(self:_accentHex()),Size=UDim2.fromOffset(3,height),Visible=false});entry.Mark=mark
 local key=text(button,"",0,0,70,height,11,0x858585,false,Enum.TextXAlignment.Right);entry.KeyLabel=key
 if self.Options.SyntaxKeybind then entry.SyntaxBind=self.Options.SyntaxKeybind(group.Id,button,scope,height) end
 if group.Definition.integrationExample then entry.ExampleBadge=text(button,self:_tr("Demo"),0,0,48,height,14,0xD8B88E,false,Enum.TextXAlignment.Center);entry.ExampleBadge.Name="IntegrationExample" end
 local expand=create("TextButton",button,{Name="OptionsButton",Text="",AutoButtonColor=false,BackgroundTransparency=1,Size=UDim2.fromOffset(28,height)})
 local mode=self.Layout=="Neverlose" and "Arrow" or self.Theme["Module Option Open Button"]
 -- Opai's source preset hides this control; expose it for mouse and touch users.
 if self.Layout=="Dropdown" and self.Preset=="Opai" then mode="Arrow" end
 local expandIcon=icon(expand,"down",10,0x888888);expandIcon.Root.Position=UDim2.new(.5,-5,.5,-5);entry.ExpandIcon=expandIcon
 if mode=="Dots" then
  expandIcon.Root.Visible=false
  for i=-1,1 do local dot=create("Frame",expand,{Name="OptionDot",BackgroundColor3=color(0x888888),Position=UDim2.new(.5,-1.25,.5,i*5-1.25),Size=UDim2.fromOffset(2.5,2.5)});corner(dot,1.25) end
 elseif mode=="Future" then expandIcon.Root.Visible=false;expand.Text="+";expand.TextSize=16;expand.TextColor3=color(0xC0C0C0) end
 expand.Visible=mode~="Off" and (not self.Options.SyntaxKeybind or #entry.Rows>0);entry.ExpandButton=expand
 if self.Layout=="Neverlose" then
  entry.Switch=create("Frame",button,{Name="Toggle",BackgroundColor3=color(0x49414F),Size=UDim2.fromOffset(30,18)});corner(entry.Switch,9)
  entry.Switch.Size=UDim2.fromOffset(38,22);corner(entry.Switch,11)
  entry.Knob=create("Frame",entry.Switch,{BackgroundColor3=color(0xFBEAF5),Position=UDim2.fromOffset(3,3),Size=UDim2.fromOffset(16,16)});corner(entry.Knob,8)
  entry.Tick=icon(entry.Knob,"check",11,self:_accentHex());entry.Tick.Root.Position=UDim2.fromOffset(2.5,2.5)
  entry.Reset=self:_iconButton(button,"reset",0,0,28,height,function() self:_resetModule(group,entry.Reset) end,scope)
  create("UIGradient",button,{Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color(0xF4C5E1)),ColorSequenceKeypoint.new(1,color(0xAC87B5))}),Rotation=25})
  entry.Mark.Size=UDim2.fromOffset(3,height-16);entry.Mark.Position=UDim2.fromOffset(0,8)
 elseif self.Layout=="Imgui" then
  label.Font=Enum.Font.Code;label.Position=UDim2.fromOffset(29,0)
  local box=create("Frame",button,{Name="ImGuiCheckbox",BackgroundColor3=color(0x343434),Position=UDim2.fromOffset(6,6),Size=UDim2.fromOffset(16,16)})
  entry.ImCheck=create("Frame",box,{BackgroundColor3=color(0x4296FA),Position=UDim2.fromOffset(3,3),Size=UDim2.fromOffset(10,10)})
 end
 function entry:Place(width,y)
  self.Width=width;self.Frame.Position=UDim2.fromOffset(0,y);self.Header.Size=UDim2.fromOffset(width,self.Height)
  self.Label.Size=UDim2.fromOffset(math.max(1,width-(self.Switch and 130 or 35)-(self.ExampleBadge and 50 or 0)),self.Height)
  self.ExpandButton.Position=UDim2.fromOffset(width-(self.Switch and 83 or 28),0)
  if self.Group.Window.Layout=="Dropdown" and self.Group.Window.Preset=="Opai" then
   self.ExpandButton.Size=UDim2.fromOffset(44,self.Height);self.ExpandButton.Position=UDim2.fromOffset(width-44,0)
   self.Label.Size=UDim2.fromOffset(math.max(1,width-64-(self.ExampleBadge and 50 or 0)),self.Height)
  end
  self.KeyLabel.Position=UDim2.fromOffset(math.max(30,width-106),0)
  if self.ExampleBadge then self.ExampleBadge.Position=UDim2.fromOffset(width-(self.Switch and 166 or 82),0);self.KeyLabel.Visible=false end
  if self.SyntaxBind then
   self.SyntaxBind.Position=UDim2.fromOffset(width-(self.Switch and 188 or 124),0)
   self.Label.Size=UDim2.fromOffset(math.max(1,width-(self.Switch and 208 or 144)),self.Height)
   self.KeyLabel.Visible=false
  end
  if self.Switch then self.Switch.Position=UDim2.fromOffset(width-48,(self.Height-22)/2);self.Reset.Position=UDim2.fromOffset(width-112,0);self.KeyLabel.Visible=false end
 end
 local function refresh()
  local enabled=group.Enabled
  local bg,alpha
  if self.Layout=="Neverlose" then bg=color(enabled and 0x65354F or 0x28202D);alpha=.94
  elseif self.Layout=="Imgui" then bg=color(0x232323);alpha=1
  elseif enabled then bg=self:_named(self.Theme["Module Background Color (Enabled)"],entry.Index);alpha=self.Theme["Module Background Opacity (0~1)"]
  else bg=self:_named(self.Theme["Module Background Color"],entry.Index);alpha=self.Theme["Module Background Color"]=="Transparent" and 0 or self.Theme["Module Background Opacity (0~1)"];bg=bg:Lerp(Color3.new(0,0,0),self.Theme["Module Background Blackness (0~1)"] or 0) end
  if entry.Hover then bg=bg:Lerp(color(0x51463F),.5) end
  local code=bg:ToHex()
  if entry.TargetBackground~=code then entry.TargetBackground=code;self:_animate(button,{BackgroundColor3=bg},self.Layout=="Neverlose" and .3 or .18) end
  if entry.TargetAlpha~=alpha then entry.TargetAlpha=alpha;button.BackgroundTransparency=1-(alpha or 1) end
  label.TextColor3=self.Layout=="Neverlose" and color(0xEAD9E6) or rgba(enabled and self.Theme["Module Text Color (Enabled)"] or self.Theme["Module Text Color"],0xC8C8C8)
  label.TextXAlignment=Enum.TextXAlignment[self.Theme["Module Name Alignment"] or "Left"]
  mark.Visible=enabled and (self.Layout=="Neverlose" or self.Theme["Module Left Bar"]==true)
  key.Text=self.Theme["Module Keybind Display"] and group.Key~="None" and group.Key or ""
  if entry.Switch and entry.LastEnabled~=enabled then
   self:_animate(entry.Switch,{BackgroundColor3=color(enabled and self:_accentHex() or 0x49414F)},.22)
   self:_animate(entry.Knob,{Position=UDim2.fromOffset(enabled and 19 or 3,3)},.22);entry.Tick.Root.Visible=enabled
  end
  entry.LastEnabled=enabled
  if entry.ImCheck then entry.ImCheck.Visible=enabled end
 end
 entry.Refresh=refresh;refresh()
 self:_motion(frame,function(dt)
  if entry.TargetHeight and math.abs(entry.TargetHeight-(entry.DisplayHeight or 0))>.001 then
   entry.HeightTime=(entry.HeightTime or 0)+dt
   local t=self.ReducedMotion and 1 or math.clamp(entry.HeightTime/.3,0,1)
   entry.DisplayHeight=(entry.StartHeight or 0)+(entry.TargetHeight-(entry.StartHeight or 0))*(1-(1-t)^3)
   if t==1 then entry.DisplayHeight=entry.TargetHeight end
   self._layoutDirty=true
  end
 end,scope)
 self:_listen(group,"enabled",refresh,scope);self:_listen(group,"key",refresh,scope)
 local function open()
  if self.Options.SyntaxKeybind and #entry.Rows==0 then return end
  if self.Theme["Module Option Style"]=="Old" and self.Layout=="Dropdown" then self:OpenModule(group.Id)
  else entry.Expanded=not entry.Expanded;self._expanded[group.Id]=entry.Expanded;self:_animate(entry.ExpandIcon.Root,{Rotation=entry.Expanded and 180 or 0},.22);self:_layout() end
 end
 self:_on(button.Activated,function() group:SetEnabled(not group.Enabled) end,scope)
 self:_on(button.MouseButton2Click,open,scope);self:_on(expand.Activated,open,scope)
 self:_on(button.MouseEnter,function() entry.Hover=true;self:Describe(self:_tr(group.Definition.description or group.Name));refresh() end,scope)
 self:_on(button.MouseLeave,function() entry.Hover=false;refresh() end,scope)
 self._entries[#self._entries+1]=entry
 return entry
end
function Window:_entryHeight(entry,width)
 local fullHeight=self:_placeRows(entry.Group,entry.Rows,width)
 local maximum=entry.Group.Definition.maxRows or (self.Layout=="Neverlose" and 15 or 10)
 local target=entry.Expanded and math.min(fullHeight,maximum*32+8) or 0
 if entry.DisplayHeight==nil then entry.DisplayHeight=target;entry.TargetHeight=target end
 if target~=entry.TargetHeight then
  entry.StartHeight=entry.DisplayHeight;entry.TargetHeight=target;entry.HeightTime=0
 end
 if self.ReducedMotion then entry.DisplayHeight=target end
 local height=entry.DisplayHeight
 entry.Body.Visible=entry.Expanded or height>.1;entry.Body.Size=UDim2.fromOffset(width,height);entry.Body.CanvasSize=UDim2.fromOffset(0,fullHeight)
 entry.Frame.Size=UDim2.fromOffset(width,entry.Height+height)
 return entry.Height+height
end
function Window:OpenModule(id)
 local group=assert(self._byId[id],"Unknown module")
 local popup=self:_popup("Module:"..id,nil,460,math.min(520,100+#(group.Definition.settings or {})*32),true);if not popup then return end
 text(popup.Frame,self:_moduleName(group),16,8,popup.Width-65,30,20,0xE5E5E5)
 self:_button(popup.Frame,"×",popup.Width-40,10,26,24,function() self:_closePopups() end,popup.Scope)
 local scroll=create("ScrollingFrame",popup.Frame,{Name="ModuleOptions",BackgroundTransparency=1,Position=UDim2.fromOffset(0,48),Size=UDim2.new(1,0,1,-96),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollBarImageColor3=color(self:_accentHex()),Active=true})
 local rows=self:_settingsRows(group,scroll,popup.Scope);for _,row in ipairs(self:_moduleTools(group,scroll,popup.Scope)) do rows[#rows+1]=row end
 local function layout() local h=self:_placeRows(group,rows,popup.Width);scroll.CanvasSize=UDim2.fromOffset(0,h) end
 popup.Reflow=layout;for key in pairs(group._definitions) do self:_listen(group,key,layout,popup.Scope) end;layout()
 self:_button(popup.Frame,self:_tr("Reset"),16,popup.Height-38,85,24,function() self:_resetModule(group,nil) end,popup.Scope)
 local bind=self:_button(popup.Frame,group.Key,popup.Width-150,popup.Height-38,134,24,function() end,popup.Scope)
 self:_on(bind.Activated,function() self:_beginBinding(group,"key",bind,popup.Scope) end,popup.Scope)
 self:_listen(group,"key",function(v) bind.Text=v end,popup.Scope)
end
function Window:_buildDropdown()
 local scroll=create("ScrollingFrame",self.View,{Name="CategoryCanvas",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),CanvasSize=UDim2.fromOffset(0,0),ScrollingDirection=Enum.ScrollingDirection.XY,ScrollBarThickness=4,ScrollBarImageColor3=color(0x666666),Active=true})
 self.Canvas=scroll;self._panels={}
 for index,category in ipairs(self._categories) do
  local width=self.Theme["Tab Width (Fixed)"] and self.Theme["Tab Width (Fixed)"] or 238
  if self.Theme["Tab Width Mode"]=="Auto" then
   width=150;for _,g in ipairs(self._modules) do if g.Category==category then width=math.max(width,measured(self:_moduleName(g),self.Theme["Module Font Size"],false)+(self.Theme["Tab Width Addition (Auto)"] or 0)+35) end end
   width=math.clamp(width,140,490)
  end
  local panel={Name=category,HeaderHeight=self.Theme["Module Height"],Width=width,Entries={},Collapsed=self._collapsed[category]==true,Index=index}
  panel.Root=create("Frame",scroll,{Name="Category_"..category,BackgroundTransparency=1,Size=UDim2.fromOffset(width,100)})
  if self.Theme["Tab Shadows"] then softShadow(panel.Root,4,math.clamp(math.round((self.Theme["Tab Shadows Thickness"] or 30)*.4),3,16),self.Theme["Tab Shadows Opacity (0~1)"] or .7) end
  panel.Surface=create("Frame",panel.Root,{Active=true,BackgroundColor3=color(0x090909),BackgroundTransparency=.12,Size=UDim2.fromScale(1,1),ZIndex=1});corner(panel.Surface,self.Theme["Round Corners"] and 4 or 0)
  local header=create("TextButton",panel.Surface,{Name="CategoryHeader",Text="",BackgroundColor3=rgba(self.Theme["Tab Theme Color"],0x0A0A0A),AutoButtonColor=false,Size=UDim2.fromOffset(width,panel.HeaderHeight)});panel.Header=header
  local title=self:_tr(category);if self.Theme["Tab Name Case Style"]=="Lower Case" then title=title:lower() elseif self.Theme["Tab Name Case Style"]=="Upper Case" then title=title:upper() end
  local label=text(header,title,self.Theme["Tab Icons"] and 34 or 12,0,width-52,panel.HeaderHeight,self.Theme["Module Font Size"],0xD8D8D8);label.TextXAlignment=Enum.TextXAlignment[self.Theme["Tab Name Alignment"] or "Left"]
  if self.Theme["Tab Icons"] then local img=icon(header,CATEGORY_GLYPHS[category] or "misc",20,0xC8C8C8);img.Root.Position=UDim2.fromOffset(9,(panel.HeaderHeight-20)/2);local clr=rgba(self.Theme["Tab Icon Color"],0xFFFFFF);img:SetColor(tonumber(clr:ToHex(),16)) end
  if self.Theme.Outline then stroke(panel.Surface,tonumber(rgba(self.Theme["Tab Theme Color"],0x333333):ToHex(),16),1.3) end
  local collapse,collapseIcon=self:_iconButton(header,"up",width-28,0,28,panel.HeaderHeight,function() panel.Collapsed=not panel.Collapsed;self._collapsed[category]=panel.Collapsed;if panel.CollapseIcon then self:_animate(panel.CollapseIcon.Root,{Rotation=panel.Collapsed and 180 or 0},.22) end;self:_layout() end,self._viewScope);collapse.Visible=self.Theme["Tab Expand Arrow"]==true;panel.CollapseIcon=collapseIcon;collapseIcon.Root.Rotation=panel.Collapsed and 180 or 0
  self:_on(header.MouseButton2Click,function() panel.Collapsed=not panel.Collapsed;self._collapsed[category]=panel.Collapsed;if panel.CollapseIcon then self:_animate(panel.CollapseIcon.Root,{Rotation=panel.Collapsed and 180 or 0},.22) end;self:_layout() end,self._viewScope)
  self:_on(header.InputBegan,function(input)
   if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then self._gesture={input=input,start=self:_inputPoint(input),origin=Vector2.new(panel.Root.Position.X.Offset,panel.Root.Position.Y.Offset),panel=panel} end
  end,self._viewScope)
  panel.Body=create("ScrollingFrame",panel.Surface,{Name="ModuleList",BackgroundTransparency=1,Position=UDim2.fromOffset(0,panel.HeaderHeight),Size=UDim2.fromOffset(width,100),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=2,ScrollingDirection=Enum.ScrollingDirection.Y,Active=true})
  for _,g in ipairs(self._modules) do if g.Category==category and not g.Definition.omitFromMenu then panel.Entries[#panel.Entries+1]=self:_entry(panel.Body,g,self._viewScope) end end
  self:_motion(panel.Root,function(dt)
   if panel.TargetHeight and math.abs(panel.TargetHeight-panel.DisplayHeight)>.001 then
    panel.HeightTime+=dt;local t=self.ReducedMotion and 1 or math.clamp(panel.HeightTime/.3,0,1)
    panel.DisplayHeight=panel.StartHeight+(panel.TargetHeight-panel.StartHeight)*(1-(1-t)^3);if t==1 then panel.DisplayHeight=panel.TargetHeight end;self._layoutDirty=true
   end
  end,self._viewScope)
  self._panels[#self._panels+1]=panel
 end
end
function Window:_buildNeverlose()
 local scope=self._viewScope
 self.NLShadow=create("Frame",self.View,{Name="NeverloseShadow",BackgroundTransparency=1,Size=UDim2.fromOffset(1080,640),ZIndex=0});softShadow(self.NLShadow,15,16,.8)
 self.NL=create("Frame",self.View,{Name="Neverlose",Active=true,BackgroundColor3=Color3.new(1,1,1),Size=UDim2.fromOffset(1080,640),ClipsDescendants=false});corner(self.NL,15);stroke(self.NL,0x76556D,1)
 local backdrop=create("ImageLabel",self.NL,{Name="Wallpaper",Image=self.Options.BackgroundImage or "",ScaleType=Enum.ScaleType.Crop,BackgroundTransparency=1,ImageTransparency=self.Options.BackgroundImage and .55 or 1,Size=UDim2.fromScale(1,1),ZIndex=0});corner(backdrop,15)
 create("UIGradient",self.NL,{Rotation=32,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color(0x4C1837)),ColorSequenceKeypoint.new(.55,color(0x221B2D)),ColorSequenceKeypoint.new(1,color(0x352138))})})
 self.NLSide=create("Frame",self.NL,{Name="Sidebar",BackgroundColor3=color(0x311C30),BackgroundTransparency=.08,Size=UDim2.fromOffset(188,640),ClipsDescendants=true});corner(self.NLSide,14)
 create("UIGradient",self.NLSide,{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color(0xD8AAC4)),ColorSequenceKeypoint.new(.5,color(0x875D89)),ColorSequenceKeypoint.new(1,color(0xBC81A4))})})
 self.NLBrand=text(self.NLSide,"NEVERLOSE",18,12,164,46,23,0xFCF7FF,true)
 create("Frame",self.NLSide,{Name="BrandRule",Position=UDim2.fromOffset(18,62),Size=UDim2.new(1,-36,0,1),BackgroundColor3=color(0x1C2531)})
 self.NLFeatures=text(self.NLSide,"—  FEATURES  —",16,72,156,26,14,0xAF9BAE,false,Enum.TextXAlignment.Center)
 self.SideScroll=create("ScrollingFrame",self.NLSide,{Name="Categories",BackgroundTransparency=1,Position=UDim2.fromOffset(12,112),Size=UDim2.new(1,-24,1,-202),CanvasSize=UDim2.fromOffset(0,#self._categories*42),ScrollBarThickness=2,ScrollBarImageColor3=color(0x89617B),Active=true})
 self.NLCategories={}
 local tones={0xE35698,0x5CEB7D,0x82CC82,0xA16AEF,0x57C6D8,0xBE69F0,0x9EF18B,0xB170E9,0x6C9FEB,0xF5BA78}
 for i,category in ipairs(self._categories) do
  local b=self:_button(self.SideScroll,"",0,(i-1)*42,164,38,function() self:SelectCategory(category) end,scope);b.Name="Category_"..category
  local active=category==self.Category;b.BackgroundColor3=color(active and 0x62405F or 0x302030);b.BackgroundTransparency=active and .15 or 1;b.TextXAlignment=Enum.TextXAlignment.Left;b.TextSize=16
  local img=icon(b,CATEGORY_GLYPHS[category] or "misc",20,tones[i] or 0xC58FC0);img.Root.Position=UDim2.fromOffset(10,9)
  local marker=create("Frame",b,{Name="SelectionBar",BackgroundColor3=color(0xE76AAE),Position=UDim2.fromOffset(0,9),Size=UDim2.fromOffset(3,20),Visible=false});corner(marker,2)
  self.NLCategories[#self.NLCategories+1]={Name=category,Button=b}
  self:_on(b.MouseLeave,function() self:_animate(b,{BackgroundColor3=color(category==self.Category and 0x62405F or 0x302030)}) end,scope)
 end
 self.NLSelection=create("Frame",self.SideScroll,{Name="SelectionIndicator",BackgroundColor3=color(0xE76AAE),Position=UDim2.fromOffset(0,((table.find(self._categories,self.Category) or 1)-1)*42+9),Size=UDim2.fromOffset(3,20),ZIndex=5});corner(self.NLSelection,2)
 self.NLAccount=create("Frame",self.NLSide,{Name="Account",BackgroundColor3=color(0x1B1221),BackgroundTransparency=.3,Position=UDim2.new(0,10,1,-78),Size=UDim2.new(1,-20,0,66)});corner(self.NLAccount,8)
 local user=create("ImageLabel",self.NLAccount,{Name="User",BackgroundColor3=color(0x554B60),Position=UDim2.fromOffset(10,14),Size=UDim2.fromOffset(36,36),Image=self.Player and 'rbxthumb://type=AvatarHeadShot&id='..self.Player.UserId..'&w=150&h=150' or ""});corner(user,18)
 self.NLUsername=text(self.NLAccount,self.Player and self.Player.DisplayName or "Roblox",56,10,100,24,14,0xF0E5EF,true)
 self.NLAccountDetail=text(self.NLAccount,self.Options.Embedded and "Syntax" or "Jackal · Roblox",56,34,100,20,14,0xB390AB)
 self.NLSearchWrap=field(self.NL,208,20,570,36);self.NLSearchWrap.Name="SearchBar";self.NLSearchWrap.BackgroundColor3=color(0x17101C);corner(self.NLSearchWrap,7);stroke(self.NLSearchWrap,0x855B7A,1)
 local searchIcon=icon(self.NLSearchWrap,"search",20,0xBA9AB2);searchIcon.Root.Position=UDim2.fromOffset(10,8)
 self.NLSearch=create("TextBox",self.NLSearchWrap,{Name="InlineSearch",BackgroundTransparency=1,Position=UDim2.fromOffset(38,0),Size=UDim2.new(1,-48,1,0),Text=self.NLQuery or "",PlaceholderText=self:_tr("Search modules and settings").."  (Ctrl+F)",PlaceholderColor3=color(0xB89AAC),TextColor3=color(T.Title),Font=Enum.Font.BuilderSans,TextSize=16,ClearTextOnFocus=false,TextXAlignment=Enum.TextXAlignment.Left})
 self:_on(self.NLSearch:GetPropertyChangedSignal("Text"),function() self.NLQuery=self.NLSearch.Text;self:_layoutModules() end,scope)
 self.NLActions=create("Frame",self.NL,{Name="Actions",BackgroundTransparency=1,Size=UDim2.fromOffset(114,36)})
 self:_iconButton(self.NLActions,"save",0,0,34,36,function() if self.Options.Embedded then self.Options.OnOpenConfigs() else self:SetPage("Profiles") end end,scope)
 self:_iconButton(self.NLActions,"gear",40,0,34,36,function() if self.Options.Embedded then self.Options.OnOpenAppearance() else self:SetPage("GUI") end end,scope)
 self:_iconButton(self.NLActions,"down",80,0,34,36,function()
  local any=false;for _,e in ipairs(self._entries) do if e.Expanded then any=true end end
  for _,e in ipairs(self._entries) do e.Expanded=not any;self._expanded[e.Group.Id]=e.Expanded;self:_animate(e.ExpandIcon.Root,{Rotation=e.Expanded and 180 or 0},.22) end;self:_layout()
 end,scope)
 self.NLTitle=text(self.NL,self:_tr(self.Category),208,65,600,29,17,0xEFE4EF,true)
 self.NLBody=create("Frame",self.NL,{Name="Cards",BackgroundTransparency=1,ClipsDescendants=true,Position=UDim2.fromOffset(208,100),Size=UDim2.fromOffset(850,510)})
 self:_buildNeverloseContents()
 self.NLStatus=text(self.NL,self.Options.Embedded and "SYNTAX" or "JACKAL  /  UI "..UI.Version,208,0,600,24,14,0xB399AD);self.NLStatus.Position=UDim2.new(0,208,1,-27)
 self:_bindNeverloseDrag()
end
function Window:_buildImgui()
 self.IG=create("Frame",self.View,{Name="ImguiWindow",Active=true,BackgroundColor3=color(0x171717),Size=UDim2.fromOffset(840,560)});stroke(self.IG,0x696969,1)
 local header=create("TextButton",self.IG,{Name="Titlebar",Text="  JackalClient 1.1.9 — Dear ImGui",Font=Enum.Font.Code,TextSize=13,TextColor3=color(0xFFFFFF),TextXAlignment=Enum.TextXAlignment.Left,BackgroundColor3=color(0x294F81),Size=UDim2.new(1,0,0,26),AutoButtonColor=false})
 self:_on(header.InputBegan,function(input) if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then self._gesture={input=input,start=self:_inputPoint(input),origin=self._imguiPosition or Vector2.new(0,0),imgui=true} end end,self._viewScope)
 self.IGTree=create("ScrollingFrame",self.IG,{Name="CategoryTree",BackgroundColor3=color(0x1E1E1E),Position=UDim2.fromOffset(7,33),Size=UDim2.new(0,160,1,-40),CanvasSize=UDim2.fromOffset(0,#self._categories*28),ScrollBarThickness=2,Active=true})
 for i,category in ipairs(self._categories) do
  local b=self:_button(self.IGTree,"▸ "..self:_tr(category),3,(i-1)*28,151,25,function() self.Category=category;self:_invalidate() end,self._viewScope)
  b.Font=Enum.Font.Code;b.TextSize=14;b.BackgroundColor3=color(category==self.Category and 0x31567B or 0x252525);b.TextXAlignment=Enum.TextXAlignment.Left
 end
 self.IGBody=create("ScrollingFrame",self.IG,{Name="ImGuiContent",BackgroundTransparency=1,Position=UDim2.fromOffset(177,33),Size=UDim2.new(1,-185,1,-40),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,Active=true})
 for _,g in ipairs(self._modules) do if g.Category==self.Category and not g.Definition.omitFromMenu then self:_entry(self.IGBody,g,self._viewScope) end end
end
function Window:_layoutModules()
 local w,h=self._width,self._height-self._top-32
 if self.Layout=="Dropdown" then
  local x,maxY=12,0
  for _,panel in ipairs(self._panels) do
   local offset=self._positions[panel.Name] or Vector2.new(x,10)
   panel.Root.Position=UDim2.fromOffset(offset.X,offset.Y)
   local y=0
   for _,entry in ipairs(panel.Entries) do
    entry.Frame.Visible=true;entry:Place(panel.Width,y)
    y+=self:_entryHeight(entry,panel.Width);entry.Refresh()
   end
   local targetH=panel.Collapsed and 0 or math.min(y,math.max(100,h-30))
   if panel.DisplayHeight==nil then panel.DisplayHeight=targetH;panel.TargetHeight=targetH end
   if panel.TargetHeight~=targetH then panel.StartHeight=panel.DisplayHeight;panel.TargetHeight=targetH;panel.HeightTime=0 end
   local visibleH=panel.DisplayHeight
   panel.Body.Visible=visibleH>.1;panel.Body.Size=UDim2.fromOffset(panel.Width,visibleH);panel.Body.CanvasSize=UDim2.fromOffset(0,y)
   panel.Root.Size=UDim2.fromOffset(panel.Width,panel.HeaderHeight+visibleH)
   x+=panel.Width+14;maxY=math.max(maxY,offset.Y+panel.HeaderHeight+visibleH)
  end
  local sorted=table.clone(self._panels)
  table.sort(sorted,function(a,b) if a.Root.Position.X.Offset==b.Root.Position.X.Offset then return a.Index<b.Index end;return a.Root.Position.X.Offset<b.Root.Position.X.Offset end)
  local edge=12
  for _,panel in ipairs(sorted) do
   local target=math.max(edge,panel.Root.Position.X.Offset);local top=panel.Root.Position.Y.Offset
   if target~=panel.Root.Position.X.Offset then panel.Root.Position=UDim2.fromOffset(target,top);self._positions[panel.Name]=Vector2.new(target,top) end
   edge=target+panel.Width+14
  end
  local right=x;for _,p in ipairs(self._panels) do right=math.max(right,p.Root.Position.X.Offset+p.Width+12) end
  self.Canvas.CanvasSize=UDim2.fromOffset(right,maxY+12)
 elseif self.Layout=="Neverlose" then
  local width=math.min(1080,w-24);local height=math.min(640,h-14);local sidebar=width<650 and 64 or 188;local compact=height<380
  self.NL.Size=UDim2.fromOffset(width,height);local position=self:_clampNeverlosePosition(self._nlPosition or Vector2.new(math.round((w-width)/2),7),width,height,w,h)
  if self._nlPosition then self._nlPosition=position end
  self.NL.Position=UDim2.fromOffset(position.X,position.Y);self.NLSide.Size=UDim2.fromOffset(sidebar,height);self.NLShadow.Position=self.NL.Position;self.NLShadow.Size=self.NL.Size
  self.NLDragStrip.Position=UDim2.fromOffset(sidebar,0);self.NLDragStrip.Size=UDim2.new(1,-sidebar,0,14)
  self.NLBrand.Text=sidebar<100 and "NL" or "NEVERLOSE";self.NLBrand.Size=UDim2.fromOffset(sidebar-28,46);self.NLBrand.TextSize=math.round((sidebar<100 and 20 or 23)*self:_activeScale())/self:_activeScale();self.NLFeatures.Visible=sidebar>=100 and not compact;self.NLUsername.Visible=sidebar>=100;self.NLAccountDetail.Visible=sidebar>=100
  self.NLAccount.Position=UDim2.new(0,sidebar<100 and 4 or 10,1,-78);self.NLAccount.Size=UDim2.new(1,sidebar<100 and -8 or -20,0,66)
  for _,category in ipairs(self.NLCategories) do category.Button.Size=UDim2.fromOffset(sidebar-24,38);category.Button.Text=sidebar<100 and "" or "         "..self:_tr(category.Name) end
  self.NLAccount.Visible=not compact
  self.SideScroll.Position=UDim2.fromOffset(12,compact and 54 or 112);self.SideScroll.Size=UDim2.new(1,-24,1,compact and -62 or -202)
  local start=sidebar+18;local bodyW=width-sidebar-36
  self.NLSearchWrap.Position=UDim2.fromOffset(start,compact and 8 or 18);self.NLSearchWrap.Size=UDim2.fromOffset(math.max(80,bodyW-(width<650 and 0 or 130)),36)
  self.NLActions.Visible=width>=650;self.NLActions.Position=UDim2.fromOffset(width-132,compact and 8 or 18)
  local count=0;local query=(self.NLQuery or ""):lower()
  for _,e in ipairs(self._entries) do
   local saved=self.Query;self.Query=query;e.Filtered=not self:_searchMatch(e.Group);self.Query=saved
   e.Frame.Visible=not e.Filtered;if not e.Filtered then count+=1 end
  end
  self.NLTitle.Text=self:_tr(self.Category).."  ("..count..")";self.NLTitle.Position=UDim2.fromOffset(start,compact and 48 or 62);self.NLTitle.Size=UDim2.fromOffset(bodyW,30)
  self.NLBody.Position=UDim2.fromOffset(start,compact and 84 or 99);self.NLBody.Size=UDim2.fromOffset(bodyW,math.max(40,height-(compact and 94 or 134)))
  self.NLStatus.Visible=not compact;self.NLStatus.Position=UDim2.new(0,start,1,-27);self.NLStatus.Size=UDim2.fromOffset(bodyW,24)
  local cols=bodyW>=600 and 2 or 1;local colW=math.floor((bodyW-(cols-1)*14)/cols);local ends={0,0};local visibleIndex=0
  for i,column in ipairs(self.NLColumns) do column.Visible=i<=cols;column.Position=UDim2.fromOffset((i-1)*(colW+14),0);column.Size=UDim2.fromOffset(colW,math.max(40,height-(compact and 94 or 134))) end
  for _,entry in ipairs(self._entries) do if not entry.Filtered then
   visibleIndex+=1;local col=(visibleIndex-1)%cols+1
   if entry.Frame.Parent~=self.NLColumns[col] then entry.Frame.Parent=self.NLColumns[col] end
   entry:Place(colW,ends[col]);ends[col]+=self:_entryHeight(entry,colW)+10;entry.Refresh()
  end end
  for i,column in ipairs(self.NLColumns) do column.CanvasSize=UDim2.fromOffset(0,ends[i]) end

 else
  local width=math.min(840,w-24);local height=math.min(560,h-14)
  local position=self._imguiPosition or Vector2.new((w-width)/2,7);position=Vector2.new(math.clamp(position.X,0,math.max(0,w-width)),math.clamp(position.Y,0,math.max(0,h-height)))
  self.IG.Position=UDim2.fromOffset(position.X,position.Y);self.IG.Size=UDim2.fromOffset(width,height)
  local treeW=width<550 and 90 or 160
  self.IGTree.Size=UDim2.fromOffset(treeW,height-40);self.IGBody.Position=UDim2.fromOffset(treeW+17,33);self.IGBody.Size=UDim2.fromOffset(width-treeW-25,height-40)
  local y=0;for _,entry in ipairs(self._entries) do entry:Place(width-treeW-25,y);y+=self:_entryHeight(entry,width-treeW-25)+4;entry.Refresh() end
  self.IGBody.CanvasSize=UDim2.fromOffset(0,y)
 end
end

-- The window, sidebar, search and account remain mounted across category changes.
function Window:_buildNeverloseContents()
 local scope=Scope.new(self._viewScope);self._nlContentScope=scope
 self.NLCards=create("Frame",self.NLBody,{Name="CategoryPage_"..self.Category,BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=2});scope.root=self.NLCards
 self.NLColumns={}
 for i=1,2 do self.NLColumns[i]=create("ScrollingFrame",self.NLCards,{Name="CardColumn"..i,BackgroundTransparency=1,Size=UDim2.fromOffset(400,510),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollBarImageColor3=color(0xEBA6D0),Active=true}) end
 local n=0
 for _,g in ipairs(self._modules) do if g.Category==self.Category and not g.Definition.omitFromMenu then n+=1;self:_entry(self.NLColumns[(n-1)%2+1],g,scope,true) end end
end
function Window:_switchNeverloseCategory(value)
 if value==self.Category then return self end
 local direction=(table.find(self._categories,value) or 1)>(table.find(self._categories,self.Category) or 1) and 1 or -1
 self._nlScrolls=self._nlScrolls or {};self._nlScrolls[self.Category]={self.NLColumns[1].CanvasPosition,self.NLColumns[2].CanvasPosition}
 if self._nlExitScope then self._nlExitScope:Clean();self._nlExitScope=nil end
 self:_closePopups(nil,true);self._drag=nil;self._gesture=nil
 if self.Options.CancelSyntaxBinding then self.Options.CancelSyntaxBinding() end
 if self.Visible and not self.ReducedMotion then
  local ghost=self.NLCards:Clone();ghost.Name="LeavingCategory";ghost.Parent=self.NLBody;ghost.ZIndex=1
  for _,o in ipairs(ghost:GetDescendants()) do if o:IsA("GuiButton") or o:IsA("TextBox") then o.Active=false;o.Interactable=false end end
  local exit=Scope.new(self._viewScope);exit.root=ghost;self._nlExitScope=exit
  self:_transition(ghost,1,0,.16,exit,function() exit:Clean();if self._nlExitScope==exit then self._nlExitScope=nil end end,{X=-direction*14,Y=-3})
 end
 self._nlContentScope:Clean();self._entries={};self.Category=value
 for object,tween in pairs(self._tweens) do if not object.Parent then tween:Cancel();self._tweens[object]=nil end end
 self:_buildNeverloseContents();self:_layoutModules();self:_snapText(self.NLCards,self:_activeScale())
 for i,button in ipairs(self.NLCategories) do
  local active=button.Name==value
  self:_animate(button.Button,{BackgroundTransparency=active and .15 or 1,BackgroundColor3=color(active and 0x62405F or 0x302030)},self.ReducedMotion and 0 or .22)
  if active then self:_animate(self.NLSelection,{Position=UDim2.fromOffset(0,(i-1)*42+9)},self.ReducedMotion and 0 or .28) end
 end
 local saved=self._nlScrolls[value]
 if saved then for i,column in ipairs(self.NLColumns) do column.CanvasPosition=saved[i] end end
 self:_transition(self.NLCards,0,1,.28,self._nlContentScope,nil,{X=direction*20,Y=7})
 return self
end

-- Drag only the title, top empty strip or status label; controls keep their input.
function Window:_clampNeverlosePosition(position,width,height,viewW,viewH)
 local grip=math.min(96,width*.5)
 return Vector2.new(math.clamp(position.X,-math.max(0,width-grip),math.max(0,viewW-grip)),math.clamp(position.Y,0,math.max(0,viewH-48)))
end
function Window:_bindNeverloseDrag()
 local scope=self._viewScope
 self.NLDragStrip=create("TextButton",self.NL,{Name="NeverloseDragStrip",Text="",BackgroundTransparency=1,AutoButtonColor=false,Active=true,Position=UDim2.fromOffset(188,0),Size=UDim2.new(1,-188,0,14),ZIndex=0})
 local function start(input)
  if not self.Visible or self._gesture or self._drag or self:_bindingBusy() then return end
  if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
  self:_closePopups(nil,true)
  local point=self:_inputPoint(input);local origin=self.View.AbsolutePosition-self.Gui.AbsolutePosition
  local scale=self.NL.AbsoluteSize.X/math.max(1,self.NL.Size.X.Offset)
  local grab=Vector2.new((point.X-origin.X)/scale-self.NL.Position.X.Offset,(point.Y-origin.Y)/scale-self.NL.Position.Y.Offset)
  self._gesture={input=input,start=point,origin=Vector2.new(self.NL.Position.X.Offset,self.NL.Position.Y.Offset),grab=grab,neverlose=true}
 end
 self.NLBrand.Active=true;self.NLStatus.Active=true
 self:_on(self.NLBrand.InputBegan,start,scope)
 self:_on(self.NLDragStrip.InputBegan,start,scope)
 self:_on(self.NLStatus.InputBegan,start,scope)
end
function Window:_bindingBusy()
 return self._binding~=nil or (self.Options.SyntaxBindingActive and self.Options.SyntaxBindingActive(nil))
end

function Window:_optionsPage(group,title)
 text(self.View,title,16,10,self._width-32,34,23,0xE7E7E7,true)
 local scroll=create("ScrollingFrame",self.View,{Name="PageOptions",BackgroundColor3=color(0x0D1117),BackgroundTransparency=.12,Position=UDim2.fromOffset(16,55),Size=UDim2.fromOffset(math.min(720,self._width-32),self._height-self._top-105),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,ScrollBarImageColor3=color(self:_accentHex()),Active=true});corner(scroll,6)
 local rows=self:_settingsRows(group,scroll,self._viewScope);self._pageRows={Group=group,Rows=rows,Scroll=scroll}
end
function Window:_searchMatch(group)
 local query=self.Query:lower();if query=="" then return true end
 if group.Id:lower():find(query,1,true) or self:_moduleName(group):lower():find(query,1,true) or (group.Definition.description or ""):lower():find(query,1,true) then return true end
 for key,def in pairs(group._definitions) do
  if key:lower():find(query,1,true) or self:_tr(key):lower():find(query,1,true) or Http:JSONEncode(group.Values[key]):lower():find(query,1,true) then return true end
  for _,option in ipairs(def.options or def.Options or {}) do if tostring(option):lower():find(query,1,true) then return true end end
 end
 return false
end
function Window:_searchResults()
 if self._resultsScope then self._resultsScope:Clean() end;self._resultsScope=Scope.new(self._viewScope)
 local scope=self._resultsScope;local root=create("Frame",self.SearchResults,{BackgroundTransparency=1,Size=UDim2.fromScale(1,1)});scope.root=root
 local width=math.max(100,self._width-40);local cols=math.max(1,math.floor(width/250));local itemW=(width-(cols-1)*12)/cols;local count=0
 for _,g in ipairs(self._modules) do if not g.Definition.omitFromMenu and self:_searchMatch(g) then
  local index=count;local button=self:_button(root,self:_moduleName(g),index%cols*(itemW+12),math.floor(index/cols)*49,itemW,42,function() self:OpenModule(g.Id) end,scope)
  button.TextSize=14;button.TextXAlignment=Enum.TextXAlignment.Left;button.Text="  "..button.Text;button.BackgroundColor3=color(g.Enabled and self:_accentHex() or 0x1F242D)
  self:_on(button.MouseButton2Click,function() g:SetEnabled(not g.Enabled) end,scope);count+=1
 end end
 self.SearchCount.Text=tostring(count).." "..self:_tr("Results")
 self.SearchResults.CanvasSize=UDim2.fromOffset(0,math.ceil(count/cols)*49)
 if count==0 then text(root,self:_tr("No matching modules"),0,15,width,32,15,0xD7B06B,false,Enum.TextXAlignment.Center) end
end
function Window:_buildSearch()
 text(self.View,self:_tr("Search"),15,0,self._width-30,48,28,0xE7E4F5,true,Enum.TextXAlignment.Center)
 self.SearchInput=create("TextBox",self.View,{Name="SearchInput",BackgroundColor3=color(0x0B0D15),Position=UDim2.fromOffset(20,57),Size=UDim2.fromOffset(self._width-40,38),ClearTextOnFocus=false,PlaceholderText=self:_tr("Search modules and settings"),PlaceholderColor3=color(0x777777),Text=self.Query,Font=Enum.Font.Gotham,TextSize=16,TextColor3=color(0xE8E6EC),TextXAlignment=Enum.TextXAlignment.Center});corner(self.SearchInput,6);stroke(self.SearchInput,self:_accentHex(),1)
 self.SearchCount=text(self.View,"",20,100,self._width-40,24,13,0xAD84DB,false,Enum.TextXAlignment.Center)
 self.SearchResults=create("ScrollingFrame",self.View,{Name="SearchResults",BackgroundTransparency=1,Position=UDim2.fromOffset(20,135),Size=UDim2.fromOffset(self._width-40,self._height-self._top-182),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,Active=true})
 self:_on(self.SearchInput:GetPropertyChangedSignal("Text"),function() self.Query=self.SearchInput.Text;self:_searchResults() end,self._viewScope)
 self:_searchResults()
end
function Window:_buildProfiles()
 text(self.View,self:_tr("Profiles"),18,6,self._width-36,36,24,0xEEEEEE,true)
 local scope=self._viewScope;local width=math.min(680,self._width-36)
 local name=create("TextBox",self.View,{Name="ProfileName",BackgroundColor3=color(0x121820),Position=UDim2.fromOffset(18,53),Size=UDim2.fromOffset(width-90,30),Text=self._selectedProfile or "Default",PlaceholderText="Profile name",ClearTextOnFocus=false,Font=Enum.Font.Gotham,TextSize=13,TextColor3=color(0xE7E7E7)});corner(name,4)
 self:_button(self.View,self:_tr("Save"),width-62,53,80,30,function() local ok,err=self:SaveProfile(name.Text);if ok then self:Notify("Profile saved");self:_invalidate() else self:Notify(err) end end,scope)
 local scroll=create("ScrollingFrame",self.View,{Name="ProfilesList",BackgroundTransparency=1,Position=UDim2.fromOffset(18,96),Size=UDim2.fromOffset(width,self._height-self._top-190),CanvasSize=UDim2.fromOffset(0,0),ScrollBarThickness=3,Active=true})
 local names={};for key in pairs(self._profiles) do names[#names+1]=key end;table.sort(names)
 for i,key in ipairs(names) do
  local b=self:_button(scroll,key,0,(i-1)*42,width-90,35,function() local ok,err=self:LoadProfile(key);self:Notify(ok and "Profile loaded" or err) end,scope);b.TextXAlignment=Enum.TextXAlignment.Left;b.Text="  "..key;b.TextSize=14
  self:_button(scroll,"×",width-75,(i-1)*42,64,35,function() self:DeleteProfile(key);self:_invalidate() end,scope)
 end
 scroll.CanvasSize=UDim2.fromOffset(0,#names*42)
 if #names==0 then text(scroll,self:_tr("No saved profiles"),0,12,width,32,14,0x777777) end
 self:_button(self.View,"Import JSON",18,self._height-self._top-80,130,28,function() self:_textDialog("Import JSON","",function(raw) return self:ImportJSON(raw) end) end,scope)
 self:_button(self.View,"Export JSON",160,self._height-self._top-80,130,28,function() self:_textDialog("Export JSON",self:ExportJSON()) end,scope)
end
function Window:_buildApps()
 text(self.View,self:_tr("Apps"),18,6,self._width-36,36,24,0xEEEEEE,true)
 local scroll=create("ScrollingFrame",self.View,{BackgroundTransparency=1,Position=UDim2.fromOffset(18,55),Size=UDim2.new(1,-36,1,-70),CanvasSize=UDim2.fromOffset(0,#(self.Options.Apps or {})*54),ScrollBarThickness=3,Active=true})
 for i,app in ipairs(self.Options.Apps or {}) do
  local b=self:_button(scroll,app.Name or app.name or "Application",0,(i-1)*54,math.min(680,self._width-36),44,function() if app.Callback then task.spawn(app.Callback,self) end end,self._viewScope);b.TextSize=15
 end
 if #(self.Options.Apps or {})==0 then text(scroll,"Add applications with Options.Apps",0,15,self._width-36,30,14,0x888888) end
end
function Window:_buildAbout()
 local lines={"JACKAL CLIENT","Roblox UI Library · "..UI.Version,"Original client: 1.1.9 · @Wormwaker","Dropdown / Neverlose / Imgui","10 source GUI Styler presets","Original UI configuration: AGPL-3.0","Roblox port: native instances and client input","Windows module names in the demo are interface examples."}
 for i,line in ipairs(lines) do text(self.View,line,16,18+(i-1)*42,self._width-32,36,i==1 and 30 or 14,i==1 and self:_accentHex() or 0xCCC4D4,i==1,Enum.TextXAlignment.Center) end
 local y=18+#lines*42
 self:_button(self.View,"Launcher preview",math.max(16,self._width/2-100),y,200,32,function() self:ShowLauncher(self.Launcher or "Default") end,self._viewScope)
end
function Window:ShowLauncher(style)
 assert(table.find(LAUNCHER_NAMES,style),"Unknown launcher style")
 local colors={Default=0xD2D2D2,Vape=0x5BD38B,Jackal=0xDC5E41,Neon=0xE24DD7,Matrix=0x49D54A,Aurora=0x7C84F9}
 if style=="Random" then style=LAUNCHER_NAMES[math.random(1,#LAUNCHER_NAMES-1)] end
 self.Launcher=style
 local popup=self:_popup("Launcher",nil,380,250,true);if not popup then return end
 popup.Frame.BackgroundColor3=color(style=="Matrix" and 0x061108 or 0x11131C)
 if style=="Matrix" then for i=1,14 do text(popup.Frame,"0101 1010",8+(i%5)*78,6+math.floor(i/5)*24,75,20,11,0x185125) end end
 text(popup.Frame,"JACKAL",18,65,popup.Width-36,44,36,colors[style] or 0xFFFFFF,true,Enum.TextXAlignment.Center)
 text(popup.Frame,style.." · Native launcher preview",18,112,popup.Width-36,24,12,0xAAA7B9,false,Enum.TextXAlignment.Center)
 self:_button(popup.Frame,"START",popup.Width/2-70,173,140,32,function() self:_closePopups();self:SetPage("Modules") end,popup.Scope)
end
function Window:_settingsModels()
 local function def(name,kind,value,options,callback) return {name=name,type=kind,default=value,options=options,callback=callback} end
 self.Models={}
 self.Models.GUI=self:_newGroup({id="@GUI",settings={
  def("ClickGUI Layout","select",self.Layout,LAYOUT_NAMES,function(v) self:SetLayout(v) end),
  def("Style Preset","select",self.Preset,PRESET_NAMES,function(v) self:SetPreset(v) end),
  def("Language","select",self.Language,{"English","中文"},function(v) self:SetLanguage(v) end),
  self.Options.Embedded and {name="Global Scale",type="slider",default=self.RequestedScale,min=.5,max=4,step=.05} or def("Global Scale","select",self.RequestedScale,{.75,1,1.05,1.25,1.5,2},function(v) self:SetScale(v) end),
  def("Reduced motion","toggle",self.ReducedMotion,nil,function(v) self:SetReducedMotion(v) end),
  def("Launcher Style","select","Default",LAUNCHER_NAMES,function(v) self.Launcher=v end),
  {name="Reset panel positions",type="button",buttonText="Reset",callback=function() self:ResetPositions() end},
 }})
 self.Models.HUD=self:_newGroup({id="@HUD",settings={def("Arraylist","toggle",true),def("Keystrokes","toggle",true),def("Time display","toggle",true),def("HUD while menu open","toggle",self.Options.HUDWhileMenuOpen==true),def("Dynamic Island","toggle",false),def("Crosshair","toggle",false)}})
 self.Models.Sound=self:_newGroup({id="@Sound",settings={def("Option sound","toggle",false),{name="Volume",type="slider",min=0,max=100,step=1,default=80},{name="Sound asset",type="text",default=""},{name="Preview sound",type="button",buttonText="Play",callback=function() local ok,err=self:PlayUISound();if not ok then self:Notify(err) end end}}})
 self.Models.Config=self:_newGroup({id="@Config",settings={def("Confirm reset","toggle",true),def("Display default values","toggle",true),def("Highlight modified options","toggle",true),{name="Profiles",type="button",buttonText="Open",callback=function() self:SetPage("Profiles") end}}})
end

function Window:GetState()
 local modules={};for _,group in ipairs(self._modules) do modules[group.Id]=group:GetState() end
 local models={};for name,group in pairs(self.Models) do models[name]=group:GetState() end
 return {version=1,modules=modules,models=models,ui={layout=self.Layout,preset=self.Preset,scale=self.RequestedScale,island=self.DynamicIsland and self.DynamicIsland:GetOptions() or nil,reducedMotion=self.ReducedMotion,language=self.Language,category=self.Category,launcher=self.Launcher or "Default"}}
end
function Window:ApplyState(state)
 if type(state)~="table" or state.version~=1 or type(state.modules)~="table" then return false,"Invalid configuration" end
 local ui=state.ui or {};if type(ui)~="table" then return false,"Invalid interface configuration" end
 if ui.layout and not table.find(LAYOUT_NAMES,ui.layout) then return false,"Invalid layout" end
 if ui.preset and not PRESETS[ui.preset] then return false,"Invalid preset" end
 if ui.scale and (not finite(ui.scale) or ui.scale<.5 or ui.scale>2) then return false,"Invalid scale" end
 if ui.language and ui.language~="English" and ui.language~="中文" then return false,"Invalid language" end
 if ui.launcher and not table.find(LAUNCHER_NAMES,ui.launcher) then return false,"Invalid launcher" end
 if ui.reducedMotion~=nil and type(ui.reducedMotion)~="boolean" then return false,"Invalid motion preference" end
 local islandOptions
 if ui.island~=nil then local ok,result=pcall(self._validateIslandConfig,self,ui.island);if not ok then return false,"Invalid island configuration" end;islandOptions=result end
 local staged={}
 local function stage(group,value)
  if type(value)~="table" or type(value.enabled)~="boolean" or type(value.settings)~="table" then return false end
  local key=normalized({type="key"},value.key or "None");if not key or value.hidden~=nil and type(value.hidden)~="boolean" then return false end
  local values={}
  for name,v in pairs(value.settings) do if group._definitions[name] then local result=normalized(group._definitions[name],v);if result==nil then return false end;values[name]=result end end
  staged[#staged+1]={group=group,enabled=value.enabled,key=key,hidden=value.hidden==true,values=values,previous=group:GetState()};return true
 end
 for id,value in pairs(state.modules) do if self._byId[id] and not stage(self._byId[id],value) then return false,"Invalid module: "..id end end
 if state.models~=nil then
  if type(state.models)~="table" then return false,"Invalid page options" end
  for name,value in pairs(state.models) do if self.Models[name] and not stage(self.Models[name],value) then return false,"Invalid page options: "..name end end
 end
 -- All fields are validated before mutating state. Restore values without firing layout callbacks mid-import.
 self._batch=true
 for _,entry in ipairs(staged) do
  local group=entry.group;group.Enabled=entry.enabled;group.Key=entry.key;group.Hidden=entry.hidden
  for key,v in pairs(entry.values) do group.Values[key]=clone(v) end
 end
 self.Layout=ui.layout or self.Layout;self.Preset=ui.preset or self.Preset;self.Theme=clone(PRESETS[self.Preset]);self.RequestedScale=ui.scale or self.RequestedScale;self.Language=ui.language or self.Language;self.Launcher=ui.launcher or self.Launcher
 self.Accent=NAMED[self.Theme["Module Background Color (Enabled)"]] or 0x55C25F
 for _,entry in ipairs(staged) do if entry.group.Id=="GUIStyler" and entry.group._definitions["Style preset"] then entry.group.Values["Style preset"]=self.Preset;entry.values["Style preset"]=self.Preset end end
 if ui.category and table.find(self._categories,ui.category) then self.Category=ui.category end
 self.Models.GUI.Values["ClickGUI Layout"]=self.Layout;self.Models.GUI.Values["Style Preset"]=self.Preset;self.Models.GUI.Values["Global Scale"]=self.RequestedScale;self.Models.GUI.Values.Language=self.Language
 if ui.reducedMotion~=nil then self.ReducedMotion=ui.reducedMotion end
 self.Models.GUI.Values["Reduced motion"]=self.ReducedMotion
 if islandOptions then
  if self.DynamicIsland then self.DynamicIsland.Options=islandOptions else self:CreateDynamicIsland(islandOptions) end
  local module=self:_component("Island")
  if module then self.Models.HUD.Values["Dynamic Island"]=module.Enabled else self.Models.HUD.Values["Dynamic Island"]=islandOptions.Enabled==true end
 end
 self:_fit();self:_invalidate()
 -- Reapply functional module callbacks once per changed module/setting, through the normal notification path.
 for _,entry in ipairs(staged) do
  if entry.group.Id:sub(1,1)~="@" then
   if entry.previous.enabled~=entry.enabled then self:_notify(entry.group,"enabled",entry.enabled) end
   if entry.previous.key~=entry.key then self:_notify(entry.group,"key",entry.key) end
   if entry.previous.hidden~=entry.hidden then self:_notify(entry.group,"hidden",entry.hidden) end
   for key,v in pairs(entry.values) do if Http:JSONEncode(entry.previous.settings[key])~=Http:JSONEncode(v) then self:_notify(entry.group,key,v) end end
  end
 end
 self._batch=false;self._needsLayout=false;self:_applyComponents();self:_layout();return true
end
function Window:ExportJSON() return Http:JSONEncode(self:GetState()) end
function Window:ImportJSON(raw)
 local ok,result=pcall(Http.JSONDecode,Http,raw);if not ok then return false,"Invalid JSON" end;return self:ApplyState(result)
end
function Window:_loadProfiles()
 _G.JackalProfiles=_G.JackalProfiles or {};self._profiles=clone(_G.JackalProfiles[self.Options.Name or "JackalUI"] or {})
 local storage=self.Options.Storage
 if storage and storage.Load then local ok,raw=pcall(storage.Load,storage);if ok and type(raw)=="string" then local valid,result=pcall(Http.JSONDecode,Http,raw);if valid and type(result)=="table" then self._profiles=result end end end
end
function Window:_saveProfiles()
 _G.JackalProfiles[self.Options.Name or "JackalUI"]=clone(self._profiles)
 local storage=self.Options.Storage
 if storage and storage.Save then local ok,err=pcall(storage.Save,storage,Http:JSONEncode(self._profiles));if not ok then return false,tostring(err) end end
 return true
end
function Window:SaveProfile(name)
 if type(name)~="string" then return false,"Profile name required" end;name=name:match("^%s*(.-)%s*$")
 if name=="" or #name>80 then return false,"Profile name must be 1–80 bytes" end
 self._profiles[name]=self:GetState();self._selectedProfile=name;return self:_saveProfiles()
end
function Window:LoadProfile(name)
 if not self._profiles[name] then return false,"Profile not found" end
 local ok,err=self:ApplyState(clone(self._profiles[name]));if ok then self._selectedProfile=name end;return ok,err
end
function Window:DeleteProfile(name)
 if not self._profiles[name] then return false,"Profile not found" end;self._profiles[name]=nil;return self:_saveProfiles()
end

-- Dynamic Island: a live, reusable notification/progress component.
local Island={};Island.__index=Island
local IslandMessage={};IslandMessage.__index=IslandMessage
local ISLAND_COLORS={info=0xA692F7,success=0x68E0AB,warning=0xFFCF7D,error=0xFF879B,progress=0xE98FC0}
local function islandString(value,fallback)
 if value==nil then return fallback or "" end
 assert(type(value)=="string" and utf8.len(value),"Island text must be valid UTF-8")
 return shortText(value,4096)
end
local function islandOptions(base,patch)
 local out=clone(base)
 for k,v in pairs(patch or {}) do out[k]=v end
 for key,range in pairs({Width={100,700},MaxWidthRate={.2,1},Duration={0,5},OffsetY={0,300},QueueLimit={1,100}}) do
  if out[key]~=nil then assert(finite(out[key]),"Invalid island "..key);out[key]=math.clamp(out[key],range[1],range[2]) end
 end
 for _,key in ipairs({"Enabled","Progress","ShowBrand","ShowUser","ShowFPS","ShowTime","HideWhenIdle","SyncNotifications","ReserveSpace","AutoWidth"}) do if out[key]~=nil then assert(type(out[key])=="boolean","Island "..key.." must be boolean") end end
 if out.BrandName~=nil then assert(type(out.BrandName)=="string" and utf8.len(out.BrandName),"Invalid island brand name") end
 if out.Easing then assert(table.find({"Cubic","Linear","Exponential"},out.Easing),"Unknown island easing") end
 return out
end
function Window:CreateDynamicIsland(options)
 if self.DynamicIsland and not self.DynamicIsland._dead then self.DynamicIsland:SetOptions(options or {});return self.DynamicIsland end
 local component=setmetatable({Window=self,Options=islandOptions({Enabled=false,Width=240,MaxWidthRate=.75,Duration=.3,Easing="Cubic",Progress=true,ShowBrand=true,ShowUser=true,ShowFPS=true,ShowTime=true,HideWhenIdle=false,SyncNotifications=true,OffsetY=10,QueueLimit=24,ReserveSpace=true},options),_scope=Scope.new(self._scope),_queue={},_items={},_serial=0,_elapsed=0,_width=200,_height=38,_expanded=true},Island)
 local layer=create("Frame",self.Gui,{Name="DynamicIslandLayer",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=70});component._scope.root=layer
 local root=create("Frame",layer,{Name="DynamicIsland",BackgroundColor3=color(0x0E0C14),BackgroundTransparency=.06,AnchorPoint=Vector2.new(.5,0),Position=UDim2.new(.5,0,0,10),Size=UDim2.fromOffset(240,38),ClipsDescendants=true,Visible=false});corner(root,20)
 component.Root=root;component.Scale=create("UIScale",root,{Scale=1});component.Border=stroke(root,0x745269,1)
 component.Hit=create("TextButton",root,{Name="ExpandCollapse",Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,ZIndex=1})
 component.Idle=text(root,"",14,0,210,38,14,0xE4DCEB,true,Enum.TextXAlignment.Center);component.Idle.ZIndex=2
 component.Symbol=icon(root,"info",21,ISLAND_COLORS.info);component.Symbol.Root.Position=UDim2.fromOffset(14,13);component.Symbol.Root.ZIndex=2
 component.Title=text(root,"",46,6,180,28,17,0xFCF5FF,true);component.Title.Name="IslandTitle";component.Title.ZIndex=2
 component.Detail=text(root,"",46,35,180,42,14,0xC9BDCE);component.Detail.Name="IslandDetail";component.Detail.TextWrapped=true;component.Detail.TextTruncate=Enum.TextTruncate.None;component.Detail.TextYAlignment=Enum.TextYAlignment.Top;component.Detail.ZIndex=2
 component.Track=create("Frame",root,{Name="IslandProgressTrack",BackgroundColor3=color(0x4B3A50),Position=UDim2.fromOffset(16,83),Size=UDim2.fromOffset(200,4),ZIndex=2});corner(component.Track,3)
 component.Fill=create("Frame",component.Track,{Name="IslandProgressFill",BackgroundColor3=color(ISLAND_COLORS.progress),Size=UDim2.fromScale(0,1)});corner(component.Fill,3)
 component.Percent=text(root,"",0,6,42,28,14,0xDAC8DD,false,Enum.TextXAlignment.Right);component.Percent.ZIndex=2
 component.Close=create("TextButton",root,{Name="IslandDismiss",Text="",BackgroundTransparency=1,Position=UDim2.fromOffset(200,8),Size=UDim2.fromOffset(28,28),AutoButtonColor=false,ZIndex=3})
 local cross=icon(component.Close,"close",14,0xD9CDD9);cross.Root.Position=UDim2.fromOffset(7,7)
 component.Cancel=create("TextButton",root,{Name="IslandCancel",Text="Cancel",Font=Enum.Font.BuilderSans,TextSize=14,TextColor3=color(0xF4D9E8),BackgroundColor3=color(0x4F3047),Position=UDim2.fromOffset(14,98),Size=UDim2.fromOffset(90,26),AutoButtonColor=false,ZIndex=3});corner(component.Cancel,6)
 self:_on(component.Hit.Activated,function() if component.Active then component:SetExpanded(not component._expanded) end end,component._scope)
 self:_on(component.Close.Activated,function() if component.Active then component:_remove(component.Active.Id,"dismissed") end end,component._scope)
 self:_on(component.Cancel.Activated,function() if component.Active then component:_remove(component.Active.Id,"cancelled") end end,component._scope)
 self:_on(root.MouseEnter,function() component._hovered=Input.MouseEnabled==true end,component._scope);self:_on(root.MouseLeave,function() component._hovered=false end,component._scope)
 self:_motion(root,function(dt) component:_step(dt) end,component._scope)
 self.DynamicIsland=component
 component._scope.disposals[#component._scope.disposals+1]=function() component._dead=true;table.clear(component._items);table.clear(component._queue);component.Active=nil end
 if self._built then self:_componentLayoutChanged() end
 return component
end
function Island:SetOptions(options)
 assert(not self._dead,"Island destroyed")
 local before=self.Options.Enabled and self.Options.ReserveSpace
 local wasEnabled=self.Options.Enabled
 self.Options=islandOptions(self.Options,options)
 self.Window:_islandOptionsChanged(options)
 if wasEnabled~=self.Options.Enabled then self.Window:_islandEnabledChanged(self.Options.Enabled) end
 if before~=(self.Options.Enabled and self.Options.ReserveSpace) then self.Window:_componentLayoutChanged() end
 return self
end
function Island:SetEnabled(value)
 assert(type(value)=="boolean","Enabled must be boolean")
 if self._dead then return self end
 local changed=self.Options.Enabled~=value;self.Options.Enabled=value
 if changed then self.Window:_islandEnabledChanged(value);self.Window:_componentLayoutChanged() end
 return self
end
function Island:SetExpanded(value) self._expanded=value==true;return self end
function Island:_patch(item,patch)
 local nextItem=clone(item)
 if patch.Title~=nil then nextItem.Title=islandString(patch.Title) end
 if patch.Text~=nil then nextItem.Text=islandString(patch.Text) end
 if patch.Level~=nil then assert(ISLAND_COLORS[patch.Level],"Unknown notification level");nextItem.Level=patch.Level end
 if patch.Progress~=nil then assert(finite(patch.Progress),"Progress must be a finite number");nextItem.Progress=math.clamp(patch.Progress,0,1) end
 if patch.Duration~=nil then assert(finite(patch.Duration) and patch.Duration>=0,"Invalid notification duration");nextItem.Duration=math.min(patch.Duration,120);nextItem.Remaining=nextItem.Duration end
 if patch.OnCancel~=nil then assert(type(patch.OnCancel)=="function","OnCancel must be a function");nextItem.OnCancel=patch.OnCancel end
 for k,v in pairs(nextItem) do item[k]=v end
end
function Island:_enqueue(options,kind)
 assert(not self._dead,"Island destroyed");options=options or {};self._serial+=1
 local id=tostring(options.Id or self._serial)
 if self._items[id] then self:_patch(self._items[id],options);return setmetatable({Island=self,Id=id,Generation=self._items[id].Generation},IslandMessage) end
 local item={Id=id,Generation=self._serial,Kind=kind,Level=kind=="progress" and "progress" or "info",Title="Jackal",Text="",Progress=0,Duration=kind=="progress" and 0 or 3,Remaining=kind=="progress" and 0 or 3}
 self:_patch(item,options)
 self._items[id]=item
 if not self.Active then self.Active=item;self._expanded=true
 elseif options.Priority==true or kind=="progress" and self.Active.Kind~="progress" then
  table.insert(self._queue,1,self.Active);self.Active=item;self._expanded=true
 else
  if #self._queue>=self.Options.QueueLimit then local old=table.remove(self._queue,1);self._items[old.Id]=nil end
  self._queue[#self._queue+1]=item
 end
 if #self._queue>self.Options.QueueLimit then local evicted=table.remove(self._queue);self._items[evicted.Id]=nil end
 return setmetatable({Island=self,Id=id,Generation=item.Generation},IslandMessage)
end
function Island:Notify(options) if type(options)=="string" then options={Text=options} end;return self:_enqueue(options,"notification") end
function Island:BeginProgress(options) return self:_enqueue(options,"progress") end
function Island:_remove(id,reason)
 local item=self._items[id];if not item then return false end
 self._items[id]=nil
 if self.Active==item then self.Active=table.remove(self._queue,1);self._expanded=true else local index=table.find(self._queue,item);if index then table.remove(self._queue,index) end end
 if (reason=="cancelled" or reason=="dismissed") and item.Kind=="progress" and item.OnCancel then
  local callback=item.OnCancel;task.spawn(function() local ok,err=pcall(callback,reason);if not ok then self.Window:Notify(tostring(err),{Island=false}) end end)
 end
 return true
end
function Island:Clear() table.clear(self._queue);table.clear(self._items);self.Active=nil;return self end
function Island:GetState()
 local active=self.Active
 return {Enabled=self.Options.Enabled,Expanded=self._expanded,QueueLength=#self._queue,Active=active and {Id=active.Id,Title=active.Title,Text=active.Text,Kind=active.Kind,Level=active.Level,Progress=active.Progress,Remaining=active.Remaining} or nil}
end
function IslandMessage:Update(options)
 local component=self.Island;local item=not component._dead and component._items[self.Id]
 if not item or item.Generation~=self.Generation then return false end;component:_patch(item,options or {});return true
end
function IslandMessage:SetProgress(value,message) return self:Update({Progress=value,Text=message}) end
function IslandMessage:Complete(message,duration)
 local component=self.Island;local item=not component._dead and component._items[self.Id];if not item or item.Generation~=self.Generation then return false end
 component:_patch(item,{Progress=1,Text=message or item.Text,Level="success",Duration=duration or 2.5});item.Kind="notification";return true
end
function IslandMessage:Close()
 local item=not self.Island._dead and self.Island._items[self.Id]
 return item and item.Generation==self.Generation and self.Island:_remove(self.Id,"closed") or false
end
function IslandMessage:Cancel()
 local item=not self.Island._dead and self.Island._items[self.Id]
 return item and item.Generation==self.Generation and self.Island:_remove(self.Id,"cancelled") or false
end
function Island:Destroy()
 if self._dead then return end;self._scope:Clean()
 if self.Window.DynamicIsland==self then self.Window.DynamicIsland=nil;self.Window:_islandEnabledChanged(false);self.Window:_componentLayoutChanged() end
end
function Island:_step(dt)
 if self._dead then return end
 local window=self.Window;local options=self.Options;local active=self.Active
 if not options.Enabled then self.Root.Visible=false;return end
 local scale=window:_activeScale();self.Scale.Scale=scale
 local maxWidth=math.min(window.Gui.AbsoluteSize.X/scale-20,window.Gui.AbsoluteSize.X/scale*options.MaxWidthRate)
 maxWidth=math.max(80,maxWidth)
 local idleText=""
 if not active then
  local parts={};if options.ShowBrand then parts[#parts+1]=options.BrandName or "Jackal" end
  if options.ShowUser and window.Player then parts[#parts+1]=window.Player.DisplayName end
  if options.ShowFPS then parts[#parts+1]=tostring(math.round(window._fps or 60)).." FPS" end
  if options.ShowTime then parts[#parts+1]=window:_formatClock("%H:%M") end
  idleText=table.concat(parts,"  ·  ")
 end
 local targetWidth=math.min(options.Width,maxWidth);local targetHeight=38
 local idleWidth=measured(idleText,14,true)
 if not active and options.AutoWidth~=false then targetWidth=math.min(maxWidth,math.max(targetWidth,idleWidth+28)) end
 local expanded=active and self._expanded
 if active then
  local measureKey=active.Title.."\0"..active.Text
  if self._measureKey~=measureKey then self._measureKey=measureKey;self._messageWidth=math.max(measured(active.Title,17,true)+144,math.min(390,measured(active.Text,14,false)+70)) end
  targetWidth=math.min(maxWidth,math.max(targetWidth,self._messageWidth))
  targetHeight=expanded and (active.Kind=="progress" and active.OnCancel and 134 or 98) or 44
  if options.Enabled and active.Duration>0 and not self._hovered then active.Remaining-=dt;if active.Remaining<=0 then self:_remove(active.Id,"expired");active=self.Active end end
 end
 local signature=tostring(targetWidth)..":"..tostring(targetHeight)
 if self._target~=signature then self._target=signature;self._fromW=self._width;self._fromH=self._height;self._elapsed=0 end
 self._elapsed+=dt
 local t=(window.ReducedMotion or options.Duration==0) and 1 or math.clamp(self._elapsed/options.Duration,0,1)
 local eased=options.Easing=="Linear" and t or options.Easing=="Exponential" and (t==1 and 1 or 1-2^(-10*t)) or 1-(1-t)^3
 self._width=(self._fromW or self._width)+(targetWidth-(self._fromW or self._width))*eased;self._height=(self._fromH or self._height)+(targetHeight-(self._fromH or self._height))*eased
 self.Root.Visible=options.Enabled and (active~=nil or not options.HideWhenIdle)
 local targetY=(window.Visible and (window._chromeHeight or 42)*scale or 0)+options.OffsetY
 self._y=(self._y or targetY)+(targetY-(self._y or targetY))*(window.ReducedMotion and 1 or 1-math.exp(-dt*18));self.Root.Position=UDim2.new(.5,0,0,self._y)
 self.Root.Size=UDim2.fromOffset(self._width,self._height)
 self.Idle.Visible=not active;self.Idle.Size=UDim2.fromOffset(self._width-24,38)
 if not active then
  self.Idle.Text=idleText
  local overflow=math.max(0,idleWidth-(self._width-28))
  self.Idle.TextTruncate=Enum.TextTruncate.None;self.Idle.Size=UDim2.fromOffset(math.max(self._width-28,idleWidth),38)
  self.Idle.Position=UDim2.fromOffset(14-overflow*(.5-.5*math.cos(window._componentClock*.6)),0)
 end
 self.Symbol.Root.Visible=active~=nil;self.Title.Visible=active~=nil;self.Close.Visible=active~=nil;self.Detail.Visible=expanded==true;self.Percent.Visible=active and active.Kind=="progress" or false
 self.Track.Visible=expanded and options.Progress and active and (active.Kind=="progress" or active.Duration>0) or false
 self.Cancel.Visible=expanded and active and active.Kind=="progress" and active.OnCancel~=nil or false
 if active then
  local tint=ISLAND_COLORS[active.Level];self.Symbol:SetColor(tint);self.Fill.BackgroundColor3=color(tint);self.Border.Color=color(tint)
  self.Symbol.Root.Rotation=active.Kind=="progress" and ((self.Symbol.Root.Rotation or 0)+dt*120)%360 or 0
  self.Title.Text=active.Title;self.Detail.Text=active.Text
  self.Title.Size=UDim2.fromOffset(math.max(1,self._width-(active.Kind=="progress" and 130 or 84)),28)
  self.Detail.Size=UDim2.fromOffset(math.max(1,self._width-62),42)
  self.Close.Position=UDim2.fromOffset(self._width-36,8);self.Percent.Position=UDim2.fromOffset(self._width-84,6)
  self.Percent.Text=tostring(math.round(active.Progress*100)).."%"
  self.Track.Size=UDim2.fromOffset(math.max(1,self._width-32),4)
  local fraction=active.Kind=="progress" and active.Progress or active.Duration>0 and math.clamp(active.Remaining/active.Duration,0,1) or 1
  self._fraction=(self._fraction or fraction)+(fraction-(self._fraction or fraction))*(window.ReducedMotion and 1 or 1-math.exp(-dt*20));self.Fill.Size=UDim2.fromScale(self._fraction,1)
  self.Cancel.Text=window:_tr("Cancel")
 end
 if self._textScale~=scale then self._textScale=scale;window:_snapText(self.Root,scale) end
end

function Island:GetOptions()
 local out={}
 for _,key in ipairs({"Enabled","Width","MaxWidthRate","Duration","Easing","Progress","ShowBrand","ShowUser","ShowFPS","ShowTime","HideWhenIdle","SyncNotifications","OffsetY","QueueLimit","ReserveSpace","AutoWidth","BrandName"}) do out[key]=self.Options[key] end
 return out
end
function Window:_validateIslandConfig(options)
 assert(type(options)=="table","Invalid island configuration")
 return islandOptions(self.DynamicIsland and self.DynamicIsland:GetOptions() or {},options)
end

-- Native UI effects. Only resources owned by this window are modified.
local COMPONENT_IDS={Arraylist={"Arraylist"},Keystrokes={"Keystrokes"},TimeDisplay={"TimeDisplay","Time Display"},Island={"Island","DynamicIsland","Dynamic Island"},GUIBlur={"GUIBlur","GUI Blur"},Background={"Background"},Crosshair={"Crosshair"},Volume={"Volume"}}
local HUD_COMPONENTS={Arraylist="Arraylist",Keystrokes="Keystrokes",TimeDisplay="Time display",Island="Dynamic Island",Crosshair="Crosshair"}
function Window:_component(name)
 if self.Options.BindBuiltinComponents==false then return nil end
 for _,id in ipairs(COMPONENT_IDS[name] or {}) do if self._byId[id] then return self._byId[id] end end
 return nil
end
function Window:_componentLayoutChanged()
 if self._batch then self._componentReflowPending=true;return end
 if self._built and not self._dead and self._componentsReady then self:_fit();self:_invalidate() end
end
function Window:_islandEnabledChanged(value)
 if not self.Models or self._syncingComponents then return end
 self._syncingComponents=true
 local group=self:_component("Island");if group then group:SetEnabled(value) end
 self.Models.HUD:Set("Dynamic Island",value)
 self._syncingComponents=false
end
function Window:_componentChanged(group,key,value)
 if not self._componentsReady or self._syncingComponents then return end
 self._syncingComponents=true
 for name,setting in pairs(HUD_COMPONENTS) do
  local module=self:_component(name)
  if group==module and key=="enabled" then self.Models.HUD:Set(setting,value)
  elseif group==self.Models.HUD and key==setting and module then module:SetEnabled(value) end
 end
 self._syncingComponents=false
 self:_applyComponents()
 if not self._batch and self.Models.Sound.Values["Option sound"] and self.OptionSound.SoundId~="" and self.SoundGroup.Volume>0 then self.OptionSound:Play() end
end
function Window:_formatClock(format)
 if self.Options.TimeProvider then return tostring(self.Options.TimeProvider(format)) end
 if os.date then return os.date(format) end
 return format:find("%%S") and "12:00:00" or "12:00"
end
function Window:_componentTint(value,offset)
 value=value or {Hex="#FFFFFF",Alpha=1}
 if value.Rainbow then return Color3.fromHSV((self._componentClock*.1+(offset or 0))%1,.65,1) end
 return Color3.fromHex(value.Hex)
end
function Window:_createHUD()
 self.HUD=create("Frame",self.Gui,{Name="HUD",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=20})
 self.Arraylist=create("Frame",self.HUD,{Name="ArraylistHUD",BackgroundTransparency=1,Position=UDim2.new(1,-254,0,42),Size=UDim2.fromOffset(242,520)})
 self._arrayLabels={}
 self.Clock=text(self.HUD,"",12,8,280,28,15,0xB8AACF)
 self.KeyHUD=create("Frame",self.HUD,{Name="Keystrokes",BackgroundTransparency=1,Position=UDim2.new(0,16,1,-196),Size=UDim2.fromOffset(126,168)})
 self.Keys={}
 for _,info in ipairs({{"W",43,0},{"A",0,43},{"S",43,43},{"D",86,43},{"Space",0,86}}) do
  local b=field(self.KeyHUD,info[2],info[3],info[1]=="Space" and 126 or 40,40);b.Active=false;b.Interactable=false;b.Text=info[1];b.Font=Enum.Font.BuilderSans;b.TextSize=14;b.TextColor3=color(0xA5DDCF);self.Keys[info[1]]=b
 end
 self.MouseKeys={};self.MouseCPS={}
 for i,label in ipairs({"LMB","RMB"}) do
  local b=field(self.KeyHUD,(i-1)*66,132,60,34);b.Name=label;b.Active=false;b.Interactable=false;b.Text=""
  text(b,label,0,0,60,18,14,0xBDD4CF,true,Enum.TextXAlignment.Center)
  local cps=text(b,"0 CPS",0,16,60,18,14,0xA4BCB8,false,Enum.TextXAlignment.Center)
  self.MouseKeys[i]=b;self.MouseCPS[i]=cps
 end
 self._clickTimes={{},{}};self._mouseDown={false,false};self._componentClock=0;self._fps=60
 self.Crosshair=create("Frame",self.HUD,{Name="Crosshair",BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),Size=UDim2.fromOffset(100,100),Visible=false})
 self.CrosshairLines={}
 for i=1,4 do self.CrosshairLines[i]=create("Frame",self.Crosshair,{Name="CrosshairLine"..i,BackgroundColor3=color(0xFFFFFF),Size=UDim2.fromOffset(10,2),Position=UDim2.fromOffset(45,49)}) end
 self.CrosshairDot=create("Frame",self.Crosshair,{Name="CrosshairDot",BackgroundColor3=color(0xFFFFFF),Position=UDim2.fromOffset(49,49),Size=UDim2.fromOffset(2,2)});corner(self.CrosshairDot,2)
 self:_on(Input.InputBegan,function(input)
  local index=input.UserInputType==Enum.UserInputType.MouseButton1 and 1 or input.UserInputType==Enum.UserInputType.MouseButton2 and 2
  if index then self._mouseDown[index]=true;table.insert(self._clickTimes[index],self._componentClock) end
 end)
 self:_on(Input.InputEnded,function(input)
  local index=input.UserInputType==Enum.UserInputType.MouseButton1 and 1 or input.UserInputType==Enum.UserInputType.MouseButton2 and 2
  if index then self._mouseDown[index]=false end
 end)
 self:_on(Input.WindowFocusReleased,function() self._mouseDown={false,false} end)
end
function Window:_initComponents()
 self.EffectLayer=create("Frame",self.Main,{Name="VisualEffects",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=0})
 self.BackgroundTint=create("Frame",self.EffectLayer,{Name="BackgroundFilter",BackgroundColor3=color(0x346A5A),BackgroundTransparency=.5,Size=UDim2.fromScale(1,1),Visible=false})
 self.BackgroundGradient=create("UIGradient",self.BackgroundTint,{Rotation=35,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,color(0xB8FFE3)),ColorSequenceKeypoint.new(1,color(0x605DE8))})})
 self.MaterialTint=create("Frame",self.EffectLayer,{Name="MaterialTint",BackgroundColor3=color(0x241D2D),BackgroundTransparency=.6,Size=UDim2.fromScale(1,1),Visible=false})
 self.Blur=create("BlurEffect",Lighting,{Name=(self.Options.Name or "JackalUI").."_Blur",Size=0,Enabled=false})
 self.SoundGroup=create("SoundGroup",SoundService,{Name=(self.Options.Name or "JackalUI").."_Audio",Volume=.8})
 self.OptionSound=create("Sound",self.SoundGroup,{Name="InteractionSound",SoundId="",Volume=.8,SoundGroup=self.SoundGroup})
 self._scope.disposals[#self._scope.disposals+1]=function() if self.Blur.Parent then self.Blur:Destroy() end;if self.SoundGroup.Parent then self.SoundGroup:Destroy() end end
 local config=clone(self.Options.DynamicIsland or {});local islandModule=self:_component("Island")
 if islandModule then config.Enabled=islandModule.Enabled end
 self:CreateDynamicIsland(config)
 self._componentsReady=true
 for name,setting in pairs(HUD_COMPONENTS) do local module=self:_component(name);if module then self.Models.HUD.Values[setting]=module.Enabled end end
 self.Models.HUD.Values["Dynamic Island"]=config.Enabled==true
 self:_applyComponents()
end
function Window:_applyComponents()
 if not self._componentsReady or self._dead then return end
 local island=self:_component("Island");local opts={Enabled=self.Models.HUD.Values["Dynamic Island"]}
 if island then
  local v=island.Values;opts.Width=v.Width or 240;opts.Progress=v.Progress~=false;opts.Duration=(v["Animation/Duration (ms)"] or 300)/1000;opts.Easing=v["Animation/Easing"] or "Cubic"
  for _,name in ipairs({"Show brand","Show user","Show FPS","Show time","Hide when idle","Sync notifications"}) do
   local key=({["Show brand"]="ShowBrand",["Show user"]="ShowUser",["Show FPS"]="ShowFPS",["Show time"]="ShowTime",["Hide when idle"]="HideWhenIdle",["Sync notifications"]="SyncNotifications"})[name]
   if v[name]~=nil then opts[key]=v[name] end
  end
 end
 if not self.DynamicIsland and opts.Enabled then self:CreateDynamicIsland(opts) end
 if self.DynamicIsland then self._applyingIslandOptions=true;self.DynamicIsland:SetOptions(opts);self._applyingIslandOptions=false end
 local bg=self:_component("Background");local blur=self:_component("GUIBlur");local mode=bg and bg.Values.Filter or "Off"
 self.BackgroundTint.Visible=bg~=nil and bg.Enabled and mode~="Off" and self.Visible
 if bg then local value=bg.Values.Tint or {Hex="#346A5A",Alpha=1};self.BackgroundTint.BackgroundColor3=Color3.fromHex(value.Hex);self.BackgroundTint.BackgroundTransparency=1-(bg.Values.Opacity or .5)*value.Alpha end
 self.BackgroundGradient.Enabled=mode=="Flow" or mode=="Gradient"
 if mode~="Flow" then self.BackgroundGradient.Rotation=35;self.BackgroundGradient.Offset=Vector2.new(0,0) end
 self.Main.BackgroundTransparency=self.Options.Embedded and 1 or (self.BackgroundTint.Visible and .75 or .25)
 local blurOn=self.Visible and (blur and blur.Enabled or bg and bg.Enabled and mode=="Blur")
 local strength=blur and blur.Enabled and (blur.Values.Strength or 8) or 8
 self.Blur.Enabled=blurOn==true;self.Blur.Size=blurOn and strength or 0
 local style=blur and blur.Values.Style or "Blur"
 self.MaterialTint.Visible=blurOn==true
 self.MaterialTint.BackgroundTransparency=style=="Mica" and .25 or style=="Acrylic" and .58 or .9
 self.MaterialTint.BackgroundColor3=color(blur and blur.Values["Dark mode"]==false and 0xEEE8F4 or 0x241D2D)
 local volume=self:_component("Volume");local volumeSettings=volume and volume.Values or {}
 self.SoundGroup.Volume=volume and volume.Enabled and (volumeSettings.Mute and 0 or (volumeSettings.Level or 100)/100) or 1
 local sound=self.Models.Sound.Values;self.OptionSound.Volume=(sound.Volume or 80)/100
 local asset=tostring(sound["Sound asset"] or "");local id=asset:match("^rbxassetid://(%d+)$") or asset:match("^(%d+)$")
 self.OptionSound.SoundId=id and "rbxassetid://"..id or ""
 if not sound["Option sound"] or self.SoundGroup.Volume==0 or self.OptionSound.Volume==0 then self.OptionSound:Stop() end
 self:_refreshHUD()
 if self._componentReflowPending and not self._batch then self._componentReflowPending=false;self:_componentLayoutChanged() end
end
function Window:PlayUISound()
 if self._dead then return false,"UI destroyed" end
 self:_applyComponents()
 if self.OptionSound.SoundId=="" then return false,"Enter an audio asset ID first" end
 if self.SoundGroup.Volume==0 or self.OptionSound.Volume==0 then return false,"UI audio is muted" end
 self.OptionSound:Play();return true
end
function Window:_stepEffects(dt)
 self._componentClock+=dt
 if dt>0 then self._fps+=(math.clamp(1/dt,1,1000)-self._fps)*(1-math.exp(-dt*3)) end
 local bg=self:_component("Background")
 if bg and bg.Enabled and bg.Values.Tint and bg.Values.Tint.Rainbow then self.BackgroundTint.BackgroundColor3=self:_componentTint(bg.Values.Tint) end
 if bg and bg.Enabled and bg.Values.Filter=="Flow" and self.Visible then self.BackgroundGradient.Rotation=(self._componentClock*14)%360;self.BackgroundGradient.Offset=Vector2.new(math.sin(self._componentClock*.3)*.15,0) end
end
function Window:_refreshHUD()
 if not self.Models then return end
 local settings=self.Models.HUD.Values;self.HUD.Visible=settings["HUD while menu open"] or not self.Visible
 self.Arraylist.Visible=settings.Arraylist;self.Clock.Visible=settings["Time display"];self.KeyHUD.Visible=settings.Keystrokes;self.Crosshair.Visible=settings.Crosshair==true
 local list=self:_component("Arraylist");local listValues=list and list.Values or {};local font=listValues["Font size"] or 14
 local modules={};for _,g in ipairs(self._modules) do if g.Enabled and not g.Hidden then modules[#modules+1]=g end end
 table.sort(modules,function(a,b) return measured(self:_moduleName(a),font,false)>measured(self:_moduleName(b),font,false) end)
 for i,group in ipairs(modules) do
  local row=self._arrayLabels[i]
  if not row then
   local shadow=text(self.Arraylist,"",1,1,240,font+8,font,0x000000,false,Enum.TextXAlignment.Right)
   local label=text(self.Arraylist,"",0,0,240,font+8,font,0xFFFFFF,false,Enum.TextXAlignment.Right)
   row={Label=label,Shadow=shadow};self._arrayLabels[i]=row
  end
  local mode=listValues["Color mode"] or "Rainbow";local value=listValues.Color or {Hex="#55E69C",Alpha=1}
  local tint=mode=="Single" and self:_componentTint(value,i*.03) or mode=="Flow" and Color3.fromHex(value.Hex):Lerp(color(0xE3A6E2),.5+.5*math.sin(self._componentClock*.8+i*.3)) or Color3.fromHSV((self._componentClock*.08+i*.035)%1,.55,1)
  row.Label.Visible=true;row.Shadow.Visible=listValues.Shadow~=false
  row.Label.Text=self:_moduleName(group);row.Shadow.Text=row.Label.Text
  row.Label.Position=UDim2.fromOffset(0,(i-1)*(font+5));row.Shadow.Position=UDim2.fromOffset(1,(i-1)*(font+5)+1)
  row.Label.Size=UDim2.fromOffset(240,font+5);row.Shadow.Size=row.Label.Size;row.Label.TextSize=font;row.Shadow.TextSize=font
  row.Label.TextColor3=tint;row.Label.TextTransparency=1-(value.Alpha or 1);row.Shadow.TextTransparency=.25
 end
 for i=#modules+1,#self._arrayLabels do self._arrayLabels[i].Label.Visible=false;self._arrayLabels[i].Shadow.Visible=false end
 local time=self:_component("TimeDisplay");local tv=time and time.Values or {};local pattern=tv.Format=="12 hour" and "%I:%M" or "%H:%M"
 if tv.Seconds~=false then pattern..=":%S" end;if tv.Format=="12 hour" then pattern..=" %p" end
 self.Clock.Position=UDim2.fromOffset(12,self.Visible and (self._chromeHeight or 42)*self:_activeScale()+8 or 8)
 self.Clock.Text=self:_formatClock(pattern);if tv.Color then self.Clock.TextColor3=self:_componentTint(tv.Color);self.Clock.TextTransparency=1-tv.Color.Alpha end
 local keys=self:_component("Keystrokes");local kv=keys and keys.Values or {};local tint=kv.Color and self:_componentTint(kv.Color) or color(0xA5DDCF)
 for name,b in pairs(self.Keys) do local pressed=Input:IsKeyDown(Enum.KeyCode[name]);b.BackgroundColor3=pressed and tint or color(0x101419);b.TextColor3=pressed and color(0x101419) or tint end
 for i,b in ipairs(self.MouseKeys) do
  b.Visible=kv["Mouse buttons"]~=false
  local times=self._clickTimes[i];while times[1] and self._componentClock-times[1]>1 do table.remove(times,1) end
  self.MouseCPS[i].Visible=kv["Show CPS"]~=false;self.MouseCPS[i].Text=tostring(#times).." CPS"
  b.BackgroundColor3=self._mouseDown[i] and tint or color(0x101419)
 end
 local cross=self:_component("Crosshair");local cv=cross and cross.Values or {};local value=cv.Color or {Hex="#FFFFFF",Alpha=1};local tintCross=self:_componentTint(value)
 local length=cv.Size or 10;local thick=cv.Thickness or 2;local gap=cv.Gap or 4
 local positions={{50-gap-length,50-thick/2,length,thick},{50+gap,50-thick/2,length,thick},{50-thick/2,50-gap-length,thick,length},{50-thick/2,50+gap,thick,length}}
 for i,line in ipairs(self.CrosshairLines) do local p=positions[i];line.Position=UDim2.fromOffset(p[1],p[2]);line.Size=UDim2.fromOffset(p[3],p[4]);line.BackgroundColor3=tintCross;line.BackgroundTransparency=1-value.Alpha end
 self.CrosshairDot.Visible=cv.Dot~=false;self.CrosshairDot.BackgroundColor3=tintCross;self.CrosshairDot.BackgroundTransparency=1-value.Alpha
end
function Window:DemoDynamicIsland(kind)
 local island=self.DynamicIsland
 if not island then island=self:CreateDynamicIsland({Enabled=true}) end
 island:SetEnabled(true)
 if kind=="progress" then
  local taskHandle=island:BeginProgress({Title=self:_tr("Progress"),Text="0%",OnCancel=function() self:Notify(self:_tr("Cancelled")) end})
  local elapsed=0;local owner=create("Frame",self.Gui,{Name="DemoProgressTask",Visible=false,Size=UDim2.fromOffset(0,0)})
  local taskScope=Scope.new(self._scope);taskScope.root=owner
  self:_motion(owner,function(dt)
   elapsed+=dt
   local value=math.min(1,elapsed/5)
   if not taskHandle:SetProgress(value,tostring(math.round(value*100)).."%") then taskScope:Clean();return end
   if value>=1 then taskHandle:Complete(self:_tr("Completed"));taskScope:Clean() end
  end,taskScope)
  return taskHandle
 end
 return island:Notify({Priority=true,Title=self:_tr("Dynamic Island"),Text=self:_tr("Notification received"),Level=kind or "success",Duration=3})
end

function Window:GetDynamicIsland() return self.DynamicIsland end
function Window:BeginProgress(options)
 local island=self.DynamicIsland or self:CreateDynamicIsland({Enabled=true})
 if not island.Options.Enabled then island:SetEnabled(true) end
 return island:BeginProgress(options)
end

function Window:_islandOptionsChanged(patch)
 if self._syncingComponents or self._applyingIslandOptions or not self._componentsReady then return end
 local group=self:_component("Island");if not group then return end
 self._syncingComponents=true
 local map={Width="Width",Progress="Progress",Easing="Animation/Easing",Duration="Animation/Duration (ms)",ShowBrand="Show brand",ShowUser="Show user",ShowFPS="Show FPS",ShowTime="Show time",HideWhenIdle="Hide when idle",SyncNotifications="Sync notifications"}
 for option,key in pairs(map) do
  if patch[option]~=nil and group._definitions[key] then
   group:Set(key,option=="Duration" and patch[option]*1000 or patch[option])
   if self.DynamicIsland then self.DynamicIsland.Options[option]=option=="Duration" and group.Values[key]/1000 or group.Values[key] end
  end
 end
 self._syncingComponents=false
end

function Window:_invalidate()
 if not self._built or self._dead then return end
 self:_cancelTransition(self.Main,true);self.Main.Visible=self.Visible
 self:_closePopups(nil,true);self._drag=nil;self._gesture=nil;self._resultsScope=nil
 if self._binding then self._binding.cancel();self._binding=nil end
 if self._pageExitScope then self._pageExitScope:Clean();self._pageExitScope=nil end
 if self._viewScope then
  self:_cancelTransition(self.View,true)
  if self.View.Parent and self.Visible and not self.ReducedMotion then
   local ghost=self.View:Clone();ghost.Name="LeavingPage";ghost.Parent=self.Main;ghost.ZIndex=1
   for _,o in ipairs(ghost:GetDescendants()) do if o:IsA("GuiButton") or o:IsA("TextBox") then o.Active=false;o.Interactable=false end end
   local exit=Scope.new(self._scope);exit.root=ghost;self._pageExitScope=exit
   self:_transition(ghost,1,0,.12,exit,function() exit:Clean();if self._pageExitScope==exit then self._pageExitScope=nil end end,{X=-12})
  end
  self._viewScope:Clean()
 end
 for target,tween in pairs(self._tweens) do if not target.Parent then tween:Cancel();self._tweens[target]=nil end end
 self._viewScope=Scope.new(self._scope);self._entries={};self._panels={};self._pageRows=nil
 self.View=create("Frame",self.Main,{Name="Page_"..self.Page,BackgroundTransparency=1,Position=UDim2.fromOffset(0,self._top),Size=UDim2.fromOffset(self._width,self._height-self._top-32)});self._viewScope.root=self.View
 if self.Page=="Modules" then
  if self.Layout=="Dropdown" then self:_buildDropdown() elseif self.Layout=="Neverlose" then self:_buildNeverlose() else self:_buildImgui() end
 elseif self.Page=="Search" then self:_buildSearch()
 elseif self.Page=="Profiles" then self:_buildProfiles()
 elseif self.Page=="Apps" then self:_buildApps()
 elseif self.Page=="About" then self:_buildAbout()
 else self:_optionsPage(self.Models[self.Page],self:_tr(self.Page)) end
 self:_layout()
 self:_snapText(self.Main,self:_activeScale())
 self:_transition(self.View,0,1,self._built and .15 or 0,self._viewScope,nil,{X=self.Layout=="Neverlose" and 18 or 0})
end
function Window:_layout()
 if not self._built or self._dead then return end
 if self.Options.Embedded then self.LayoutButton.Text=self.Options.StyleName;self.PresetButton.Text=self:_tr("Configs") else self.LayoutButton.Text=self.Layout;self.PresetButton.Text=self.Preset;self.LanguageButton.Text=self.Language=="English" and "中 / EN" or "EN / 中" end
 for name,button in pairs(self.NavButtons) do button.BackgroundColor3=color(name==self.Page and self:_accentHex() or 0x0A0A0A);button.Text=self:_tr(name);button.TextColor3=rgba(self.Theme["Top Tab Text Color"],0xE6E6E6) end
 if self.Page=="Modules" then self:_layoutModules()
 elseif self._pageRows then
  local p=self._pageRows;local width=math.min(720,self._width-32);p.Scroll.Size=UDim2.fromOffset(width,self._height-self._top-105);p.Scroll.CanvasSize=UDim2.fromOffset(0,self:_placeRows(p.Group,p.Rows,width))
 elseif self.Page=="Search" then self:_searchResults() end
 for _,popup in ipairs(self._popups) do if popup.Reflow then popup.Reflow() end end
end
function Window:_fit()
 self:_cancelTransition(self.Main,true);self:_stopTween(self.Main);self.Main.Position=UDim2.fromOffset(0,0);self.Main.Visible=self.Visible;if self.MenuBlocker then self.MenuBlocker.Visible=false end;
 local size=self.Gui.AbsoluteSize
 self._scale=math.min(self.RequestedScale,math.max(.5,(size.X-4)/340),math.max(.5,(size.Y-4)/260))
 self.ScaleObject.Scale=self._scale;self._width=size.X/self._scale;self._height=size.Y/self._scale
 self.Main.Size=UDim2.fromOffset(self._width,self._height)
 self._top=self._width<1080 and 78 or 42
 self.Version.Size=UDim2.fromOffset(180,34)
 local navY=self._width<1080 and 40 or 4;local navX=self._width<1080 and 8 or 185
 self.Nav.Position=UDim2.fromOffset(navX,navY);self.Nav.Size=UDim2.fromOffset(self._width-(self._width<1080 and 16 or 500),30)
 self.Controls.Position=UDim2.fromOffset(math.max(185,self._width-306),4)
 -- On small screens the selectors occupy their own horizontal strip.
 if self._width<510 then self._top=112;self.Controls.Position=UDim2.fromOffset(8,39);self.Nav.Position=UDim2.fromOffset(8,77);self.Nav.Size=UDim2.fromOffset(self._width-16,29) end
 if self.Options.Embedded then
  self._top=self._width<510 and 104 or 76
  self.Controls.Position=UDim2.fromOffset(self._width<510 and 12 or math.max(190,self._width-310),self._width<510 and 36 or 4)
  self.Nav.Visible=false;self.LanguageButton.Visible=true
  self.LayoutButton.Size=UDim2.fromOffset(150,28);self.PresetButton.Position=UDim2.fromOffset(156,0);self.PresetButton.Size=UDim2.fromOffset(90,28)
  self.LanguageButton.Position=UDim2.fromOffset(252,0);self.LanguageButton.Size=UDim2.fromOffset(48,28)
 end
 self._chromeHeight=self._top
 if self.DynamicIsland and self.DynamicIsland.Options.Enabled and self.DynamicIsland.Options.ReserveSpace then self._top+=48 end
 self:_snapText(self.Main,self:_activeScale())
 self.Hint.Position=UDim2.fromOffset(12,self._height-28);self.Hint.Size=UDim2.fromOffset(self._width-24,25)
 self.Toast.Position=UDim2.new(.5,0,1,-14);self.Toast.Size=UDim2.fromOffset(math.min(size.X-24,640),42)
end
function Window:SetLayout(value)
 if value=="Neverlose (PRO)" then value="Neverlose" end
 assert(table.find(LAYOUT_NAMES,value),"Unknown ClickGUI layout")
 if self.Layout==value then return self end
 self.Layout=value
 if self.Models then self.Models.GUI.Values["ClickGUI Layout"]=value end
 self:_invalidate();if self.Options.OnLayoutChanged then task.spawn(self.Options.OnLayoutChanged,value,self) end;return self
end
function Window:SetPreset(value)
 assert(PRESETS[value],"Unknown style preset")
 if self._built and self.Preset==value then return self end
 self.Preset=value;self.Theme=clone(PRESETS[value])
 local mode=self.Theme["Module Background Color (Enabled)"];self.Accent=mode=="Rainbow" and 0x55C25F or NAMED[mode] or 0x34A5F8
 if self.Models then self.Models.GUI.Values["Style Preset"]=value end
 local styler=self._byId.GUIStyler
 if styler and styler._definitions["Style preset"] then styler.Values["Style preset"]=value end
 self:_invalidate();return self
end
function Window:SetScale(value)
 assert(finite(value) and value>=.5 and value<=(self.Options.Embedded and 4 or 2),"Invalid scale")
 self.RequestedScale=value;if self.Models then self.Models.GUI.Values["Global Scale"]=value end
 self:_fit();self:_invalidate();return self
end
function Window:SetLanguage(value)
 assert(value=="English" or value=="中文","Unsupported language")
 self.Language=value;if self.Models then self.Models.GUI.Values.Language=value end;self:_invalidate();return self
end
function Window:SetPage(value)
 assert(table.find(PAGES,value),"Unknown page")
 self.Page=value;self:_invalidate();return self
end
function Window:Search(query)
 self.Query=tostring(query or "")
 if self.Page~="Search" then self:SetPage("Search") else self:_searchResults() end;return self
end
function Window:SelectCategory(value)
 assert(table.find(self._categories,value),"Unknown category")
 if self.Page=="Modules" and self.Layout=="Neverlose" and self.NLCards and self.NLCards.Parent then return self:_switchNeverloseCategory(value) end
 self.Category=value
 if self.Layout=="Dropdown" and self.Page=="Modules" then
  for _,p in ipairs(self._panels) do if p.Name==value then self.Canvas.CanvasPosition=Vector2.new(p.Root.Position.X.Offset*self._scale,0) end end
 else self.Page="Modules";self:_invalidate() end;return self
end
function Window:ResetPositions() self._positions={};self._imguiPosition=nil;self._nlPosition=nil;self:_layout();return self end
function Window:SetVisible(value)
 value=value==true
 if value==self.Visible and self.Main.Visible==value then return self end
 self.Visible=value;if self.Options.OnVisibilityChanged then self.Options.OnVisibilityChanged(value) end;self.Main.Visible=true;self:_applyComponents();if self.MenuBlocker then self.MenuBlocker.Visible=not value end;self:_closePopups();self._drag=nil;self._gesture=nil
 local mode=self.Theme["Menu Toggle Animation"] or "Fade"
 local duration=self.ReducedMotion and 0 or mode=="Off" and 0 or .4
 local dy=mode=="Slide (Top)" and -36 or mode=="Slide (Bottom)" and 36 or 0
 self:_transition(self.Main,value and 0 or 1,value and 1 or 0,duration,self._scope,function() if not self.Visible then self.Main.Visible=false end end,{Y=dy,Zoom=mode=="Enlarge II" and .94 or nil})
 if value and self.Page=="Modules" and self.Layout=="Dropdown" then
  for i,panel in ipairs(self._panels) do
   panel.Surface.Position=UDim2.fromOffset(0,-8-(i-1)*2)
   self:_animate(panel.Surface,{Position=UDim2.fromOffset(0,0)},.3+(i-1)*.028)
  end
 end
 if self._binding then self._binding.cancel();self._binding=nil end
 if not value then local box=Input:GetFocusedTextBox();if box and box:IsDescendantOf(self.Gui) then box:ReleaseFocus() end end
 return self
end
function Window:Toggle() return self:SetVisible(not self.Visible) end
function Window:_chrome()
 self.Version=text(self.Main,self.Options.Embedded and "Syntax" or "Jackal Client 1.1.9",12,0,180,34,15,0x9ED677,true)
 self.Nav=create("ScrollingFrame",self.Main,{Name="TopTabs",BackgroundTransparency=1,Size=UDim2.fromOffset(550,30),CanvasSize=UDim2.fromOffset(9*62,0),ScrollBarThickness=1,ScrollingDirection=Enum.ScrollingDirection.X,Active=true,ZIndex=5})
 self.NavButtons={}
 local navX=0
 for _,name in ipairs(PAGES) do
  local width=math.max(70,measured(name,16,false)+16)
  local b=self:_button(self.Nav,name,navX,0,width-1,28,function() self:SetPage(name) end);b.TextSize=16;self.NavButtons[name]=b;navX+=width
  self:_on(b.MouseLeave,function() self:_animate(b,{BackgroundColor3=color(name==self.Page and self:_accentHex() or 0x0A0A0A)}) end)
 end
 self.Nav.CanvasSize=UDim2.fromOffset(navX,0)
 self.Controls=create("Frame",self.Main,{Name="StyleSelectors",BackgroundTransparency=1,Size=UDim2.fromOffset(300,30),ZIndex=5})
 self.LayoutButton=self:_button(self.Controls,self.Layout,0,0,102,28,function() if self.Options.Embedded then self:_listPopup(self.LayoutButton,self.Options.StyleOptions,self.Options.StyleName,false,self.Options.OnSelectStyle) else self:_listPopup(self.LayoutButton,LAYOUT_NAMES,self.Layout,false,function(v) self:SetLayout(v) end) end end)
 self.PresetButton=self:_button(self.Controls,self.Preset,108,0,132,28,function() if self.Options.Embedded then self.Options.OnOpenConfigs() else self:_listPopup(self.PresetButton,PRESET_NAMES,self.Preset,false,function(v) self:SetPreset(v) end) end end)
 self.LanguageButton=self:_button(self.Controls,self.Options.Embedded and "HUD" or "中 / EN",246,0,54,28,function() if self.Options.Embedded then self.Options.OnEditHUD() else self:SetLanguage(self.Language=="English" and "中文" or "English") end end)
 self.Hint=text(self.Main,"LMB toggle · RMB / dots options · Drag category headers · RightShift menu",12,0,900,25,12,0xE3A181)
 self.Toast=text(self.Gui,"",12,0,640,42,14,0xD4F3E7,false,Enum.TextXAlignment.Center)
 self.Toast.Name="NotificationToast";self.Toast.AnchorPoint=Vector2.new(.5,1);self.Toast.BackgroundColor3=color(0x17121D);self.Toast.ZIndex=75;self.Toast.Visible=false;self.Toast.TextWrapped=true;corner(self.Toast,8)
end
function Window:_input()
 self:_on(Input.InputChanged,function(input)
  local drag=self._drag
  if drag and (input==drag.input or drag.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then drag.apply(self:_inputPoint(input)) end
  local g=self._gesture
  if g and (input==g.input or g.input.UserInputType==Enum.UserInputType.MouseButton1 and input.UserInputType==Enum.UserInputType.MouseMovement) then
   local delta=self:_inputPoint(input)-g.start;local target=g.origin+Vector2.new(delta.X/self._scale,delta.Y/self._scale)
   if g.panel then self._positions[g.panel.Name]=Vector2.new(math.max(0,target.X),math.max(0,target.Y)) elseif g.imgui then self._imguiPosition=target elseif g.neverlose then
    local point=self:_inputPoint(input);local origin=self.View.AbsolutePosition-self.Gui.AbsolutePosition
    local scale=self.NL.AbsoluteSize.X/math.max(1,self.NL.Size.X.Offset)
    self._nlPosition=Vector2.new((point.X-origin.X)/scale-g.grab.X,(point.Y-origin.Y)/scale-g.grab.Y)
   end
   self:_layoutModules()
  end
 end)
 self:_on(Input.InputEnded,function(input)
  if self._drag and (input==self._drag.input or input.UserInputType==Enum.UserInputType.MouseButton1) then self._drag=nil end
  if self._gesture and (input==self._gesture.input or input.UserInputType==Enum.UserInputType.MouseButton1) then self._gesture=nil end
 end)
 self:_on(Input.WindowFocusReleased,function() self._drag=nil;self._gesture=nil end)
 self:_on(Input.TextBoxFocused,function() if self._binding then self._binding.cancel();self._binding=nil end end)
 self:_on(Input.InputBegan,function(input,processed)
  if self.Options.SyntaxBindingActive and self.Options.SyntaxBindingActive(input) then return end
  if self.Options.Embedded and not self.Visible then return end
  if input.UserInputType~=Enum.UserInputType.Keyboard then return end
  local key=input.KeyCode;local focused=Input:GetFocusedTextBox()
  if self._binding then
   local mods={"LeftControl","RightControl","LeftShift","RightShift","LeftAlt","RightAlt","LeftMeta","RightMeta"}
   if table.find(mods,key.Name) then return end
   local binding=self._binding;self._binding=nil;binding.cancel()
   local parts={};if not self.Options.Embedded then for _,name in ipairs(mods) do if Input:IsKeyDown(Enum.KeyCode[name]) then parts[#parts+1]=name end end end;parts[#parts+1]=key.Name
   binding.set((key==Enum.KeyCode.Escape or key==Enum.KeyCode.Backspace or key==Enum.KeyCode.Delete) and "None" or table.concat(parts,"+"));return
  end
  if focused then if key==Enum.KeyCode.Escape and focused:IsDescendantOf(self.Gui) then if self._editCancel then self._editCancel() end;focused:ReleaseFocus() end;return end
  if not self.Options.Embedded and key==self.ToggleKey then self:Toggle();return end
  if self.Visible and key==Enum.KeyCode.Escape then if #self._popups>0 then self:_closePopups(#self._popups) elseif self.Page~="Modules" then self:SetPage("Modules") else self:SetVisible(false) end;return end
  if self.Visible and key==Enum.KeyCode.F and (Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)) then
   if self.Page=="Modules" and self.Layout=="Neverlose" then self.NLSearch:CaptureFocus() else self:SetPage("Search");self.SearchInput:CaptureFocus() end;return
  end
  if not self.Options.Embedded and not processed then for _,g in ipairs(self._modules) do
   local parts={};for part in g.Key:gmatch("[^+]+") do parts[#parts+1]=part end
   if parts[#parts]==key.Name then local ready=true;for i=1,#parts-1 do if not Input:IsKeyDown(Enum.KeyCode[parts[i]]) then ready=false end end;if ready then g:SetEnabled(not g.Enabled) end end
  end end
 end)
 self:_on(self.Gui:GetPropertyChangedSignal("AbsoluteSize"),function() self:_fit();self:_invalidate() end)
end
function Window:_hud() self:_createHUD() end
function Window:_stepHUD() self:_refreshHUD() end
function Window:Destroy()
 if self._dead then return end;self._dead=true;self._drag=nil;self._gesture=nil;self:_closePopups()
 for root in pairs(self._transitions) do self:_cancelTransition(root,true) end
 for _,tw in pairs(self._tweens) do tw:Cancel() end;table.clear(self._tweens);self._scope:Clean()
end
function Window:Inspect()
 local entries={};for _,e in ipairs(self._entries) do entries[#entries+1]={id=e.Group.Id,x=e.Frame.Position.X.Offset,y=e.Frame.Position.Y.Offset,w=e.Frame.Size.X.Offset,h=e.Frame.Size.Y.Offset} end
 return {version=UI.Version,layout=self.Layout,preset=self.Preset,page=self.Page,scale=self._scale,width=self._width,height=self._height,entries=entries,popups=#self._popups}
end
function UI.new(options)
 assert(Run:IsClient(),"Jackal UI must run on the client");options=options or {};assert(options.FontFace==nil or typeof(options.FontFace)=="Font","FontFace must be a Roblox Font");local player=Players.LocalPlayer
 local parent=options.Parent or player and player:WaitForChild("PlayerGui",10);assert(parent,"PlayerGui unavailable")
 local namespace=options.Name or "JackalUI";local old=parent:FindFirstChild(namespace)
 if old then local shutdown=old:FindFirstChild("Shutdown");if shutdown then shutdown:Fire() end;old:Destroy() end
 local self=setmetatable({Options=options,Player=player,Language=options.Language or "English",Layout=options.Layout or "Dropdown",Preset=options.Preset or "Vape",Page=options.Page or "Modules",Category=options.Category or "Render",RequestedScale=options.Scale or UI.DefaultScale,Visible=true,Query="",_scope=Scope.new(),_modules={},_byId={},_categories={},_expanded={},_collapsed={},_positions={},_entries={},_popups={},_motions={},_profiles={},_tweens=setmetatable({},{__mode="k"}),_transitions={},_toastAt=-100,ReducedMotion=options.ReducedMotion==true},Window)
 assert(table.find(LAYOUT_NAMES,self.Layout) and PRESETS[self.Preset],"Unknown layout or preset")
 assert(finite(self.RequestedScale) and self.RequestedScale>=.5 and self.RequestedScale<=(options.Embedded and 4 or 2),"Invalid scale")
 self.Theme=clone(PRESETS[self.Preset]);self.Accent=NAMED[self.Theme["Module Background Color (Enabled)"]] or 0x55C25F;self.ToggleKey=options.ToggleKey or Enum.KeyCode.RightShift;if type(self.ToggleKey)=="string" then self.ToggleKey=Enum.KeyCode[self.ToggleKey] end
 self.Gui=create("ScreenGui",parent,{Name=namespace,ResetOnSpawn=false,IgnoreGuiInset=false,ScreenInsets=Enum.ScreenInsets.CoreUISafeInsets,ClipToDeviceSafeArea=true,DisplayOrder=options.DisplayOrder or 90,ZIndexBehavior=Enum.ZIndexBehavior.Sibling});self._scope.root=self.Gui
 local shutdown=create("BindableEvent",self.Gui,{Name="Shutdown"});self:_on(shutdown.Event,function() self:Destroy() end)
 self._changed=create("BindableEvent",self.Gui,{Name="Changed"});self.Changed=self._changed.Event
 self:_hud()
 self.Main=create("Frame",self.Gui,{Name="JackalClickGUI",BackgroundColor3=color(0x090B10),BackgroundTransparency=options.Embedded and 1 or .25,Size=UDim2.fromScale(1,1),ZIndex=10});self.ScaleObject=create("UIScale",self.Main,{Scale=1})
 self.Backdrop=create("TextButton",self.Main,{Name="InputBackdrop",Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,Active=true,Modal=true,ZIndex=0})
 self:_on(self.Backdrop.Activated,function(input)
  if self.Visible and self.Page=="Modules" and self.Layout=="Neverlose" then
   local p=input and self:_inputPoint(input) or Input:GetMouseLocation()-self.Gui.AbsolutePosition;local a=self.NL.AbsolutePosition-self.Gui.AbsolutePosition;local size=self.NL.AbsoluteSize
   if p.X<a.X or p.X>a.X+size.X or p.Y<a.Y or p.Y>a.Y+size.Y then self:SetVisible(false) end
  end
 end)
 self:_chrome();self:_fit()
 for _,category in ipairs(options.Categories or CATEGORY_NAMES) do self:AddCategory(category) end
 for _,def in ipairs(options.Modules or {}) do self:AddModule(def) end
 if not table.find(self._categories,self.Category) then self.Category=self._categories[1] end
 local styler=self._byId.GUIStyler;if styler and styler._definitions["Style preset"] then styler.Values["Style preset"]=self.Preset end
 self:_settingsModels();self:_initComponents();self._built=true;self:_fit();self:_loadProfiles();self:_invalidate();self:_input()
 self.MenuBlocker=create("TextButton",self.Main,{Name="ClosingInputGuard",BackgroundTransparency=1,Text="",AutoButtonColor=false,Size=UDim2.fromScale(1,1),Active=true,Visible=false,ZIndex=9999})
 local mobile=field(self.Gui,0,0,36,36);mobile.Name="TouchMenu";mobile.Position=UDim2.new(1,-52,1,-52);mobile.Text="J";mobile.TextColor3=color(0xA8DD9D);mobile.TextSize=18;mobile.Visible=Input.TouchEnabled and not options.Embedded;mobile.ZIndex=1000;corner(mobile,18)
 self:_on(mobile.Activated,function() self:Toggle() end)
 local elapsed=0
 self:_on(Run.RenderStepped,function(dt)
  self:_stepEffects(dt)
  self:_tickTransitions(dt)
  for owner,step in pairs(self._motions) do if owner.Parent then step(dt) end end
  if self._layoutDirty then self._layoutDirty=false;self:_layout() end
  elapsed+=dt
  if elapsed>.08 then elapsed=0;self:_stepHUD();if self.Page=="Modules" and self.Visible then for _,e in ipairs(self._entries) do e.Refresh() end end end
  if os.clock()-self._toastAt>2.2 then self.Toast.TextTransparency=math.min(1,self.Toast.TextTransparency+dt*4);self.Toast.BackgroundTransparency=.18+.82*self.Toast.TextTransparency;if self.Toast.TextTransparency==1 then self.Toast.Visible=false end end
 end)
 self:_on(self.Gui.Destroying,function() if not self._dead then self:Destroy() end end)
 if options.Visible==false then self.Visible=false;self.Main.Visible=false;self:_applyComponents() end
 return self
end

return UI

end)()
uiDiagnostics.Stage="声明 Syntax UI 与模糊核心"
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
local UI={ArrayLayoutVersion="2026-10-11.1",ToolbarVersion="2026-10-11.2",BlurVersion="2026-10-17.SampledV8",HUDEffectsVersion="2026-10-18.V9.13",DefaultScale=1.05,JackalStylesVersion="2026-10-16.3",Styles={"Neverlose","Opai","Jackal Neverlose","Jackal Opai"}}
local language="English"
local translations={
  ["Combat"]="战斗",["Targets"]="目标",["Movement"]="移动",["Player"]="玩家",["Visual"]="视觉",["Visuals"]="视觉",["Misc"]="杂项",["Miscellaneous"]="杂项",["HUD Editor"]="界面编辑",["Configs"]="配置",["Enabled"]="启用",["Disabled"]="禁用",["Save"]="保存",["Load"]="载入",["Delete"]="删除",["Apply"]="应用",["Search"]="搜索",["Appearance"]="外观",["UI scale"]="界面缩放",["HUD scale"]="HUD缩放",["Accent color"]="强调色",["Source colors"]="原始配色",["Flowing colors"]="流光配色",["Animations: On"]="动画：开",["Animations: Off"]="动画：关",["Animation speed"]="动画速度",["Island background transparency"]="灵动岛背景透明度",["Island Background Transparency"]="灵动岛背景透明度",["Jackal Neverlose"]="Jackal Neverlose",["Jackal Opai"]="Jackal Opai",["Island animation speed"]="灵动岛动画速度",["Island Animation Speed"]="灵动岛动画速度",["Island shadow"]="灵动岛阴影",["Island Shadow Strength"]="灵动岛阴影强度",["Local blur"]="局部模糊",["Saved configurations"]="已保存配置",["Create configuration"]="新建配置",["No modules found"]="未找到模块",["Background"]="背景",["Shadow"]="阴影",["Categories"]="分类",["Lowercase"]="小写",["Show suffix"]="显示后缀",["Right line"]="右侧线条",["Widgets"]="组件",["Array List mode"]="功能列表样式",["Glow renderer"]="辉光渲染器",["Smooth Glow strength"]="柔光强度",["Smooth Glow radius"]="柔光半径",["Smooth Glow layers"]="柔光层数",["XHan Glow"]="功能列表辉光",["Local Blur strength"]="菜单模糊强度",["Local Blur softness"]="菜单柔化程度",["Island Blur strength"]="灵动岛模糊强度",["Island Blur softness"]="灵动岛柔化程度",["ArrayList Blur strength"]="功能列表模糊强度",["ArrayList Blur softness"]="功能列表柔化程度",["TargetHUD Blur strength"]="目标显示模糊强度",["TargetHUD Blur softness"]="目标显示柔化程度",["WaterMark Blur strength"]="水印模糊强度",["WaterMark Blur softness"]="水印柔化程度",["Local Blur radius"]="菜单模糊半径",["Island Blur radius"]="灵动岛模糊半径",["BloomFlow Blur radius"]="BloomFlow 模糊半径",["TargetHUD Blur radius"]="目标显示模糊半径",["ArrayList Shadow"]="功能列表阴影",["ArrayList Shadow strength"]="功能列表阴影强度",["ArrayList Shadow radius"]="功能列表阴影半径",["ArrayList Shadow layers"]="功能列表阴影层数",["Island State Duration"]="灵动岛状态停留时间（秒）",["HUD Color source"]="HUD 配色来源",["Palette"]="列表配色",["WaterMark Text size"]="水印字号",["BloomFlow Corner radius"]="列表阶梯圆角半径",["ArrayList Blur"]="功能列表模糊",["ArrayList Blur radius"]="功能列表模糊半径",["WaterMark"]="水印",["WaterMark Blur"]="水印模糊",["WaterMark Blur radius"]="水印模糊半径",["WaterMark Glow"]="水印辉光",["WaterMark Glow strength"]="水印辉光强度",["WaterMark Glow radius"]="水印辉光半径",["WaterMark Glow layers"]="水印辉光层数",["WaterMark Flow speed"]="水印流光速度",["WaterMark Background opacity"]="水印底板不透明度",["Island Blur"]="灵动岛模糊",["BloomFlow Blur"]="BloomFlow 模糊",["TargetHUD Blur"]="目标显示模糊",["TargetHUD Glow"]="目标显示辉光",["TargetHUD Glow strength"]="目标辉光强度",["TargetHUD Glow radius"]="目标辉光半径",["TargetHUD Glow layers"]="目标辉光层数",["Original"]="原版",["Range"]="范围",["Speed"]="速度",["Mode"]="模式",["Color"]="颜色",["Scale"]="缩放",["Players"]="玩家",["Items"]="物品",["Health bar"]="生命条",["Outline"]="描边",["Opacity"]="不透明度",["Width"]="宽度",["Height"]="高度",["Size"]="大小",["Distance"]="距离",["Rotation"]="旋转",["Theme"]="主题",["Style"]="样式",["Language"]="语言",["None"]="无",["Default"]="默认",["Opai"]="Opai",["XHan"]="XHan",["Click GUI"]="点击界面",["Full Bright"]="全亮",["Name Tags"]="名称标签",["Target HUD"]="目标面板",["Dynamic Island"]="灵动岛",["ArrayList"]="功能列表"
}
local words={Max="最大",Min="最小",Auto="自动",Target="目标",Targets="目标",Show="显示",Hide="隐藏",Health="生命",Armor="护甲",Effect="效果",Effects="效果",Rendering="渲染",Render="渲染",Mode="模式",Speed="速度",Range="范围",Strength="强度",Background="背景",Shadow="阴影",Size="大小",Width="宽度",Height="高度",Color="颜色",Colors="颜色",Glow="发光",Text="文字",Font="字体",Scale="缩放",Island="灵动岛",Delay="延迟",Distance="距离",Duration="时长",Time="时间",Damage="伤害",Chance="概率",Count="数量",Amount="数量",Interval="间隔",Radius="半径",Angle="角度",Offset="偏移",Vertical="垂直",Horizontal="水平",Threshold="阈值",Priority="优先级",Players="玩家",Player="玩家",Blocks="方块",Block="方块",Items="物品",Item="物品",Inventory="背包",Potion="药水",Session="会话",Movement="移动",Combat="战斗",Visual="视觉",Enabled="启用",Disabled="禁用",Apply="应用",Lowercase="小写",Suffix="后缀",Categories="分类",Animation="动画",Animations="动画",Right="右",Left="左",None="无",Default="默认"}
-- Presentation only: never translate module IDs, setting keys or saved values.
local moduleNames={
 ["全图连发"]="Map Burst",["单次全载具弱点打击"]="Vehicle Weakpoint Strike",["载具帧频轰炸"]="Vehicle Frame Burst",
 ["增强静默瞄准"]="SilentAim Pro",["SilentAim 队伍检测"]="SilentAim Team Check",["SilentAim 墙体检测"]="SilentAim Wall Check",["SilentAim 概率追踪"]="SilentAim Probability Tracking",["SilentAim 追踪概率"]="SilentAim Tracking Chance",["显示 SilentAim FOV"]="Show SilentAim FOV",["SilentAim FOV 半径"]="SilentAim FOV Radius",["SilentAim 目标高亮"]="SilentAim Target Highlight",
 ["队友载具弹药监控"]="Team Vehicle Ammo Monitor",["命中框扩展"]="Hitbox Expansion",["命中框大小"]="Hitbox Size",["命中框部位"]="Hitbox Part",["镜头瞄准"]="Aimbot",["瞄准队伍检测"]="Aim Team Check",["瞄准墙体检测"]="Aim Wall Check",["瞄准平滑度"]="Aim Smoothness",["瞄准FOV"]="Aim FOV",["瞄准部位"]="Aim Part",["无限弹药"]="Infinite Ammo",["彩色弹道轨迹"]="Bullet Tracers",["命中标记"]="Hit Marker",["战斗缩放状态"]="Combat Zoom",["显示镜头FOV圈"]="Show Camera FOV",
 ["移动速度开关"]="Walk Speed",["移动速度"]="Walk Speed Value",["跳跃高度开关"]="Jump Height",["跳跃高度"]="Jump Height Value",["视野范围开关"]="Camera FOV",["视野范围"]="Camera FOV Value",["穿墙模式"]="Noclip",["无限跳跃"]="Infinite Jump",["无限体力"]="Infinite Stamina",["全亮模式"]="Full Bright",["幽灵模式"]="Ghost Mode",["载具飞行"]="Vehicle Fly",["旋转模式 SpinBot"]="SpinBot",["SpinBot 速度"]="SpinBot Speed",["即时交互"]="Instant Interact",
 ["人物透视"]="Player ESP",["载具透视"]="Vehicle ESP",["通风口透视"]="Vent ESP",["可破坏物透视"]="Destructible ESP",["水坑透视"]="Puddle ESP",["污渍透视"]="Stain ESP",["显示瞄准FOV圈"]="Show Aim FOV",
 ["启用 Adonis Bypass"]="Adonis Bypass",["重新加入服务器"]="Rejoin Server",["聊天日志"]="Chat Logs",["紧急关闭新增功能"]="Emergency Disable",["自动兑换码"]="Auto Redeem Codes",["自动拖地"]="Auto Mop",["自动擦玻璃"]="Auto Clean Windows",["自动修理"]="Auto Repair",["破坏设备"]="Destroy Devices",["破坏设备攻击模式"]="Device Attack Mode",["破坏设备攻击频率（×0.01秒）"]="Device Attack Interval (x0.01s)",["破坏设备攻击距离（Stud）"]="Device Attack Range (studs)",["破坏设备无限制模式"]="Device Unlimited Mode",
 ["保存配置"]="Save Config",["读取配置"]="Load Config",["重置主要状态"]="Reset Main State",["隐藏主 UI"]="Hide Main UI",["立即打开主 UI"]="Open Main UI",["回到第一个页面"]="Return to First Page",["功能列表样式"]="ArrayList Style",["UI 样式设置"]="UI Style Settings",["UI字体样式"]="UI Font",["UI字体颜色"]="UI Font Color",["RageBot 攻击间隔 (×0.01秒)"]="RageBot Attack Interval (x0.01s)",["RageBot 搜索范围"]="RageBot Search Range",
 ["SilentAim 目标类型"]="SilentAim Target Types",["SilentAim 目标部位"]="SilentAim Target Part",["SilentAim 瞄准模式"]="SilentAim Aim Mode",["SilentAim 特殊模式"]="SilentAim Special Mode",
 ["FOV 半径"]="FOV Radius",["玩家+NPC"]="Players + NPCs",["单体攻击"]="Single Attack",["群体攻击"]="Group Attack",["纯白"]="White",["纯黑"]="Black",["冷灰白"]="Cool Gray",["冰蓝"]="Ice Blue",["薄荷青"]="Mint",["樱粉"]="Cherry Pink",["浅紫"]="Lilac",["暖金"]="Warm Gold",
 ["队伍检测"]="Team Check",["墙体检测"]="Wall Check",["概率追踪"]="Probability Tracking",["追踪概率"]="Tracking Chance",["目标高亮"]="Target Highlight",["目标类型"]="Target Types",["目标部位"]="Target Part",["瞄准模式"]="Aim Mode",["特殊模式"]="Special Mode",
 ["静默瞄准"]="SilentAim",["静默瞄准增强版"]="SilentAim Pro",["Module Toggled"]="Module Toggled",
}
for zh,en in pairs(moduleNames) do
 if zh~=en then translations[en]=zh end
end
translations["Module Toggled"]="功能状态"
translations["Recording blur preset"]="录屏模糊预设"
translations["Local Blur"]="局部模糊"
translations["SilentAim"]="静默瞄准"
translations["AutoPowerOrder++"]="自动电力订单++"
translations["RageBot"]="暴力瞄准"
-- These remain the source name in Chinese; the English equivalents use the same resolver.
local englishNames={}
local orderedNames={}
for en in pairs(translations) do orderedNames[#orderedNames+1]=en end
table.sort(orderedNames)
for _,en in ipairs(orderedNames) do local zh=translations[en];if not englishNames[zh] then englishNames[zh]=en end end
for zh,en in pairs(moduleNames) do englishNames[zh]=en end
local function translateSource(value)
 value=tostring(value or "")
 if language=="English" then return moduleNames[value] or englishNames[value] or value end
 local english=moduleNames[value] or englishNames[value] or value
 if translations[english] then return translations[english] end
 return value
end

local function localize(value)
 local translated=translateSource(value)
 if translated~=value or language~="中文" then return translated end
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
 return (detail~="" and detail.." " or "")..localize(enabled and "Enabled" or "Disabled").."."
end
local SampledLocalBlur=(function()
-- Syntax sampled local blur V9.2. Shared by the library and standalone UI test.
-- Base-color reconstruction, not a framebuffer capture. No independent render binding.
local LocalBlur={Version="2026-10-18.RecordedLightDetail"}
LocalBlur.Defaults={refresh=120,radius=1,strength=100,edge=100,smooth=100,columns=81,sampleRows=65,
 renderColumns=97,band=1,transparency=100,brightness=100,saturation=100,distance=100,budget=6.5,idle=30,
 nodes=768,skyR=107,skyG=143,skyB=184,frameSync=true,adaptive=true,guard=24}
local ranges={refresh={5,120},radius={0,120},strength={0,100},edge={0,100},smooth={0,100},columns={25,81},
 sampleRows={17,65},renderColumns={17,97},band={1,4},transparency={0,100},brightness={50,150},saturation={0,150},
 distance={100,3000},budget={1,8},idle={1,30},nodes={128,768},skyR={0,255},skyG={0,255},skyB={0,255},guard={0,96}}
local function validated(base,patch)
 assert(type(patch)=="table","Local blur profile must be a table")
 local result=table.clone(base)
 for key,value in pairs(patch) do
  local r=ranges[key]
  if r then
   assert(type(value)=="number" and value==value and value>=r[1] and value<=r[2],"Invalid local blur setting: "..key)
   if key=="columns" or key=="sampleRows" or key=="renderColumns" or key=="nodes" then assert(value%1==0,"Expected whole number: "..key) end
  else assert((key=="frameSync" or key=="adaptive") and type(value)=="boolean","Unknown local blur setting: "..tostring(key)) end
  result[key]=value
 end
 return result
end
function LocalBlur.Profile(patch) return validated(LocalBlur.Defaults,patch or {}) end
local function make(class,parent,properties)
 local object=Instance.new(class)
 if class=="Frame" or class=="ImageLabel" then object.BorderSizePixel=0 end
 for key,value in pairs(properties) do object[key]=value end
 object.Parent=parent;return object
end
local function checkpoint() coroutine.yield() end
local function finite(n) return type(n)=="number" and n==n and n>-math.huge and n<math.huge end
local function validBounds(b) return type(b)=="table" and finite(b.x) and finite(b.y) and finite(b.w) and finite(b.h) and b.w>8 and b.h>8 end
local function cloneBounds(b) return b and {x=b.x,y=b.y,w=b.w,h=b.h} or nil end
local function cameraSnapshot(camera,screenCoordinates)
 local size=camera.ViewportSize;local w,h=math.max(1,size.X),math.max(1,size.Y)
 local function ray(x,y)
  if screenCoordinates then return camera:ScreenPointToRay(x,y,0) end
  return camera:ViewportPointToRay(x,y,0)
 end
 local center=ray(w*.5,h*.5)
 local normal=camera.CFrame.LookVector or center.Direction.Unit
 local function plane(x,y)
  local direction=ray(x,y).Direction
  return direction/math.max(.00001,direction:Dot(normal))
 end
 local a=plane(0,0)
 return {origin=center.Origin,a=a,dx=plane(w,0)-a,dy=plane(0,h)-a,w=w,h=h}
end

-- One continuous, opaque RGB texture removes per-band raster seams when image APIs are available.
-- Permission/size/write failures fall back once to the borderless gradient renderer.
local TEX_W,TEX_H=256,128
local TextureSurface={Width=TEX_W,Height=TEX_H}
function TextureSurface.new()
 local self={ready=false,reason=nil,image=nil,content=nil}
 local ok,err=pcall(function()
  self.image=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(TEX_W,TEX_H)})
  assert(self.image,"EditableImage unavailable")
  self.content=Content.fromObject(self.image)
 end)
 if ok then self.ready=true else
  self.reason=tostring(err)
  if self.image then self.image:Destroy();self.image=nil end
 end
 function self:Commit(pixels)
  local success,message=pcall(function() self.image:WritePixelsBuffer(Vector2.new(0,0),Vector2.new(TEX_W,TEX_H),pixels) end)
  if not success then self.ready=false;self.reason=tostring(message) end
  return success
 end
 function self:Present(view,info,bounds,profile,opacity,masks,masked)
  if not info.texture or not self.content then return false end
  local lp,ls=view.layer.Position,view.layer.Size
  local ox,oy=lp.X.Scale*bounds.w,lp.Y.Scale*bounds.h
  local sw,sh=ls.X.Scale*bounds.w,ls.Y.Scale*bounds.h
  view.imageViews=view.imageViews or {}
  local shapes=masked and (masks or {}) or {{x=0,y=0,w=1,h=1}}
  local used=0
  for _,mask in ipairs(shapes) do
   if mask.w>0 and mask.h>0 and (mask.alpha or 1)>.001 then
    used+=1;local slot=view.imageViews[used]
    if not slot then
     local image=make("ImageLabel",view.layer,{Name="LocalBlurTexture",BackgroundTransparency=1,BorderSizePixel=0,Active=false,ZIndex=1,ScaleType=Enum.ScaleType.Stretch,ResampleMode=Enum.ResamplerMode.Default})
     slot={image=image,corner=make("UICorner",image,{CornerRadius=UDim.new(0,0)})};view.imageViews[used]=slot
    end
    local x,y,w,h=mask.x*bounds.w,mask.y*bounds.h,mask.w*bounds.w,mask.h*bounds.h
    local alpha=profile.strength/100*opacity*(mask.alpha or 1)
    if slot.image.Parent~=view.layer then slot.image.Parent=view.layer end
    slot.image.Visible=true;slot.image.ImageContent=self.content
    if not mask.band then
     slot.image.Position=UDim2.fromScale((x-ox)/sw,(y-oy)/sh)
     slot.image.Size=UDim2.fromScale(w/sw,h/sh)
     slot.image.ImageRectOffset=Vector2.new((x-ox)/sw*TEX_W,(y-oy)/sh*TEX_H)
     slot.image.ImageRectSize=Vector2.new(w/sw*TEX_W,h/sh*TEX_H)
    end
    slot.image.ImageTransparency=1-alpha
    -- Per-corner list contour clips reuse the SAME sampled texture. Four
    -- disjoint native clips avoid translucent overlap and row sampling jobs.
    local custom=mask.tl~=nil
    slot.image.Visible=not custom
    if custom then
     slot.quads=slot.quads or {}
     local radii={mask.tl,mask.tr,mask.br,mask.bl}
     for i=1,4 do
      local q=slot.quads[i]
      if not q then
       local clip=make("Frame",view.layer,{Name="LocalBlurCornerClip",BackgroundTransparency=1,ClipsDescendants=true,Active=false,ZIndex=1})
       local image=make("ImageLabel",clip,{Name="LocalBlurTexture",BackgroundTransparency=1,BorderSizePixel=0,Active=false,ZIndex=1,Size=UDim2.fromScale(2,2),ScaleType=Enum.ScaleType.Stretch,ResampleMode=Enum.ResamplerMode.Default})
       q={clip=clip,image=image,corner=make("UICorner",image,{CornerRadius=UDim.new(0,0)})};slot.quads[i]=q
      end
      local right=i==2 or i==3;local bottom=i>=3
      q.clip.Visible=true;q.clip.Position=UDim2.fromScale((x+(right and w/2 or 0)-ox)/sw,(y+(bottom and h/2 or 0)-oy)/sh);q.clip.Size=UDim2.fromScale(w/2/sw,h/2/sh)
      q.image.Position=UDim2.fromScale(right and -1 or 0,bottom and -1 or 0)
      q.image.ImageContent=self.content;q.image.ImageRectOffset=slot.image.ImageRectOffset;q.image.ImageRectSize=slot.image.ImageRectSize;q.image.ImageTransparency=1-alpha
      local radius=math.min((radii[i] or 0)*bounds.h,w/2,h/2)
      q.corner.CornerRadius=UDim.new(radius/math.max(1,math.min(w,h)),0)
      local tintAlpha=masked and (1-profile.transparency/100)*opacity*(mask.alpha or 1) or 0
      if tintAlpha>0 and not q.tint then
       q.tint=make("Frame",q.image,{Name="MaskedBlurTint",BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(12,16,25),Size=UDim2.fromScale(1,1),ZIndex=2})
       q.tintCorner=make("UICorner",q.tint,{CornerRadius=UDim.new(0,0)})
      end
      if q.tint then q.tint.Visible=tintAlpha>0;q.tint.BackgroundTransparency=1-tintAlpha;q.tintCorner.CornerRadius=q.corner.CornerRadius end
     end
    elseif slot.quads then for _,q in ipairs(slot.quads) do q.clip.Visible=false end end
    -- Radius is expressed as a fraction of the mask's own shorter side, never multiplied by UIScale twice.
    local radius=math.min((mask.radius or 0)*bounds.h,w/2,h/2)
    slot.corner.CornerRadius=UDim.new(radius/math.max(1,math.min(w,h)),0)
    local tintAlpha=masked and (1-profile.transparency/100)*opacity*(mask.alpha or 1) or 0
    if tintAlpha>0 and not slot.tint then
     slot.tint=make("Frame",slot.image,{Name="MaskedBlurTint",BorderSizePixel=0,BackgroundColor3=Color3.fromRGB(12,16,25),Size=UDim2.fromScale(1,1),ZIndex=2})
     slot.tintCorner=make("UICorner",slot.tint,{CornerRadius=UDim.new(0,0)})
    end
    if slot.tint then slot.tint.Visible=tintAlpha>0;slot.tint.BackgroundTransparency=1-tintAlpha;slot.tintCorner.CornerRadius=slot.corner.CornerRadius end
    if mask.band then
     -- No one-pixel ClipsDescendants containers. Snap shared SCREEN edges once,
     -- then use a bounded, nonzero integer texture crop directly on the image.
     local left=math.floor(bounds.x+x+.5)-bounds.x
     local top=math.floor(bounds.y+y+.5)-bounds.y
     local right=math.floor(bounds.x+x+w+.5)-bounds.x
     local bottom=math.floor(bounds.y+y+h+.5)-bounds.y
     slot.image.Visible=right>left and bottom>top
     slot.image.Position=UDim2.fromOffset(left-ox,top-oy)
     slot.image.Size=UDim2.fromOffset(math.max(0,right-left),math.max(0,bottom-top))
     local sx=math.clamp(math.floor((left-ox)/sw*TEX_W),0,TEX_W-1)
     local sy=math.clamp(math.floor((top-oy)/sh*TEX_H),0,TEX_H-1)
     local ex=math.clamp(math.ceil((right-ox)/sw*TEX_W),sx+1,TEX_W)
     local ey=math.clamp(math.ceil((bottom-oy)/sh*TEX_H),sy+1,TEX_H)
     slot.image.ImageRectOffset=Vector2.new(sx,sy)
     slot.image.ImageRectSize=Vector2.new(ex-sx,ey-sy)
    end
   end
  end
  for i=used+1,#view.imageViews do local slot=view.imageViews[i];slot.image.Visible=false;if slot.quads then for _,q in ipairs(slot.quads) do q.clip.Visible=false end end end
  return true
 end
 function self:Destroy() if self.image then self.image:Destroy();self.image=nil end;self.content=nil;self.ready=false end
 return self
end
-- Reuse a normalized horizontal lookup; unpack colors once per control point,
-- instead of repeating integer channel extraction for every output texel.
function TextureSurface.newPixels() return buffer.create(TEX_W*TEX_H*4) end
local rowLookup={}
local channelR,channelG,channelB={},{},{}
function TextureSurface.row(pixels,y,codes,count)
 local lookup=rowLookup[count]
 if not lookup then
  lookup={}
  for x=0,TEX_W-1 do
   local gx=x/(TEX_W-1)*(count-1);local ix=math.min(count-2,math.floor(gx))
   lookup[x+1]={ix+1,gx-ix}
  end
  rowLookup[count]=lookup
 end
 for i=1,count do
  local code=codes[i]
  channelR[i]=math.floor(code/65536);channelG[i]=math.floor(code/256)%256;channelB[i]=code%256
 end
 for x=0,TEX_W-1 do
  local p=lookup[x+1];local i,t=p[1],p[2]
  local r=channelR[i]+(channelR[i+1]-channelR[i])*t
  local g=channelG[i]+(channelG[i+1]-channelG[i])*t
  local b=channelB[i]+(channelB[i+1]-channelB[i])*t
  buffer.writeu32(pixels,(y*TEX_W+x)*4,math.round(r)+math.round(g)*256+math.round(b)*65536+4278190080)
 end
end

local function horizontal(source,target,w,h,q)
 local r=math.floor(q);local f=q-r;local n=2*r+1+2*f
 for y=0,h-1 do
  local row=y*w;local rr,gg,bb=0,0,0
  for k=-r,r do local p=(row+math.clamp(k,0,w-1))*3;rr+=source[p+1];gg+=source[p+2];bb+=source[p+3] end
  for x=0,w-1 do
   local a=(row+math.clamp(x-r-1,0,w-1))*3;local b=(row+math.clamp(x+r+1,0,w-1))*3;local p=(row+x)*3
   target[p+1]=(rr+f*(source[a+1]+source[b+1]))/n
   target[p+2]=(gg+f*(source[a+2]+source[b+2]))/n
   target[p+3]=(bb+f*(source[a+3]+source[b+3]))/n
   a=(row+math.clamp(x-r,0,w-1))*3
   rr+=source[b+1]-source[a+1];gg+=source[b+2]-source[a+2];bb+=source[b+3]-source[a+3]
  end
  if y%2==1 then checkpoint() end
 end
end
local function vertical(source,target,w,h,q)
 local r=math.floor(q);local f=q-r;local n=2*r+1+2*f
 for x=0,w-1 do
  local rr,gg,bb=0,0,0
  for k=-r,r do local p=(math.clamp(k,0,h-1)*w+x)*3;rr+=source[p+1];gg+=source[p+2];bb+=source[p+3] end
  for y=0,h-1 do
   local a=(math.clamp(y-r-1,0,h-1)*w+x)*3;local b=(math.clamp(y+r+1,0,h-1)*w+x)*3;local p=(y*w+x)*3
   target[p+1]=(rr+f*(source[a+1]+source[b+1]))/n
   target[p+2]=(gg+f*(source[a+2]+source[b+2]))/n
   target[p+3]=(bb+f*(source[a+3]+source[b+3]))/n
   a=(math.clamp(y-r,0,h-1)*w+x)*3
   rr+=source[b+1]-source[a+1];gg+=source[b+2]-source[a+2];bb+=source[b+3]-source[a+3]
  end
  if x%2==1 then checkpoint() end
 end
end
local function mono(a,b,c,d,t)
 local delta=c-b
 if delta==0 or t==0 then return b end
 local left=b-a;local right=d-c
 local m0=left*delta<=0 and 0 or 2*left*delta/(left+delta)
 local m1=right*delta<=0 and 0 or 2*right*delta/(right+delta)
 local t2=t*t;local t3=t2*t
 return math.clamp((2*t3-3*t2+1)*b+(t3-2*t2+t)*m0+(-2*t3+3*t2)*c+(t3-t2)*m1,math.min(b,c),math.max(b,c))
end

local function resolveEdges(base,target,w,h,originX,originY,stepX,stepY,amount,readAt)
 local count=0;local limit=math.max(1,math.floor(w*h*.08))
 for y=0,h-1 do
  for x=0,w-1 do
   local p=(y*w+x)*3
   local r,g,b=base[p+1],base[p+2],base[p+3]
   local contrast=0
   local left=(y*w+math.max(0,x-1))*3
   local right=(y*w+math.min(w-1,x+1))*3
   local up=(math.max(0,y-1)*w+x)*3
   local down=(math.min(h-1,y+1)*w+x)*3
   for channel=1,3 do
    local value=base[p+channel]
    contrast=math.max(contrast,math.abs(value-base[left+channel]),math.abs(value-base[right+channel]),math.abs(value-base[up+channel]),math.abs(value-base[down+channel]))
   end
   if contrast>.08 and count<limit then
    local px,py=originX+x*stepX,originY+y*stepY
    local rr,gg,bb=r,g,b
    for iy=-1,1,2 do
     for ix=-1,1,2 do
      local ar,ag,ab=readAt(px+ix*.35*stepX,py+iy*.35*stepY)
      rr+=ar;gg+=ag;bb+=ab
     end
     checkpoint()
    end
    r+=(rr/5-r)*amount;g+=(gg/5-g)*amount;b+=(bb/5-b)*amount
    count+=1
   end
   target[p+1]=r;target[p+2]=g;target[p+3]=b
   if x%16==15 then checkpoint() end
  end
 end
 return count
end


function LocalBlur.new(host,options)
 options=options or {}
 local profile=LocalBlur.Profile(options.Profile)
 local player=game:GetService("Players").LocalPlayer
 local root=make("Frame",host,{Name="SyntaxSampledLocalBlur",BackgroundTransparency=1,BorderSizePixel=0,ClipsDescendants=true,
  Position=UDim2.fromScale(0,0),Size=UDim2.fromScale(1,1),ZIndex=0,Visible=false})
 local tint=make("Frame",root,{Name="LocalBlurTint",BorderSizePixel=0,Size=UDim2.fromScale(1,1),
  BackgroundColor3=Color3.fromRGB(12,16,25),BackgroundTransparency=profile.transparency/100,ZIndex=1})
 local function createBuffer(name)
  return {layer=make("Frame",root,{Name=name,BackgroundTransparency=1,BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=0,Visible=false}),entries={},count=0}
 end
 local new=make
 local front,back=createBuffer("LocalBlurFront"),createBuffer("LocalBlurBack")
 local source,temp,filtered,ping,refined={},{},{},{},{}
 local params=RaycastParams.new();params.FilterType=Enum.RaycastFilterType.Exclude;params.IgnoreWater=false
 local job,frontInfo,current=nil,nil,nil
 local active,dead,failed=false,false,false
 local wasEnabled=false
 local destroyConnection=nil
 local version,completed,elapsed,slow=0,0,1,0
 local quality=1
 local force=true
 local reason="warming"
 local lastSlice,totalCPU=0,0
 local opacityFactor=1
 local texture=nil
 tint.Visible=not options.Masked
 local api={Root=root,Version=LocalBlur.Version}
 -- Optional HUD display masks share the sampled image; they never resample per row.
 local masks=nil;local maskRevision=0
 function api:SetMasks(rectangles)
  local changed=not masks or #masks~=#rectangles
  if not changed then
   for i,a in ipairs(rectangles) do
    local b=masks[i]
    if a.x~=b.x or a.y~=b.y or a.w~=b.w or a.h~=b.h or a.radius~=b.radius or a.alpha~=b.alpha or a.tl~=b.tl or a.tr~=b.tr or a.br~=b.br or a.bl~=b.bl or a.band~=b.band then changed=true;break end
   end
  end
  masks=rectangles
  if changed then maskRevision+=1 end
 end
 local function applyMasks(buffer,info,bounds)
  if texture and texture:Present(buffer,info,bounds,profile,opacityFactor,masks,options.Masked) then return end
  if buffer.imageViews then for _,slot in ipairs(buffer.imageViews) do slot.image.Visible=false;if slot.quads then for _,q in ipairs(slot.quads) do q.clip.Visible=false end end end end
  if not options.Masked then return end
  local lp,ls=buffer.layer.Position,buffer.layer.Size
  local ox,oy=lp.X.Scale*bounds.w,lp.Y.Scale*bounds.h
  local sw,sh=ls.X.Scale*bounds.w,ls.Y.Scale*bounds.h
  local cached=buffer.maskCache
  if cached and cached.info==info and cached.bx==bounds.x and cached.by==bounds.y and cached.revision==maskRevision and cached.ox==ox and cached.oy==oy and cached.sw==sw and cached.sh==sh and cached.w==bounds.w and cached.h==bounds.h and cached.strength==profile.strength and cached.radius==profile.radius and cached.opacity==opacityFactor and cached.tint==profile.transparency then return end
  buffer.maskCache={info=info,bx=bounds.x,by=bounds.y,revision=maskRevision,ox=ox,oy=oy,sw=sw,sh=sh,w=bounds.w,h=bounds.h,strength=profile.strength,radius=profile.radius,opacity=opacityFactor,tint=profile.transparency}
  for i=1,buffer.count do
   local e=buffer.entries[i];local used=0
   local x,y=e.x*sw+ox,e.y*sh+oy;local w,h=e.w*sw,e.h*sh
   for _,mask in ipairs(masks or {}) do
    local mx,my,mw,mh=mask.x*bounds.w,mask.y*bounds.h,mask.w*bounds.w,mask.h*bounds.h
    local t,b=math.max(y,my,0),math.min(y+h,my+mh,bounds.h)
    if b>t then
     local function inset(topRadius,bottomRadius)
      local cy=(t+b)*.5-my
      local radius=math.min((cy<mh/2 and topRadius or bottomRadius)*bounds.h,mw/2,mh/2)
      if radius<=0 then return 0 end
      local d=math.max(radius-cy,cy-(mh-radius),0)
      return radius-math.sqrt(math.max(0,radius*radius-d*d))
     end
     local edge=inset(mask.tl or mask.radius or 0,mask.bl or mask.radius or 0)
     local rightEdge=inset(mask.tr or mask.radius or 0,mask.br or mask.radius or 0)
     local l,r=math.max(x,mx+edge,0),math.min(x+w,mx+mw-rightEdge,bounds.w)
     if r>l and (mask.alpha or 1)>.001 then
      used+=1
      -- Flat bands avoid a second, independently rounded 1px Clip frame.
      -- Interior boundaries use the same screen-pixel rounding on both sides.
      if t>my+.001 and t>0 then t=math.clamp(math.floor(bounds.y+t+.5)-bounds.y,my,my+mh) end
      if b<my+mh-.001 and b<bounds.h then b=math.clamp(math.floor(bounds.y+b+.5)-bounds.y,my,my+mh) end
      if l>mx+edge+.001 and l>0 then l=math.clamp(math.floor(bounds.x+l+.5)-bounds.x,mx+edge,mx+mw-rightEdge) end
      if r<mx+mw-rightEdge-.001 and r<bounds.w then r=math.clamp(math.floor(bounds.x+r+.5)-bounds.x,mx+edge,mx+mw-rightEdge) end
      local slot=e.clips[used]
      if not slot then
       local row=new("Frame",buffer.layer,{Name="LocalBlurMask",BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=1})
       slot={row=row,gradient=new("UIGradient",row,{Rotation=0})};e.clips[used]=slot
      end
      slot.row.Visible=b>t and r>l
      slot.row.Position=UDim2.fromScale((l-ox)/sw,(t-oy)/sh)
      slot.row.Size=UDim2.fromScale(math.max(0,r-l)/sw,math.max(0,b-t)/sh)
      local lo,hi=math.clamp((l-x)/w,0,1),math.clamp((r-x)/w,0,1)
      local seq=e.fullSequence
      if slot.sequence~=seq or slot.lo~=lo or slot.hi~=hi then
       local keys=seq.Keypoints
       local function at(t)
        for k=1,#keys-1 do local a,b=keys[k],keys[k+1];if t<=b.Time then return a.Value:Lerp(b.Value,math.clamp((t-a.Time)/(b.Time-a.Time),0,1)) end end
        return keys[#keys].Value
       end
       if lo==0 and hi==1 then slot.gradient.Color=seq
       elseif hi>lo then
        local clipped={ColorSequenceKeypoint.new(0,at(lo))}
        for _,key in ipairs(keys) do if key.Time>lo+1e-6 and key.Time<hi-1e-6 then clipped[#clipped+1]=ColorSequenceKeypoint.new((key.Time-lo)/(hi-lo),key.Value) end end
        clipped[#clipped+1]=ColorSequenceKeypoint.new(1,at(hi))
        slot.gradient.Color=ColorSequence.new(clipped)
       end
       slot.sequence=seq;slot.lo=lo;slot.hi=hi
      end
      local alpha=(e.alpha or 1)*(mask.alpha or 1)
      slot.row.BackgroundTransparency=1-alpha
      local tintAlpha=(1-profile.transparency/100)*opacityFactor*(mask.alpha or 1)
      if tintAlpha>0 and not slot.tint then slot.tint=new("Frame",slot.row,{Name="MaskedBlurTint",BackgroundColor3=Color3.fromRGB(12,16,25),BorderSizePixel=0,Size=UDim2.fromScale(1,1),ZIndex=2}) end
      if slot.tint then slot.tint.Visible=tintAlpha>0;slot.tint.BackgroundTransparency=1-tintAlpha end
     end
    end
   end
   for j=used+1,#e.clips do e.clips[j].row.Visible=false end
   e.row.Visible=used>0
  end
 end
 local function positionBuffer(buffer,info,bounds)
  if not info then return end
  -- Counter-translate within the pre-sampled margins. Larger movements clamp to
  -- the filled texture edge, preserving coverage until a fresh result completes.
  local scaleX,scaleY=bounds.w/info.bounds.w,bounds.h/info.bounds.h
  local guardX,guardY=info.guardX*scaleX,info.guardY*scaleY
  local dx=math.clamp(info.bounds.x-bounds.x,-guardX,guardX)
  local dy=math.clamp(info.bounds.y-bounds.y,-guardY,guardY)
  buffer.layer.Position=UDim2.fromScale((dx-guardX)/bounds.w,(dy-guardY)/bounds.h)
  buffer.layer.Size=UDim2.fromScale(1+guardX*2/bounds.w,1+guardY*2/bounds.h)
 end
 local function updateOpacity()
  tint.BackgroundTransparency=profile.transparency/100
  if not frontInfo then return end
  local alpha=profile.strength/100*math.min(1,profile.radius/math.max(1,math.max(frontInfo.stepX,frontInfo.stepY)*.6))*opacityFactor
  for i=1,front.count do
   local e=front.entries[i]
   if e.alpha~=alpha then e.row.BackgroundTransparency=1-alpha;e.alpha=alpha end
  end
 end
 local function buildFrame(j)
  local c=j.config;local nx,ny=j.nx,j.ny
  local stepX,stepY=j.stepX,j.stepY
  local sx=math.max(c.radius/2.5/stepX,c.smooth/100*1.1)
  local sy=math.max(c.radius/2.5/stepY,c.smooth/100*1.1)
  local qx=math.min(16,(math.sqrt(1+4*sx*sx)-1)/2);local qy=math.min(16,(math.sqrt(1+4*sy*sy)-1)/2)
  local padX,padY=0,0 -- Sample a bounded world-space halo instead of expanding grid dimensions.
  local w,h=nx+padX*2,ny+padY*2
  local originX,originY=j.bounds.x-j.guardX-j.halo,j.bounds.y-j.guardY-j.halo
  local sky=Color3.fromRGB(c.skyR,c.skyG,c.skyB)
  params.FilterDescendantsInstances=player and player.Character and {player.Character} or {}
  local function readAt(px,py)
   local color=sky
   if j.sampler then color=j.sampler(px,py)
   else
    local p=j.projection
    local direction=(p.a+p.dx*(px/p.w)+p.dy*(py/p.h)).Unit
    local hit=workspace:Raycast(p.origin,direction*c.distance,params)
    if hit then
     if hit.Instance:IsA("Terrain") then color=workspace.Terrain:GetMaterialColor(hit.Material)
     elseif hit.Instance:IsA("BasePart") then color=hit.Instance.Color end
    end
   end
   return color.R,color.G,color.B
  end
  local sampled=0
  for y=0,h-1 do for x=0,w-1 do
   local r,g,b=readAt(originX+(x-padX)*stepX,originY+(y-padY)*stepY)
   local p=(y*w+x)*3;source[p+1]=r;source[p+2]=g;source[p+3]=b
   sampled+=1;if sampled%32==0 then checkpoint() end
  end end
  local first=source;j.refinedPoints=0
  if c.edge>0 then
   j.refinedPoints=resolveEdges(source,refined,w,h,originX-padX*stepX,originY-padY*stepY,stepX,stepY,c.edge/100,readAt)
   first=refined
  end
  horizontal(first,temp,w,h,qx);vertical(temp,filtered,w,h,qy)
  horizontal(filtered,temp,w,h,qx);vertical(temp,ping,w,h,qy)
  horizontal(ping,temp,w,h,qx);vertical(temp,filtered,w,h,qy)
 local output=c.renderColumns;local segments=math.ceil((output-1)/16)
 local rows=j.texture and TextureSurface.Height or math.max(1,math.min(math.ceil(j.size.Y/c.band),math.floor(c.nodes/segments)))
 local count=rows*segments
 local buffer=back
 local frameAlpha=1 -- opacity is updated on the visible buffer, independent of color work
 j.renderRows,j.renderColumns,j.count=rows,output,j.texture and 0 or count
 if j.texture then buffer.pixelData=buffer.pixelData or TextureSurface.newPixels();j.pixels=buffer.pixelData end
 local lineR,lineG,lineB,codes={},{},{},{}
 local xlookup={}
 for ix=0,output-1 do
  local gx=(j.halo+ix/(output-1)*j.size.X)/stepX;local x=math.floor(gx)
  xlookup[ix+1]={math.max(0,x-1)+1,x+1,math.min(nx-1,x+1)+1,math.min(nx-1,x+2)+1,gx-x}
 end
 for i=1,rows do
  local top=math.floor((i-1)*j.size.Y/rows);local bottom=i==rows and j.size.Y or math.floor(i*j.size.Y/rows)
  local sampleY=j.texture and (i-.5)/rows*j.size.Y or (top+bottom)*.5
  local gy=(j.halo+sampleY)/stepY;local y=math.floor(gy);local ty=gy-y
  local a=(math.max(0,y-1)+padY)*w+padX
  local b=(y+padY)*w+padX
  local d=(math.min(ny-1,y+1)+padY)*w+padX
  local e=(math.min(ny-1,y+2)+padY)*w+padX
  for x=0,nx-1 do
   local p0=(a+x)*3;local p1=(b+x)*3;local p2=(d+x)*3;local p3=(e+x)*3
   lineR[x+1]=mono(filtered[p0+1],filtered[p1+1],filtered[p2+1],filtered[p3+1],ty)
   lineG[x+1]=mono(filtered[p0+2],filtered[p1+2],filtered[p2+2],filtered[p3+2],ty)
   lineB[x+1]=mono(filtered[p0+3],filtered[p1+3],filtered[p2+3],filtered[p3+3],ty)
  end
  for ix=1,output do
   local p=xlookup[ix];local x0,x1,x2,x3,t=p[1],p[2],p[3],p[4],p[5]
   local r=mono(lineR[x0],lineR[x1],lineR[x2],lineR[x3],t)
   local g=mono(lineG[x0],lineG[x1],lineG[x2],lineG[x3],t)
   local bl=mono(lineB[x0],lineB[x1],lineB[x2],lineB[x3],t)
   if c.saturation~=100 or c.brightness~=100 then
    local l=r*.2126+g*.7152+bl*.0722;local sat=c.saturation/100;local br=c.brightness/100
    r=(l+(r-l)*sat)*br;g=(l+(g-l)*sat)*br;bl=(l+(bl-l)*sat)*br
   end
   codes[ix]=math.round(math.clamp(r,0,1)*255)*65536+math.round(math.clamp(g,0,1)*255)*256+math.round(math.clamp(bl,0,1)*255)
  end
  if j.texture then TextureSurface.row(j.pixels,i-1,codes,output)
  else
  for segment=1,segments do
   local index=(i-1)*segments+segment
   local entry=buffer.entries[index]
   if not entry then
    local row=new("Frame",buffer.layer,{Name="LocalBlurBand",BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=1})
    entry={row=row,gradient=new("UIGradient",row,{Rotation=0}),codes={}};buffer.entries[index]=entry
   end
   local first=(segment-1)*16;local last=math.min(output-1,segment*16)
   local layoutKey=tostring(rows)..":"..tostring(output)..":"..tostring(j.size.Y)
   if entry.layoutKey~=layoutKey then
    entry.row.Position=UDim2.fromScale(first/(output-1),top/j.size.Y)
    entry.row.Size=UDim2.fromScale((last-first)/(output-1),(bottom-top)/j.size.Y);entry.layoutKey=layoutKey
   end
   entry.x,entry.y,entry.w,entry.h=first/(output-1),top/j.size.Y,(last-first)/(output-1),(bottom-top)/j.size.Y
   if options.Masked and not entry.clips then
    entry.row.Name="LocalBlurMask"
    entry.clips={{row=entry.row,gradient=entry.gradient}}
   end
   entry.row.Visible=not options.Masked
   local changed=entry.length~=last-first+1
   for x=first,last do if entry.codes[x-first+1]~=codes[x+1] then changed=true;break end end
   if changed then
    local keys={}
    for x=first,last do
     local code=codes[x+1];entry.codes[x-first+1]=code
     local r=math.floor(code/65536);local g=math.floor(code/256)%256;local bl=code%256
     keys[#keys+1]=ColorSequenceKeypoint.new((x-first)/(last-first),Color3.fromRGB(r,g,bl))
    end
    entry.fullSequence=ColorSequence.new(keys);entry.gradient.Color=entry.fullSequence;entry.length=last-first+1
   end
   if entry.alpha~=frameAlpha then entry.row.BackgroundTransparency=1-frameAlpha;entry.alpha=frameAlpha end
  end
  end
  if i%2==0 then checkpoint() end
 end
 if j.texture then
  j.discard=not texture:Commit(j.pixels)
  buffer.count=0
  return
 end
 for i=count+1,#buffer.entries do
  buffer.entries[i].row.Visible=false
  if i%16==0 then checkpoint() end
 end
 if options.Masked then for i=count+1,#buffer.entries do for _,slot in ipairs(buffer.entries[i].clips or {}) do slot.row.Visible=false end end end
 buffer.count=count
 end
 local function startJob(camera)
  local sampler=options.SampleFactory and options.SampleFactory() or nil
  if not sampler and (not camera or camera.ViewportSize.X<=1 or camera.ViewportSize.Y<=1) then reason="camera-not-ready";return end
  if not texture then
   if options.Texture==false then texture={ready=false,reason="disabled",Present=function() return false end,Destroy=function() end}
   else texture=TextureSurface.new() end
  end
  local visibleX=math.max(math.min(profile.columns,25),math.round(profile.columns*quality))
  local visibleY=math.max(math.min(profile.sampleRows,19),math.round(profile.sampleRows*quality))
  local stepX,stepY=current.w/(visibleX-1),current.h/(visibleY-1)
  local gx,gy=math.min(4,math.ceil(profile.guard/stepX)),math.min(4,math.ceil(profile.guard/stepY))
  local j={config=table.clone(profile),bounds=cloneBounds(current),nx=visibleX+gx*2,ny=visibleY+gy*2,
   visibleX=visibleX,visibleY=visibleY,stepX=stepX,stepY=stepY,guardX=gx*stepX,guardY=gy*stepY,
   size=Vector2.new(current.w+gx*stepX*2,current.h+gy*stepY*2),version=version,cpu=0,sampler=sampler,
   camera=camera,pose=camera and camera.CFrame,fov=camera and camera.FieldOfView,viewport=camera and camera.ViewportSize}
  j.halo=profile.radius*1.5
  j.stepX=(j.size.X+2*j.halo)/(j.nx-1);j.stepY=(j.size.Y+2*j.halo)/(j.ny-1)
  j.steps=0;j.age=0;j.texture=texture.ready
  if not sampler then j.projection=cameraSnapshot(camera,options.ScreenCoordinates~=false) end
  j.co=coroutine.create(function() buildFrame(j) end)
  job=j;force=false;elapsed=0;reason=frontInfo and nil or "warming"
 end
 function api:GetConfig() return table.clone(profile) end
 function api:SetConfig(patch)
  assert(not dead,"Local blur is destroyed")
  local nextProfile=validated(profile,patch)
  local changed=false
  for k,v in pairs(nextProfile) do if profile[k]~=v then changed=true;break end end
  if not changed then return end
  local expensive=false
  for k,v in pairs(nextProfile) do
   if profile[k]~=v and k~="strength" and k~="transparency" and k~="budget" and k~="refresh" and k~="idle" and k~="frameSync" then expensive=true end
  end
  profile=nextProfile;quality=1;slow=0;failed=false
  if expensive then version+=1;force=true end
  updateOpacity()
 end
 function api:Invalidate(clear)
  version+=1;force=true;failed=false
  if clear then job=nil;frontInfo=nil;front.layer.Visible=false;back.layer.Visible=false;active=false;root.Visible=false end
 end
 function api:Step(bounds,enabled,dt,opacity,workBudget)
  if dead then return end
  local started=os.clock()
  dt=type(dt)=="number" and math.clamp(dt,0,.25) or 1/60
  opacityFactor=finite(opacity) and math.clamp(opacity,0,1) or 1
  local valid=validBounds(bounds)
  local inset=math.max(0,options.Inset or 0)
  local canUse=enabled and valid and host.Parent and host.Visible and profile.strength>0 and profile.radius>0
  if not canUse then wasEnabled=false;job=nil;active=false;root.Visible=false;reason=not enabled and "hidden" or "invalid-bounds";return end
  local b={x=bounds.x+inset,y=bounds.y+inset,w=bounds.w-inset*2,h=bounds.h-inset*2}
  if not validBounds(b) then job=nil;active=false;root.Visible=false;reason="invalid-bounds";return end
  if not current or b.x~=current.x or b.y~=current.y or b.w~=current.w or b.h~=current.h then force=true end
  if not wasEnabled then failed=false;force=true;wasEnabled=true end
  current=b
  root.Position=UDim2.fromScale(inset/bounds.w,inset/bounds.h)
  root.Size=UDim2.fromScale(b.w/bounds.w,b.h/bounds.h)
  root.Visible=true;elapsed+=dt
  if frontInfo then positionBuffer(front,frontInfo,b);active=true end
  updateOpacity()
  if frontInfo then applyMasks(front,frontInfo,b) end
  if failed then return end
  local camera=workspace.CurrentCamera
  local ref=job or frontInfo
  local moving=not ref or ref.camera~=camera or (camera and (ref.pose~=camera.CFrame or ref.fov~=camera.FieldOfView or ref.viewport~=camera.ViewportSize))
  local rate=profile.frameSync and 0 or profile.refresh
  if profile.adaptive and not moving and not profile.frameSync then rate=math.min(rate,profile.idle) end
  if not job and (force or rate==0 or elapsed+1e-6>=1/rate) then
   local ok,err=pcall(startJob,camera)
   if not ok then failed=true;reason="sampling-error: "..tostring(err) end
  end
  if job then
   local work=job;work.steps+=1;work.age+=dt
   local sliceStarted=os.clock();local resumes=0
   local sliceBudget=finite(workBudget) and math.clamp(workBudget,0,profile.budget) or profile.budget
   while job==work and resumes<512 and (os.clock()-started)*1000<sliceBudget do
    resumes+=1
    local ok,err=coroutine.resume(work.co)
    if not ok then job=nil;failed=true;reason="sampling-error: "..tostring(err);break end
    if coroutine.status(work.co)=="dead" then
     if work.discard then job=nil;force=true;reason="texture-write-failed; gradient fallback";break end
     front.layer.Visible=false;back.layer.Visible=true;front,back=back,front
     frontInfo=work;job=nil;completed+=1;active=true;reason=nil
     totalCPU=work.cpu+(os.clock()-sliceStarted)*1000
     positionBuffer(front,work,current);updateOpacity();applyMasks(front,work,current)
     if profile.adaptive and (work.steps>2 or totalCPU>profile.budget*2) then slow+=1 else slow=0 end
     if slow>=2 and quality>.5 then quality=math.max(.5,quality-.125);slow=0;force=true end
     if work.version~=version or work.bounds.x~=current.x or work.bounds.y~=current.y or work.bounds.w~=current.w or work.bounds.h~=current.h then force=true end
     break
    end
   end
   work.cpu+=(os.clock()-sliceStarted)*1000
  end
  lastSlice=(os.clock()-started)*1000
 end
 function api:Inspect()
  return {active=active,unsupported=false,renderer="SampledV8",version=LocalBlur.Version,bounds=cloneBounds(current),reason=reason,
   pending=job~=nil,completed=completed,gradients=front.count,sliceMs=lastSlice,totalCpuMs=totalCPU,
   sampleColumns=frontInfo and frontInfo.visibleX or profile.columns,sampleRows=frontInfo and frontInfo.visibleY or profile.sampleRows,
   reusedWhileMoving=frontInfo and current and (frontInfo.bounds.x~=current.x or frontInfo.bounds.y~=current.y) or false,
   refinedPoints=frontInfo and frontInfo.refinedPoints or 0,guard=profile.guard,
   completedSteps=frontInfo and frontInfo.steps or 0,completedAge=frontInfo and frontInfo.age or 0,
   samplePoints=frontInfo and frontInfo.nx*frontInfo.ny or 0,
   surface=frontInfo and frontInfo.texture and "ContinuousTexture" or "GradientFallback",
   textureReason=texture and texture.reason or nil,
   textureWidth=frontInfo and frontInfo.texture and TextureSurface.Width or 0,
   textureHeight=frontInfo and frontInfo.texture and TextureSurface.Height or 0,
   renderColumns=frontInfo and frontInfo.renderColumns or profile.renderColumns}
 end
 function api:Destroy()
  if dead then return end
  dead=true;job=nil;frontInfo=nil;active=false
  if destroyConnection then destroyConnection:Disconnect();destroyConnection=nil end
  table.clear(source);table.clear(temp);table.clear(filtered);table.clear(ping);table.clear(refined)
  if texture then texture:Destroy();texture=nil end
  root:Destroy()
 end
 destroyConnection=host.Destroying:Connect(function() api:Destroy() end)
 return api
end

return LocalBlur

end)()
local function updateRegionalBlur(pane,anchor,enabled,bounds,dt,opacity)
 if not pane.renderer then return end
 pane.renderer:Step(bounds,enabled and anchor and anchor.Parent and anchor.Visible,dt,opacity,pane.frameBudget)
 local info=pane.renderer:Inspect()
 pane.active=info.active;pane.unsupported=info.unsupported;pane.bounds=info.bounds;pane.reason=info.reason
end
local function destroyRegionalBlur(pane)
 if pane.renderer then pane.renderer:Destroy();pane.renderer=nil end
 pane.active=false;pane.bounds=nil;pane.reason=nil
end

local function createSyntaxTargetHUD(parent,glowFactory,glowOptions)
    local TweenService = game:GetService("TweenService")
    local host = new("Frame", parent, {Name="EditableTargetHUD", BackgroundTransparency=1,
        Size=UDim2.fromOffset(292,76), Visible=false, ZIndex=40})
    local layoutScale = new("UIScale", host, {Scale=1})
local TargetHud = Instance.new("Frame")
TargetHud.Name = "TargetHud"
TargetHud.AnchorPoint = Vector2.new(0.5, 0.5)
TargetHud.Position = UDim2.fromScale(0.5, 0.5)
TargetHud.Size = UDim2.fromOffset(292, 76)
TargetHud.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetHud.BackgroundTransparency = 1
TargetHud.BorderSizePixel = 0
TargetHud.ClipsDescendants = false
TargetHud.Visible = false
TargetHud.ZIndex = 50
TargetHud.Parent = host

local TargetHudCorner = Instance.new("UICorner")
TargetHudCorner.CornerRadius = UDim.new(0, 18)
TargetHudCorner.Parent = TargetHud

local TargetHudStroke = Instance.new("UIStroke")
TargetHudStroke.Color = Color3.fromRGB(255, 255, 255)
TargetHudStroke.Transparency = 1
TargetHudStroke.Thickness = 1
TargetHudStroke.Parent = TargetHud

local TargetHudGradient = Instance.new("UIGradient")
TargetHudGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(55, 56, 62)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(24, 25, 29)),
})
TargetHudGradient.Rotation = 8
TargetHudGradient.Transparency = NumberSequence.new(1)
TargetHudGradient.Parent = TargetHud

-- TargetHUD old shadow removed; blur and V3 Smooth use separate layers.
local TargetHudScale = Instance.new("UIScale")
TargetHudScale.Scale = 0.94
TargetHudScale.Parent = TargetHud

local TargetHudDamageFlash = Instance.new("Frame")
TargetHudDamageFlash.Name = "DamageFlash"
TargetHudDamageFlash.Size = UDim2.fromScale(1, 1)
TargetHudDamageFlash.BackgroundColor3 = Color3.fromRGB(255, 70, 85)
TargetHudDamageFlash.BackgroundTransparency = 1
TargetHudDamageFlash.BorderSizePixel = 0
TargetHudDamageFlash.ZIndex = 51
TargetHudDamageFlash.Parent = TargetHud

local TargetHudDamageCorner = Instance.new("UICorner")
TargetHudDamageCorner.CornerRadius = UDim.new(0, 18)
TargetHudDamageCorner.Parent = TargetHudDamageFlash

local TargetAvatarHolder = Instance.new("Frame")
TargetAvatarHolder.Name = "AvatarHolder"
TargetAvatarHolder.Position = UDim2.fromOffset(10, 10)
TargetAvatarHolder.Size = UDim2.fromOffset(56, 56)
TargetAvatarHolder.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetAvatarHolder.BackgroundTransparency = 0.86
TargetAvatarHolder.BorderSizePixel = 0
TargetAvatarHolder.ZIndex = 52
TargetAvatarHolder.ClipsDescendants = true
TargetAvatarHolder.Parent = TargetHud

local TargetAvatarCorner = Instance.new("UICorner")
TargetAvatarCorner.CornerRadius = UDim.new(0, 14)
TargetAvatarCorner.Parent = TargetAvatarHolder

local TargetAvatar = Instance.new("ImageLabel")
TargetAvatar.Name = "Avatar"
TargetAvatar.Size = UDim2.fromScale(1, 1)
TargetAvatar.BackgroundTransparency = 1
TargetAvatar.ScaleType = Enum.ScaleType.Crop
TargetAvatar.Image = ""
TargetAvatar.ZIndex = 53
TargetAvatar.Parent = TargetAvatarHolder

local TargetAvatarInitial = Instance.new("TextLabel")
TargetAvatarInitial.Name = "Initial"
TargetAvatarInitial.Size = UDim2.fromScale(1, 1)
TargetAvatarInitial.BackgroundTransparency = 1
TargetAvatarInitial.Text = "?"
TargetAvatarInitial.TextColor3 = Color3.fromRGB(245, 245, 248)
TargetAvatarInitial.TextSize = 24
TargetAvatarInitial.Font = Enum.Font.GothamBold
TargetAvatarInitial.ZIndex = 52
TargetAvatarInitial.Parent = TargetAvatarHolder

local TargetName = Instance.new("TextLabel")
TargetName.Name = "TargetName"
TargetName.Position = UDim2.fromOffset(76, 11)
TargetName.Size = UDim2.new(1, -88, 0, 24)
TargetName.BackgroundTransparency = 1
TargetName.Text = "Name: --"
TargetName.TextColor3 = Color3.fromRGB(245, 245, 248)
TargetName.TextTransparency = 0.02
TargetName.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TargetName.TextStrokeTransparency = 0.48
TargetName.TextSize = 14
TargetName.Font = Enum.Font.GothamMedium
TargetName.TextXAlignment = Enum.TextXAlignment.Left
TargetName.TextTruncate = Enum.TextTruncate.AtEnd
TargetName.ZIndex = 52
TargetName.Parent = TargetHud

-- Colored glow follows the CURRENT health width.
local TargetHealthGlowHolder = Instance.new("Frame")
TargetHealthGlowHolder.Name = "HealthGlowHolder"
TargetHealthGlowHolder.Position = UDim2.fromOffset(76, 43)
TargetHealthGlowHolder.Size = UDim2.new(1, -126, 0, 11)
TargetHealthGlowHolder.BackgroundTransparency = 1
TargetHealthGlowHolder.BorderSizePixel = 0
TargetHealthGlowHolder.ClipsDescendants = false
TargetHealthGlowHolder.ZIndex = 50
TargetHealthGlowHolder.Parent = TargetHud

local TargetHealthTrack = Instance.new("Frame")
TargetHealthTrack.Name = "HealthTrack"
TargetHealthTrack.Position = UDim2.fromOffset(76, 43)
TargetHealthTrack.Size = UDim2.new(1, -126, 0, 11)
TargetHealthTrack.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetHealthTrack.BackgroundTransparency = 0.90
TargetHealthTrack.BorderSizePixel = 0
TargetHealthTrack.ClipsDescendants = true
TargetHealthTrack.ZIndex = 52
TargetHealthTrack.Parent = TargetHud

local TargetHealthTrackCorner = Instance.new("UICorner")
TargetHealthTrackCorner.CornerRadius = UDim.new(1, 0)
TargetHealthTrackCorner.Parent = TargetHealthTrack

local TargetHealthLag = Instance.new("Frame")
TargetHealthLag.Name = "HealthLag"
TargetHealthLag.Size = UDim2.fromScale(1, 1)
TargetHealthLag.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetHealthLag.BackgroundTransparency = 0.35
TargetHealthLag.BorderSizePixel = 0
TargetHealthLag.ZIndex = 53
TargetHealthLag.Parent = TargetHealthTrack

local TargetHealthLagCorner = Instance.new("UICorner")
TargetHealthLagCorner.CornerRadius = UDim.new(1, 0)
TargetHealthLagCorner.Parent = TargetHealthLag

local TargetHealthFill = Instance.new("Frame")
TargetHealthFill.Name = "HealthFill"
TargetHealthFill.Size = UDim2.fromScale(1, 1)
TargetHealthFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
TargetHealthFill.BorderSizePixel = 0
TargetHealthFill.ZIndex = 54
TargetHealthFill.Parent = TargetHealthTrack

local TargetHealthFillCorner = Instance.new("UICorner")
TargetHealthFillCorner.CornerRadius = UDim.new(1, 0)
TargetHealthFillCorner.Parent = TargetHealthFill

local TargetHealthGradient = Instance.new("UIGradient")
TargetHealthGradient.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 240, 170)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(160, 229, 255)),
})
TargetHealthGradient.Parent = TargetHealthFill

local TargetHealthText = Instance.new("TextLabel")
TargetHealthText.Name = "HealthText"
TargetHealthText.AnchorPoint = Vector2.new(1, 0.5)
TargetHealthText.Position = UDim2.new(1, -10, 0, 48)
TargetHealthText.Size = UDim2.fromOffset(34, 22)
TargetHealthText.BackgroundTransparency = 1
TargetHealthText.Text = "--"
TargetHealthText.TextColor3 = Color3.fromRGB(235, 238, 242)
TargetHealthText.TextTransparency = 0.04
TargetHealthText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
TargetHealthText.TextStrokeTransparency = 0.50
TargetHealthText.TextSize = 13
TargetHealthText.Font = Enum.Font.GothamMedium
TargetHealthText.TextXAlignment = Enum.TextXAlignment.Right
TargetHealthText.ZIndex = 52
TargetHealthText.Parent = TargetHud

local TargetHudShown = false
local TargetHudKey = nil
local TargetHudLastHealth = nil
local TargetHudLastRatio = 1
local TargetHudPreviewUntil = 0
local TargetHudPreviewKey = "__TARGETHUD_PREVIEW_V32__"
local TargetHudBasePosition = TargetHud.Position
local TargetHudAnimationSerial = 0
local TargetHudScaleTween = nil
local TargetHudFrameTween = nil

local function CancelTargetHudAnimation()
    if TargetHudScaleTween then
        pcall(function()
            TargetHudScaleTween:Cancel()
        end)
        TargetHudScaleTween = nil
    end

    if TargetHudFrameTween then
        pcall(function()
            TargetHudFrameTween:Cancel()
        end)
        TargetHudFrameTween = nil
    end
end

local function TargetHudOffsetPosition(offsetY)
    return UDim2.new(
        TargetHudBasePosition.X.Scale,
        TargetHudBasePosition.X.Offset,
        TargetHudBasePosition.Y.Scale,
        TargetHudBasePosition.Y.Offset + offsetY
    )
end

local function SetTargetHudVisible(state, instant)
    state = state == true

    if not instant then
        if state and TargetHudShown and TargetHud.Visible then
            return
        end

        -- TargetHudShown becomes false as soon as the exit tween starts.
        -- Ignore repeated RenderStepped hide requests until that tween ends.
        if not state and not TargetHudShown then
            return
        end
    end

    TargetHudAnimationSerial += 1
    local serial = TargetHudAnimationSerial

    if instant then
        CancelTargetHudAnimation()
        TargetHudShown = state
        TargetHud.Visible = state
        TargetHud.Position = TargetHudBasePosition
        TargetHud.Rotation = 0
        TargetHudScale.Scale = state and 1 or 0.82
        return
    end

    if state then
        TargetHudShown = true
        CancelTargetHudAnimation()

        TargetHud.Visible = true
        TargetHud.Position = TargetHudOffsetPosition(18)
        TargetHud.Rotation = -1.5
        TargetHudScale.Scale = 0.78

        TargetHudScaleTween = TweenService:Create(
            TargetHudScale,
            TweenInfo.new(
                0.24,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ),
            {Scale = 1}
        )

        TargetHudFrameTween = TweenService:Create(
            TargetHud,
            TweenInfo.new(
                0.20,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {
                Position = TargetHudBasePosition,
                Rotation = 0,
            }
        )

        TargetHudScaleTween:Play()
        TargetHudFrameTween:Play()
        return
    end

    TargetHudShown = false
    CancelTargetHudAnimation()

    TargetHudScaleTween = TweenService:Create(
        TargetHudScale,
        TweenInfo.new(
            0.14,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        ),
        {Scale = 0.82}
    )

    TargetHudFrameTween = TweenService:Create(
        TargetHud,
        TweenInfo.new(
            0.14,
            Enum.EasingStyle.Quad,
            Enum.EasingDirection.In
        ),
        {
            Position = TargetHudOffsetPosition(14),
            Rotation = 1.2,
        }
    )

    local hideTween = TargetHudFrameTween
    TargetHudScaleTween:Play()
    hideTween:Play()

    task.spawn(function()
        pcall(function()
            hideTween.Completed:Wait()
        end)

        if serial == TargetHudAnimationSerial
            and not TargetHudShown
            and TargetHud
            and TargetHud.Parent then

            TargetHud.Visible = false
            TargetHud.Position = TargetHudBasePosition
            TargetHud.Rotation = 0
            TargetHudScale.Scale = 0.78
        end
    end)
end
local function SetHealthGradient(ratio)
    local sequence

    if ratio <= 0.25 then
        sequence = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(255, 74, 109)
            ),
            ColorSequenceKeypoint.new(
                0.5,
                Color3.fromRGB(255, 113, 155)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(255, 190, 208)
            ),
        })
    elseif ratio <= 0.60 then
        sequence = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(255, 126, 187)
            ),
            ColorSequenceKeypoint.new(
                0.52,
                Color3.fromRGB(255, 196, 122)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(255, 239, 151)
            ),
        })
    else
        sequence = ColorSequence.new({
            ColorSequenceKeypoint.new(
                0,
                Color3.fromRGB(255, 221, 112)
            ),
            ColorSequenceKeypoint.new(
                0.34,
                Color3.fromRGB(137, 255, 173)
            ),
            ColorSequenceKeypoint.new(
                0.68,
                Color3.fromRGB(105, 226, 255)
            ),
            ColorSequenceKeypoint.new(
                1,
                Color3.fromRGB(180, 142, 255)
            ),
        })
    end

    TargetHealthGradient.Color = sequence
end
local function ShowTargetHudPreview()
    if TargetHudKey ~= TargetHudPreviewKey then
        TargetHudKey = TargetHudPreviewKey
        TargetHudLastHealth = nil
        TargetHudLastRatio = 1

        TargetName.Text = "TargetHUD READY"
        TargetAvatar.Image = ""
        TargetAvatar.Visible = false
        TargetAvatarInitial.Visible = true
        TargetAvatarInitial.Text = "✓"
        TargetHealthText.Text = "--"
        TargetHealthFill.Size = UDim2.fromScale(1, 1)
        TargetHealthLag.Size = UDim2.fromScale(1, 1)
        TargetHealthGlowHolder.Size = UDim2.new(1, -126, 0, 11)
        SetHealthGradient(1)
    end

    SetTargetHudVisible(true, false)
end


    local controller = {Host=host, LayoutScale=layoutScale, Frame=TargetHud, AnimationScale=TargetHudScale, Current=nil}
    function controller:Update(info)
        if not info then SetTargetHudVisible(false);return end
    local targetChanged =
        TargetHudKey ~= info.Key

    if targetChanged then
        TargetHudKey = info.Key
        TargetHudLastHealth = nil
        TargetHudLastRatio = 1

        TargetName.Text =
            "Name: " .. tostring(info.Name or "--")

        if info.Avatar then
            TargetAvatar.Image = info.Avatar
            TargetAvatar.Visible = true
            TargetAvatarInitial.Visible = false
        else
            TargetAvatar.Image = ""
            TargetAvatar.Visible = false
            TargetAvatarInitial.Visible = true
            TargetAvatarInitial.Text =
                tostring(info.Initial or "?")
        end

    else
        TargetName.Text =
            "Name: " .. tostring(info.Name or "--")
    end

    local ratio = 1
    local healthText = "--"

    if info.Health ~= nil
        and info.MaxHealth ~= nil then

        ratio = math.clamp(
            info.Health / math.max(info.MaxHealth, 1),
            0,
            1
        )

        healthText =
            tostring(
                math.max(
                    0,
                    math.floor(info.Health + 0.5)
                )
            )
    end

    TargetHealthText.Text = healthText

    local ratioChanged =
        targetChanged
        or math.abs(ratio - TargetHudLastRatio) > 0.001

    -- Do not allocate three new tweens every RenderStepped when health is
    -- unchanged. This matters a lot in vehicle mode where target scanning is
    -- already more expensive than player/NPC mode.
    if ratioChanged then
        SetHealthGradient(ratio)

        local fillGoal =
            UDim2.new(ratio, 0, 1, 0)

        local glowGoal =
            UDim2.new(
                ratio,
                -126 * ratio,
                0,
                11
            )

        TweenService:Create(
            TargetHealthGlowHolder,
            TweenInfo.new(
                0.14,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {Size = glowGoal}
        ):Play()

        TweenService:Create(
            TargetHealthFill,
            TweenInfo.new(
                0.12,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {Size = fillGoal}
        ):Play()

        TweenService:Create(
            TargetHealthLag,
            TweenInfo.new(
                0.32,
                Enum.EasingStyle.Quart,
                Enum.EasingDirection.Out
            ),
            {Size = fillGoal}
        ):Play()
    end

    if TargetHudLastHealth ~= nil
        and info.Health ~= nil
        and info.Health < TargetHudLastHealth - 0.01 then

        TargetHudDamageFlash.BackgroundTransparency = 0.82

        TweenService:Create(
            TargetHudDamageFlash,
            TweenInfo.new(
                0.24,
                Enum.EasingStyle.Quad,
                Enum.EasingDirection.Out
            ),
            {BackgroundTransparency = 1}
        ):Play()

        TargetHudScale.Scale = 1.025

        TweenService:Create(
            TargetHudScale,
            TweenInfo.new(
                0.18,
                Enum.EasingStyle.Back,
                Enum.EasingDirection.Out
            ),
            {Scale = 1}
        ):Play()
    end

    if info.Health ~= nil then
        TargetHudLastHealth = info.Health
    end

    TargetHudLastRatio = ratio
    SetTargetHudVisible(true, false)
end

    function controller:Preview() ShowTargetHudPreview() end
    function controller:Inspect()
        return {Visible=host.Visible and TargetHud.Visible, HudParent=TargetHud.Parent,
            HudAbsolutePosition=TargetHud.AbsolutePosition, HudAbsoluteSize=TargetHud.AbsoluteSize,
            HudText=TargetName.Text}
    end
        local targetSmooth=glowFactory(TargetHud,glowOptions)
    targetSmooth.root.Name="TargetHUDTopGlow"
    targetSmooth.root.ZIndex=100 -- above blur, damage flash, avatar, names and health bar
    local function effectReason(reason)
        return reason and reason:gsub("Using original glow", "TargetHUD glow disabled")
    end
    function controller:RenderGlow(st,enabled)
        targetSmooth:Begin(enabled and st["TargetHUD Glow"]~=false,st["TargetHUD Glow strength"] or .5,st["TargetHUD Glow layers"] or 2)
        if enabled then
            local width=math.max(0,292*TargetHealthGlowHolder.Size.X.Scale+TargetHealthGlowHolder.Size.X.Offset)
            local keys=TargetHealthGradient.Color.Keypoints
            -- Overlapping radial spots follow the animated CURRENT health width.
            -- Split into gradient intervals so the latest mask preserves health colors.
            for i=1,#keys-1 do
                local a,b=keys[i],keys[i+1]
                local color=a.Value:Lerp(b.Value,.5)
                local packed=math.round(color.R*255)*65536+math.round(color.G*255)*256+math.round(color.B*255)
                targetSmooth:Draw(76+width*a.Time,43,width*(b.Time-a.Time),11,packed,1,st["TargetHUD Glow radius"] or 24,1)
            end
        end
        targetSmooth:Finish()
    end
    function controller:InspectGlow()
        local info=targetSmooth:Inspect();info.reason=effectReason(info.reason)
        info.renderer="V3 Smooth";info.zindex=targetSmooth.root.ZIndex;info.layer="Top"
        info.healthWidth=math.max(0,292*TargetHealthGlowHolder.Size.X.Scale+TargetHealthGlowHolder.Size.X.Offset)
        return info
    end
    function controller:DestroyEffects() targetSmooth:Destroy() end

    return controller
end

-- V3 Smooth: continuous radial alpha, shared texture and pooled ImageLabels.
local SmoothGlow={Size=256}
UI.SmoothGlowImageId="" -- Optional uploaded V3Smooth_DefaultMask.png image ID.
function SmoothGlow.alpha(distance,power,layers)
 if distance>=1 then return 0 end
 local transmission=1
 for layer=1,layers do
  local t=layers==1 and 1 or (layer-1)/(layers-1)
  local sigma=.25+.75*t;local edge=math.exp(-4/(sigma*sigma))
  local falloff=(math.exp(-4*distance*distance/(sigma*sigma))-edge)/(1-edge)
  transmission*=1-math.clamp(power*(1-.5*t)*.26,0,.65)*falloff
 end
 return 1-transmission
end
function SmoothGlow.pixels(power,layers)
 local size=SmoothGlow.Size
 local pixels=buffer.create(size*size*4)
 local bayer={0,8,2,10,12,4,14,6,3,11,1,9,15,7,13,5}
 local lut=table.create(4097)
 for i=0,4096 do lut[i+1]=SmoothGlow.alpha(i/4096,power,layers) end
 if not SmoothGlow.distances then
  SmoothGlow.distances=table.create(size*size)
  for y=0,size-1 do for x=0,size-1 do
   local nx=(x+.5-size/2)/(size/2-2);local ny=(y+.5-size/2)/(size/2-2)
   SmoothGlow.distances[y*size+x+1]=math.sqrt(nx*nx+ny*ny)
  end end
 end
 for y=0,size-1 do for x=0,size-1 do
  local index=y*size+x;local distance=SmoothGlow.distances[index+1];local alpha=0
  if distance<1 then
   local scaled=distance*4096;local base=math.floor(scaled)
   alpha=lut[base+1]+(lut[base+2]-lut[base+1])*(scaled-base)
  end
  local noise=(bayer[(y%4)*4+x%4+1]+.5)/16
  buffer.writeu8(pixels,index*4,255);buffer.writeu8(pixels,index*4+1,255);buffer.writeu8(pixels,index*4+2,255)
  buffer.writeu8(pixels,index*4+3,math.clamp(math.floor(alpha*255+noise),0,255))
 end end
 return pixels
end
function SmoothGlow.addSettings(module)
 local settings=module.settings
 local function add(def)
  for _,existing in ipairs(settings) do if existing.name==def.name then return end end
  settings[#settings+1]=def
 end
 add({name="XHan Glow",type="toggle",default=true})
 add({name="Glow renderer",type="select",default="V3 Smooth",options={"Original","V3 Smooth"}})
 add({name="Smooth Glow strength",type="slider",default=.5,min=0,max=1.6,step=.05})
 add({name="Smooth Glow radius",type="slider",default=30,min=6,max=72,step=1})
 add({name="Smooth Glow layers",type="slider",default=2,min=1,max=4,step=1})
end
function SmoothGlow.new(parent,options)
 local self={images={},used=0,state="idle",ready=false,busy=false,dead=false,revision=0,options=options,updates=0}
 self.root=new("Frame",parent,{Name="V3SmoothGlow",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=0,ClipsDescendants=false,Active=false,Visible=false})
 function self:Report(text)
  self.reason=text
  if not self.reported then self.reported=true;if self.options.onUnavailable then self.options.onUnavailable(text) end end
 end
 function self:Request(power,layers)
  local key=string.format("%.4f:%d",power,layers)
  if self.busy or self.state=="unavailable" or self.state=="uploaded" or self.key==key then return end
  self.key=key;self.busy=true
  local revision=self.revision
  task.defer(function()
   if self.dead or self.revision~=revision then return end
   local ok=pcall(function()
    if not self.image then
     self.image=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(SmoothGlow.Size,SmoothGlow.Size)})
     assert(self.image,"EditableImage unavailable")
     self.content=Content.fromObject(self.image)
    end
    self.image:WritePixelsBuffer(Vector2.new(0,0),Vector2.new(SmoothGlow.Size,SmoothGlow.Size),SmoothGlow.pixels(power,layers))
   end)
   if self.dead or self.revision~=revision then return end
   if ok then
    self.ready=true;self.state="dynamic";self.power=power;self.layers=layers;self.reason=nil;self.updates+=1
   elseif self.ready then
    self:Report("Smooth texture update failed; retaining the previous texture.")
   else
    if self.image then self.image:Destroy();self.image=nil;self.content=nil end
    local id=self.options.imageId
    if type(id)=="string" and id~="" then
     local uri=id:match("^rbxassetid://") and id or "rbxassetid://"..id
     local loaded=true
     local fetched=pcall(function()
      game:GetService("ContentProvider"):PreloadAsync({uri},function(_,result) if result~=Enum.AssetFetchStatus.Success then loaded=false end end)
     end)
     if self.dead or self.revision~=revision then return end
     if fetched and loaded then
      self.uri=uri;self.ready=true;self.state="uploaded";self.power=.5;self.layers=2
      self:Report("Uploaded smooth mask active: layers fixed at 2; strength adjusts image opacity.")
     else self.state="unavailable";self:Report("Smooth glow image could not load. Using original glow; check the image ID and permissions.") end
    else
     self.state="unavailable"
     self:Report("Smooth glow needs Mesh / Image API access or SmoothGlowImageId. Using original glow.")
    end
   end
   self.busy=false
  end)
 end
 function self:Begin(enabled,power,layers)
  self.used=0
  self.enabled=enabled and power>0
  self.requestedPower=math.clamp(power,0,1.6)
  if self.enabled then self:Request(self.requestedPower,math.clamp(math.round(layers),1,4)) end
  self.root.Visible=self.enabled and self.ready
  return self.enabled and self.ready
 end
 function self:Draw(x,y,w,h,color,fade,radius,scale)
  if not self.enabled or not self.ready or w<=0 or h<=0 or fade<=.001 then return end
  scale=math.max(.05,scale or 1)
  local vertical=h>w;local length=math.max(w,h);local short=math.min(w,h)
  local count=math.clamp(math.ceil(length/(18*scale)),1,24)
  local spacing=length/count;local outer=radius*scale+short*.4
  local overlap=math.max(1,outer/math.max(spacing,scale))
  local extent=outer*SmoothGlow.Size/(SmoothGlow.Size-4)
  local powerScale=self.state=="uploaded" and self.requestedPower/.5 or 1
  for point=1,count do
   self.used+=1
   local image=self.images[self.used]
   if not image then
    image=new("ImageLabel",self.root,{Name="SmoothRadialGlow",BackgroundTransparency=1,BorderSizePixel=0,Active=false,ScaleType=Enum.ScaleType.Stretch,ResampleMode=Enum.ResamplerMode.Default,ZIndex=1})
    self.images[self.used]=image
   end
   if self.content then image.ImageContent=self.content else image.Image=self.uri end
   local offset=(point-.5)*spacing
   local cx=x+(vertical and w/2 or offset);local cy=y+(vertical and offset or h/2)
   image.Visible=true;image.Position=UDim2.fromOffset(cx-extent,cy-extent);image.Size=UDim2.fromOffset(extent*2,extent*2)
   image.ImageColor3=rgb(color);image.ImageTransparency=1-math.clamp(fade*powerScale/overlap,0,1)
  end
 end
 function self:Finish()
  for i=self.used+1,#self.images do self.images[i].Visible=false end
 end
 function self:Inspect()
  return {state=self.state,reason=self.reason,active=self.root.Visible,points=self.used,textureUpdates=self.updates,power=self.power,layers=self.layers}
 end
 function self:Destroy()
  if self.dead then return end
  self.dead=true;self.revision+=1;self.root:Destroy();table.clear(self.images)
  if self.image then self.image:Destroy();self.image=nil end
  self.content=nil
 end
 return self
end

-- Private read-only layout/palette data lives outside the per-window constructor.
local sourceThemes={Default={0xFFFFFF,0xFFFFFF},Flower={0xFFFFFF,0xFFFFFF},Gold={0xFFA500,0xFFFF00},Ocean={0x00C6FF,0x0072FF},Nova={0xFF64C8,0x1996FF},Emerald={0x00E676,0x164D2B},Inferno={0xFF5722,0x7A321F},Sakura={0xFF80AB,0xE040FB},Cherry={0xDD3D69,0xE0B3B7}}
local flowPalettes={Starlight={0xE9A8BC,0x6EC8F1,0xFFFFFF},Aurora={0xFF78DC,0x8269FF,0x5FDCFF,0xD2FFF5},Rainbow={0xFF6978,0xFFBE5A,0x73F09B,0x5ABEFF,0xAF73FF}}
local appearanceRanges={UI={.5,4},HUD={.5,4},Speed={.5,3},Glow={0,1},Island={0,100},IslandBackground={0,100},IslandSpeed={.25,3}}
local navNames={"Combat","Targets","Movement","Player","Visuals","Misc","HUD Editor","Configs"}
local navY={96,132,200,236,304,372,408,444}
local modernNames={"Combat","Movement","Visuals","Player","Other"}
local modernCats={"Combat","Movement","Visual","Player","Misc"}

-- The same V3 Smooth alpha texture and image pool as the colored glow, tinted black.
local ArrayListShadow={}
function ArrayListShadow.new(parent,options)
 local self={rows=0,dead=false}
 -- Keep the entire subtree under all list backgrounds, blur, glow and text.
 self.root=new("Frame",parent,{Name="ArrayListShadow",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=1,Active=false,ClipsDescendants=false,Visible=false})
 self.smooth=SmoothGlow.new(self.root,options)
 function self:Step(metrics,settings,visible)
  self.rows=0
  local strength=(settings["ArrayList Shadow strength"] or 55)/100
  local radius=settings["ArrayList Shadow radius"] or 18
  local enabled=visible and settings["ArrayList Shadow"]~=false and strength>0 and radius>0
  if metrics.mode=="Opai" and settings["Opai Shadow"]==false then enabled=false end
  local scale=math.max(.05,metrics.shadowScale or 1)
  self.smooth:Begin(enabled,strength,settings["ArrayList Shadow layers"] or 2)
  if enabled then
   for _,row in ipairs(metrics.rows or {}) do
    local fade=math.clamp(row.alpha or 0,0,1)
    if row.width>0 and row.height>0 and fade>.001 then
     self.rows+=1
     local padding=metrics.mode=="Default" and 6.5*scale or 0
     self.smooth:Draw(row.x-padding,row.y+scale,row.width+padding,row.height,0x000000,fade,radius,scale)
    end
   end
  end
  self.smooth:Finish()
  self.root.Visible=enabled and self.smooth.root.Visible and self.smooth.used>0
 end
 function self:Inspect()
  local info=self.smooth:Inspect()
  info.active=self.root.Visible;info.rows=self.rows;info.pooledPoints=#self.smooth.images
  info.zindex=self.root.ZIndex;info.renderer="V3 Smooth";info.color=0x000000
  return info
 end
 function self:Destroy()
  if self.dead then return end
  self.dead=true;self.smooth:Destroy();self.root:Destroy();self.rows=0
 end
 return self
end

-- A connected silhouette with signed inner/outer corners. Narrow strips are
-- geometry only; blur strips all view one full continuous sampled texture.
local ListContour={}
function ListContour.Shape(rows,radius)
 local function turn(delta,r)
  return (delta<0 and -1 or 1)*math.min(r,math.abs(delta)/2)
 end
 local function inset(value,depth)
  local r=math.abs(value)
  if r==0 or depth>=r then return 0 end
  return (value<0 and -1 or 1)*(r-math.sqrt(math.max(0,r*r-(r-depth)^2)))
 end
 for i,row in ipairs(rows) do
  local previous,after=rows[i-1],rows[i+1]
  -- Never permit capsule ends, including when an old profile stored radius 12.
  local r=math.min(radius,row.height*.2,row.width*.2)
  row.tl=previous and turn(previous.x-row.x,r) or r
  row.tr=previous and turn(row.x+row.width-previous.x-previous.width,r) or r
  row.bl=after and turn(after.x-row.x,r) or r
  row.br=after and turn(row.x+row.width-after.x-after.width,r) or r
  local top=math.ceil(math.max(math.abs(row.tl),math.abs(row.tr)))
  local bottom=math.ceil(math.max(math.abs(row.bl),math.abs(row.br)))
  local bands={};local y=0
  while y<row.height do
   local nextY=(y<top or y>=row.height-bottom) and math.min(row.height,y+1) or math.max(y+1,row.height-bottom)
   nextY=math.min(nextY,row.height)
   local middle=(y+nextY)/2
   local left=inset(row.tl,middle)+inset(row.bl,row.height-middle)
   local right=inset(row.tr,middle)+inset(row.br,row.height-middle)
   bands[#bands+1]={x=row.x+left,y=row.y+y,w=math.max(.01,row.width-left-right),h=nextY-y,alpha=row.alpha,color=row.color,topColor=row.topColor,bottomColor=row.bottomColor,fraction=middle/row.height}
   y=nextY
  end
  row.bands=bands
 end
end
-- Only the thin color edge is drawn here. The contour itself is a blur mask;
-- it never paints a dark or opaque backing behind the feature text.
function ListContour.new(parent)
 local self={rows={},used=0,root=new("Frame",parent,{Name="ArrayListContour",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=10,Active=false})}
 function self:Begin(enabled) self.used=0;self.root.Visible=enabled end
 function self:Draw(row,scale)
  self.used+=1;local slot=self.rows[self.used]
  if not slot then
   local edge=new("Frame",self.root,{Name="ContourEdge",BorderSizePixel=0,Active=false})
   slot={edge=edge,gradient=new("UIGradient",edge,{Rotation=90})};self.rows[self.used]=slot
  end
  local width=math.min(1.5*(scale or 1),row.width)
  slot.edge.Visible=true;slot.edge.Position=UDim2.fromOffset(row.x+row.width-width,row.y);slot.edge.Size=UDim2.fromOffset(width,row.height)
  slot.edge.BackgroundColor3=Color3.new(1,1,1);slot.edge.BackgroundTransparency=1-.96*row.alpha
  slot.gradient.Color=ColorSequence.new(rgb(row.topColor),rgb(row.bottomColor))
 end
 function self:Finish() for i=self.used+1,#self.rows do self.rows[i].edge.Visible=false end end
 return self
end

local WaterMark={}
function WaterMark.new(parent,options)
 local self={brand=options.text or "Syntax",phase=0,dead=false}
 self.root=new("Frame",parent,{Name="WaterMark",BackgroundTransparency=1,Size=UDim2.fromOffset(112,32),Position=UDim2.fromOffset(16,16),ZIndex=8000,ClipsDescendants=false,Active=false,Visible=false})
 self.blur=new("Frame",self.root,{Name="WaterMarkLocalBlur",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=0,Active=false})
 self.backdrop=new("Frame",self.root,{Name="WaterMarkBackdrop",BackgroundColor3=rgb(0x101319),BackgroundTransparency=.75,Size=UDim2.fromScale(1,1),ZIndex=10,Active=false})
 self.corner=new("UICorner",self.backdrop,{CornerRadius=UDim.new(0,8)})
 self.label=new("TextLabel",self.root,{Name="WaterMarkText",Text="Syntax",BackgroundTransparency=1,Font=Enum.Font.Gotham,TextSize=22,TextColor3=Color3.new(1,1,1),TextScaled=false,TextWrapped=false,AutomaticSize=Enum.AutomaticSize.None,TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=Enum.TextXAlignment.Left,ZIndex=30,Active=false})
 self.nativeTextScale=new("UIScale",self.label,{Name="NativePixelText",Scale=1})
 self.logo=new("Frame",self.root,{Name="WaterMarkLogo",BackgroundTransparency=1,Size=UDim2.fromOffset(18,18),ZIndex=30,Active=false})
 self.logoStrokes={}
 for i,stroke in ipairs({{3,5,8,2,42},{3,11,8,2,-42},{12,13,6,2,0}}) do
  local line=new("Frame",self.logo,{Name="TerminalStroke"..i,AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromOffset(stroke[1],stroke[2]),Size=UDim2.fromOffset(stroke[3],stroke[4]),Rotation=stroke[5],BorderSizePixel=0,ZIndex=30,Active=false})
  new("UICorner",line,{CornerRadius=UDim.new(.5,0)});self.logoStrokes[i]={line=line,shape=stroke}
 end
 self.gradient=new("UIGradient",self.label,{Name="FlowingText",Rotation=0})
 self.glow=SmoothGlow.new(self.root,options)
 self.glow.root.Name="WaterMarkGlow";self.glow.root.ZIndex=20
 function self:Step(settings,view,hudScale,at,enabled,dt,info)
  self.root.Visible=enabled
  local power=settings["WaterMark Glow strength"] or .5
  self.glow:Begin(enabled and settings["WaterMark Glow"]~=false,power,settings["WaterMark Glow layers"] or 2)
  if not enabled then self.glow:Finish();return end
  self.phase=(self.phase+math.min(.1,math.max(0,dt))*.08*(settings["WaterMark Flow speed"] or 1))%1
  self.text=self.brand
  local baseSize=settings["WaterMark Text size"] or 22;local baseHeight=baseSize+16
  local scale=math.min(hudScale/2*(at and at.scale or 1),math.max(.1,(view.Y-4)/baseHeight))
  local size=math.max(1,math.round(baseSize)) -- Native pixels: only the text-size slider changes this.
  if self.measuredText~=self.text or self.measuredSize~=size then
   self.measuredText=self.text;self.measuredSize=size
   self.measuredWidth=TextService:GetTextSize(self.text or self.brand,size,Enum.Font.Gotham,Vector2.new(10000,100)).X
  end
  local logoSize=math.max(16,baseSize);local labelX=12+logoSize+8
  local width=self.measuredWidth+(labelX+12)*scale
  local w=math.max(1,math.min(width,view.X-4));local h=math.max(size+8,baseHeight*scale)
  local x=math.clamp(at and at.x or 16,2,math.max(2,view.X-w-2))
  local y=math.clamp(at and at.y or 16,2,math.max(2,view.Y-h-2))
  self.bounds={x=x,y=y,w=w,h=h};self.scale=scale
  self.root.Position=UDim2.fromOffset(x,y);self.root.Size=UDim2.fromOffset(w,h)
  self.backdrop.BackgroundTransparency=1-(settings["WaterMark Background opacity"] or 25)/100
  self.corner.CornerRadius=UDim.new(0,8*scale)
  local ancestorScale=1;local ancestor=self.label.Parent
  while ancestor do
   for _,child in ipairs(ancestor:GetChildren()) do
    if child:IsA("UIScale") then ancestorScale*=child.Scale end
   end
   ancestor=ancestor.Parent
  end
  self.ancestorScale=ancestorScale;self.nativeTextScale.Scale=1/math.max(.001,ancestorScale)
  self.label.TextScaled=false;self.label.TextWrapped=false;self.label.AutomaticSize=Enum.AutomaticSize.None
  self.label.Text=self.text or self.brand;self.label.TextSize=size
  self.logo.Position=UDim2.fromOffset(12*scale,(h-logoSize*scale)/2);self.logo.Size=UDim2.fromOffset(logoSize*scale,logoSize*scale)
  self.label.Position=UDim2.fromOffset(math.round(labelX*scale),0);self.label.Size=UDim2.fromOffset(math.ceil(math.max(1,w-(labelX+12)*scale)*ancestorScale),math.ceil(h*ancestorScale))
  local colors={}
  for i=0,4 do colors[i+1]=ColorSequenceKeypoint.new(i/4,options.color and rgb(options.color(self.phase+i/4)) or Color3.fromHSV((self.phase+i*.13)%1,.5,1)) end
  self.gradient.Color=ColorSequence.new(colors)
  for i,stroke in ipairs(self.logoStrokes) do
   local shape=stroke.shape;local line=stroke.line
   line.Position=UDim2.fromOffset(shape[1]*logoSize/18*scale,shape[2]*logoSize/18*scale);line.Size=UDim2.fromOffset(shape[3]*logoSize/18*scale,shape[4]*logoSize/18*scale)
   line.BackgroundColor3=colors[i].Value
  end
  for i=1,4 do
   local c=colors[i].Value:Lerp(colors[i+1].Value,.5)
   local packed=math.round(c.R*255)*65536+math.round(c.G*255)*256+math.round(c.B*255)
   self.glow:Draw(12*scale+(w-24*scale)*(i-1)/4,(h-size)/2,math.max(0,w-24*scale)/4,size,packed,1,settings["WaterMark Glow radius"] or 18,scale)
  end
  self.glow:Finish()
 end
 function self:SetText(value) assert(type(value)=="string" and #value>0 and #value<=120,"Invalid WaterMark text");self.brand=value end
 function self:Inspect() return {visible=self.root.Visible,text=self.label.Text,logo=">_",font=self.label.Font.Name,fontSize=self.label.TextSize,textScaleIndependent=true,textCompensation=self.nativeTextScale.Scale,effectiveFontSize=self.label.TextSize*(self.ancestorScale or 1)*self.nativeTextScale.Scale,phase=self.phase,bounds=self.bounds,glow=self.glow:Inspect(),glowZIndex=self.glow.root.ZIndex,textZIndex=self.label.ZIndex,backdropZIndex=self.backdrop.ZIndex} end
 function self:Destroy() if self.dead then return end;self.dead=true;self.glow:Destroy();self.root:Destroy() end
 return self
end

function UI.new(options)
 uiDiagnostics.Stage="初始化 UI 设置"
 options=table.clone(options or {})
 assert(options.Language==nil or options.Language=="English" or options.Language=="中文","Unknown language")
 language=options.Language or "English"
 options.Modules=copy(options.Modules or {})
 local function addBlurControl(module,name,key,source)
  module.settings=module.settings or {}
  for _,setting in ipairs(module.settings) do if setting.name==name then return end end
  module.settings[#module.settings+1]={name=name,type="slider",default=source and source[key] or SampledLocalBlur.Defaults[key],min=0,max=100,step=1}
 end
 for _,module in ipairs(options.Modules) do
  if module.id=="ClickGUI" then
   addBlurControl(module,"Local Blur strength","strength",options.LocalBlurOptions)
   addBlurControl(module,"Local Blur softness","smooth",options.LocalBlurOptions)
  elseif module.id=="HUD" then
   local profile=table.clone(options.LocalBlurOptions or {})
   for key,value in pairs(options.HUDBlurOptions or {}) do profile[key]=value end
   for _,region in ipairs({"Island","ArrayList","TargetHUD","WaterMark"}) do
    addBlurControl(module,region.." Blur strength","strength",profile)
    addBlurControl(module,region.." Blur softness","smooth",profile)
   end
  end
 end
 for _,m in ipairs(options.Modules) do
  if m.id=="ClickGUI" then for _,setting in ipairs(m.settings or {}) do if setting.name=="Style" then setting.options=copy(UI.Styles) end end end
  if m.id=="ClickGUI" then
   m.settings=m.settings or {}
   local found=false;for _,setting in ipairs(m.settings) do if setting.name=="Local Blur radius" then found=true end end
   if not found then m.settings[#m.settings+1]={name="Local Blur radius",type="slider",default=options.LocalBlurOptions and options.LocalBlurOptions.radius or 1,min=0,max=120,step=1} end
  end
  if m.id=="HUD" then
   m.settings=m.settings or {};SmoothGlow.addSettings(m)
   local function addHUDSetting(def)
    for _,old in ipairs(m.settings) do if old.name==def.name then return end end
    m.settings[#m.settings+1]=def
   end
   for _,name in ipairs({"Island Blur","BloomFlow Blur","TargetHUD Blur","TargetHUD Glow"}) do addHUDSetting({name=name,type="toggle",default=true}) end
   addHUDSetting({name="ArrayList Shadow",type="toggle",default=true})
   addHUDSetting({name="ArrayList Shadow strength",type="slider",default=55,min=0,max=100,step=1,when={op="eq",name="ArrayList Shadow",value=true}})
   addHUDSetting({name="ArrayList Shadow radius",type="slider",default=18,min=0,max=72,step=1,when={op="eq",name="ArrayList Shadow",value=true}})
   addHUDSetting({name="Island State Duration",type="slider",default=2,min=.5,max=15,step=.1})
   addHUDSetting({name="ArrayList Shadow layers",type="slider",default=2,min=1,max=4,step=1,when={op="eq",name="ArrayList Shadow",value=true}})
   local suppliedArrayList={}
   for _,setting in ipairs(m.settings) do if setting.name=="ArrayList Blur" or setting.name=="ArrayList Blur radius" then suppliedArrayList[setting.name]=true end end
   addHUDSetting({name="HUD Color source",type="select",default="Theme",options={"Theme","Palette"}})
   addHUDSetting({name="WaterMark Text size",type="slider",default=22,min=10,max=36,step=1})
   addHUDSetting({name="BloomFlow Corner radius",type="slider",default=3,min=0,max=12,step=.5})
   addHUDSetting({name="ArrayList Blur",type="toggle",default=true})
   addHUDSetting({name="ArrayList Blur radius",type="slider",default=options.HUDBlurOptions and options.HUDBlurOptions.radius or options.LocalBlurOptions and options.LocalBlurOptions.radius or 1,min=0,max=120,step=1})
   for _,name in ipairs({"WaterMark Blur","WaterMark Glow"}) do addHUDSetting({name=name,type="toggle",default=true}) end
   addHUDSetting({name="WaterMark Blur radius",type="slider",default=options.HUDBlurOptions and options.HUDBlurOptions.radius or options.LocalBlurOptions and options.LocalBlurOptions.radius or 1,min=0,max=120,step=1})
   addHUDSetting({name="WaterMark Glow strength",type="slider",default=.5,min=0,max=1.6,step=.05})
   addHUDSetting({name="WaterMark Glow radius",type="slider",default=18,min=6,max=72,step=1})
   addHUDSetting({name="WaterMark Glow layers",type="slider",default=2,min=1,max=4,step=1})
   addHUDSetting({name="WaterMark Flow speed",type="slider",default=1,min=0,max=5,step=.1})
   addHUDSetting({name="WaterMark Background opacity",type="slider",default=25,min=0,max=100,step=1})
   addHUDSetting({name="Widgets",type="multi",default=options.WaterMarkDefault==false and {} or {"WaterMark"},options={"Dynamic Island","ArrayList","TargetHUD","WaterMark"}})
   for _,setting in ipairs(m.settings) do
    if setting.name=="Widgets" then
     if not table.find(setting.options,"WaterMark") then setting.options[#setting.options+1]="WaterMark" end
     if options.WaterMarkDefault~=false and not table.find(setting.default,"WaterMark") then setting.default[#setting.default+1]="WaterMark" end
    elseif setting.name=="BloomFlow Blur" or setting.name=="BloomFlow Blur radius" then
     local canonical=setting.name=="BloomFlow Blur" and "ArrayList Blur" or "ArrayList Blur radius"
     if not suppliedArrayList[canonical] then
      for _,other in ipairs(m.settings) do if other.name==canonical then other.default=setting.default end end
     end
     setting.when={op="eq",name="ArrayList mode",value="__LegacyAliasOnly"}
    end
   end
   -- Keep shadow controls at the top of HUD settings.
   do
    local priority={"HUD Color source","WaterMark Text size","BloomFlow Corner radius","ArrayList Blur","ArrayList Blur radius","WaterMark Blur","WaterMark Blur radius","WaterMark Glow","WaterMark Glow strength","WaterMark Glow radius","WaterMark Glow layers","WaterMark Flow speed","WaterMark Background opacity","ArrayList Shadow","ArrayList Shadow strength","ArrayList Shadow radius","ArrayList Shadow layers","Island State Duration","Widgets","ArrayList mode"}
    local promoted,seen={},{}
    for _,name in ipairs(priority) do
     for _,setting in ipairs(m.settings) do if setting.name==name then promoted[#promoted+1]=setting;seen[name]=true;break end end
    end
    for _,setting in ipairs(m.settings) do if not seen[setting.name] then promoted[#promoted+1]=setting end end
    m.settings=promoted
   end
   for _,name in ipairs({"Island Blur radius","BloomFlow Blur radius","TargetHUD Blur radius"}) do
    addHUDSetting({name=name,type="slider",default=options.HUDBlurOptions and options.HUDBlurOptions.radius or options.LocalBlurOptions and options.LocalBlurOptions.radius or 1,min=0,max=120,step=1})
   end
   addHUDSetting({name="TargetHUD Glow strength",type="slider",default=.5,min=0,max=1.6,step=.05})
   addHUDSetting({name="TargetHUD Glow radius",type="slider",default=24,min=6,max=72,step=1})
   addHUDSetting({name="TargetHUD Glow layers",type="slider",default=2,min=1,max=4,step=1})
   local found=false
   for _,setting in ipairs(m.settings) do if setting.name=="Island Background Transparency" then found=true end end
   if not found then m.settings[#m.settings+1]={name="Island Background Transparency",type="slider",default=options.IslandBackgroundTransparency or 40,min=0,max=100,step=1} end
   local speedFound=false;for _,setting in ipairs(m.settings) do if setting.name=="Island Animation Speed" then speedFound=true end end
   if not speedFound then m.settings[#m.settings+1]={name="Island Animation Speed",type="slider",default=options.IslandAnimationSpeed or 1,min=.25,max=3,step=.05} end
  end
 end
 for _,name in ipairs({"Scale","HUDScale"}) do local value=options[name];assert(value==nil or (type(value)=="number" and value==value and value>=.5 and value<=4),name.." must be between 0.5 and 4") end
 local parent=options.Parent or Players.LocalPlayer:WaitForChild("PlayerGui")
 -- Shutdown is owned by this UI, so repeat execution also works without writable globals.
 do
 local old=parent:FindFirstChild("SamsaraOpaiV2")
 if old then local shutdown=old:FindFirstChild("Shutdown");if shutdown and shutdown:IsA("BindableEvent") then shutdown:Fire() end;old:Destroy() end
 end
 uiDiagnostics.Stage="创建 UI 根容器"
 local gui=new("ScreenGui",parent,{Name="SamsaraOpaiV2",IgnoreGuiInset=true,ResetOnSpawn=false,DisplayOrder=2147483647,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
 -- Explicit full-screen coordinates: IgnoreGuiInset alone still leaves device safe insets.
 gui.ScreenInsets=Enum.ScreenInsets.None
 gui.ClipToDeviceSafeArea=false
 local shutdown=new("BindableEvent",gui,{Name="Shutdown"})
 local changed=new("BindableEvent",gui,{Name="Changed"})
  local api={Gui=gui,Changed=changed.Event,renderStepName="SyntaxUIRender"..Http:GenerateGUID(false)}
 local root=new("Frame",gui,{Name="Canvas",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=10})
 local scaling=new("UIScale",root,{Scale=UI.DefaultScale})
 local catcher=new("TextButton",gui,{Name="InputSurface",Text="",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),AutoButtonColor=false,Modal=true,ZIndex=1})
 root.ZIndex=2
 local blur=new("BlurEffect",Lighting,{Name="SamsaraOpaiV2Blur",Size=0})
 local conns,pools,columns,rows,state,hits={},{},{},{},{},{}
 local theme="Lavender"
 local visible,dead,opacity,opened=true,false,0,os.clock()
 local k,zoom,width,height,mx,my,offsetX,offsetY=UI.DefaultScale,1,960,540,-100,-100,0,0
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
 local islandBackgroundTransparency=options.IslandBackgroundTransparency or 40
 assert(type(islandBackgroundTransparency)=="number" and islandBackgroundTransparency==islandBackgroundTransparency and islandBackgroundTransparency>=0 and islandBackgroundTransparency<=100,"IslandBackgroundTransparency must be 0–100")
 local bridge={app=nil,syncing=false,suspended=false,style=nil,language=nil,scale=nil,animations=nil,islandAnimationSpeed=options.IslandAnimationSpeed or 1,bindings={}}
 assert(type(bridge.islandAnimationSpeed)=="number" and bridge.islandAnimationSpeed==bridge.islandAnimationSpeed and bridge.islandAnimationSpeed>=.25 and bridge.islandAnimationSpeed<=3,"IslandAnimationSpeed must be 0.25–3")
  local appearanceT=0
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
  function p:text(s,x,centerY,size,w,c,plain,align,rowParent)
   if w<=0 then return end
   self.ti+=1;local o=self.texts[self.ti]
   if not o then o=new("TextLabel",self.parent,{BackgroundTransparency=1,TextTruncate=Enum.TextTruncate.AtEnd,TextYAlignment=Enum.TextYAlignment.Center});self.texts[self.ti]=o end
    local scale=self.drawScale
    -- A pooled label may have belonged to a different ArrayList row last frame.
    local textParent=rowParent or self.parent
    if o.Parent~=textParent then o.Parent=textParent end
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
  if m.id=="HUD" then values["BloomFlow Blur"]=values["ArrayList Blur"];values["BloomFlow Blur radius"]=values["ArrayList Blur radius"] end
  state[m.id]={enabled=m.enabled==true,key="Unknown",settings=values}
  rows[m.id]={def=m,expanded=false,reveal=0,enabled=m.enabled and 1 or 0,hover=0,animations={}}
 end
 if state.HUD and state.HUD.settings["Island Background Transparency"]~=nil then islandBackgroundTransparency=state.HUD.settings["Island Background Transparency"] end
 if state.HUD and state.HUD.settings["Island Animation Speed"]~=nil then bridge.islandAnimationSpeed=state.HUD.settings["Island Animation Speed"] end
 local function selectedTheme() local s=state.ClickGUI;if s and palettes[s.settings["Opai Color"]] then return s.settings["Opai Color"] end;return theme end

 local customAccent
 local paletteCache
 local appearanceOpen=false
 local appearanceGeometry
 local appearanceSliding
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
 local function hudFlowColor(phase,period)
  local st=state.HUD and state.HUD.settings or {}
  if st["HUD Color source"]=="Palette" then return flowingColor(st["XHan Colors"] or "Starlight",0,period or 3,phase or 0) end
  if themeEffect=="FlowingGlow" then return flowingColor("Aurora",0,period or 5,phase or 0) end
  local source=state.Theme and state.Theme.settings or {}
  if not customAccent and source.Theme and sourceThemes[source.Theme] then return clientColor((phase or 0)*360) end
  local accent=customAccent or currentPalette().accent
  return mixColor(accent,0xFFFFFF,.12+.3*(math.sin((phase or 0)*math.pi*2)+1)/2)
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
  function api:SetIslandBackgroundTransparency(value)
   assert(type(value)=="number" and value==value and value>=0 and value<=100,"Transparency must be 0–100")
   islandBackgroundTransparency=value
   if state.HUD and state.HUD.settings["Island Background Transparency"]~=nil then self:SetSetting("HUD","Island Background Transparency",value) end
   notify("Appearance","islandBackgroundTransparency",value)
  end
  function api:SetIslandAnimationSpeed(value)
   assert(type(value)=="number" and value==value and value>=.25 and value<=3,"Island animation speed must be 0.25–3")
   bridge.islandAnimationSpeed=value
   if state.HUD and state.HUD.settings["Island Animation Speed"]~=nil then self:SetSetting("HUD","Island Animation Speed",value) end
   notify("Appearance","islandAnimationSpeed",value)
  end
  function api:BeginKeybind(id)
   local row=assert(rows[id],"Unknown module");if not visible then return false end
   if binding==row then binding=nil else binding=row end
   dropdown=nil;sliding=nil;drag=nil;bridge.RefreshBindings();return true
  end
  function api:CancelKeybind() binding=nil;bridge.RefreshBindings() end
  function api:SetKeybind(id,key)
   assert(state[id],"Unknown module");assert(type(key)=="string" and not key:find("+",1,true),"Syntax uses a single key")
   local ok,item=pcall(function() return Enum.KeyCode[key] end);assert(ok and item,"Invalid key")
   state[id].key=key;binding=nil;notify(id,"key",key);bridge.RefreshBindings()
  end
  function api:Translate(value) return localize(tostring(value)) end
  function api:GetAppearance() return {language=language,islandAnimationSpeed=bridge.islandAnimationSpeed,islandBackgroundTransparency=islandBackgroundTransparency,islandShadow=islandShadow,scale=options.Scale or k,hudScale=hudScale,accent=customAccent or false,effect=themeEffect,animations=animations,animationSpeed=animationSpeed,glowStrength=glowStrength} end
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
 function api:GetState() return {version=3,theme=selectedTheme(),appearance=api:GetAppearance(),hudLayout=copy(hudPlacements),modules=copy(state)} end
 function api:SetEnabled(id,value)
  assert(state[id] and type(value)=="boolean","Invalid module")
  if state[id].enabled==value then return end
  state[id].enabled=value;notify(id,"enabled",value)
  if postNotice and id~="HUD" then postNotice("module:"..id,"Module Toggled",rows[id].def.name.." has been ","toggle",value,(state.HUD and state.HUD.settings["Island State Duration"]) or 2) end
 end
 function api:SetSetting(id,name,value)
  local row=assert(rows[id],"Invalid module")
   for _,s in ipairs(row.def.settings or {}) do if s.name==name then assert(valid(s,value),"Invalid setting");state[id].settings[name]=copy(value)
    if id=="HUD" then
     local alias={['ArrayList Blur']='BloomFlow Blur',['BloomFlow Blur']='ArrayList Blur',['ArrayList Blur radius']='BloomFlow Blur radius',['BloomFlow Blur radius']='ArrayList Blur radius'}
     if alias[name] then state[id].settings[alias[name]]=copy(value) end
    end
    if id=="HUD" and name=="Island Shadow Strength" then islandShadow=value end;if id=="HUD" and name=="Island Background Transparency" then islandBackgroundTransparency=value end;if id=="HUD" and name=="Island Animation Speed" then bridge.islandAnimationSpeed=value end;notify(id,name,value);return end end
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
    if type(oldGUI)=="table" and type(oldGUI.settings)=="table" and oldGUI.settings.Style~=nil and oldGUI.settings.Style~="Neverlose" and oldGUI.settings.Style~="Opai" and oldGUI.settings.Style~="Jackal Neverlose" and oldGUI.settings.Style~="Jackal Opai" then oldGUI.settings.Style="Neverlose" end
   local incomingHUD=snapshot.modules.HUD
   if type(incomingHUD)=="table" and type(incomingHUD.settings)=="table" then
    local hudSettings=incomingHUD.settings
    for old,newName in pairs({['BloomFlow Blur']='ArrayList Blur',['BloomFlow Blur radius']='ArrayList Blur radius'}) do
     if hudSettings[newName]~=nil then hudSettings[old]=hudSettings[newName]
     elseif hudSettings[old]~=nil then hudSettings[newName]=hudSettings[old] end
    end
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
   for name,range in pairs({animationSpeed={.5,3},glowStrength={0,1},islandShadow={0,100},islandBackgroundTransparency={0,100},islandAnimationSpeed={.25,3}}) do local v=incomingAppearance[name];if v~=nil and (type(v)~="number" or v~=v or v<range[1] or v>range[2]) then return false,"Invalid "..name end end
   if incomingAppearance.language~=nil and incomingAppearance.language~="English" and incomingAppearance.language~="中文" then return false,"Invalid language" end
    if incomingAppearance.accent~=nil and incomingAppearance.accent~=false and not parseAccent(incomingAppearance.accent) then return false,"Invalid accent" end
  end
  if snapshot.hudLayout~=nil then
   if type(snapshot.hudLayout)~="table" then return false,"Invalid HUD layout" end
   for name,at in pairs(snapshot.hudLayout) do
    if (name~="ArrayList" and name~="TargetHUD" and name~="WaterMark") or type(at)~="table" then return false,"Invalid HUD panel" end
    for _,axis in ipairs({"x","y"}) do local v=at[axis];if type(v)~="number" or v~=v or math.abs(v)==math.huge then return false,"Invalid HUD position" end end
    local s=at.scale or 1;if type(s)~="number" or s~=s or s<.5 or s>2 then return false,"Invalid HUD scale" end
   end
  end
  local notifications={}
  for id,incoming in pairs(snapshot.modules) do state[id].enabled=incoming.enabled;state[id].key=incoming.key or "Unknown";notifications[#notifications+1]={id,"enabled",incoming.enabled};for name,value in pairs(incoming.settings) do if state[id].settings[name]~=nil then state[id].settings[name]=copy(value);notifications[#notifications+1]={id,name,value} end end end
  if snapshot.hudLayout then hudPlacements=copy(snapshot.hudLayout) end
  if snapshot.theme then self:SetTheme(snapshot.theme) end
   if state.HUD and state.HUD.settings["Island Shadow Strength"]~=nil then islandShadow=state.HUD.settings["Island Shadow Strength"] end
   if state.HUD and state.HUD.settings["Island Background Transparency"]~=nil then islandBackgroundTransparency=state.HUD.settings["Island Background Transparency"] end
   if state.HUD and state.HUD.settings["Island Animation Speed"]~=nil then bridge.islandAnimationSpeed=state.HUD.settings["Island Animation Speed"] end
   if incomingAppearance then if incomingAppearance.islandAnimationSpeed~=nil then self:SetIslandAnimationSpeed(incomingAppearance.islandAnimationSpeed) end;if incomingAppearance.islandBackgroundTransparency~=nil then self:SetIslandBackgroundTransparency(incomingAppearance.islandBackgroundTransparency) end;self:SetScale(incomingAppearance.scale or k);self:SetHUDScale(incomingAppearance.hudScale or hudScale);self:SetAccent(incomingAppearance.accent);self:SetThemeEffect(incomingAppearance.effect or "Source");self:SetAnimations(incomingAppearance.animations~=false);self:SetAnimationSpeed(incomingAppearance.animationSpeed or 1);self:SetGlowStrength(incomingAppearance.glowStrength or .75);if incomingAppearance.islandShadow~=nil then self:SetIslandShadow(incomingAppearance.islandShadow) end;self:SetLanguage(incomingAppearance.language or "English") end
  for _,entry in ipairs(notifications) do notify(entry[1],entry[2],entry[3]) end
  dropdown=nil;return true
 end
 function api:ExportJSON() return Http:JSONEncode(self:GetState()) end
 function api:ImportJSON(text) local ok,result=pcall(Http.JSONDecode,Http,text);if not ok then return false,"Invalid JSON" end;return self:ApplyState(result) end
 function api:Expand(id,value)
  local row=assert(rows[id]);assert(type(value)=="boolean");row.expanded=value;row.nlExpanded=value;dropdown=nil
  if bridge.app then bridge.app._expanded[id]=value;for _,entry in ipairs(bridge.app._entries) do if entry.Group.Id==id then entry.Expanded=value end end;bridge.app:_layout() end
 end
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
  k=options.Scale or UI.DefaultScale
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
      local title=content:text(binding==row and "Press a key" or row.def.name,P,ey+R/2,8.3,W-2*P-18,palette.text)
      title.TextColor3=rgb(palette.text):Lerp(rgb(palette.enabledText),row.enabled)
      hit(rect(x,y+H+ey,W,R),"module",row,bodyClip)
      if #(row.def.settings or {})>0 then
       local cx,cy=W-11,ey+R/2;local direction=1-2*row.reveal
       local left=content:box(cx-4,cy-1.5*direction,5,1.2,palette.text,1,.6);if left then left.Rotation=35*direction end
       local right=content:box(cx,cy-1.5*direction,5,1.2,palette.text,1,.6);if right then right.Rotation=-35*direction end
       hit(rect(x+W-25,y+H+ey,25,R),"expandModule",row,bodyClip)
      end
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

  local styleNames={Neverlose=true,Opai=true,["Jackal Neverlose"]=true,["Jackal Opai"]=true}
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
  local blurPane={active=false,unsupported=false,renderer=SampledLocalBlur.new(altGlass,{Profile=options.LocalBlurOptions,Inset=4,ScreenCoordinates=true})}
  function api:GetLocalBlurConfig()
   local result=blurPane.renderer:GetConfig()
   for key,name in pairs({radius="Local Blur radius",strength="Local Blur strength",smooth="Local Blur softness"}) do
    if state.ClickGUI and state.ClickGUI.settings[name]~=nil then result[key]=state.ClickGUI.settings[name] end
   end
   return result
  end
  function api:SetLocalBlurConfig(patch)
   blurPane.renderer:SetConfig(patch)
   for key,name in pairs({radius="Local Blur radius",strength="Local Blur strength",smooth="Local Blur softness"}) do
    if patch[key]~=nil and state.ClickGUI and state.ClickGUI.settings[name]~=nil then self:SetSetting("ClickGUI",name,patch[key]) end
   end
  end
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
 -- These native controls are direct ScreenGui children, outside Canvas UIScale.
 -- Both buttons use the same hover, press and activation handling.
 function front:setupFixedToolbar()
  self.toolbar={buttons={},root=new("Frame",gui,{Name="FixedToolbar",BackgroundTransparency=1,Size=UDim2.fromOffset(59,26.7),Visible=false,Active=false,ZIndex=1500})}
  local function addButton(label,action,x,textSize)
   local button=new("TextButton",self.toolbar.root,{Name=action,Text=label,Position=UDim2.fromOffset(x,0),Size=UDim2.fromOffset(26.7,26.7),Font=opaiFont(false),TextSize=textSize,TextScaled=false,TextWrapped=false,AutoButtonColor=false,Selectable=true,Active=true,ZIndex=1})
   local entry={button=button,x=x,action=action,hovered=false,t=0,pressed=nil}
   entry.corner=new("UICorner",button,{CornerRadius=UDim.new(0,5)})
   self.toolbar.buttons[#self.toolbar.buttons+1]=entry
   connect(button.MouseEnter,function() entry.hovered=true end)
   connect(button.MouseLeave,function() entry.hovered=false end)
   connect(button.InputBegan,function(input)
    if visible and (input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) then entry.pressed=input end
   end)
   connect(Input.InputEnded,function(input) if entry.pressed==input then entry.pressed=nil end end)
   connect(Input.WindowFocusReleased,function() entry.pressed=nil;entry.hovered=false end)
   connect(button.Activated,function()
    if dead or not visible then return end
    if action=="appearanceOpen" then api:OpenAppearance()
    else api:SetLanguage(language=="English" and "中文" or "English") end
   end)
  end
  addButton("中","languageToggle",0,9)
  addButton("Aa","appearanceOpen",32.3,10)
 end
 function front:drawFixedToolbar(frameDelta)
  local bar=self.toolbar;bar.root.Visible=root.Visible
  -- Leave room for the fixed mobile S shortcut as well.
  local mobileSpace=Input.TouchEnabled and 40 or 0
  bar.root.Position=UDim2.new(1,-99.3-mobileSpace,1,-34.7)
  local pal=currentPalette()
  for _,entry in ipairs(bar.buttons) do
   if not visible then entry.pressed=nil;entry.hovered=false end
   local active=entry.hovered or entry.pressed~=nil or (entry.action=="appearanceOpen" and appearanceOpen)
   entry.t=animations and ease(entry.t,active and 1 or 0,math.min(frameDelta,.1),12) or (active and 1 or 0)
   local expand=entry.t*1.2
   entry.button.Position=UDim2.fromOffset(entry.x-expand,-expand)
   entry.button.Size=UDim2.fromOffset(26.7+expand*2,26.7+expand*2)
   entry.corner.CornerRadius=UDim.new(0,5+expand)
   entry.button.BackgroundColor3=rgb(pal.field):Lerp(rgb(pal.selected),entry.t)
   entry.button.BackgroundTransparency=1-opacity;entry.button.TextTransparency=1-opacity
   entry.button.TextColor3=rgb(pal.accent);entry.button.Active=visible
   if entry.action=="languageToggle" then entry.button.Text=language=="English" and "中" or "EN" end
  end
 end
 front:setupFixedToolbar()
 connect(accentBox.FocusLost,function()
  if not appearanceOpen then return end
  local color=parseAccent(accentBox.Text)
  if color then api:SetAccent(color);appearanceError="" else appearanceError="Use six hexadecimal digits: #RRGGBB" end
 end)
 local function appearancePoint(x,y,w,h) local a=appearanceGeometry;return rect(a.x+x*a.s,a.y+y*a.s,w*a.s,h*a.s) end
 local function appearanceSlide(x)
  if not appearanceSliding then return end;local kind=appearanceSliding;local a=appearanceGeometry;local range=appearanceRanges[kind]
  local f=math.clamp(((x-a.x)/a.s-12)/200,0,1);local value=math.round((range[1]+f*(range[2]-range[1]))*20)/20
  if kind=="UI" then api:SetScale(value) elseif kind=="HUD" then api:SetHUDScale(value) elseif kind=="Speed" then api:SetAnimationSpeed(value) elseif kind=="Island" then api:SetIslandShadow(math.round(value)) elseif kind=="IslandBackground" then api:SetIslandBackgroundTransparency(math.round(value)) elseif kind=="IslandSpeed" then api:SetIslandAnimationSpeed(value) else api:SetGlowStrength(value) end
 end
  local function drawAppearance(frameDelta)
   appearanceT=animations and ease(appearanceT,appearanceOpen and 1 or 0,math.min(frameDelta,.1),11) or (appearanceOpen and 1 or 0)
   local reveal=appearanceT*appearanceT*(3-2*appearanceT)
   appearanceRoot.Visible=appearanceOpen or appearanceT>.01;accentBox.Visible=appearanceOpen
  if not appearanceRoot.Visible then return end
  searchBox.Visible=false;altName.Visible=false;editor.Visible=false;jsonEditor.Visible=false
    local h=436;local base=math.max(.05,math.min(2/k,(width-8)/224,(height-8)/h));local s=base*(.94+.06*reveal);local x,y=(width-224*s)/2,(height-h*s)/2
   appearanceGeometry={x=x,y=y,s=s};appearanceRoot.Position=UDim2.fromOffset(x,y);appearanceRoot.Size=UDim2.fromOffset(224,h);appearanceScale.Scale=s
   local p=appearancePaint;p.alpha=reveal;p:begin();local pal=currentPalette();p:box(0,0,224,h,pal.header,1,9)
   p:stroke(0,0,224,h,pal.outline,.45,9,1)
   p:text("Appearance",12,17,11,175,pal.text);p:text("×",200,17,15,14,pal.text);if appearanceOpen then hit(rect(0,0,width,height),"appearanceOutside");hit(appearancePoint(0,0,224,h),"appearanceBlock");hit(appearancePoint(196,6,22,22),"appearanceClose") end
  local function slider(label,value,yy,kind)
   local range=appearanceRanges[kind];p:text(label,12,yy,9,150,pal.text);p:text(kind=="Glow" and tostring(math.round(value*100)).."%" or (kind=="Island" or kind=="IslandBackground") and tostring(math.round(value)).."%" or string.format("%.2fx",value),158,yy,9,54,pal.text,false,Enum.TextXAlignment.Right)
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
   slider("Animation speed",animationSpeed,257,"Speed");slider("Island shadow",islandShadow,296,"Island");slider("Island background transparency",islandBackgroundTransparency,337,"IslandBackground");slider("Island animation speed",bridge.islandAnimationSpeed,378,"IslandSpeed")
    if appearanceError~="" then p:text(appearanceError,12,422,6.5,200,0xFF8585) else p:text("F7 · appearance     Ctrl + wheel · UI scale",12,422,6.5,200,pal.line) end
  p:finish()
 end

 local alt={x=0,y=0,s=1,scroll=0,target=0,max=0,nav=1,positions={},windows={},windowOrder={},sectionOffsets={},selection=96}
 local function altRect(r) return rect(alt.x+r.x*alt.s,alt.y+r.y*alt.s,r.w*alt.s,r.h*alt.s) end
 local function altHit(r,action,data,clip) if clip then r=intersection(r,clip) end;hit(altRect(r),action,data) end
 local function textWidth(text,size) return TextService:GetTextSize(tostring(text),size,Enum.Font.GothamMedium,Vector2.new(10000,10000)).X end
 local function line(p,x,y,xx,yy,c,t)
  local dx,dy=xx-x,yy-y;local len=math.sqrt(dx*dx+dy*dy);local o=p:box((x+xx-len)/2,(y+yy-(t or 1))/2,len,t or 1,c,1,(t or 1)/2);if o then o.Rotation=math.deg(math.atan2(dy,dx)) end
 end
 -- Neverlose image assets from Barlas/Neverlose (MIT; see LICENSE-Neverlose).
 local categoryIcon=(function()
 local neverloseIcons={
  [1]="rbxassetid://96677288280405", -- Combat: crosshairs
  [2]="rbxassetid://95400397758754", -- Targets: ghost
  [3]="rbxassetid://74350468513068", -- Movement: mouse
  [4]="rbxassetid://97066657594742", -- Player: user
  [5]="rbxassetid://83365140694071", -- Visuals: pallet
  [6]="rbxassetid://118512898552101", -- Misc: hammer
  [7]="rbxassetid://100793810819046", -- HUD editor: code
  [8]="rbxassetid://136566823798983", -- Configurations: save
  [10]="rbxassetid://136566823798983", -- Save
 }
 return function(p,index,x,y,size,c)
  local asset=activeStyle=="Neverlose" and neverloseIcons[index]
  if asset then
   local image=p:image(asset,x,y,size,size,0,c,1)
   if image then image.ScaleType=Enum.ScaleType.Fit end
   return
  end
  local u=size/24
  local function segment(ax,ay,bx,by,w) line(p,x+ax*u,y+ay*u,x+bx*u,y+by*u,c,(w or 1.9)*u) end
  local function ring(ax,ay,w,h,r) p:stroke(x+ax*u,y+ay*u,w*u,h*u,c,1,(r or w/2)*u,1.8*u) end
  local function dot(ax,ay,r) p:box(x+(ax-r)*u,y+(ay-r)*u,2*r*u,2*r*u,c,1,r*u) end
  if index==1 then -- Combat: paired blades.
   segment(4,3,20,19);segment(20,3,4,19);segment(3,15,8,20);segment(16,20,21,15);segment(3,3,3,8);segment(3,3,8,3);segment(21,3,16,3);segment(21,3,21,8)
  elseif index==2 then -- Targets: precise reticle.
   ring(5,5,14,14,7);dot(12,12,1.6);segment(12,1,12,6);segment(12,18,12,23);segment(1,12,6,12);segment(18,12,23,12)
  elseif index==3 then -- Movement.
   segment(4,5,11,12,2.4);segment(11,12,4,19,2.4);segment(13,5,20,12,2.4);segment(20,12,13,19,2.4)
  elseif index==4 then -- Player.
   ring(8,2,8,8,4);segment(4,22,4,18);segment(4,18,8,14);segment(8,14,16,14);segment(16,14,20,18);segment(20,18,20,22);segment(4,22,20,22)
  elseif index==5 then -- Visuals.
   segment(1,12,6,6);segment(6,6,18,6);segment(18,6,23,12);segment(23,12,18,18);segment(18,18,6,18);segment(6,18,1,12);ring(8,8,8,8,4)
  elseif index==6 then -- Misc: gear.
   ring(5,5,14,14,7);ring(9,9,6,6,3)
   for i=0,7 do local a=i*math.pi/4;segment(12+7*math.cos(a),12+7*math.sin(a),12+10.5*math.cos(a),12+10.5*math.sin(a),2.5) end
  elseif index==7 then -- HUD editor.
   ring(2,3,20,18,2);segment(9,3,9,21);segment(9,10,22,10);segment(13,16,18,16);segment(15.5,13.5,15.5,18.5)
  elseif index==8 then -- Configurations.
   segment(2,7,2,21);segment(2,7,9,7);segment(9,7,12,10);segment(12,10,22,10);segment(22,10,22,21);segment(22,21,2,21);segment(6,3,20,3);segment(20,3,20,7)
  elseif index==9 then -- Search.
   ring(3,3,13,13,6.5);segment(15,15,22,22,2.4)
  elseif index==10 then -- Save.
   ring(3,2,18,20,1.5);segment(7,2,7,9);segment(7,9,16,9);segment(16,9,16,2);ring(7,14,10,8,1)
  end
 end
 end)()
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
  local inset=7
  if action=="altSave" then categoryIcon(p,10,r.x+7,r.y+7,12,accentColor(0x3A85E2));inset=25 end
  p:text(label,r.x+inset,r.y+r.h/2,11.5,r.w-inset-8,0xBDC3C7,true)
  if action=="altConfigs" then line(p,r.x+r.w-13,r.y+r.h/2-1.5,r.x+r.w-10,r.y+r.h/2+1.5,0x8B979F,1.4);line(p,r.x+r.w-10,r.y+r.h/2+1.5,r.x+r.w-7,r.y+r.h/2-1.5,0x8B979F,1.4) end
  if action then altHit(r,action,data,clip) end
 end
  local function drawNeverlose(dt)
   local p=altPaint;local frost=state.ClickGUI and state.ClickGUI.settings["Local Blur"]~=false
    p:gradient(0,0,184,620,0x090A0A,0x0D0E0C,frost and .22 or .82,4);p:box(180,0,580,620,0x080808,frost and .18 or 1,4)
    if frost then p:stroke(0,0,760,620,0x51585C,.15,4,1) end
   p:box(180,0,1,620,0x242525,1);p:box(180,64,580,1,0x1C1D1D,1)
  p:text("SYNTAX",18,35,24,160,0x3A85E2)
  for i,name in ipairs({"Combat","Player","Visuals","Miscellaneous"}) do p:text(name,20,({79,183,287,355})[i],10.5,145,0x646B6D) end
  alt.selection=ease(alt.selection,navY[alt.nav],dt,30);p:box(10,alt.selection,160,29,0x3D3D3B,1,3)
  for i,name in ipairs(navNames) do categoryIcon(p,i,21,navY[i]+7.5,14,accentColor(0x3A85E2));p:text(name,47,navY[i]+14.5,12.5,115,i==alt.nav and 0xEDF3F5 or 0xBDC3C7);altHit(rect(10,navY[i],160,29),"altNav",i) end
   p:box(0,558,180,1,0x30322F,1);p:box(13,572,34,34,0x20323F,1,17)
   local avatarId=Players.LocalPlayer.UserId
   if avatarId and avatarId>0 then p:image("rbxthumb://type=AvatarHeadShot&id="..avatarId.."&w=150&h=150",13,572,34,34,17) end
   p:text(options.Username or Players.LocalPlayer.DisplayName or "Player",57,581,12,113,0xEDF3F5);p:text("Syntax",57,597,10.5,113,0x3A85E2)
  styleField(p,rect(202,19,330,27),"",nil,nil);styleField(p,rect(544,19,70,27),"Save","altSave");styleField(p,rect(626,19,112,27),config.selected or "Preset","altConfigs")
  searchBox.Visible=true;searchBox.PlaceholderText="Press CTRL+F to search within GUI";searchBox.TextSize=12*alt.s;searchBox.TextColor3=rgb(0xBDC3C7);searchBox.PlaceholderColor3=rgb(0x697277);searchBox.Position=UDim2.fromOffset(alt.x+232*alt.s,alt.y+21*alt.s);searchBox.Size=UDim2.fromOffset(291*alt.s,23*alt.s)
  categoryIcon(p,9,211,26,11,0x677077)
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
    if row.nlExpanded==nil then row.nlExpanded=false;row.nlReveal=0 end
    row.nlReveal=ease(row.nlReveal or 0,row.nlExpanded and 1 or 0,dt,30)
    local height=28+(29*(#settings+(row.def.hidden and 0 or 1)))*row.nlReveal
    local col=alt.packing[row.def.id] or (ends[1]<=ends[2] and 1 or 2);alt.packing[row.def.id]=col;local xx=(col-1)*280;local yy=ends[col]-alt.scroll;ends[col]+=height+4
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
    altGlass.Visible=frost;altGlass.BackgroundTransparency=1-.05*opacity
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
  elseif a=="bind" then api:BeginKeybind(d.def.id);return
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
  elseif a=="expandModule" and button==0 then d.expanded=not d.expanded;dropdown=nil
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
 api.HUDLayer=new("Frame",gui,{Name="HUDOverlay",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=3,Active=false})
 api.arrayListShadow=ArrayListShadow.new(api.HUDLayer,{
  imageId=options.SmoothGlowImageId or UI.SmoothGlowImageId,
  onUnavailable=function(reason)
   if not dead then
    reason=reason:gsub("Using original glow", "ArrayList shadow disabled")
    warn("[SyntaxUI ArrayList Shadow] "..reason);api:Notify("ArrayList shadow",reason,"warning",7)
   end
  end})
 local island=new("Frame",api.HUDLayer,{Name="DynamicIsland",BackgroundTransparency=1,ZIndex=20})
 local shell=pool(island,true)
  local islandBackdrop=new("Frame",island,{Name="Backdrop",BackgroundColor3=rgb(0x000000),BackgroundTransparency=1-0x98/255,BorderSizePixel=0,ZIndex=30})
  local islandCorner=new("UICorner",islandBackdrop,{CornerRadius=UDim.new(0,12)})
 -- Jackal soft shadows are pooled native layers beneath the opaque surface.
 local islandClip=new("Frame",island,{Name="Content",BackgroundTransparency=1,ClipsDescendants=true,ZIndex=100})
 local ink=pool(islandClip,true)
  ink.fixedText=true
 local widgetRoot=new("Frame",api.HUDLayer,{Name="Widgets",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=10})
 local widgets=pool(widgetRoot,true)
 local hudControls=new("Frame",hudRoot,{Name="HUDControls",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=5000})
  local hudHint=new("TextButton",hudControls,{Name="Done",Text="HUD Editor · drag / scroll to resize · click here to finish",Size=UDim2.fromOffset(430,32),Position=UDim2.new(.5,-215,1,-44),BackgroundColor3=rgb(0x1C1F29),TextColor3=rgb(0xE4E1E6),Font=opaiFont(false),TextSize=14,Visible=false,AutoButtonColor=false,ZIndex=100})
 connect(hudHint.Activated,function() api:SetVisible(true) end)
 function api:EditHUD() api:SetVisible(false);hudEditing=true;if state.HUD then state.HUD.enabled=true end end
 function api:GetHUDLayout() return copy(hudPlacements) end
 function api:SetHUDLayout(name,x,y,scale)
   assert(name=="ArrayList" or name=="TargetHUD" or name=="WaterMark","Unknown draggable HUD")
  assert(type(x)=="number" and x==x and math.abs(x)<math.huge and type(y)=="number" and y==y and math.abs(y)<math.huge,"Invalid HUD position")
  scale=scale or 1;assert(type(scale)=="number" and scale==scale and scale>=.5 and scale<=2,"Invalid HUD scale")
  hudPlacements[name]={x=x,y=y,scale=scale}
 end
 local function placeWidget(name,x,y,w,h)
  local at=hudPlacements[name];local view=gui.AbsoluteSize
  x=math.clamp(at and at.x or x,2,math.max(2,view.X-w-2));y=math.clamp(at and at.y or y,2,math.max(2,view.Y-h-2))
  hudBounds[name]=rect(x,y,w,h);return x,y
 end
 uiDiagnostics.Stage="创建 TargetHUD 与 V3 Smooth"
 local targetHUD=createSyntaxTargetHUD(hudRoot,SmoothGlow.new,{
  imageId=options.SmoothGlowImageId or UI.SmoothGlowImageId,
  onUnavailable=function(reason)
   if not dead then
    reason=reason:gsub("Using original glow", "TargetHUD glow disabled")
    warn("[SyntaxUI TargetHUD Glow] "..reason);api:Notify("TargetHUD glow",reason,"warning",7)
   end
  end})
 function api:SetTargetHUD(info)
  assert(info==nil or type(info)=="table","TargetHUD data must be a table or nil")
  targetHUD.Current=info and copy(info)
 end
 function api:GetTargetHUDState() return targetHUD:Inspect() end
 api.waterMark=WaterMark.new(api.HUDLayer,{
  text=options.WaterMarkText or "Syntax",color=function(phase) return hudFlowColor(phase,3) end,imageId=options.SmoothGlowImageId or UI.SmoothGlowImageId,
  onUnavailable=function(reason) if not dead then warn("[SyntaxUI WaterMark Glow] "..reason) end end})
 function api:SetWaterMarkText(value) self.waterMark:SetText(value) end
 function api:GetWaterMarkState() return self.waterMark:Inspect() end
  local hudControlPriority={ArrayList=10,TargetHUD=40,WaterMark=60}
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
   text=localize(tostring(text));local scale=islandState.renderScale or hudScale
   local physicalSize=math.max(1,math.round(size*scale));local key="w:"..physicalSize..":"..scale..":"..tostring(plain)..":"..text
   if measureCache[key] then return measureCache[key] end
   local bounds=TextService:GetTextSize(text,physicalSize,opaiFont(plain),Vector2.new(10000,10000))
   if cacheCount>600 then measureCache={};cacheCount=0 end
   local measured=math.ceil(bounds.X/scale)+3;measureCache[key]=measured;cacheCount+=1;return measured
  end
  local function wrappedHeight(text,size,width,plain)
   text=localize(tostring(text));if text=="" then return 0 end
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
  local duration=(state.HUD and state.HUD.settings["Island State Duration"]) or 2
  local deadline=islandState.lastToggleAt and islandState.lastToggleAt+duration
  for i=#notices,1,-1 do
   local notice=notices[i]
   if notice.kind=="toggle" and deadline then notice.untilTime=deadline end
   if os.clock()>=notice.untilTime then table.remove(notices,i) end
  end
 end
 postNotice=function(key,title,detail,kind,value,duration)
  if dead then return end;expireNotices()
  local n;for _,v in ipairs(notices) do if v.key==key then n=v;break end end
  if not n then n={key=key,width=0,started=os.clock(),toggle=value and 0 or 1};notices[#notices+1]=n end
  if kind=="toggle" then
   -- A burst has one expiry boundary: an older row cannot collapse the panel
   -- while the next module's toggle state is still being shown.
   islandState.lastToggleAt=os.clock()
   local deadline=islandState.lastToggleAt+duration
   for _,active in ipairs(notices) do
    if active.kind=="toggle" then active.untilTime=deadline end
   end
  end
  n.sourceTitle=tostring(title);n.sourceDetail=tostring(detail or "");n.title=n.sourceTitle;n.detail=n.sourceDetail;n.kind=kind;n.value=value;n.untilTime=os.clock()+duration
    if kind=="toggle" then n.started=os.clock();n.animationStarted=islandState.animationTime or 0;n.toggleFrom=n.toggle end
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
  if name=="SYNTAX" then
   local u=size/24
   for _,segment in ipairs({{4,5,11,12},{11,12,4,19},{13,19,21,19}}) do
    local ax,ay,bx,by=table.unpack(segment);local dx,dy=(bx-ax)*u,(by-ay)*u;local length=math.sqrt(dx*dx+dy*dy)
    local o=p:box(x+(ax+bx)*u/2-length/2,y+(ay+by)*u/2-u,length,2*u,color,1,u)
    if o then o.Rotation=math.deg(math.atan2(dy,dx)) end
   end
   return
  end
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
 local function releaseArrayClip(item)
  if not item.clip then return end
  for _,child in ipairs(item.clip:GetChildren()) do child.Parent=item.clip.Parent;child.Visible=false end
  item.clip:Destroy();item.clip=nil
 end
 local function clearArrayEntries(entries)
  for _,item in pairs(entries) do releaseArrayClip(item) end
  table.clear(entries)
 end
 local suffixOverrides={}
 function api:SetModuleSuffix(id,value) assert(rows[id],"Unknown module");assert(value==nil or type(value)=="string");suffixOverrides[id]=value end
 local function arraySpring(s,target,dt,rate,immediate)
  if target~=s.target then if immediate then s.velocity=rate*(target-s.value) end;s.target=target end
  local offset=s.value-s.target;local linear=s.velocity+rate*offset;local decay=math.exp(-rate*math.max(0,dt))
  s.value=s.target+(offset+linear*dt)*decay;s.velocity=(s.velocity-rate*linear*dt)*decay
  if math.abs(s.value-target)<.001 and math.abs(s.velocity)<.05 then s.value=target;s.velocity=0 end
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
 -- Opacity, clipping and occupied height share one presence value. An invisible
 -- exiting row must not keep a slower, independent spacer in the stack.
 function xhan.updatePresence(item,target,dt)
  item.enabled=target
  if not animations then item.motion=spring(target and 1 or 0) end
  item.progress=arraySpring(item.motion,target and 1 or 0,dt,25,true)
  item.alpha=item.progress;item.contribution=item.progress
  return target or item.progress>0
 end
 function xhan.pixel(value) return math.floor(value+.5) end
 -- Round shared boundaries, never each row's Y and height independently.
 -- This keeps adjacent frames, backgrounds and click targets touching even
 -- at fractional HUD scales, while zero-pixel animation rows draw nothing.
 function xhan.stackRows(items,rowHeight,scale,top)
  local origin=xhan.pixel(top);local boundary=origin;local occupied=0;local visibleRows={}
  for _,item in ipairs(items) do
   occupied+=item.contribution*rowHeight*scale
   local nextBoundary=xhan.pixel(top+occupied)
   item.drawY=boundary;item.drawH=nextBoundary-boundary
   if item.drawH>0 then visibleRows[#visibleRows+1]=item end
   boundary=nextBoundary
  end
  return visibleRows,boundary-origin
 end
 xhan.root=new("Frame",api.HUDLayer,{Name="StarlightArrayList",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=7000,Visible=false,Active=false})
 xhan.smooth=SmoothGlow.new(xhan.root,{imageId=options.SmoothGlowImageId or UI.SmoothGlowImageId,onUnavailable=function(reason)
  if not dead then warn("[SyntaxUI Smooth Glow] "..reason);api:Notify("Smooth glow",reason,"warning",7) end
 end})
 xhan.contour=ListContour.new(xhan.root)
 xhan.smooth.root.ZIndex=100
 xhan.paint=pool(new("Frame",xhan.root,{Name="ArrayListDecorations",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=30,Active=false}),true)
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
    local mode=display=="BloomFlow" and "BloomFlow" or "None";local bloom=mode=="BloomFlow";xhan.contour:Begin(true);local colors=st["XHan Colors"] or "Starlight"
  local strength=(st["XHan Shadow Strength"] or 78)/100;local size=st["XHan Text size"] or 15
     local rowH=bloom and math.max(size+2,(st["XHan Row height"] or 22)-3) or size+2
   local gap=0;local extra=0
  local allowed=st["XHan Categories"] or categoryOrder;local candidates={}
  for order,def in ipairs(options.Modules or {}) do
   local id=def.id;local row=rows[id];local target=state[id].enabled and not def.hidden and table.find(allowed,def.category)~=nil
   local item=xhan.entries[id]
    if target and not item then item={id=id,enabled=false,motion=spring(0)};xhan.entries[id]=item end
   if item then
     if xhan.updatePresence(item,target,dt) then
      item.name=localize(def.name or displayName(id));item.suffix=st["XHan Show suffix"]~=false and moduleSuffix(row) or "";item.mode=item.suffix~="" and " "..item.suffix or ""
       item.nameWidth=xhanMeasure(item.name,size);item.modeWidth=xhanMeasure(item.mode,size);item.width=math.ceil(item.nameWidth+item.modeWidth+(bloom and 12 or 13)+extra);item.order=order
      candidates[#candidates+1]=item
     elseif not target then releaseArrayClip(item);xhan.entries[id]=nil end
   end
  end
  table.sort(candidates,function(a,b)
   -- Exact ordering is transitive; epsilon comparisons can disagree when
   -- asynchronous font measurements reorder several nearly equal widths.
   if a.width~=b.width then return a.width>b.width end
   if a.nameWidth~=b.nameWidth then return a.nameWidth>b.nameWidth end
   if a.name:lower()~=b.name:lower() then return a.name:lower()<b.name:lower() end;return a.order<b.order
  end)
   local occupied=0
   for _,item in ipairs(candidates) do occupied+=item.contribution*rowH end
    local widest=#candidates>0 and candidates[1].width or 0;local listH=math.max(0,occupied-gap)
  -- Reference defaults are in pixels; Samsara HUDScale=2 maps to the original 15/22px typography.
  local q=factor/2*(hudPlacements.ArrayList and hudPlacements.ArrayList.scale or 1)
   local fullHeight=math.max(1,#candidates*(rowH+gap)-gap)
   q=math.min(q,(view.X-36)/math.max(1,widest),(view.Y-32)/fullHeight)
  local at=hudPlacements.ArrayList;local right=at and at.x+widest*q or view.X-18*q;local top=at and at.y or 28*q
  right=math.clamp(right,widest*q+2,math.max(widest*q+2,view.X-2));top=math.clamp(top,2,math.max(2,view.Y-listH*q-2))
   local pixelHeight
   candidates,pixelHeight=xhan.stackRows(candidates,rowH,q,top)
   top=xhan.pixel(top)
   local smoothRequested=(st["Glow renderer"] or "V3 Smooth")=="V3 Smooth"
   local smoothPower=st["Smooth Glow strength"] or .5
   xhan.smooth:Begin(smoothRequested and st["XHan Glow"]~=false and #candidates>0,smoothPower,st["Smooth Glow layers"] or 2)
   local smooth=smoothRequested and xhan.smooth.state~="unavailable"
   arrayMetrics={shadowScale=q,mode=bloom and "BloomFlow" or "XHan",display=mode,palette=colors,glow=st["XHan Glow"]~=false,glowRenderer=smoothRequested and "V3 Smooth" or "Original",glowZIndex=xhan.smooth.root.ZIndex,contourZIndex=xhan.contour.root.ZIndex,textZIndex=3000,width=widest*q,height=pixelHeight,rows={}}
  if #candidates>0 then hudBounds.ArrayList=rect(right-widest*q,top,widest*q,pixelHeight) end
  local p=xhan.paint
  for _,item in pairs(xhan.entries) do if item.clip then item.clip.Visible=false end end
  local textClip
  local function text(value,x,y,w,color,alpha)
   if value=="" then return end
   local label=p:text(value,x,y,size*q,w*q+1,color,false,Enum.TextXAlignment.Right,textClip)
   if label then
    if textClip then label.Parent=textClip;label.Position=UDim2.fromOffset(x-textClip.Position.X.Offset,y-size*q-textClip.Position.Y.Offset) end
    if xhan.font then label.FontFace=xhan.font end;label.TextTransparency=1-alpha
   end
  end
   local total=math.max(1,#candidates)
    local flowPeriod=math.max(.5,st["XHan Flow speed"] or 3)
   for i,item in ipairs(candidates) do
    local offset=(item.width+8)*(1-item.progress)
    item.drawW=math.max(1,xhan.pixel(item.width*q))
    item.drawX=xhan.pixel(right+offset*q)-item.drawW;item.edgeH=item.drawH
    item.topColor=bloom and hudFlowColor(((i-1)/total)*.92,flowPeriod) or nil
    item.bottomColor=bloom and hudFlowColor((i/total)*.92,flowPeriod) or nil
    item.color=hudFlowColor(((i-.5)/total)*.92,flowPeriod)
    arrayMetrics.rows[i]={id=item.id,name=item.name,suffix=item.suffix,x=item.drawX,y=item.drawY,width=item.drawW,height=item.drawH,offset=offset*q,alpha=item.alpha,color=item.color,progress=item.progress,contribution=item.contribution,radius=bloom and 0 or 4,enabled=item.enabled}
   end
   for i,item in ipairs(candidates) do
    local row=arrayMetrics.rows[i]
    row.topColor=bloom and item.topColor or hudFlowColor((i-1)/total,st["XHan Flow speed"] or 3)
    row.bottomColor=bloom and item.bottomColor or hudFlowColor(i/total,st["XHan Flow speed"] or 3)
   end
   ListContour.Shape(arrayMetrics.rows,(st["BloomFlow Corner radius"] or 3)*q)
   for i,item in ipairs(candidates) do
    local row=arrayMetrics.rows[i];xhan.contour:Draw(row,q)
    local x,y,w,h=row.x,row.y,row.width,row.height
    if bloom and st["XHan Glow"]~=false then
     if smooth then xhan.smooth:Draw(x,y,w,h,item.color,item.alpha,st["Smooth Glow radius"] or 30,q)
     else
      p:image("rbxassetid://104490578391522",x-19*q,y-13*q,w+38*q,h+26*q,0,item.color,.32*strength*item.alpha,true)
      p:image("rbxassetid://102472648910048",x-11*q,y-8*q,w+22*q,h+16*q,0,item.color,.46*strength*item.alpha,true)
     end
    end
   end
   xhan.contour:Finish()
   for i,item in ipairs(candidates) do
    local x,y,w,h=item.drawX,item.drawY,item.drawW,item.drawH
    local color,fade=item.color,item.alpha
    if not item.clip then item.clip=new("Frame",xhan.root,{Name=item.id.."TextSlot",BackgroundTransparency=1,ClipsDescendants=true,ZIndex=3000}) end
    item.clip.Visible=true;item.clip.Position=UDim2.fromOffset(x-2*q,y);item.clip.Size=UDim2.fromOffset(w+4*q,h)
    textClip=item.clip
    if not bloom and st["XHan Glow"]~=false then
     if smooth then xhan.smooth:Draw(x,y,w,h,color,fade,st["Smooth Glow radius"] or 30,q)
     else local alpha=1-math.clamp(.94-.78*strength,.12,.94);p:glow(x-18*q,y-5*q,w+36*q,h+10*q,color,alpha*fade) end
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
  xhan.smooth:Finish()
  p:finish()
 end
local function drawArrayList(dt,view,factor,st,p)
  xhan.smooth:Begin(false,0,2);xhan.smooth:Finish()
   local mode=st["ArrayList mode"] or "XHan";local opai=mode=="Opai";xhan.root.Visible=false
  if not widgetEnabled("ArrayList") then clearArrayEntries(arrayEntries);clearArrayEntries(xhan.entries);arrayMode=nil;arrayMetrics={};return end
  if arrayMode~=mode then clearArrayEntries(arrayEntries);clearArrayEntries(xhan.entries);arrayMode=mode end
    if mode=="XHan" or mode=="BloomFlow" then drawXHan(dt,view,factor,st,mode);return end
    local lower=st[opai and "Opai Lowercase" or "Lowercase"]
  local showSuffix=st[opai and "Opai Show suffix" or "Show suffix"]
  local allowed=st[opai and "Opai Categories" or "Categories"] or categoryOrder
  local font=opai and Enum.Font.GothamBold or Enum.Font.GothamMedium;local size=opai and 9.08 or 8;local candidates={}
  for id,row in pairs(rows) do
   local item=arrayEntries[id]
   if not item then item={id=id,motion=spring(0),enabled=false};arrayEntries[id]=item end
   local label=localize(row.def.name or displayName(id));local suffix=showSuffix and moduleSuffix(row) or ""
   if lower then label=label:lower();suffix=suffix:lower() end
   item.name=label;item.suffix=suffix;item.font=font;item.nameWidth=arrayMeasure(label,size,font);item.gap=suffix~="" and arrayMeasure(" ",size,font) or 0
   item.text=label..(suffix~="" and " "..suffix or "");item.width=opai and (3+item.nameWidth+item.gap+arrayMeasure(suffix,size,font)+2+1) or arrayMeasure(item.text,size,font)
   item.target=state[id].enabled and not row.def.hidden and table.find(allowed,row.def.category)~=nil;candidates[#candidates+1]=item
  end
  table.sort(candidates,function(a,b)if a.width==b.width then return a.id<b.id end;return a.width>b.width end)
  local occupied=0;local visible={}
  for _,item in ipairs(candidates) do
   if xhan.updatePresence(item,item.target,dt) then
    visible[#visible+1]=item;occupied+=item.contribution*12
   end
  end
  for _,item in pairs(arrayEntries) do if item.clip then item.clip.Visible=false end end
  local function rowText(item,value,x,y,size,w,color,plain,align)
   local label=widgets:text(value,x,y,size,w,color,plain,align,item.clip)
   if label then
    label.Parent=item.clip;label.Position=UDim2.fromOffset(label.Position.X.Offset-item.clip.Position.X.Offset,label.Position.Y.Offset-item.clip.Position.Y.Offset)
    label.TextTransparency=1-(1-label.TextTransparency)*item.alpha
   end
   return label
  end
  local scale=factor*(hudPlacements.ArrayList and hudPlacements.ArrayList.scale or 1)
  local widest=#visible>0 and visible[1].width or 0;local at=hudPlacements.ArrayList
  scale=math.min(scale,(view.X-4)/math.max(1,widest+8),(view.Y-4)/math.max(1,#visible*12))
  local right=at and at.x+widest*scale or (view.X-(opai and .5*scale or 0));local top=at and at.y or 0
  right=math.clamp(right,widest*scale+1,math.max(widest*scale+1,view.X));top=math.clamp(top,0,math.max(0,view.Y-occupied*scale))
  local pixelHeight
  visible,pixelHeight=xhan.stackRows(visible,12,scale,top)
  top=xhan.pixel(top)
  arrayMetrics={shadowScale=scale,mode=opai and "Opai" or "Default",rows={},width=widest*scale,height=pixelHeight}
  if #visible>0 then hudBounds.ArrayList=rect(math.max(0,right-widest*scale),top,widest*scale,pixelHeight) end
  local background=st[opai and "Opai Background" or "Background"]~=false
  for i,item in ipairs(visible) do
    item.x=right-item.width*scale+(item.width+8)*(1-item.progress)*scale
    item.py=item.drawY;item.slotHeight=item.drawH
    if not item.clip then item.clip=new("Frame",widgetRoot,{Name=item.id.."ArraySlot",BackgroundTransparency=1,ClipsDescendants=true,ZIndex=100}) end
    item.clip.Visible=true;item.clip.Position=UDim2.fromOffset(item.x-7*scale,item.py);item.clip.Size=UDim2.fromOffset((item.width+8)*scale,item.slotHeight)
   item.radius=math.min(5,math.max(0,item.width-(visible[i+1] and visible[i+1].width or 0)))
   arrayMetrics.rows[i]={id=item.id,name=item.name,suffix=item.suffix,x=item.x,y=item.py,width=item.width*scale,height=item.slotHeight,alpha=item.alpha,enabled=item.enabled,progress=item.progress,contribution=item.contribution,radius=item.radius}
  end
  if opai then
   -- All styles use the shared bottom shadow layer.
   if background then for _,item in ipairs(visible) do bottomLeftShape(item.x,item.py,item.width*scale,item.slotHeight,item.radius*scale,0x101010,.8*item.alpha) end end
   for _,item in ipairs(visible) do
    local label=rowText(item,item.name,item.x+3*scale,item.py+item.slotHeight/2,9.08*scale,item.nameWidth*scale+1,0xFFFFFF);if label then label.Font=font end
    if item.suffix~="" then local label=rowText(item,item.suffix,item.x+(3+item.nameWidth+item.gap)*scale,item.py+item.slotHeight/2,9.08*scale,math.max(1,(item.width-6-item.nameWidth-item.gap)*scale+1),p.accent);if label then label.Font=font end end
   end
   if st["Opai Right line"]~=false then for _,item in ipairs(visible) do widgets:box(item.x+(item.width-1)*scale,item.py,scale,item.slotHeight,p.accent,item.alpha,0) end end
  else
   local bar=st["Bar mode"] or "Left"
   for i,item in ipairs(visible) do
    local color=clientColor((i-1)*20);local x,y=item.x,item.py;local w=item.width*scale
    if background then widgets:box(x-6.5*scale,y,w+6.5*scale,item.slotHeight,0x090909,.5*item.alpha,0) end
    if bar~="None" then local bx=bar=="Left" and x-4.5*scale or x+w-2.5*scale;widgets:box(bx+.5*scale,y+2.5*scale,scale,math.max(0,math.min(8*scale,item.slotHeight-2.5*scale)),0x000000,.55*item.alpha,scale);widgets:box(bx,y+2*scale,scale,math.max(0,math.min(8*scale,item.slotHeight-2*scale)),color,item.alpha,scale) end
    local offset=bar=="Left" and 2 or bar=="None" and 3.5 or 4.25
    rowText(item,item.text,x-offset*scale+.5*scale,y+item.slotHeight/2+.5*scale,8*scale,w+1,0x000000)
    rowText(item,item.text,x-offset*scale,y+item.slotHeight/2,8*scale,w+1,color)
   end
  end
 end

 local function drawHUDWidgets(dt,frameDelta)
   widgets:begin();hudBounds={};local view=gui.AbsoluteSize;local factor=hudScale
  if visible and activeStyle:match("^Jackal ") and not hudEditing then
   widgetRoot.Visible=false;xhan.root.Visible=false;targetHUD.Host.Visible=false;hudControls.Visible=false;xhan.smooth:Begin(false,0,2);xhan.smooth:Finish()
   api.waterMark:Step({},view,hudScale,nil,false,dt,{})
   widgets:finish();return
  end
  local p=currentPalette();local st=state.HUD and state.HUD.settings or {}
  factor=math.min(factor,math.max(.1,(view.X-4)/182),math.max(.1,(view.Y-4)/166))
  local function text(t,x,y,size,w,color) widgets:text(t,x,y,size,w,color or p.text) end
  drawArrayList(dt,view,factor,st,p)

  local target=targetHUD.Current
  if not target and islandState.target then
   local t=islandState.target
   target={Key=t.userId or t.name,Name=t.name,Health=t.health,MaxHealth=t.maxHealth,
    Avatar=t.userId and ("rbxthumb://type=AvatarHeadShot&id="..t.userId.."&w=150&h=150") or nil,Initial=t.initial or "?"}
  end
  local preview=not target and (visible or hudEditing)
  local shown=(target~=nil or preview or targetHUD.Frame.Visible) and (widgetEnabled("TargetHUD") or hudEditing)
  targetHUD.Host.Visible=shown
  if shown then
   local scale=math.min(hudScale/2*(hudPlacements.TargetHUD and hudPlacements.TargetHUD.scale or 1),
    (view.X-4)/292,(view.Y-4)/76)
   local w,h=292*scale,76*scale
   local x,y=placeWidget("TargetHUD",view.X*.5-w*.5,view.Y*.30-h*.5,w,h)
   targetHUD.Host.Position=UDim2.fromOffset(x,y);targetHUD.LayoutScale.Scale=scale
   if preview then targetHUD:Preview() else targetHUD:Update(target) end
  else targetHUD:Update(nil) end

  api.waterMark:Step(st,view,hudScale,hudPlacements.WaterMark,widgetEnabled("WaterMark"),frameDelta or dt,{})
  if api.waterMark.root.Visible then hudBounds.WaterMark=api.waterMark.bounds end
  widgets:finish();updateHUDControls()
 end
 uiDiagnostics.Stage="创建三个 HUD 模糊区域"
 local hudEffects=(function()
 -- HUD blur panes share a 4ms cooperative work target, never one sampler per row.
 -- Merge validated HUD overrides onto the recording profile, not onto a new UI state.
 local hudBlurProfile=SampledLocalBlur.Profile(options.LocalBlurOptions)
 hudBlurProfile.band=1
 for key,value in pairs(options.HUDBlurOptions or {}) do hudBlurProfile[key]=value end
 hudBlurProfile=SampledLocalBlur.Profile(hudBlurProfile)
 local hudBlurPanes={
  Island={host=new("Frame",island,{Name="IslandLocalBlur",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=29}),profile=table.clone(hudBlurProfile)},
  ArrayList={host=new("Frame",api.HUDLayer,{Name="ArrayListLocalBlur",BackgroundTransparency=1,ZIndex=0,Active=false}),profile=table.clone(hudBlurProfile)},
  WaterMark={host=api.waterMark.blur,profile=table.clone(hudBlurProfile)},
  TargetHUD={host=new("Frame",targetHUD.Frame,{Name="TargetHUDLocalBlur",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),ZIndex=0}),profile=table.clone(hudBlurProfile)},
 }
 local radiusSettings={Island="Island Blur radius",ArrayList="ArrayList Blur radius",TargetHUD="TargetHUD Blur radius",WaterMark="WaterMark Blur radius"}
 function api:GetHUDBlurConfig(name)
  if name=="BloomFlow" then name="ArrayList" end
  local result=table.clone(assert(hudBlurPanes[name],"Unknown HUD blur").profile)
  local value=state.HUD and state.HUD.settings[radiusSettings[name]]
  if value~=nil then result.radius=value end
  for key,suffix in pairs({strength=" strength",smooth=" softness"}) do
   local value=state.HUD and state.HUD.settings[name.." Blur"..suffix]
   if value~=nil then result[key]=value end
  end
  return result
 end
 function api:SetHUDBlurConfig(name,patch)
  if name=="BloomFlow" then name="ArrayList" end
  local pane=assert(hudBlurPanes[name],"Unknown HUD blur")
  local nextProfile=table.clone(pane.profile)
  -- Use the same atomic validator as the ClickGUI/test renderer.
  local validated=SampledLocalBlur.Profile(patch)
  for key in pairs(patch) do nextProfile[key]=validated[key] end
  pane.profile=nextProfile
  if pane.renderer then pane.renderer:SetConfig(patch) end
  if patch.radius~=nil and state.HUD and state.HUD.settings[radiusSettings[name]]~=nil then self:SetSetting("HUD",radiusSettings[name],patch.radius) end
  for key,suffix in pairs({strength=" strength",smooth=" softness"}) do
   local setting=name.." Blur"..suffix
   if patch[key]~=nil and state.HUD and state.HUD.settings[setting]~=nil then self:SetSetting("HUD",setting,patch[key]) end
  end
 end
 function api:ApplyRecordedBlurPreset()
  local patch=table.clone(SampledLocalBlur.Defaults)
  self:SetLocalBlurConfig(patch)
  for _,region in ipairs({"Island","ArrayList","TargetHUD","WaterMark"}) do self:SetHUDBlurConfig(region,patch) end
  return self:GetLocalBlurConfig()
 end
 function api:ApplyLightBlurPreset()
  local patch={radius=24,strength=25,smooth=10,brightness=100,transparency=100}
  self:SetLocalBlurConfig(patch)
  for _,region in ipairs({"Island","ArrayList","TargetHUD","WaterMark"}) do self:SetHUDBlurConfig(region,patch) end
 end
 -- Use the positions/scales assigned this render frame. GUI Absolute* values can
 -- still describe the preceding layout while a HUD is being dragged or tweened.
 local function islandRect()
  local origin=gui.AbsolutePosition;local p,s=island.Position,island.Size
  return rect(origin.X+p.X.Offset,origin.Y+p.Y.Offset,s.X.Offset,s.Y.Offset)
 end
 local function targetRect()
  local origin=gui.AbsolutePosition
  local host,frame=targetHUD.Host,targetHUD.Frame
  local scale=targetHUD.LayoutScale.Scale;local animation=targetHUD.AnimationScale.Scale
  local hs=host.Size;local p,s,a=frame.Position,frame.Size,frame.AnchorPoint
  local w=(s.X.Scale*hs.X.Offset+s.X.Offset)*scale*animation
  local h=(s.Y.Scale*hs.Y.Offset+s.Y.Offset)*scale*animation
  return rect(origin.X+host.Position.X.Offset+(p.X.Scale*hs.X.Offset+p.X.Offset)*scale-w*a.X,
   origin.Y+host.Position.Y.Offset+(p.Y.Scale*hs.Y.Offset+p.Y.Offset)*scale-h*a.Y,w,h)
 end
 local function destroyHUDEffects()
  api.arrayListShadow:Destroy()
  for _,pane in pairs(hudBlurPanes) do if pane.renderer then pane.renderer:Destroy();pane.renderer=nil end end
  targetHUD:DestroyEffects()
  api.waterMark:Destroy()
 end
 local hudBlurRotation=0
 local function renderHUDEffects(dt)
  local st=state.HUD and state.HUD.settings or {}
  local view=gui.AbsoluteSize
  local drawable=view.X>36 and view.Y>32
  local widgetsVisible=drawable and not (visible and activeStyle:match("^Jackal ") and not hudEditing)
  api.arrayListShadow:Step(arrayMetrics,st,widgetsVisible and widgetEnabled("ArrayList") and
   ((arrayMetrics.mode=="XHan" or arrayMetrics.mode=="BloomFlow") and xhan.root.Visible or
    (arrayMetrics.mode=="Default" or arrayMetrics.mode=="Opai") and widgetRoot.Visible))
  local jobs={}
  local function prepare(name,enabled,bounds,masks)
   local pane=hudBlurPanes[name]
   local patch={}
   for key,setting in pairs({radius=radiusSettings[name],strength=name.." Blur strength",smooth=name.." Blur softness"}) do
    local value=st[setting]
    if value~=nil and value~=pane.profile[key] then patch[key]=value;pane.profile[key]=value end
   end
   if next(patch) and pane.renderer then pane.renderer:SetConfig(patch) end
   enabled=enabled and pane.profile.radius>0 and pane.profile.strength>0
   pane.host.Visible=enabled
   if enabled then
    if not pane.renderer then pane.renderer=SampledLocalBlur.new(pane.host,{Profile=pane.profile,ScreenCoordinates=true,Masked=true}) end
    pane.renderer:SetMasks(masks)
    jobs[#jobs+1]={pane=pane,bounds=bounds}
   elseif pane.renderer then pane.renderer:Step(nil,false,dt) end
  end
  local ib=islandRect()
  prepare("Island",drawable and island.Visible and st["Island Blur"]~=false,ib,
   {{x=0,y=0,w=1,h=1,radius=islandCorner.CornerRadius.Offset/math.max(1,ib.h)}})
  local listVisible=widgetsVisible and widgetEnabled("ArrayList") and st["ArrayList Blur"]~=false
  local left,top,right,bottom=math.huge,math.huge,-math.huge,-math.huge
  local masks,regions={},{}
  if listVisible then
   local scale=arrayMetrics.shadowScale or 1
   for _,row in ipairs(arrayMetrics.rows or {}) do
    if row.height>.5 and row.alpha>.001 then
     if row.bands then
      for _,band in ipairs(row.bands) do
       regions[#regions+1]={x=band.x,y=band.y,w=band.w,h=band.h,alpha=band.alpha,band=true,radius=0}
       left=math.min(left,band.x);top=math.min(top,band.y);right=math.max(right,band.x+band.w);bottom=math.max(bottom,band.y+band.h)
      end
     else
      local pad=arrayMetrics.mode=="Default" and 6.5*scale or 0
      local item={x=row.x-pad,y=row.y,w=row.width+pad,h=row.height,alpha=row.alpha,radius=0,band=true}
      regions[#regions+1]=item
      left=math.min(left,item.x);top=math.min(top,item.y);right=math.max(right,item.x+item.w);bottom=math.max(bottom,item.y+item.h)
     end
    end
   end
  end
  listVisible=listVisible and right>left and bottom>top
  local pane=hudBlurPanes.ArrayList
  local bb=nil
  if listVisible then
   pane.host.Position=UDim2.fromOffset(left,top);pane.host.Size=UDim2.fromOffset(right-left,bottom-top)
   bb=rect(gui.AbsolutePosition.X+left,gui.AbsolutePosition.Y+top,right-left,bottom-top)
   for _,row in ipairs(regions) do
    local mask={x=(row.x-left)/bb.w,y=(row.y-top)/bb.h,w=row.w/bb.w,h=row.h/bb.h,alpha=row.alpha,radius=row.radius,band=row.band}
    if row.tl~=nil then mask.tl=row.tl/bb.h;mask.tr=row.tr/bb.h;mask.br=row.br/bb.h;mask.bl=row.bl/bb.h end
    masks[#masks+1]=mask
   end
  end
  prepare("ArrayList",listVisible,bb,masks)
  local wm=api.waterMark
  local wb=wm.bounds
  local globalWB=wb and rect(gui.AbsolutePosition.X+wb.x,gui.AbsolutePosition.Y+wb.y,wb.w,wb.h) or nil
  prepare("WaterMark",widgetsVisible and wm.root.Visible and st["WaterMark Blur"]~=false,globalWB,{{x=0,y=0,w=1,h=1,radius=wm.corner.CornerRadius.Offset/math.max(1,wb and wb.h or 1)}})
  local targetVisible=widgetsVisible and targetHUD.Host.Visible and targetHUD.Frame.Visible
  prepare("TargetHUD",targetVisible and st["TargetHUD Blur"]~=false,targetRect(),
   {{x=0,y=0,w=1,h=1,radius=18/76}})
  targetHUD:RenderGlow(st,targetVisible)
  local totalBudget=api:GetLocalBlurConfig().budget
  local hudBudget=visible and totalBudget*.5 or totalBudget
  local started=os.clock()
  hudBlurRotation=hudBlurRotation+1
  for i=1,#jobs do
   local job=jobs[(i+hudBlurRotation-1)%#jobs+1]
   local remaining=math.max(0,hudBudget-(os.clock()-started)*1000)
   job.pane.renderer:Step(job.bounds,true,dt,1,remaining/(#jobs-i+1))
  end
  blurPane.frameBudget=math.max(0,totalBudget-(os.clock()-started)*1000)
 end
 function api:GetHUDEffectsState()
  local result={workBudgetMs=api:GetLocalBlurConfig().budget,targetGlow=targetHUD:InspectGlow()}
  for name,pane in pairs(hudBlurPanes) do
   result[name]=pane.renderer and pane.renderer:Inspect() or {active=false,completed=0,reason="not-created"}
  end
  result.BloomFlow=copy(result.ArrayList)
  result.BloomFlow.active=result.BloomFlow.active and arrayMetrics.mode=="BloomFlow"
  result.waterMarkGlow=api.waterMark.glow:Inspect()
  return result
 end

 return {Step=renderHUDEffects,Destroy=destroyHUDEffects}
 end)()

 local function renderHUD(dt,frameDelta)
  bridge.Sync()
  bridge.RefreshBindings()
  expireNotices()
  for _,n in ipairs(notices) do
   local moduleId=n.key:match("^module:(.+)$")
   n.title=localize(n.sourceTitle or n.title)
   if n.kind=="toggle" and moduleId and rows[moduleId] then
    local name=localize(rows[moduleId].def.name or moduleId)
    n.detail=language=="中文" and name or name.." has been "
   else n.detail=localize(n.sourceDetail or n.detail) end
  end
  local view=gui.AbsoluteSize
  if view.X<=36 or view.Y<=32 then targetHUD.Host.Visible=false;island.Visible=false;widgetRoot.Visible=false;xhan.root.Visible=false;hudControls.Visible=false;api.waterMark:Step({},view,hudScale,nil,false,dt,{});xhan.smooth:Begin(false,0,2);xhan.smooth:Finish();return end
  widgetRoot.Visible=true;hudControls.Visible=true
    local scale=math.min(hudScale,(view.X-8)/70)
    islandState.renderScale=scale
    -- Render the island in physical pixels so shell morphing does not scale text.
    shell.drawScale=scale;ink.drawScale=scale
   island.Visible=widgetEnabled("Dynamic Island");drawHUDWidgets(dt,frameDelta)
  local realDelta=frameDelta or dt
  local delta=math.min(realDelta,.1)*bridge.islandAnimationSpeed
  islandState.animationTime=(islandState.animationTime or 0)+delta
  if realDelta>0 then islandState.fps=ease(islandState.fps>0 and islandState.fps or 1/realDelta,1/realDelta,math.min(realDelta,.1),3) end
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
      local suffix=localize(n.value and "Enabled" or "Disabled")
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
   islandBackdrop.BackgroundTransparency=islandBackgroundTransparency/100
   local shadowStrength=islandShadow/100
   if shadowStrength>0 then
    local spread=18
    for layer=spread,1,-1 do
     local distance=layer*.7
     shell:box(-distance,-distance,w+distance*2,h+distance*2,0x000000,.075*(shadowStrength/.7)*(1-layer/(spread+1)),radius+distance)
    end
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
     local t=not animations and 1 or math.clamp(((islandState.animationTime or 0)-(n.animationStarted or 0))/.2,0,1);if n.value then t=t==1 and 1 or 1-2^(-10*t) end
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
 -- A renderer adapter: Syntax is the single owner of module values and callbacks.
 function bridge.RefreshBindings()
  for control,entry in pairs(bridge.bindings) do
   if not control.Parent then bridge.bindings[control]=nil
   else
    entry.caption.Text=binding==rows[entry.id] and "PRESS KEY" or (state[entry.id].key=="Unknown" and "NONE" or state[entry.id].key)
    entry.caption.TextColor3=rgb(binding==rows[entry.id] and currentPalette().accent or 0x77858E)
   end
  end
 end
 function bridge.CreateKeybind(id,parentObject,scope,height)
  local control=new("TextButton",parentObject,{Name="SyntaxKeybind",BackgroundTransparency=1,Text="",AutoButtonColor=false,Size=UDim2.fromOffset(72,height),Active=true})
  control:SetAttribute("Component","SyntaxKeybind")
  local field=new("Frame",control,{Name="SyntaxKeybindField",BackgroundColor3=rgb(0x101314),Position=UDim2.new(.5,-24,.5,-9),Size=UDim2.fromOffset(48,18),Active=false})
  new("UICorner",field,{CornerRadius=UDim.new(0,2)})
  local caption=new("TextLabel",field,{Name="Value",BackgroundTransparency=1,Size=UDim2.fromScale(1,1),Text="NONE",TextSize=9,Font=opaiFont(false),TextColor3=rgb(0x77858E),TextScaled=false,TextTruncate=Enum.TextTruncate.AtEnd})
  bridge.bindings[control]={id=id,caption=caption}
  scope:On(control.Activated,function() api:BeginKeybind(id);bridge.RefreshBindings() end)
  scope:On(control.MouseButton2Click,function() api:SetKeybind(id,"Unknown") end)
  scope.disposals[#scope.disposals+1]=function() if binding==rows[id] then binding=nil end;bridge.bindings[control]=nil end
  bridge.RefreshBindings();return control
 end
 function bridge.Mirror(id,key,value)
  local app=bridge.app;if not app or bridge.syncing then return end
  local group=app._byId[id];if not group then return end
  bridge.syncing=true
  if key=="enabled" then group:SetEnabled(value)
  elseif key=="key" then group:SetKey(value=="Unknown" and "None" or value)
  elseif group._definitions[key] then group:Set(key,copy(value)) end
  bridge.syncing=false
 end
 function bridge.Create()
  if bridge.app then return end
  local definitions={}
  for _,original in ipairs(options.Modules or {}) do
   local def=copy(original);local current=state[def.id]
   def.enabled=current.enabled;def.key=current.key=="Unknown" and "None" or current.key
   for _,setting in ipairs(def.settings or {}) do setting.default=copy(current.settings[setting.name]) end
   definitions[#definitions+1]=def
  end
  bridge.app=JackalRenderer.new({Parent=parent,Name="SyntaxJackalRenderer",DisplayOrder=gui.DisplayOrder-1,
   Embedded=true,Visible=false,Modules=definitions,Categories=categoryOrder,Category=categoryOrder[1],
   Layout=activeStyle=="Jackal Neverlose" and "Neverlose" or "Dropdown",Preset="Opai",
   Scale=k,Language=language,Translate=function(value) return api:Translate(value) end,BindBuiltinComponents=false,DynamicIsland={Enabled=false},
   StyleOptions=copy(UI.Styles),StyleName=activeStyle,
   SyntaxKeybind=bridge.CreateKeybind,
   SyntaxBindingActive=function(input) return binding~=nil or (input~=nil and bridge.consumedInput==input) end,
   CancelSyntaxBinding=function() api:CancelKeybind() end,
   OnSelectStyle=function(name) api:SetStyle(name) end,
   OnOpenAppearance=function() api:OpenAppearance() end,
   OnEditHUD=function() api:EditHUD() end,
   OnOpenConfigs=function() config.open=not config.open;config.x=math.max(4,width-W-12);config.y=50 end,
   OnVisibilityChanged=function(value) if not bridge.suspended and visible~=value then api:SetVisible(value) end end})
  local app=bridge.app
  app.HUD.Visible=false
  for _,group in pairs(app.Models) do if group==app.Models.HUD then for _,name in ipairs({"Arraylist","Time display","Keystrokes","Crosshair","Dynamic Island"}) do if group._definitions[name] then group:Set(name,false) end end end end
  app.EffectLayer.Visible=false
  connect(app.Changed,function(id,key,value)
   if bridge.syncing or not state[id] then return end
   if key=="enabled" then api:SetEnabled(id,value)
   elseif key=="key" then local normalized=value=="None" and "Unknown" or value;state[id].key=normalized;notify(id,"key",normalized)
   elseif state[id].settings[key]~=nil then api:SetSetting(id,key,value) end
  end)
  connect(changed.Event,bridge.Mirror)
 end
 function bridge.Sync()
  bridge.RefreshBindings()
  local enabled=activeStyle:match("^Jackal ")~=nil
  if enabled then bridge.Create() end
  local app=bridge.app;if not app then return end
  bridge.suspended=true
  if enabled then
   if bridge.style~=activeStyle then
    bridge.style=activeStyle;app.Options.StyleName=activeStyle
    app:SetLayout(activeStyle=="Jackal Neverlose" and "Neverlose" or "Dropdown")
    app:SetPreset("Opai");app:_layout()
   end
   local scale=k
   if bridge.scale~=scale then bridge.scale=scale;app:SetScale(scale) end
   if bridge.language~=language then bridge.language=language;app:SetLanguage(language) end
   app.ReducedMotion=not animations
  end
  local target=enabled and visible and not appearanceOpen and not config.open
  if app.Visible~=target then app:SetVisible(target) end
  bridge.suspended=false
 end
 render=function(dt)
  if dead then return end;local frameDelta=dt or 0;local motionDelta=math.min(frameDelta,.1)*animationSpeed
   if animations then visualTime+=motionDelta;flowTime+=math.min(frameDelta,.1) end
  dt=animations and motionDelta or 10
  opacity=animations and ease(opacity,visible and 1 or 0,dt,30) or (visible and 1 or 0);catcher.Visible=visible and not selectedStyle():match("^Jackal ");root.Visible=opacity>.005
  front:drawFixedToolbar(frameDelta)
   local menuRadius=state.ClickGUI and state.ClickGUI.settings["Local Blur radius"]
   local settings=state.ClickGUI and state.ClickGUI.settings or {}
   local patch={};local config=blurPane.renderer:GetConfig()
   for key,name in pairs({radius="Local Blur radius",strength="Local Blur strength",smooth="Local Blur softness"}) do
    if settings[name]~=nil and settings[name]~=config[key] then patch[key]=settings[name] end
   end
   if next(patch) then blurPane.renderer:SetConfig(patch) end
   local localBlur=state.ClickGUI and state.ClickGUI.settings["Local Blur"]~=false
   blur.Size=(options.Blur==false or state.ClickGUI) and 0 or 10*opacity
  local nextStyle=selectedStyle()
  if activeStyle~=nextStyle then activeStyle=nextStyle;dropdown=nil;sliding=nil;binding=nil;drag=nil;gesture=nil;touch=nil;config.open=false;alt.nav=1;alt.target=0;alt.scroll=0;searchBox:ReleaseFocus();searchBox.Text="";altName:ReleaseFocus() end
  renderHUD(dt,frameDelta)
  hudEffects.Step(frameDelta)
  bridge.Sync()
  bridge.RefreshBindings()
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
  if activeStyle:match("^Jackal ") then if config.open then drawConfig(dt) end elseif activeStyle=="Opai" then drawColumns(dt);drawConfig(dt) else drawAlternatives(dt);if activeStyle=="Modern" and config.open then drawModernConfigs() end end
   updateRegionalBlur(blurPane,altGlass,visible and options.Blur~=false and localBlur and activeStyle=="Neverlose",
    rect(gui.AbsolutePosition.X+offsetX+alt.x*k*zoom,gui.AbsolutePosition.Y+offsetY+alt.y*k*zoom,760*alt.s*k*zoom,620*alt.s*k*zoom),frameDelta,opacity)
  drawThemeGlow()
   drawDropdown(dt)
  if animations and ripple then local t=(os.clock()-ripple.start)*animationSpeed/.32;if t<1 then local r=4+18*(1-(1-t)^3);front:stroke(ripple.x-r,ripple.y-r,r*2,r*2,currentPalette().accent,.45*(1-t),r,1) else ripple=nil end end
  if activeStyle=="Opai" then
   local x,y=width-34.7,height-34.7;front:box(x,y,26.7,26.7,currentPalette().accent,1,5)
   line(front,x+7,y+18,x+18,y+7,0x101014,5);line(front,x+6,y+22.8,x+22,y+22.8,0x101014,1.6);hit(rect(x,y,26.7,26.7),"hudEditRMB")
  end
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
   if binding then
    local id=binding.def.id
    bridge.consumedInput=input
    api:SetKeybind(id,(key==Enum.KeyCode.Escape or key==Enum.KeyCode.Backspace or key==Enum.KeyCode.Delete) and "Unknown" or key.Name)
    return
   end
   if key==Enum.KeyCode.F7 then if visible then appearanceOpen=not appearanceOpen;dropdown=nil end;return end
   if key==Enum.KeyCode.F8 then api:SetDiagnostics(not diagnostic);return end
   if key==Enum.KeyCode.F and not activeStyle:match("^Jackal ") and activeStyle~="Opai" and (Input:IsKeyDown(Enum.KeyCode.LeftControl) or Input:IsKeyDown(Enum.KeyCode.RightControl)) then searchBox:CaptureFocus();return end
   if key==Enum.KeyCode.RightShift then api:SetVisible(not visible);return end
   if key==Enum.KeyCode.Escape and visible then if activeStyle:match("^Jackal ") and not appearanceOpen and not config.open then return end; if appearanceOpen then appearanceOpen=false;appearanceSliding=nil;accentBox:ReleaseFocus() elseif dropdown then dropdown=nil elseif config.open then config.open=false else api:SetVisible(false) end;return end
   if not processed then for id,st in pairs(state) do if st.key~="Unknown" and st.key==key.Name then api:SetEnabled(id,not st.enabled) end end end
  end
 end)
 connect(Input.InputChanged,function(input)
  if hudEditing and hudDrag and (input==hudDrag.input or input.UserInputType==Enum.UserInputType.MouseMovement) then
   local d=hudDrag;local old=hudPlacements[d.name];api:SetHUDLayout(d.name,d.x+input.Position.X-d.startX,d.y+input.Position.Y-d.startY,old and old.scale or 1);return
  end
  if hudEditing and input.UserInputType==Enum.UserInputType.MouseWheel then
   local point=Input:GetMouseLocation()
   for name,bounds in pairs(hudBounds) do if inside(bounds,point.X,point.Y) then
    local at=hudPlacements[name];api:SetHUDLayout(name,bounds.x,bounds.y,math.clamp((at and at.scale or 1)+input.Position.Z*.1,.5,2));break
   end end
   return
  end
  if not visible then return end
  if activeStyle:match("^Jackal ") and not appearanceOpen and not config.open then return end
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
    if dead then return end;dead=true;Run:UnbindFromRenderStep(api.renderStepName);for _,c in ipairs(conns) do c:Disconnect() end;if bridge.app then bridge.app:Destroy();bridge.app=nil end;hudEffects.Destroy();xhan.smooth:Destroy();destroyRegionalBlur(blurPane);blur:Destroy();gui:Destroy()
 end
 connect(shutdown.Event,function() api:Destroy() end)
   connect(gui.Destroying,function() if not dead then dead=true;Run:UnbindFromRenderStep(api.renderStepName);for _,c in ipairs(conns) do c:Disconnect() end;if bridge.app then bridge.app:Destroy();bridge.app=nil end;hudEffects.Destroy();xhan.smooth:Destroy();destroyRegionalBlur(blurPane);blur:Destroy() end end)
 if options.Accent~=nil then api:SetAccent(options.Accent) end
 uiDiagnostics.Stage="执行 UI 首帧渲染"
 fit();render(0)
 uiDiagnostics.Stage="绑定 UI 渲染回调"
  Run:BindToRenderStep(api.renderStepName,Enum.RenderPriority.Last.Value,render)
 -- Inspection is useful in Studio and automated renderer verification.
  function api:Inspect() local result={appearance=api:GetAppearance(),appearanceOpen=appearanceOpen,legacyIcons="NeverloseAssetsV1",smoothGlow=xhan.smooth:Inspect(),hudEffects=self:GetHUDEffectsState(),arrayList=copy(arrayMetrics),arrayListShadow=api.arrayListShadow:Inspect(),waterMark=api.waterMark:Inspect(),hudEditing=hudEditing,hudBounds=copy(hudBounds),style=activeStyle,nativeControls=#hits,alternate={x=alt.x,y=alt.y,scale=alt.s,scroll=alt.scroll,maxScroll=alt.max,nav=alt.nav},inset=GuiService:GetGuiInset(),jackal=bridge.app and bridge.app:Inspect() or nil,island={noticeItems=copy(notices),backgroundTransparency=islandBackgroundTransparency,shadowStyle="Jackal",icons="Original+SyntaxLogoV2",animationSpeed=bridge.islandAnimationSpeed,visible=island.Visible,width=islandState.width.value,height=islandState.height.value,notices=#notices},localBlur=blurPane.renderer and blurPane.renderer:Inspect() or {active=false,unsupported=false,reason="destroyed"},scale=k,width=width,height=height,columns={},dropdown=dropdown~=nil,visible=visible};for _,c in ipairs(columns) do result.columns[#result.columns+1]={name=c.name,x=c.x-horizontal,y=c.y,height=c.bodyH,scroll=c.scroll,maxScroll=c.maxScroll,entries=#c.entries} end;return result end
 uiDiagnostics.Stage="UI 就绪"
 return api
end
return UI

end)()
UI.Diagnostics=uiDiagnostics
_G.SyntaxUILibrary=UI
return UI
