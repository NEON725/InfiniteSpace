ENT.PrintName="Solar Panel"
PushMachineLibNode("Eco-Friendly")
ENT.Models=
{
	"models/xqm/panel1x1.mdl",
	"models/xqm/panel1x2.mdl",
	"models/xqm/panel1x3.mdl",
	"models/xqm/panel1x4.mdl",
	"models/xqm/panel2x2.mdl",
	"models/xqm/panel2x3.mdl",
	"models/xqm/panel2x4.mdl",
	"models/xqm/panel2x4.mdl",
	"models/xqm/panel3x4.mdl",
	"models/xqm/panel4x4.mdl"
}


function ENT:Initialize()
	self.Baseclass.Initialize(self)
	self:SetStorageMultiplier(math.floor((self:OBBMaxs()-self:OBBMins()):Length2D()))
end

function ENT:ProcessResources()
	self.Baseclass.ProcessResources(self)
	if(self:GetEnvironment():IsOutside(self))
	then
		local powerMultiplier=math.max(self:GetUp().z,0)
		local power=math.floor(self:GetStorageMultiplier()*powerMultiplier)
		self:ProduceResource("LV Electricity",power)
	end
end
