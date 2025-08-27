local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent('tropic-shopping:checkout', function(storeKey, items)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then 
        return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Player not found.", type = 'error' })
    end

    local store = Config.Stores[storeKey]
    if not store then 
        return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Invalid store.", type = 'error' })
    end

    local totalCost, validItems = 0, {}

    for itemName, itemData in pairs(items or {}) do
        if type(itemData.count) ~= 'number' or itemData.count <= 0 then
            return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Invalid quantity for item: " .. itemName, type = 'error' })
        end

        local found, price = false, 0
        for _, zone in pairs(store.zones) do
            for _, zoneItem in pairs(zone.items) do
                if zoneItem.name == itemName then
                    found, price = true, zoneItem.price
                    break
                end
            end
            if found then break end
        end

        if not found then
            return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Invalid item: " .. itemName, type = 'error' })
        end

        totalCost += (price * itemData.count)
        validItems[#validItems+1] = { name = itemName, count = itemData.count }
    end

    if totalCost <= 0 then
        return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Invalid total cost.", type = 'error' })
    end

    if Config.Inventory == 'ox' then
        if not exports.ox_inventory:RemoveItem(src, 'cash', totalCost) then
            return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Not enough money.", type = 'error' })
        end

        for _, v in ipairs(validItems) do
            if not exports.ox_inventory:CanCarryItem(src, v.name, v.count) then
                return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Not enough space for item: " .. v.name, type = 'error' })
            end
        end

        for _, v in ipairs(validItems) do
            exports.ox_inventory:AddItem(src, v.name, v.count)
        end

    elseif Config.Inventory == 'qb' then
        if not Player.Functions.RemoveMoney("cash", totalCost) then
            return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Not enough money.", type = 'error' })
        end

        for _, v in ipairs(validItems) do
            if not Player.Functions.AddItem(v.name, v.count) then
                return TriggerClientEvent('ox_lib:notify', src, { title = "Error", description = "Not enough space for item: " .. v.name, type = 'error' })
            end
        end
    end

    TriggerClientEvent('ox_lib:notify', src, { title = "Success", description = ("Purchase complete! Total cost: $%s"):format(totalCost), type = 'success' })
end)
