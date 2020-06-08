function ENT:GetMachineNetwork()
	if(CurTime()>((self.machineNetwork or {}).timestamp or 0)+1)
	then
		local machines={}
		self.machineNetwork={timestamp=CurTime(),machines=machines}
		local scannedEnts={}
		local entsToScan={self}
		while(#entsToScan>0)
		do
			local ent=table.remove(entsToScan)
			table.insert(scannedEnts,ent)
			if(ent.IsSpaceMachine)
			then
				table.insert(machines,ent)
				ent.machineNetwork=self.machineNetwork
			end
			for _,type in pairs({"Weld","Rope"})
			do
				local constraints=constraint.FindConstraints(ent,type)
				for _,con in pairs(constraints)
				do
					local newEnt=(con.Ent1==ent) and con.Ent2 or con.Ent1
					local alreadyScanned=false
					for ___,oldEnt in pairs(scannedEnts)
					do
						if(oldEnt==newEnt)
						then
							alreadyScanned=true
							break
						end
					end
					if(not alreadyScanned)
					then
						for ___,oldEnt in pairs(entsToScan)
						do
							if(oldEnt==newEnt)
							then
								alreadyScanned=true
								break
							end
						end
					end
					if(not alreadyScanned) then table.insert(entsToScan,newEnt) end
				end
			end
		end
	end
	return self.machineNetwork.machines
end

function ENT:OfferResourceToNetwork(res,amt)
	local maxamt=amt
	for i,v in ipairs(self:GetMachineNetwork())
	do
		if(not IsValid(v) or v==self) then continue end
		amt=amt-v:OfferResource(res,amt)
	end
	return maxamt-amt
end
function ENT:RequestResourceFromNetwork(res,amt)
	local maxamt=amt
	for i,v in ipairs(self:GetMachineNetwork())
	do
		if(not IsValid(v) or v==self) then continue end
		amt=amt-v:RequestResource(res,amt)
	end
	return maxamt-amt
end
function ENT:ProduceResource(res,amt)
	self:SetResource(res,self:GetResource(res)+amt)
end

function ENT:VentResource(res,diff)
	local current=self:GetResource(res)
	if diff>current then diff=current end
	self:SetResource(res,current-diff)
	local resource=GetResourceData(res)
	local phase=resource.type
	if(phase=="solid")
	then
		--TODO: Eject solid resource.
	elseif(phase=="liquid" or phase=="gas")
	then
		local atmos=self:GetEnvironment():GetAtmosphere(phase)
		atmos[res]=(atmos[res] or 0)+diff
	end
end

function ENT:ProcessResources()
	for ResourceName,Resource in pairs(IS_RESOURCES)
	do
		local current=self:GetResource(ResourceName)
		local max=self:GetMaxResource(ResourceName)
		if current>max
		then
			self:SetResource(ResourceName,max)
			local diff=current-max
			diff=diff-self:OfferResourceToNetwork(ResourceName,diff)
			if diff>0 then self:VentResource(ResourceName,diff) end
		end
	end
end

function UseBasicPowerSwitch(self,ply,caller) self:SetPower(not self:GetPower()) end
function ENT:SetPower(on) self:SetNWBool("power",on) end
function ENT:GetPower() return self:GetNWBool("power") end

function GenerateBasicConverterMachine(ENT,Inputs,Outputs)
	ENT.Use=UseBasicPowerSwitch
	function ENT:RecalculateStorage()
		for res,amt in pairs(Inputs) do self:SetMaxResource(res,amt*self:GetStorageMultiplier()) end
	end
	function ENT:ProcessResources()
		self.Baseclass.ProcessResources(self)
		if(self:GetPower())
		then
			local full=true
			for res,_ in pairs(Inputs)
			do
				local current,maximum=self:GetResource(res),self:GetMaxResource(res)
				local needed=maximum-current
				if(needed>0)
				then
					local added=self:RequestResourceFromNetwork(res,needed)
					current=current+added
					self:SetResource(res,current)
					needed=needed-added
				end
				if(needed>0) then full=false end
			end
			if(full)
			then
				for res,amt in pairs(Outputs)
				do
					self:ProduceResource(res,amt*self:GetStorageMultiplier())
				end
				for res,_ in pairs(Inputs)
				do
					self:SetResource(res,0)
				end
			end
		end
	end
end
