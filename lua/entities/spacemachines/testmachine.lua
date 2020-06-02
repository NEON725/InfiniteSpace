ENT.PrintName="Test Machine"

ENT.Models={"models/roller.mdl"}

function ENT:Use(ply,caller)
	self.Baseclass.Use(self,ply,caller)
	print(self:GetResource("Oxygen"))
end

function ENT:ProcessResources()
	self.Baseclass.ProcessResources(self)
	if SERVER
	then
		self:ProduceResource("Oxygen",1)
	end
end

function ENT:TooltipDisplayLines()
	return {"Hi!","I'll be deleted when"," this hits beta. :("} 
end
