if SERVER
then
	function ENT:GetEnvironment() return GetEnvironmentAtVector(self:GetPos()) end
	function ENT:GetAtmosphere() return self:GetEnvironment():GetAtmosphere(self:GetPhase()) end
end
function ENT:GetPhase() return (not self:IsInWorld() and "solid") or (self:WaterLevel()>=3 and "liquid") or "gas" end
