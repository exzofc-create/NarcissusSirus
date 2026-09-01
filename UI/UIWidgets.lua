local addonName, NS = ...
local L = NS.L

local Widgets = {}
NS.Widgets = Widgets

function Widgets.CreateCloseButton(parent, size, onClick)
    local S = NS.Styling
    size = size or 22

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(size, size)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.12, 0.12, 0.18, 0.85)

    local border = CreateFrame("Frame", nil, btn)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(0.6, 0.2, 0.2, 0.8)
    border:EnableMouse(false)

    local text = btn:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", size > 24 and 16 or 12, "OUTLINE")
    text:SetTextColor(0.9, 0.3, 0.3)
    text:SetPoint("CENTER")
    text:SetText("X")

    btn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    btn:GetHighlightTexture():SetVertexColor(0.5, 0.1, 0.1, 0.3)

    if onClick then btn:SetScript("OnClick", onClick) end
    return btn
end

function Widgets.CreateThemedEditBox(parent, width, height, maxLetters)
    local S = NS.Styling

    local box = CreateFrame("EditBox", nil, parent)
    box:SetSize(width or 160, height or 22)
    box:SetAutoFocus(false)
    box:SetMaxLetters(maxLetters or 30)
    box:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    box:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    box:SetTextInsets(7, 7, 0, 0)

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.02, 0.02, 0.04, 0.9)

    local border = CreateFrame("Frame", nil, box)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    border:EnableMouse(false)

    box:SetScript("OnEditFocusGained", function()
        border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
    end)
    box:SetScript("OnEditFocusLost", function()
        border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
    end)
    box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    return box
end

function Widgets.CreateThemedCheckbox(parent, label, default, onClick)
    local S = NS.Styling

    local box = CreateFrame("Button", nil, parent)
    box:SetSize(16, 16)

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(0.02, 0.02, 0.04, 0.9)

    local border = CreateFrame("Frame", nil, box)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:EnableMouse(false)

    local fill = box:CreateTexture(nil, "ARTWORK")
    fill:SetPoint("TOPLEFT", 3, -3)
    fill:SetPoint("BOTTOMRIGHT", -3, 3)
    fill:SetTexture("Interface\\Buttons\\WHITE8x8")
    fill:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)

    local text = box:CreateFontString(nil, "OVERLAY")
    text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    text:SetPoint("LEFT", box, "RIGHT", 8, 0)
    text:SetJustifyH("LEFT")
    text:SetText(label)
    box.text = text

    box:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    box:GetHighlightTexture():SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.2)

    box.checked = default and true or false

    local function Refresh()
        if box.checked then
            fill:Show()
            border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.9)
            text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        else
            fill:Hide()
            border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
            text:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
        end
    end
    Refresh()

    box:SetScript("OnClick", function(self)
        self.checked = not self.checked
        Refresh()
        if onClick then onClick(self.checked) end
    end)

    function box:SetChecked(value)
        self.checked = value and true or false
        Refresh()
    end

    return box
end

function Widgets.CreateThemedButton(parent, text, width, height, onClick, color)
    local S = NS.Styling
    color = color or S.ACCENT

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 100, height or 22)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    bg:SetVertexColor(S.BG_SLOT[1], S.BG_SLOT[2], S.BG_SLOT[3], 0.85)

    local border = CreateFrame("Frame", nil, btn)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    border:SetBackdropBorderColor(color[1], color[2], color[3], 0.7)
    border:EnableMouse(false)

    local label = btn:CreateFontString(nil, "OVERLAY")
    label:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    label:SetTextColor(color[1], color[2], color[3])
    label:SetPoint("CENTER")
    label:SetText(text)
    btn.label = label

    btn:SetHighlightTexture("Interface\\Buttons\\WHITE8x8", "ADD")
    btn:GetHighlightTexture():SetVertexColor(color[1], color[2], color[3], 0.2)

    btn.SetText = function(self, s) self.label:SetText(s) end

    if onClick then btn:SetScript("OnClick", onClick) end
    return btn
end

local confirmFrame

function Widgets.ShowConfirm(text, acceptText, onAccept)
    local S = NS.Styling

    if not confirmFrame then
        local scrim = CreateFrame("Frame", "NarcissusSirus_ConfirmScrim", UIParent)
        scrim:SetAllPoints(UIParent)
        scrim:SetFrameStrata("FULLSCREEN_DIALOG")
        scrim:SetFrameLevel(280)
        scrim:EnableMouse(true)
        local shade = scrim:CreateTexture(nil, "BACKGROUND")
        shade:SetAllPoints()
        shade:SetTexture("Interface\\Buttons\\WHITE8x8")
        shade:SetVertexColor(0, 0, 0, 0.55)

        local f = CreateFrame("Frame", "NarcissusSirus_ConfirmFrame", scrim)
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:SetFrameLevel(285)
        f:EnableMouse(true)
        S.ApplyPanelStyle(f, 340, 132)
        S.CreateShadow(f, 6, 0.5)
        S.ApplyTabChrome(f)
        S.CreateGradientTopBorder(f)

        local body = f:CreateFontString(nil, "OVERLAY")
        body:SetFont("Fonts\\FRIZQT__.TTF", 12, "")
        body:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
        body:SetPoint("TOP", f, "TOP", 0, -24)
        body:SetWidth(300)
        body:SetJustifyH("CENTER")
        f.body = body

        local accept = Widgets.CreateThemedButton(f, "", 110, 24, function()
            local fn = f._onAccept
            Widgets.HideConfirm()
            if fn then fn() end
        end)
        accept:SetPoint("BOTTOM", f, "BOTTOM", -60, 16)
        f.accept = accept

        local cancel = Widgets.CreateThemedButton(f, L["Отмена"], 110, 24, function()
            Widgets.HideConfirm()
        end, S.TEXT_NORMAL)
        cancel:SetPoint("BOTTOM", f, "BOTTOM", 60, 16)

        tinsert(UISpecialFrames, "NarcissusSirus_ConfirmFrame")
        f:SetScript("OnHide", function() scrim:Hide() end)

        confirmFrame = f
        f.scrim = scrim
    end

    confirmFrame.body:SetText(text or "")
    confirmFrame.accept:SetText(acceptText or L["Да"])
    confirmFrame._onAccept = onAccept
    confirmFrame.scrim:Show()
    confirmFrame:Show()
    S.FadeIn(confirmFrame, 0.15)
end

function Widgets.HideConfirm()
    if not confirmFrame then return end
    confirmFrame._onAccept = nil
    confirmFrame:Hide()
    confirmFrame.scrim:Hide()
end

function Widgets.CreateThemedSlider(parent, label, minValue, maxValue, step, value, onChange, suffix)
    local S = NS.Styling

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(280, 32)

    local caption = holder:CreateFontString(nil, "OVERLAY")
    caption:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
    caption:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
    caption:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    caption:SetText(label)

    local readout = holder:CreateFontString(nil, "OVERLAY")
    readout:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
    readout:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])
    readout:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)

    local slider = CreateFrame("Slider", nil, holder)
    slider:SetOrientation("HORIZONTAL")
    slider:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 2)
    slider:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", 0, 2)
    slider:SetHeight(12)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step or 1)

    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetHeight(2)
    track:SetPoint("LEFT", slider, "LEFT", 0, 0)
    track:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
    track:SetTexture("Interface\\Buttons\\WHITE8x8")
    track:SetVertexColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)

    slider:SetThumbTexture("Interface\\Buttons\\WHITE8x8")
    local thumb = slider:GetThumbTexture()
    if thumb then
        thumb:SetSize(8, 14)
        thumb:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 1)
    end

    local function Readout(v)
        readout:SetText(tostring(v) .. (suffix or ""))
    end

    local quiet = false
    slider:SetScript("OnValueChanged", function(self, v)
        v = math.floor(v + 0.5)
        Readout(v)
        if onChange and not quiet then onChange(v) end
    end)

    slider:SetValue(value or minValue)
    Readout(math.floor((value or minValue) + 0.5))

    function holder:SetValue(v)
        quiet = true
        slider:SetValue(v)
        quiet = false
        Readout(math.floor(v + 0.5))
    end

    holder.slider = slider
    return holder
end

function Widgets.CreateAccentPicker(parent, current, onPick)
    local S = NS.Styling

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(280, 20)

    local swatches = {}
    local function Refresh(active)
        for key, sw in pairs(swatches) do
            if key == active then
                sw.ring:SetBackdropBorderColor(0.95, 0.95, 0.95, 0.95)
            else
                sw.ring:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
            end
        end
    end

    for i, preset in ipairs(S.ACCENT_PRESETS) do
        local sw = CreateFrame("Button", nil, holder)
        sw:SetSize(20, 20)
        sw:SetPoint("LEFT", holder, "LEFT", (i - 1) * 26, 0)

        local fill = sw:CreateTexture(nil, "ARTWORK")
        fill:SetPoint("TOPLEFT", 2, -2)
        fill:SetPoint("BOTTOMRIGHT", -2, 2)
        fill:SetTexture("Interface\\Buttons\\WHITE8x8")
        fill:SetVertexColor(preset.glow[1], preset.glow[2], preset.glow[3], 1)

        local ring = CreateFrame("Frame", nil, sw)
        ring:SetPoint("TOPLEFT", 0, 0)
        ring:SetPoint("BOTTOMRIGHT", 0, 0)
        ring:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        ring:EnableMouse(false)
        sw.ring = ring

        sw:RegisterForClicks("LeftButtonUp")
        sw:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_TOP")
            GameTooltip:SetText(L[preset.name], preset.glow[1], preset.glow[2], preset.glow[3])
            GameTooltip:Show()
        end)
        sw:SetScript("OnLeave", function() GameTooltip:Hide() end)
        sw:SetScript("OnClick", function()
            Refresh(preset.key)
            if onPick then onPick(preset.key) end
        end)

        swatches[preset.key] = sw
    end

    Refresh(current)
    return holder
end

function Widgets.CreateOptionPicker(parent, options, current, onPick, maxWidth)
    local S = NS.Styling

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetHeight(20)

    local buttons = {}
    local function Refresh(active)
        for _, b in ipairs(buttons) do
            if b.optionKey == active then
                b.border:SetBackdropBorderColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 1)
                b.text:SetTextColor(S.TEXT_BRIGHT[1], S.TEXT_BRIGHT[2], S.TEXT_BRIGHT[3])
                b.bg:SetVertexColor(S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.18)
            else
                b.border:SetBackdropBorderColor(S.BORDER[1], S.BORDER[2], S.BORDER[3], 0.9)
                b.text:SetTextColor(S.TEXT_DIM[1], S.TEXT_DIM[2], S.TEXT_DIM[3])
                b.bg:SetVertexColor(0.10, 0.11, 0.14, 0.85)
            end
        end
    end

    local x, rows, widest = 0, 1, 0
    for _, option in ipairs(options) do
        local btn = CreateFrame("Button", nil, holder)
        btn:SetHeight(20)
        btn.optionKey = option.key

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture("Interface\\Buttons\\WHITE8x8")
        btn.bg = bg

        local border = CreateFrame("Frame", nil, btn)
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
        border:EnableMouse(false)
        btn.border = border

        local text = btn:CreateFontString(nil, "OVERLAY")
        text:SetFont("Fonts\\FRIZQT__.TTF", 11, "")
        text:SetPoint("CENTER")
        text:SetText(option.label)
        btn.text = text

        local w = text:GetStringWidth() + 18
        btn:SetWidth(w)
        if maxWidth and x > 0 and x + w > maxWidth then
            x = 0
            rows = rows + 1
        end
        btn:SetPoint("TOPLEFT", holder, "TOPLEFT", x, -(rows - 1) * 26)
        x = x + w + 6
        if x - 6 > widest then widest = x - 6 end

        btn:RegisterForClicks("LeftButtonUp")
        btn:SetScript("OnClick", function(self)
            if onPick then onPick(self.optionKey) end
        end)

        buttons[#buttons + 1] = btn
    end

    holder:SetWidth(widest > 0 and widest or 1)
    holder:SetHeight(rows * 20 + (rows - 1) * 6)
    holder.Refresh = function(_, active) Refresh(active) end
    Refresh(current)
    return holder
end
