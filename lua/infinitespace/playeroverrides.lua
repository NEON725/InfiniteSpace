ENT=FindMetaTable("Player")
include("infinitespace/libmachineplayercommon.lua")
if SERVER
then
	function ENT:GetValidSuitResources() return {"Oxygen","Heating","Cooling"} end
	function ENT:IsValidSuitResource(res)
		for _,v in pairs(self:GetValidSuitResources())
		do
			if(v==res) then return true end
		end
		return false
	end
	function ENT:GetMaxResource(res) return self:IsValidSuitResource(res) and GetConVar("infinitespace_max_suit_resources"):GetInt() or 0 end
	local _OfferResource=ENT.OfferResource
	function ENT:OfferResource(res,amt)
		if(not self:IsValidSuitResource(res)) then return 0 end
		return _OfferResource(self,res,amt)
	end
	function ENT:RequestResourceFromNetwork(res,amt)
		if(self:InVehicle() and self:GetVehicle().IsSpaceMachine)
		then
			return self:GetVehicle():RequestResourceFromNetwork(res,amt)
		end
		return 0
	end
else
	-- Shim to enable IsInWorld method clientside.
	function ENT:IsInWorld()
		local tr={collisiongroup=COLLISION_GROUP_WORLD}
		tr.start=self:GetPos()
		tr.endpos=tr.start
		return not util.TraceLine(tr).HitWorld
	end
end
