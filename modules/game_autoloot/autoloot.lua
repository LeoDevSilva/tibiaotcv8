local lootWindow = nil
local globalLootTable = {}

function init()
    lootWindow = g_ui.displayUI('autoloot')
    connect(g_game, { onAutolooteditems = onAutolootedItems }) -- Conecta o evento ao cliente
	lootWindow:hide()
	lootWindow:addAnchor(AnchorTop, 'topMenu', AnchorBottom)
	lootWindow:setImageSource('/images/ui/loot.png')
	lootWindow:setParent(modules.game_interface.getMapPanel())
	lootWindow:setHeight(36)
end

function terminate()
    disconnect(g_game, { onAutolooteditems = onAutolootedItems })
    if lootWindow then
        lootWindow:destroy()
    end
end

function onAutolootedItems(items)
    -- Processar os itens recebidos e adicioná-los à tabela global
    for itemId, count in pairs(items) do
        local validItemId = tonumber(itemId)
        local validCount = tonumber(count)

        if validItemId and validCount then
            if globalLootTable[validItemId] then
                globalLootTable[validItemId] = globalLootTable[validItemId] + validCount
            else
                globalLootTable[validItemId] = validCount
            end
        else
            print("⚠ Erro ao processar item! ID ou Count inválidos:", itemId, count)
        end
    end
    
	local itemsToLootAllWindow = {}
    for itemId, count in pairs(globalLootTable) do
        table.insert(itemsToLootAllWindow, itemId)
        table.insert(itemsToLootAllWindow, count)
    end

    show(unpack(itemsToLootAllWindow))
end

function show(...)
    local args = { ... }

    -- Garantir que a lootWindow tenha largura suficiente
    lootWindow:setWidth(modules.game_interface.getMapPanel():getWidth())
    addEvent(function() g_effects.fadeIn(lootWindow, 250) end)
    lootWindow:setPhantom(false)
    lootWindow:show()
    lootWindow:raise()
    lootWindow:focus()

    -- Limpar TODOS os slots antes de atualizar (supondo que você tem 11 slots)
    for i = 1, 11 do
        local lootSlot = lootWindow:getChildById('loot' .. i)
        local countSlot = lootWindow:getChildById('count' .. i)
        if lootSlot then
            lootSlot:setItemId(0)  -- ou um valor que indique "vazio"
			lootSlot:setVirtual(true)
        end
        if countSlot then
            countSlot:setText("")
        end
    end

    -- Atualizar os slots com os itens recebidos
    for i = 1, #args, 2 do
        local itemID = tonumber(args[i])      -- Garantir que seja número
        local count = tonumber(args[i + 1])     -- Garantir que seja número

        if itemID and count then
            local slotIndex = (i + 1) / 2
            local lootSlot = lootWindow:getChildById('loot' .. slotIndex)
            local countSlot = lootWindow:getChildById('count' .. slotIndex)

            if lootSlot then
                lootSlot:setItemId(itemID)
				lootSlot:setVirtual(true)
            end

            if countSlot then
                countSlot:setText(count > 1 and tostring(count) or "")
            end
        else
            print("Erro ao processar item: ", itemID, count)
        end
    end

    -- Ajuste de espaçamento conforme a quantidade de itens
    local lastItemIndex = math.floor(#args / 2)
    lootWindow:getChildById('loot1'):setMarginRight(16 * lastItemIndex)
    lootWindow:getChildById('count1'):setMarginRight(16 * lastItemIndex)

    if desaparecendo ~= nil then removeEvent(desaparecendo) end

    desaparecendo = scheduleEvent(function() 
        g_effects.fadeOut(lootWindow, 2900)
        desaparecendo = nil
        lootWindow:setPhantom(true)
        globalLootTable = {}  -- Resetar após o fadeOut
    end, 3000)
end
