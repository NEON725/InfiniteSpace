function ENT:GetMachineNetwork()
        local retVal={}
	local scannedEnts={}
	local entsToScan={self}
	while(#entsToScan>0)
	do
		local ent=table.remove(entsToScan)
		table.insert(scannedEnts,ent)
		if(ent.IsSpaceMachine) then table.insert(retVal,ent) end
		for _,type in pairs({"Weld","Rope"})
		do
			local constraints=constraint.FindConstraints(ent,type)
			for _,con in pairs(constraints)
			do
				local newEnts={con.Ent1,con.Ent2}
				for __,newEnt in pairs(newEnts)
				do
					local alreadyScanned=false
					for ___,oldEnt in pairs(scannedEnts)
					do
						if(oldEnt==newEnt)
						then
							alreadyScanned=true
							break
						end
					end
					for ___,oldEnt in pairs(entsToScan)
					do
						if(oldEnt==newEnt)
						then
							alreadyScanned=true
							break
						end
					end
					if(not alreadyScanned) then table.insert(entsToScan,newEnt) end
				end
			end
		end
	end
	return retVal
end

function ENT:AssignPendingNWVar(var,val,type)
	if(not type) then type="Float" end
	self.PendingNWVars=self.PendingNWVars or {}
	self.PendingNWVars[var]={val=val,type=type}
end
function ENT:SynchronizeNWVars()
	for i,v in pairs(self.PendingNWVars or {}) do self["SetNW"..v.type](self,i,v.val) end
	self.PendingNWVars={}
end
function ENT:GetResource(res) return self:GetNWFloat("resource_current_"..res) end
function ENT:GetMaxResource(res) return self:GetNWFloat("resource_maximum_"..res) end
function ENT:SetResource(res,amt) return self:SetNWFloat("resource_current_"..res,amt) end
function ENT:SetMaxResource(res,amt) return self:SetNWFloat("resource_maximum_"..res,amt) end

function ENT:OfferResourceToNetwork(res,amt)
        local maxamt=amt
        for i,v in ipairs(self:GetMachineNetwork())
        do
                amt=amt-v:OfferResource(res,amt)
        end
        return maxamt-amt
end
function ENT:OfferResource(res,amt)
        local current=self:GetResource(res)
        local max=self:GetMaxResource(res)
        local accepting=max-current
        if amt>accepting then amt=accepting end
        current=current+amt
        self:SetResource(res,current)
        return amt
end
function ENT:RequestResourceFromNetwork(res,amt)
        local maxamt=amt
        for i,v in ipairs(self:getMachineNetwork())
        do
                amt=amt-v:RequestResource(res,amt)
        end
        return maxamt-amt
end
function ENT:RequestResource(res,amt)
        local resTab=GetResourceData(res)
        local maxamt=amt
        for equiv,mul in pairs(resTab)
        do
                local current=self:GetResource(equiv)
                if current*mul>=amt
                then
                        current=current-amt/mul
                        self:SetResource(equiv,current)
                        amt=0
                        break
                else
                        amt=amt-current*mul
                        self:SetResource(equiv,0)
                end
        end
        return maxamt-amt
end

function ENT:VentResource(res,diff)
        local current=self:GetResource(res)
        if diff>current then diff=current end
        self:SetResource(res,current-diff)
        --TODO: Affect environment
end
