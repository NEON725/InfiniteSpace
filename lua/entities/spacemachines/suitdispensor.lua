ENT.PrintName="Suit Dispensor"

ENT.Models=
{
	"models/props_lab/hevplate.mdl",
	"models/props_combine/combine_intwallunit.mdl",
	"models/props_lab/tpswitch.mdl"
}

function ENT:Use(plr,caller)
	for _,res in pairs(plr:GetValidSuitResources())
	do
		local accepting=plr:GetAcceptingResource(res)
		local acquired=self:RequestResourceFromNetwork(res,accepting)
		acquired=acquired-plr:OfferResource(res,acquired)
		if(acquired>0) then self:SetResource(res,self:GetResource(res)+acquired) end
	end
end
