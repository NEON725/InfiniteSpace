PushMachineLibNode("Storage")

local Models=
{
	Liquid=
	{
		"models/props_farm/oilcan01.mdl",
		"models/props_farm/oilcan01b.mdl",
		"models/props_hydro/water_barrel.mdl",
		"models/props_hydro/water_barrel_cluster.mdl",
		"models/props_hydro/water_barrel_cluster2.mdl",
		"models/props_hydro/water_barrel_cluster3.mdl",
		"models/props_hydro/water_barrel_large.mdl",
		"models/props_c17/oildrum001.mdl",
		"models/props_junk/metalgascan.mdl",
		"models/props_badlands/barrel01.mdl",
		"models/props_badlands/barrel02.mdl",
		"models/props_badlands/barrel03.mdl",
		"models/props_badlands/barrel_flatbed01.mdl",
		"models/props_wasteland/laundry_washer001a.mdl",
		"models/props_mining/watertower.mdl",
		"models/props_wasteland/horizontalcoolingtank04.mdl",
		"models/props_silhouettes/pipeline_sec1gate.mdl",
		"models/props_hydro/water_machinery4.mdl",
		"models/props_hydro/water_machinery2.mdl",
		"models/props_2fort/tank001.mdl",
		"models/props_2fort/tank002.mdl",
		"models/props_trainyard/metal_watertower001.mdl",
		"models/props_trainyard/metal_watertower002.mdl",
		"models/props_interiors/BathTub01a.mdl"
	},
	Gas=
	{
		"models/props_c17/canister01a.mdl",
		"models/props_c17/canister02a.mdl",
		"models/props_c17/canister_propane01a.mdl",
		"models/props_junk/PropaneCanister001a.mdl",
		"models/props_citizen_tech/firetrap_propanecanister01a.mdl",
		"models/props_silhouettes/pipeline_sec1gate.mdl",
		"models/props_wasteland/horizontalcoolingtank04.mdl"
	}
}

for res,tab in pairs(IS_RESOURCES)
do
	local type=tab.type
	if(tab.abstract) then continue end
	if(type=="Liquid" or type=="Gas")
	then
		local prior=BeginSubMachine("storage_"..res:lower())
		ENT.PrintName=res.." Storage"
		ENT.Base="spacemachine"
		ENT.ToolIcon="icon16/database.png"
		ENT.Models=Models[type]
		function ENT:RecalculateStorage()
			self:SetMaxResource(res,math.floor(self:GetStorageMultiplier()/tab.volume))
		end
		ENT.WireInputs={"Vent"}
		ENT.WireOutputs={"Current","Maximum"}
		function ENT:ProcessResources()
			self.Baseclass.ProcessResources(self)
			local vent=self:GetWireInput("Vent")
			if(vent>0)
			then
				self:VentResource(res,math.min(vent,self:GetResource(res)))
			end
			self:SetWireOutput("Current",self:GetResource(res))
			self:SetWireOutput("Maximum",self:GetMaxResource(res))
		end
		FinishSubMachine(prior)
	end
end
