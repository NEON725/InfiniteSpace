TOOL.Name="#tool.spacemachine.name"
TOOL.Category="Infinite Space"
TOOL.ClientConVar=
{
	type="",
	model="",
	weld=1,
	createflat=0
}
local NET_STRING="spacemachine_stool_use"
local TARGET_WIDTH=300
local SPAWNICON_WIDTH=100

local MoveToSurface=function(ent,tr,createflat)
	local ang
	if(not createflat)
	then
		if(tr.HitNormal.x==0 and tr.HitNormal.y==0)
		then
			local normal=tr.Normal
			normal.z=0
			ang=normal:GetNormalized():Angle()
			if(tr.HitNormal.z<0) then ang:RotateAroundAxis(normal,180) end
		else
			local sideVector=tr.HitNormal:Cross(Vector(0,0,1)):GetNormalized()
			ang=tr.HitNormal:Angle()
			ang:RotateAroundAxis(sideVector,-90)
		end
	else ang=tr.HitNormal:Angle() end
	ent:SetAngles(ang)
	local offset=createflat and -ent:OBBMins().x or -ent:OBBMins().z
	ent:SetPos(tr.HitPos+tr.HitNormal*offset)
end

local SpaceMachineToolSetModel=function(model) --This has to be a global because vital functions don't have access to the tool instance. Thanks garry.
	GetConVar("spacemachine_model"):SetString(model)
end

function CreateSpaceMachine(plr,type,model,weld,flat,freeze)
	local ent=ents.Create(type)
	local tr=plr:GetEyeTrace()
	if(not tr.Hit) then return end
	ent:SetPos(tr.HitPos)
	ent:SetModel(model)
	MoveToSurface(ent,tr,flat)
	ent:Spawn()
	ent:GetPhysicsObject():EnableMotion(not freeze)
	if(weld and not tr.HitWorld) then constraint.Weld(ent,tr.Entity,0,0,0,true,false) end
	undo.Create(ent.PrintName..": "..model)
	undo.AddEntity(ent)
	undo.SetPlayer(plr)
	undo.SetCustomUndoText("Dismantled "..ent.PrintName)
	undo.Finish()
end

if CLIENT or game.SinglePlayer() --THAT IS NOT HOW PREDICTION WORKS. Thanks garry.
then
	function TOOL:Deploy()
		self:MakeGhostEntity("models/roller.mdl")
	end
	function TOOL:Think()
		if(self.GhostEntity)
		then
			local model=GetConVar("spacemachine_model"):GetString()
			if(not model or model=="") then model="models/roller.mdl" end
			self.GhostEntity:SetModel(model)
			self.GhostEntity:SetColor(Color(255,255,255,100))
			self.GhostEntity:SetRenderMode(RENDERMODE_TRANSCOLOR)
			MoveToSurface(self.GhostEntity,self:GetOwner():GetEyeTrace(),GetConVar("spacemachine_createflat"):GetInt()==1)
		end
	end
end

if CLIENT
then
	language.Add("Tool.spacemachine.name","Machine Spawner")
	language.Add("Tool.spacemachine.desc","All machines in a welded or roped contraption share a resource network. Other constraints do not convey linkage.")
	language.Add("Tool.spacemachine.0","Read machine stats by pointing at it with this tool, or using your cursor with the context menu open.")
	function TOOL:LeftClick(tr)
		net.Start(NET_STRING)
		net.WriteString(GetConVar("spacemachine_type"):GetString())
		net.WriteString(GetConVar("spacemachine_model"):GetString())
		net.WriteBool(GetConVar("spacemachine_weld"):GetInt()==1)
		net.WriteBool(GetConVar("spacemachine_createflat"):GetInt()==1)
		net.WriteBool(tr.HitWorld or (IsValid(tr.Entity) and IsValid(tr.Entity:GetPhysicsObject()) and tr.Entity:GetPhysicsObject():IsMotionEnabled()))
		net.SendToServer()
		return true
	end
	function TOOL.BuildCPanel(panel)
		panel:SetName("Space Machines")
		local modelPanel=vgui.Create("DPanel")
		function modelPanel:RebuildModels(modelList)
			if(self.childModelPanels)
			then
				for _,child in pairs(self.childModelPanels) do child:Remove() end
			else self.childModelPanels={} end
			local x,y=-SPAWNICON_WIDTH,0
			for _,_model in pairs(modelList)
			do
				local model=_model --For the closure.
				local button=vgui.Create("SpawnIcon",self)
				button:SetSize(SPAWNICON_WIDTH,SPAWNICON_WIDTH)
				x=x+SPAWNICON_WIDTH
				if(x>TARGET_WIDTH)
				then
					x=0
					y=y+SPAWNICON_WIDTH
				end
				button:SetPos(x,y)
				button:SetModel(model)
				function button.DoClick() SpaceMachineToolSetModel(model) end
				table.insert(self.childModelPanels,button)
			end
			self:SetSize(TARGET_WIDTH,y+SPAWNICON_WIDTH)
		end
		local machineTree=vgui.Create("DTree",panel)
		panel:AddPanel(panel)
		machineTree:SetSize(TARGET_WIDTH,TARGET_WIDTH)
		machineTree:Dock(TOP)
		local machineLib=GetSpaceMachineLibrary()
		local IncorporateTable
		IncorporateTable=function(libTab,tree)
			for i,v in pairs(libTab)
			do
				if(not v.IsMachineTab)
				then
					local node=tree:AddNode(i)
					IncorporateTable(v,node)
				elseif(v.ToolSpawnable)
				then
					local node=tree:AddNode(i,v.ToolIcon or "icon16/bullet_wrench.png")
					node.DoClick=function()
						GetConVar("spacemachine_type"):SetString(v.ClassName)
						local models=v.Models
						SpaceMachineToolSetModel(models[1])
						modelPanel:RebuildModels(models)
					end
				end
			end
		end
		IncorporateTable(machineLib,machineTree)
		panel:AddPanel(modelPanel)
		panel:AddControl("Checkbox",{Label="Weld",Command="spacemachine_weld"})
		panel:AddControl("Checkbox",{Label="Face away from surface",Command="spacemachine_createflat"})
	end
	function TOOL:DrawToolScreen(width,height)
		surface.SetDrawColor(Color(0,0,50))
		surface.DrawRect(0,0,width,height)
		local x,y=0,0
		local lines=POPUP_TEXT_LINES
		if(not lines or #lines==0) then lines={"Point me at a machine!"} end
		for _,line in pairs(lines)
		do
			draw.SimpleTextOutlined(line,TOOL_TEXT_FONT,x,y,Color(100,100,255),TEXT_ALIGN_LEFT,TEXT_ALIGN_TOP,3,Color(0,0,0))
			local tW,tH=surface.GetTextSize(line)
			y=y+tH
		end
	end
end
if SERVER
then
	util.AddNetworkString(NET_STRING)
	net.Receive(NET_STRING,function(len,plr)
		local type=net.ReadString()
		local model=net.ReadString()
		local weld=net.ReadBool()
		local createflat=net.ReadBool()
		local freeze=net.ReadBool()
		CreateSpaceMachine(plr,type,model,weld,createflat,freeze)
	end)
	if(game.SinglePlayer())
	then
		function TOOL:LeftClick(tr)
			local type=GetConVar("spacemachine_type"):GetString()
			local model=GetConVar("spacemachine_model"):GetString()
			local weld=GetConVar("spacemachine_weld"):GetInt()
			local flat=GetConVar("spacemachine_createflat"):GetInt()
			local freeze=tr.HitWorld or (IsValid(tr.Entity) and IsValid(tr.Entity:GetPhysicsObject()) and tr.Entity:GetPhysicsObject():IsMotionEnabled())
			CreateSpaceMachine(self:GetOwner(),type,model,weld==1,flat==1,freeze)
			return true
		end
	end
end
