AddCSLuaFile()
ENT.Type="anim"
ENT.Base="base_gmodentity"
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
			self:SetNWFloat("storageMultiplier",math.floor(phys:GetVolume()))
		end
		self:SetUseType(self:GetUseType())
		self.Inputs=Wire_CreateOutputs(self,self:GetWireInputs())
		self.Outputs=Wire_CreateOutputs(self,self:GetWireOutputs())
	end
end

function ENT:GetWireInputs() return {} end
function ENT:GetWireOutputs() return {} end
function ENT:TriggerInput(iname,value) self:SetNWInt(iname,value) end
function ENT:TooltipDisplayLines() return {} end

function ENT:GetUseType() return SIMPLE_USE end
function ENT:Use(ply,caller)
	local IsOn=self:GetNWInt("Power")!=0
	self:SetNWInt("Power",Either(IsOn,0,1))
end

function ENT:GetOverlayText() return "" end
function ENT:Draw() self:DrawModel() end

function ENT:GetStorageMultiplier() return self:GetNWFloat("storageMultiplier") end
function ENT:GetEnvironment() return GetEnvironmentAtVector(self:GetPos()) end

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
	ENT.Base=prior.ClassName
	ENT.ClassName="spacemachine_"..newclassname
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
