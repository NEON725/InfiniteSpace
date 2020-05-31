Environment={}
Environment.__index=Environment

function Environment:new(name,pos,radius,shape)
	if not shape then shape="sphere" end
	local retval=
	{
		name=name,
		position=pos,
		radius=radius,
		shape=shape,
		atmosphere=
		{
			gas={},
			liquid={},
			solid={}
		}
	}
	setmetatable(retval,Environment)
	return retval
end

setmetatable(Environment,{__call=Environment.new})
