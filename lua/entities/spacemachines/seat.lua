local ValidSuitResources={"Oxygen"}

hook.Add("PlayerSpawnedVehicle","IS_SEAT_OVERRIDE",function(plr,ent)
	if(ent:IsVehicle())
	then
		ent.IsSpaceMachine=true
		ENT=ent
		include("infinitespace/libmachinenetwork.lua")
		function ent:GetStorageMultiplier() return 0 end
		function ent:TooltipDisplayLines()
			return {"Players use resources"," from their ship","when seated."}
		end
		function ent:OfferResource(res,amt)
			if(IsValid(self:GetDriver())) then return self:GetDriver():OfferResource(res,amt) end
			return 0
		end
	end
end)
