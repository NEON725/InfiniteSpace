local generators=
{
	["Vespene Reactor"]=
	{
		Inputs={["Vespene Gas"]=1},
		Outputs={["MV Electricity"]=1},
		Models=
		{
			"models/props_c17/trappropeller_engine.mdl",
			"models/props_vehicles/generatortrailer01.mdl",
			"models/props_outland/generator_static01a.mdl",
			"models/props_vehicles/generator.mdl",
			"models/props_mining/diesel_generator.mdl"
		}
	}
}

PushMachineLibNode("Generators")

for i,tab in pairs(generators)
do
	local prior=BeginSubMachine("generator_"..i)
	ENT.PrintName=i
	ENT.Models=tab.Models
	function ENT:Initialize()
		self.Baseclass.Initialize(self)
		if(SERVER) then self:SetStorageMultiplier(math.floor(self:GetPhysicsObject():GetVolume()/10000)) end
	end
	GenerateBasicConverterMachine(ENT,tab.Inputs,tab.Outputs)
	FinishSubMachine(prior)
end
