PushMachineLibNode("Storage")

local Models=
{
	Liquid=
	{
		"models/props_borealis/bluebarrel001.mdl",
		"models/props_c17/oildrum001.mdl",
		"models/props_junk/metalgascan.mdl",
		"models/props_wasteland/laundry_washer001a.mdl",
		"models/props_mining/watertower.mdl",
		"models/props_wasteland/horizontalcoolingtank04.mdl",
		"models/props_silhouettes/pipeline_sec1gate.mdl",
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
	if type=="Liquid" or type=="Gas"
	then
		local prior=BeginSubMachine("storage_"..res:lower())
		ENT.PrintName=res.." Storage"
		ENT.Base="spacemachine"
		ENT.ToolIcon="icon16/database.png"
		ENT.Models=Models[type]
		function ENT:RecalculateStorage()
			self:SetMaxResource(res,math.floor(self:GetStorageMultiplier()/tab.volume))
		end
		FinishSubMachine(prior)
	end
end
