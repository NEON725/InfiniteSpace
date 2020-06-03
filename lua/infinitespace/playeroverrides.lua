ENT=FindMetaTable("Player")
if SERVER
then
	local validSuitResources={Oxygen=true}
	function ENT:GetResource(res) return (self.suit or {})[res] or 0 end
	function ENT:GetMaxResource(res) return validSuitResources[res] and GetConVar("infinitespace_max_suit_resources"):GetInt() or 0 end
	function ENT:SetResource(res,amt)
		self.suit=self.suit or {}
		self.suit[res]=amt
	end
	function ENT:OfferResource(res,amt)
		if(not validSuitResources[res]) then return 0 end
		local current,max=self:GetResource(res),self:GetMaxResource(res)
		local accepted=math.min(amt,max-current)
		if(accepted>0)
		then
			current=current+accepted
			self:SetResource(res,current)
		end
		return accepted
	end
	function ENT:RequestResource(res,amt)
		local maxamt=amt
		local takenFromNetwork=self:RequestResourceFromNetwork(res,amt)
		amt=amt-takenFromNetwork
		if(amt>0)
		then
			local current=self:GetResource(res)
			local takenFromSuit=math.min(amt,current)
			if(takenFromSuit>0)
			then
				current=current-takenFromSuit
				amt=amt-takenFromSuit
				self:SetResource(res,current)
			end
		end
		return maxamt-amt
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
include("infinitespace/libmachineplayercommon.lua")
