ENT=FindMetaTable("Player")
include("infinitespace/libmachineplayercommon.lua")
if SERVER
then
	function GetValidSuitResources() return {"Oxygen","Heating","Cooling"} end
	function IsValidSuitResource(res)
		for _,v in pairs(GetValidSuitResources())
		do
			if(v==res) then return true end
		end
		return false
	end
	function ENT:GetMaxResource(res) return IsValidSuitResource(res) and GetConVar("infinitespace_max_suit_resources"):GetInt() or 0 end
	local _OfferResource=ENT.OfferResource
	function ENT:OfferResource(res,amt)
		if(not IsValidSuitResource(res)) then return 0 end
		return _OfferResource(self,res,amt)
	end
	function ENT:RequestResourceFromNetwork(res,amt)
		local maxamt=amt
		if(self:InVehicle() and self:GetVehicle().IsSpaceMachine)
		then
			amt=amt-self:GetVehicle():RequestResourceFromNetwork(res,amt)
		end
		local reserve=self:GetResource(res)
		if(amt>0 and reserve>0)
		then
			local taken=math.min(amt,reserve)
			amt=amt-taken
			reserve=reserve-taken
			self:SetResource(res,reserve)
		end
		return maxamt-amt
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
