local ValidSuitResources={"Oxygen"}

hook.Add("PlayerSpawnedVehicle","IS_SEAT_OVERRIDE",function(plr,ent)
	if(ent:IsVehicle())
	then
		ent.IsSpaceMachine=true
		ENT=ent
		include("infinitespace/libmachinenetwork.lua")
		include("infinitespace/libmachineplayercommon.lua")
		function ent:GetStorageMultiplier() return 0 end
		function ent:OfferResource(res,amt)
			if(IsValid(self:GetDriver())) then return self:GetDriver():OfferResource(res,amt) end
			return 0
		end
	end
end)
