local submachines=
{
	["Vespene Geyser"]=
	{
		ore="Vespene Gas",
		Models={"models/props_wasteland/antlionhill.mdl"},
		OnInit=function(self) self:SetColor(Color(0,255,0)) end,
		OnDeplete=function(self) self:SetColor(Color(200,50,50)) end
	}
}

PushMachineLibNode("Ore Veins")

for i,tab in pairs(submachines)
do
	local prior=BeginSubMachine("orevein_"..i:gsub(" ","_"):lower())
	ENT.PrintName=i
	for property,value in pairs(tab) do ENT[property]=value end
	function ENT:Initialize()
		self.Baseclass.Initialize(self)
		if SERVER
		then
			self:SetStorageMultiplier(1000)
			self.rootPos=self:GetPos()
			self.rootAngle=self:GetAngles()
			self:GetPhysicsObject():EnableMotion(false)
			self:OnInit()
			self.IsSpaceMachine=false
		end
	end

	function ENT:Deplete()
		self.depleted=true
		self:OnDeplete()
	end

	function ENT:RecalculateStorage() self:SetMaxResource(self.ore,self:GetStorageMultiplier()) end

	function ENT:Think()
		self.Baseclass.Think(self)
		if(SERVER and not self.depleted)
		then
			local dist2=self:GetPos():DistToSqr(self.rootPos)
			if(dist2>10000) then self:Deplete()
			elseif(dist2>0)
			then
				self:GetPhysicsObject():EnableMotion(false)
				self:SetPos(self.rootPos)
				self:SetAngles(self.rootAngle)
			end
		end
	end

	function ENT:ProcessResources()
		local underground=self:GetEnvironment():GetAtmosphere("solid")
		local remaining=underground[self.ore] or 0
		if(remaining>0)
		then
			remaining=remaining-self:OfferResource(self.ore,math.min(25,underground[self.ore]))
			underground[self.ore]=remaining
		else self:Deplete() end
	end

	function ENT:GetMachineNetwork() return {self} end

	FinishSubMachine(prior)
end
