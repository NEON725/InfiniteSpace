AddCSLuaFile()
ENT.Type="anim"
ENT.Base="base_wire_entity"
ENT.PrintName=nil
ENT.WireDebugName="SpaceMachine"
DEFINE_BASECLASS(ENT.Base)

local SPACEMACHINE_LIBRARY={}
function GetSpaceMachineLibrary() return SPACEMACHINE_LIBRARY end

function ENT:SetupDataTables()
end

function ENT:Initialize()
	self.IsSpaceMachine=true
	if not self:GetModel() or self:GetModel()=="" or self:GetModel()=="models/error.mdl" then self:SetModel("models/roller.mdl") end
	if SERVER
	then
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetMoveType(MOVETYPE_VPHYSICS)
		self:SetSolid(SOLID_VPHYSICS)
		local phys=self:GetPhysicsObject()
		if phys:IsValid()
		then
			phys:Wake()
			self:SetStorageMultiplier(math.floor(phys:GetVolume()/10))
		end
		self:SetUseType(self:GetUseType())
		local inputNames,inputTypes=self.WireInputs,self.WireInputTypes
		if(inputNames and not inputTypes)
		then
			inputTypes={}
			for _,__ in pairs(inputNames) do table.insert(inputTypes,"NORMAL") end
		end
		local outputNames,outputTypes=self.WireOutputs,self.WireOutputTypes
		if(outputNames and not outputTypes)
		then
			outputTypes={}
			for _,__ in pairs(outputNames) do table.insert(outputTypes,"NORMAL") end
		end
		self.WireInputs=nil
		self.WireInputTypes=nil
		self.WireOutputs=nil
		self.WireOutputTypes=nil
		if(inputNames) then self.Inputs=WireLib.CreateSpecialInputs(self,inputNames,inputTypes) end
		if(outputNames) then self.Outputs=WireLib.CreateSpecialOutputs(self,outputNames,outputTypes) end
	end
end

function ENT:TriggerInput(iname,value) self:SetNWInt("wire_"..iname,value) end
function ENT:GetWireInput(iname) return self:GetNWInt("wire_"..iname) end
function ENT:SetWireOutput(iname,value) Wire_TriggerOutput(self,iname,value) end
function ENT:SetTooltipDisplayLines(lines) self:AssignPendingNWVar("tooltip_lines",lines,"Table") end
function ENT:GetTooltipDisplayLines() return self:GetActualOrPendingNWVar("tooltip_lines","Table") end

function ENT:GetUseType() return SIMPLE_USE end
function ENT:Use() end

function ENT:GetOverlayText() return "" end
function ENT:Draw() self:DrawModel() end

function ENT:GetStorageMultiplier() return self:GetNWFloat("storageMultiplier") end
function ENT:SetStorageMultiplier(mul)
	self:SetNWFloat("storageMultiplier",mul)
	if SERVER then self:RecalculateStorage() end
end
function ENT:RecalculateStorage() end

function ENT:Think()
	BaseClass.Think(self)
	self:SynchronizeNWVars()
	if SERVER
	then
		if(not self.lastProcessResourceTime) then self.lastProcessResourceTime=math.floor(CurTime())
		elseif(CurTime()>=self.lastProcessResourceTime)
		then
			self.lastProcessResourceTime=self.lastProcessResourceTime+1
			self:ProcessResources()
		end
	end
end

ENT.Models={"models/roller.mdl"}

include("infinitespace/libmachinenetwork.lua")
include("infinitespace/libmachineplayercommon.lua")

--==================== SUB MACHINE LIBRARY
ENT.IsMachineTab=true
ENT.ToolSpawnable=true

local MachineLibStack={SPACEMACHINE_LIBRARY}
function GetTopMachineLibNode() return MachineLibStack[#MachineLibStack] end
function PushMachineLibNode(nodename)
	local newtab={}
	GetTopMachineLibNode()[nodename]=newtab
	table.insert(MachineLibStack,newtab)
end
function AddMachineLibEnt(machinetab)
	GetTopMachineLibNode()[machinetab.PrintName]=machinetab
end
function PopMachineLibNode(targetLength)
	if not targetLength then targetLength=#MachineLibStack-1 end
	while #MachineLibStack>targetLength
	do
		table.remove(MachineLibStack,#MachineLibStack)
	end
end

function BeginSubMachine(newclassname,prior)
	if prior then FinishSubMachine(prior) end
	prior=ENT
	ENT=table.Copy(ENT)
	ENT.Baseclass=prior
	ENT.Base="spacemachine"
	ENT.ClassName="spacemachine_"..newclassname:gsub(" ","_"):lower()
	return prior
end

function FinishSubMachine(prior)
	if ENT and ENT.PrintName
	then
		scripted_ents.Register(ENT,ENT.ClassName)
		AddMachineLibEnt(ENT)
		print("Loaded space machine: "..ENT.ClassName)
	end
	ENT=prior
end

function IncludeSubMachine(classname,filename)
	if SERVER then AddCSLuaFile(filename) end
	local MachineLibStackLength=#MachineLibStack
	local prior=BeginSubMachine(classname,ENT)
	include(filename)
	FinishSubMachine(prior)
	PopMachineLibNode(MachineLibStackLength)
end

function AddSubMachineTable(classname,tab)
	local prior=BeginSubMachine(classname)
	for i,v in pairs(tab) do ENT[i]=v end
	FinishSubMachine(prior)
end

local DIRPREFIX="entities/spacemachines/"
local files,directories=file.Find(DIRPREFIX.."*.lua","LUA")
for i,v in pairs(files)
do
	local filename=DIRPREFIX..v
	local machinename=v:sub(1,#v-4)
	IncludeSubMachine(machinename,filename)
end
