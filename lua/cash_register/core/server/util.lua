PxlCashRegister.Util = PxlCashRegister.Util or {}
local Util = PxlCashRegister.Util


function Util.GetAllEntities(ent, result)
    local first = false

    if not result then
        result = {}
        first = true
    end

    result[ent] = ent

    for _, con in pairs(ent.Constraints or {}) do
        for i=1, 6 do
            local e = con["Ent"..i]
            if e and not result[e] and e:IsValid() then
                Util.GetAllEntities(e, result)
            end
        end
    end

    if first then
        local newresult = {}
        for _, e in pairs(result) do
            table.insert(newresult, e)
        end
        return newresult
    end

    return result
end

function Util.GetAllConstraints(ents)
    local contraints = {}

    for _, ent in pairs(ents) do
        for _, contr in pairs(ent.Constraints or {}) do
            if not contraints[contr] then
                contraints[contr] = contr
            end
        end
    end

    local result = {}
    for _, c in pairs(contraints) do
        table.insert(result, c)
    end

    return result
end

function Util.NiceModel(model)
    local ar = string.Explode("/", model)
    return string.sub(ar[#ar], 0, -5)
end

function Util.Reverse(tab)
    local ntab = {}

    for k,v in pairs(tab) do
        ntab[v] = k
    end

    return ntab
end

function Util.ChangeOwnership(entities, ply)
    local contsraints = Util.GetAllConstraints(entities) or {}

    for _, ent in pairs(entities) do
        if ent.SID then
            ent.SID = ply.SID
        end

        if ent.Getowning_ent and IsValid(ent:Getowning_ent()) then
            ent:Setowning_ent(ply)
        end

        if CPPI and IsValid(ent:CPPIGetOwner()) then
            ent:CPPISetOwner(ply)
        end
    end

    for uid, plytab in pairs(undo.GetTable()) do
        for id, u in pairs(plytab) do
            rents = Util.Reverse(u.Entities)

            for _, ent in pairs(entities) do
                if rents[ent] then
                    plytab[id] = nil
                end
            end

            for _, c in pairs(contsraints) do
                if rents[c] then
                    plytab[id] = nil
                end
            end
        end
    end

    for uid, plytab in pairs(cleanup.GetList()) do
        for type, tab in pairs(plytab) do
            local rtab = table.Reverse(tab)

            for _, ent in pairs(entities) do
                if rtab[ent] then
                    table.remove(tab, rtab[ent])
                    table.insert(cleanup.GetList()[ply:UniqueID()][type], ent)
                end
            end

            for _, c in pairs(contsraints) do
                if rtab[c] then
                    table.remove(tab, rtab[c])
                    table.insert(cleanup.GetList()[ply:UniqueID()][type], c)
                end
            end
        end
    end

    if g_SBoxObjects then
        for uid, plytab in pairs(g_SBoxObjects) do
            for type, tab in pairs(plytab) do
                local rtab = {}
                for k,v in pairs(tab) do rtab[v] = k end

                for _, ent in pairs(entities) do
                    if rtab[ent] then
                        table.remove(tab, rtab[ent])

                        g_SBoxObjects[ply:UniqueID()] = g_SBoxObjects[ply:UniqueID()] or {}
                        g_SBoxObjects[ply:UniqueID()][type] = g_SBoxObjects[ply:UniqueID()][type] or {}
                        table.insert(g_SBoxObjects[ply:UniqueID()][type], ent)
                    end
                end
            end
        end
    end
end

