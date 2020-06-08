local submachines=
{
	["Vespene Refinery"]=
	{
		ore="Vespene Gas",
		Models=
		{
			"models/props_silhouettes/pipeline_cluster_large01a.mdl",
			"models/props_silhouettes/pipeline_tallstructure01a.mdl"
		},
		OnInit=function(self) end,
		OnAttach=function(self) end,
		OnDetach=function(self) end
	}
}

PushMachineLibNode("Mining")

for i,tab in pairs(submachines)
do
	local prior=BeginSubMachine("oreminer_"..i)
	ENT.PrintName=i
	for property,value in pairs(tab) do ENT[property]=value end
	function ENT:Initialize()
		self.Baseclass.Initialize(self)
		if SERVER then self:OnInit() end
	end

	function ENT:PhysicsCollide(collision,collider)
		local ent=collision.HitEntity
		if(IsValid(ent) and not self.attachedVein and string.sub(ent:GetClass(),1,21)=="spacemachine_orevein_" and ent.ore==self.ore)
		then
			self:GetPhysicsObject():EnableMotion(false)
			self.rootPos=ent:GetPos()
			self.rootAngle=ent:GetAngles()
			self:SetPos(self.rootPos)
			self:SetAngles(self.rootAngle)
			self.attachedVein=ent
			self:OnAttach(collider)
		end
	end
	function ENT:Think()
		self.Baseclass.Think(self)
		if(SERVER)
		then
			if(IsValid(self.attachedVein))
			then
				self:SetTooltipDisplayLines({self.ore.." exposed:",self.attachedVein:GetResource(self.ore)})
				local dist2=self:GetPos():DistToSqr(self.rootPos)
				if(dist2>10000)
				then
					self.attachedVein=nil
					self.rootPos=nil
					self.rootAngles=nil
					self:OnDetach()
				elseif(dist2>0)
				then
					self:GetPhysicsObject():EnableMotion(false)
					self:SetPos(self.rootPos)
					self:SetAngles(self.rootAngle)
				end
			else
				self:SetTooltipDisplayLines({"Touch a "..self.ore," vein with this.","Then weld your"," machinery to this"," miner."})
			end
		end
	end

	function ENT:RequestResource(res,amt) return self.attachedVein and self.attachedVein:RequestResource(res,amt) or 0 end

	FinishSubMachine(prior)
end
