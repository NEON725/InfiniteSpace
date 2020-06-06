PushMachineLibNode("Harvesters")

local Models=
{
	Liquid=
	{
		"models/props_farm/water_spigot.mdl",
		"models/props_2fort/waterpump001.mdl",
		"models/props_mining/generator_machine01.mdl",
		"models/props_wasteland/buoy01.mdl",
		"models/props_swamp/buoy_ref.mdl"
	},
	Gas=
	{
		"models/props_2fort/chimney003.mdl",
		"models/props_farm/air_intake.mdl",
		"models/props_wasteland/laundry_washer003.mdl",
		"models/props_moonbase/moon_interior_fan01.mdl"
	}
}

for res,tab in pairs(IS_RESOURCES)
do
	local type=tab.type
	if(tab.abstract) then continue end
	if(type=="Liquid" or type=="Gas")
	then
		local prior=BeginSubMachine("harvester_"..res:lower())
		ENT.PrintName=res.." "..((type=="Liquid") and "Pump" or "Filter")
		ENT.Base="spacemachine"
		ENT.ToolIcon=(type=="Liquid") and "icon16/water.png" or "icon16/weather_clouds.png"
		ENT.Models=Models[type]
		ENT.Use=UseBasicPowerSwitch
		ENT.resource=res
		function ENT:Initialize()
			self.Baseclass.Initialize(self)
			if SERVER then self:SetStorageMultiplier(math.max(1,math.floor(self:GetPhysicsObject():GetVolume()/1000))) end
		end
		function ENT:ProcessResources()
			self.Baseclass.ProcessResources(self)
			if(self:GetPower())
			then
				local requiredPower=self:GetStorageMultiplier()
				local gathered=self:RequestResourceFromNetwork("LV Electricity",requiredPower)
				local gatherMultiplier=math.floor(self:GetStorageMultiplier()*gathered/requiredPower)
				local atmos=self:GetAtmosphere()
				local inAtmos=atmos[res]
				local taken=math.min(inAtmos,gatherMultiplier)
				atmos[res]=atmos[res]-taken
				self:ProduceResource(self.resource,taken)
			end
		end
		FinishSubMachine(prior)
	end
end
