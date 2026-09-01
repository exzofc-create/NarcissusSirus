local addonName, NS = ...

local floor = math.floor
local tonumber = tonumber
local ipairs = ipairs

local afterTimerFrame = CreateFrame("Frame")
local afterTimers = {}

afterTimerFrame:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    local i = 1
    while i <= #afterTimers do
        local t = afterTimers[i]
        if now >= t.endTime then
            tremove(afterTimers, i)
            local ok, err = pcall(t.callback)
            if not ok and NS.Print then
                NS.Print("|cffff4444Timer error:|r " .. tostring(err))
            end
        else
            i = i + 1
        end
    end
    if #afterTimers == 0 then
        self:Hide()
    end
end)

function NS.After(delay, callback)
    tinsert(afterTimers, { endTime = GetTime() + delay, callback = callback })
    afterTimerFrame:Show()
end

function NS.ParseItemLink(link)
    if not link then return nil end
    local color, itemString, name = link:match("|cff(%x+)|H(item:[^|]+)|h%[([^%]]+)%]|h|r")
    if not itemString then return nil end

    local fields = {strsplit(":", itemString)}

    return {
        color = color,
        itemString = itemString,
        name = name,
        itemId = tonumber(fields[2]) or 0,
        enchantId = tonumber(fields[3]) or 0,
        gem1 = tonumber(fields[4]) or 0,
        gem2 = tonumber(fields[5]) or 0,
        gem3 = tonumber(fields[6]) or 0,
        gem4 = tonumber(fields[7]) or 0,
        suffixId = tonumber(fields[8]) or 0,
        uniqueId = tonumber(fields[9]) or 0,
        level = tonumber(fields[10]) or 0,
        link = link,
    }
end

function NS.GetItemLevel(link)
    if not link then return 0 end
    local _, _, _, itemLevel = GetItemInfo(link)
    return itemLevel or 0
end

function NS.GetAverageItemLevel()
    if GetAverageItemLevel then
        return GetAverageItemLevel()
    end
    local totalLevel = 0
    local count = 0
    local slots = {1, 2, 3, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17}
    for _, slotID in ipairs(slots) do
        local link = GetInventoryItemLink("player", slotID)
        if link then
            local level = NS.GetItemLevel(link)
            if level > 0 then
                totalLevel = totalLevel + level
                count = count + 1
            end
        end
    end
    if count > 0 then
        return floor(totalLevel / count * 100 + 0.5) / 100
    end
    return 0
end

function NS.GetEnchantInfo(link)
    local parsed = NS.ParseItemLink(link)
    if not parsed then return nil end
    if parsed.enchantId > 0 then
        return NS.ENCHANT_DATA[parsed.enchantId] or { name = "Enchant #" .. parsed.enchantId, id = parsed.enchantId }
    end
    return nil
end

function NS.GetGemInfo(link)
    local gems = {}
    for i = 1, 4 do
        local gemName, gemLink = GetItemGem(link, i)
        if gemLink then
            local _, _, _, _, _, _, _, _, _, gemTexture = GetItemInfo(gemLink)
            gems[i] = {
                name = gemName,
                link = gemLink,
                texture = gemTexture,
            }
        end
    end
    return gems
end

function NS.TruncateText(text, maxChars)
    if not text or maxChars < 1 then return text or "" end
    local chars = 0
    for i = 1, #text do
        local b = text:byte(i)
        if b < 128 or b >= 192 then
            chars = chars + 1
            if chars > maxChars then
                return (text:sub(1, i - 1):gsub("%s+$", "")) .. "..."
            end
        end
    end
    return text
end

function NS.GetQualityColor(quality)
    if quality and ITEM_QUALITY_COLORS then
        local c = ITEM_QUALITY_COLORS[quality]
        if c then return c.r, c.g, c.b end
    end
    return 1, 1, 1
end

function NS.CreateBackdrop(frame, inset, r, g, b, a)
    inset = inset or 2
    r = r or 0
    g = g or 0
    b = b or 0
    a = a or 0.85

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = inset, right = inset, top = inset, bottom = inset },
        })
        frame:SetBackdropColor(r, g, b, a)
        frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end
end

function NS.Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccffNarcissusSirus|r: " .. msg)
end
