local function SetAbsVelocity(pEntity, vAbsVelocity)
	if (pEntity:GetInternalVariable("m_vecAbsVelocity") ~= vAbsVelocity) then
		// The abs velocity won't be dirty since we're setting it here
		pEntity:RemoveEFlags(EFL_DIRTY_ABSVELOCITY)

		// All children are invalid, but we are not
		local tChildren = pEntity:GetChildren()

		for i = 1, #tChildren do
			tChildren[i]:AddEFlags(EFL_DIRTY_ABSVELOCITY)
		end

		pEntity:SetSaveValue("m_vecAbsVelocity", vAbsVelocity)

		// NOTE: Do *not* do a network state change in this case.
		// m_vVelocity is only networked for the player, which is not manual mode
		local pMoveParent = pEntity:GetMoveParent()

		if (pMoveParent:IsValid()) then
			// First subtract out the parent's abs velocity to get a relative
			// velocity measured in world space
			// Transform relative velocity into parent space
			-- FIXME
			--pEntity:SetSaveValue("m_vecVelocity", (vAbsVelocity - pMoveParent:_GetAbsVelocity()):IRotate(pMoveParent:EntityToWorldTransform()))
			pEntity:SetSaveValue("velocity", vAbsVelocity)
		else
			pEntity:SetSaveValue("velocity", vAbsVelocity)
		end
	end
end

------------------------
-- Might be useful
------------------------
local inf,ninf,ind = 1/0,-1/0,(1/0)/(1/0)

--(ind==ind) == false :(. This should do though. >= and <= because you never know :3

function math.BadNumber(v) 
	return not v or v==inf or v==ninf or not (v>=0 or v<=0) or tostring(v) == "nan"
end

local max_reasonable_pos 		= 25000
local min_reasonable_pos 		= -25000

function IsReasonable( pos )
	local posY, posZ = pos.y, pos.z

	if (pos.x > max_reasonable_pos or posY < min_reasonable_pos or
		posY > max_reasonable_pos or posZ < min_reasonable_pos or
		posZ > max_reasonable_pos) then
		return false
	end
	return true
end

-- OnCrazyPhysics is raised by the physics engine. Recovery must not change
-- collision rules, teleport physics objects, or remove constraints in that call.
local pendingRecovery = setmetatable({}, {__mode = "k"})
hook.Add("OnCrazyPhysics", "crazy_physics", function(ent, physobj)
	if not IsValid(ent) or not IsValid(physobj) then return end
	if pendingRecovery[physobj] then return end
	pendingRecovery[physobj] = true

	timer.Simple(0, function()
		pendingRecovery[physobj] = nil
		if not IsValid(ent) or not IsValid(physobj) then return end

		-- No collision filter was changed, so CollisionRulesChanged is unnecessary.
		physobj:EnableMotion(false)
		physobj:Sleep()
		physobj:SetPos(vector_origin)
		physobj:SetAngles(angle_zero)
		physobj:SetVelocity(vector_origin)
		physobj:SetAngleVelocity(vector_origin)

		ent:SetLocalAngularVelocity(angle_zero)
		ent:SetVelocity(vector_origin)
		ent:SetLocalVelocity(vector_origin)
		SetAbsVelocity(ent, vector_origin)

		-- Keep the existing constrained-entity cleanup, outside the callback.
		if SERVER then
			local constrained = constraint.GetAllConstrainedEntities(ent)
			for _, linked in pairs(constrained or {}) do
				if IsValid(linked) then
					local connected = constraint.GetAllConstrainedEntities(linked)
					for _, other in pairs(connected or {}) do
						if other ~= ent and IsValid(other) and not other.__removed__ then
							other.__removed__ = true
							other:Remove()
						end
					end
					if IsValid(linked) and not linked.__removed__ then
						linked.__removed__ = true
						linked:Remove()
					end
				end
			end
		end
	end)
end)
