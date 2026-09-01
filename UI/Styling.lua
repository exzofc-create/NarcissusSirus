local addonName, NS = ...

local Styling = {}
NS.Styling = Styling

Styling.BG_DARK      = { 0.03, 0.03, 0.06 }
Styling.BG_DARK_A    = 0.94
Styling.BG_SLOT      = { 0.06, 0.07, 0.10 }
Styling.BG_STRIPE    = { 0.05, 0.09, 0.16 }

Styling.ACCENT       = { 0.0, 0.68, 0.48 }
Styling.ACCENT_DIM   = { 0.0, 0.40, 0.28 }
Styling.ACCENT_GLOW  = { 0.0, 0.85, 0.60 }

Styling.ACCENT_PRESETS = {
    { key = "emerald", name = "Изумруд",  base = { 0.00, 0.68, 0.48 }, dim = { 0.00, 0.40, 0.28 }, glow = { 0.00, 0.85, 0.60 } },
    { key = "azure",   name = "Лазурь",   base = { 0.10, 0.55, 0.85 }, dim = { 0.06, 0.32, 0.50 }, glow = { 0.25, 0.72, 1.00 } },
    { key = "amber",   name = "Янтарь",   base = { 0.88, 0.62, 0.12 }, dim = { 0.52, 0.36, 0.07 }, glow = { 1.00, 0.78, 0.28 } },
    { key = "crimson", name = "Багрянец", base = { 0.80, 0.20, 0.28 }, dim = { 0.48, 0.12, 0.17 }, glow = { 1.00, 0.36, 0.42 } },
    { key = "violet",  name = "Аметист",  base = { 0.58, 0.36, 0.86 }, dim = { 0.34, 0.21, 0.52 }, glow = { 0.74, 0.53, 1.00 } },
    { key = "frost",   name = "Иней",     base = { 0.45, 0.72, 0.78 }, dim = { 0.26, 0.43, 0.47 }, glow = { 0.62, 0.90, 0.96 } },
}

function Styling.ApplyAccent(key)
    for _, preset in ipairs(Styling.ACCENT_PRESETS) do
        if preset.key == key then
            for i = 1, 3 do
                Styling.ACCENT[i] = preset.base[i]
                Styling.ACCENT_DIM[i] = preset.dim[i]
                Styling.ACCENT_GLOW[i] = preset.glow[i]
            end
            return true
        end
    end
    return false
end

Styling.GOLD         = { 1.0, 0.82, 0.0 }
Styling.GOLD_DIM     = { 0.80, 0.65, 0.0 }

Styling.TEXT_BRIGHT  = { 0.92, 0.92, 0.92 }
Styling.TEXT_NORMAL  = { 0.70, 0.70, 0.75 }
Styling.TEXT_DIM     = { 0.45, 0.45, 0.50 }

Styling.BORDER       = { 0.18, 0.20, 0.28, 0.85 }
Styling.BORDER_LIGHT = { 0.25, 0.30, 0.40, 0.6 }

Styling.PANEL_WIDTH  = 440
Styling.PANEL_HEIGHT = 340
Styling.PANEL_X      = -8
Styling.PANEL_GAP    = 6

Styling.PANEL_Y      = (Styling.PANEL_HEIGHT + Styling.PANEL_GAP) / 2

function Styling.CreateGradientTopBorder(parent, height, r, g, b, a)
    height = height or 2
    r = r or Styling.ACCENT[1]
    g = g or Styling.ACCENT[2]
    b = b or Styling.ACCENT[3]
    a = a or 0.9

    local border = parent:CreateTexture(nil, "OVERLAY")
    border:SetHeight(height)
    border:SetPoint("TOPLEFT", parent, "TOPLEFT", 4, -3)
    border:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -4, -3)
    border:SetTexture("Interface\\Buttons\\WHITE8x8")
    border:SetVertexColor(r, g, b, a)
    return border
end

function Styling.AddHoverGlow(frame, r, g, b, size)
    r = r or Styling.ACCENT_GLOW[1]
    g = g or Styling.ACCENT_GLOW[2]
    b = b or Styling.ACCENT_GLOW[3]
    size = size or 1

    local glow = CreateFrame("Frame", nil, frame)
    glow:SetPoint("TOPLEFT", -size - 1, size + 1)
    glow:SetPoint("BOTTOMRIGHT", size + 1, -size - 1)
    glow:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = size,
    })
    glow:SetBackdropBorderColor(r, g, b, 0)
    glow:SetFrameLevel(frame:GetFrameLevel() + 1)
    glow:EnableMouse(false)

    local elapsed = 0
    local duration = 0.15

    frame:HookScript("OnEnter", function(self)
        elapsed = 0
        glow:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local t = min(elapsed / duration, 1)
            self:SetBackdropBorderColor(r, g, b, t * 0.7)
            if t >= 1 then self:SetScript("OnUpdate", nil) end
        end)
    end)

    frame:HookScript("OnLeave", function(self)
        elapsed = 0
        glow:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local t = min(elapsed / duration, 1)
            self:SetBackdropBorderColor(r, g, b, (1 - t) * 0.7)
            if t >= 1 then
                self:SetScript("OnUpdate", nil)
                self:SetBackdropBorderColor(r, g, b, 0)
            end
        end)
    end)

    return glow
end

function Styling.CreateRingBorder(parent, radius, r, g, b)
    r = r or Styling.ACCENT[1]
    g = g or Styling.ACCENT[2]
    b = b or Styling.ACCENT[3]

    local ring = CreateFrame("Frame", nil, parent)
    ring:SetPoint("TOPLEFT", -3, 3)
    ring:SetPoint("BOTTOMRIGHT", 3, -3)
    ring:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    ring:SetBackdropBorderColor(r * 0.5, g * 0.5, b * 0.5, 0.5)
    ring:SetFrameLevel(parent:GetFrameLevel() + 1)
    ring:EnableMouse(false)

    local elapsed = 0
    local duration = 0.2

    parent:HookScript("OnEnter", function(self)
        elapsed = 0
        ring:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local t = min(elapsed / duration, 1)
            local ease = t * t * (3 - 2 * t)
            self:SetBackdropBorderColor(
                r * 0.5 + r * 0.5 * ease,
                g * 0.5 + g * 0.5 * ease,
                b * 0.5 + b * 0.5 * ease,
                0.5 + 0.4 * ease
            )
            if t >= 1 then self:SetScript("OnUpdate", nil) end
        end)
    end)

    parent:HookScript("OnLeave", function(self)
        elapsed = 0
        ring:SetScript("OnUpdate", function(self, dt)
            elapsed = elapsed + dt
            local t = min(elapsed / duration, 1)
            local ease = t * t * (3 - 2 * t)
            self:SetBackdropBorderColor(
                r * (1 - 0.5 * ease),
                g * (1 - 0.5 * ease),
                b * (1 - 0.5 * ease),
                0.9 - 0.4 * ease
            )
            if t >= 1 then
                self:SetScript("OnUpdate", nil)
                self:SetBackdropBorderColor(r * 0.5, g * 0.5, b * 0.5, 0.5)
            end
        end)
    end)

    return ring
end

local CORNER_LEN = 12
local CORNERS = {
    { point = "TOPLEFT",     x =  3, y = -3 },
    { point = "TOPRIGHT",    x = -3, y = -3 },
    { point = "BOTTOMLEFT",  x =  3, y =  3 },
    { point = "BOTTOMRIGHT", x = -3, y =  3 },
}

function Styling.ApplyTabChrome(frame)
    if not frame or frame._tabChrome then return end
    frame._tabChrome = true

    local grad = frame:CreateTexture(nil, "BACKGROUND", nil, 2)
    grad:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    grad:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    grad:SetTexture("Interface\\Buttons\\WHITE8x8")
    grad:SetGradientAlpha("VERTICAL", 0, 0, 0, 0.32, 0, 0, 0, 0)

    local bevel = frame:CreateTexture(nil, "BORDER")
    bevel:SetHeight(1)
    bevel:SetPoint("TOPLEFT", frame, "TOPLEFT", 3, -3)
    bevel:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -3, -3)
    bevel:SetTexture("Interface\\Buttons\\WHITE8x8")
    bevel:SetVertexColor(0.45, 0.50, 0.62, 0.28)

    local A = Styling.ACCENT
    for _, c in ipairs(CORNERS) do
        local h = frame:CreateTexture(nil, "OVERLAY")
        h:SetSize(CORNER_LEN, 1)
        h:SetPoint(c.point, frame, c.point, c.x, c.y)
        h:SetTexture("Interface\\Buttons\\WHITE8x8")
        h:SetVertexColor(A[1], A[2], A[3], 0.75)

        local v = frame:CreateTexture(nil, "OVERLAY")
        v:SetSize(1, CORNER_LEN)
        v:SetPoint(c.point, frame, c.point, c.x, c.y)
        v:SetTexture("Interface\\Buttons\\WHITE8x8")
        v:SetVertexColor(A[1], A[2], A[3], 0.75)
    end
end

local PANEL_SLIDE = 28
local PANEL_ANIM  = 0.22

local function GetBasePoint(frame)
    if not frame._basePoint then
        local point, rel, relPoint, x, y = frame:GetPoint()
        frame._basePoint = {
            point or "TOPRIGHT",
            rel or frame:GetParent(),
            relPoint or "TOPRIGHT",
            x or 0,
            y or 0,
        }
    end
    return frame._basePoint
end

local function ApplyOffset(frame, dx)
    local b = frame._basePoint
    if not b then return end
    frame:ClearAllPoints()
    frame:SetPoint(b[1], b[2], b[3], b[4] + dx, b[5])
end

function Styling.AnimationsEnabled()
    return not NS.db or NS.db.animations ~= false
end

function Styling.PanelIn(frame, duration)
    if not frame then return end
    duration = duration or PANEL_ANIM
    GetBasePoint(frame)

    if not Styling.AnimationsEnabled() then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(1)
        ApplyOffset(frame, 0)
        frame:Show()
        return
    end

    local elapsed = 0
    frame:SetAlpha(0)
    ApplyOffset(frame, PANEL_SLIDE)
    frame:Show()

    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / duration
        if t >= 1 then
            self:SetAlpha(1)
            ApplyOffset(self, 0)
            self:SetScript("OnUpdate", nil)
        else
            local ease = 1 - (1 - t) ^ 3
            self:SetAlpha(ease)
            ApplyOffset(self, PANEL_SLIDE * (1 - ease))
        end
    end)
end

function Styling.PanelOut(frame, duration)
    if not frame or not frame:IsShown() then return end
    duration = duration or (PANEL_ANIM * 0.65)
    GetBasePoint(frame)

    if not Styling.AnimationsEnabled() then
        Styling.PanelHideNow(frame)
        return
    end

    local startAlpha = frame:GetAlpha()
    local elapsed = 0

    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local t = elapsed / duration
        if t >= 1 then
            self:SetScript("OnUpdate", nil)
            ApplyOffset(self, 0)
            self:Hide()
            self:SetAlpha(1)
        else
            local ease = t * t
            self:SetAlpha(startAlpha * (1 - ease))
            ApplyOffset(self, PANEL_SLIDE * 0.6 * ease)
        end
    end)
end

function Styling.PanelHideNow(frame)
    if not frame then return end
    frame:SetScript("OnUpdate", nil)
    frame:Hide()
    frame:SetAlpha(1)
    ApplyOffset(frame, 0)
end

function Styling.SetClassIcon(texture, class)
    if not texture then return end
    local coords = class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[class]
    if not coords then
        texture:Hide()
        return
    end
    texture:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
    texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    texture:SetVertexColor(1, 1, 1, 1)
    texture:Show()
end

function Styling.StyleScrollBar(scrollFrame)
    local bar = scrollFrame and scrollFrame.ScrollBar
    if not bar or bar._narciStyled then return end
    bar._narciStyled = true

    for _, btn in ipairs({ bar.ScrollUpButton, bar.ScrollDownButton }) do
        if btn then
            btn:Hide()
            btn:SetAlpha(0)
            btn:EnableMouse(false)
        end
    end

    bar:SetWidth(6)

    local track = bar:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("TOPLEFT", bar, "TOPLEFT", 1, 0)
    track:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -1, 0)
    track:SetTexture("Interface\\Buttons\\WHITE8x8")
    track:SetVertexColor(Styling.BORDER[1], Styling.BORDER[2], Styling.BORDER[3], 0.35)

    local thumb = bar:GetThumbTexture()
    if thumb then
        thumb:SetTexture("Interface\\Buttons\\WHITE8x8")
        thumb:SetTexCoord(0, 1, 0, 1)
        thumb:SetVertexColor(Styling.ACCENT[1], Styling.ACCENT[2], Styling.ACCENT[3], 0.75)
        thumb:SetSize(6, 36)
    end

    local FADE_HEIGHT = 14
    local holder = CreateFrame("Frame", nil, scrollFrame:GetParent())
    holder:SetAllPoints(scrollFrame)
    holder:SetFrameLevel(scrollFrame:GetFrameLevel() + 4)
    holder:Hide()

    local B = Styling.BG_DARK
    local function Fade(atTop)
        local t = holder:CreateTexture(nil, "OVERLAY")
        t:SetHeight(FADE_HEIGHT)
        t:SetTexture("Interface\\Buttons\\WHITE8x8")
        if atTop then
            t:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
            t:SetPoint("TOPRIGHT", holder, "TOPRIGHT", -8, 0)
            t:SetGradientAlpha("VERTICAL", B[1], B[2], B[3], 0, B[1], B[2], B[3], 0.95)
        else
            t:SetPoint("BOTTOMLEFT", holder, "BOTTOMLEFT", 0, 0)
            t:SetPoint("BOTTOMRIGHT", holder, "BOTTOMRIGHT", -8, 0)
            t:SetGradientAlpha("VERTICAL", B[1], B[2], B[3], 0.95, B[1], B[2], B[3], 0)
        end
        return t
    end
    local topFade, bottomFade = Fade(true), Fade(false)

    local function UpdateFades()
        local range = scrollFrame:GetVerticalScrollRange() or 0
        local offset = scrollFrame:GetVerticalScroll() or 0
        if offset > 1 then topFade:Show() else topFade:Hide() end
        if offset < range - 1 then bottomFade:Show() else bottomFade:Hide() end
    end
    scrollFrame:HookScript("OnVerticalScroll", UpdateFades)

    local function UpdateBarVisibility()
        local range = scrollFrame:GetVerticalScrollRange()
        if range and range > 1 then
            bar:Show()
            holder:Show()
            UpdateFades()
        else
            bar:Hide()
            holder:Hide()
        end
    end
    scrollFrame:HookScript("OnScrollRangeChanged", UpdateBarVisibility)
    scrollFrame:HookScript("OnShow", UpdateBarVisibility)
    UpdateBarVisibility()

    return bar
end

function Styling.CreateShadow(parent, size, alpha)
    size = size or 4
    alpha = alpha or 0.4

    local shadow = CreateFrame("Frame", nil, parent)
    shadow:SetPoint("TOPLEFT", -size, size)
    shadow:SetPoint("BOTTOMRIGHT", size, -size)
    shadow:SetFrameLevel(parent:GetFrameLevel() - 1)
    shadow:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = size,
        insets = { left = size, right = size, top = size, bottom = size },
    })
    shadow:SetBackdropColor(0, 0, 0, alpha * 0.3)
    shadow:SetBackdropBorderColor(0, 0, 0, alpha)
    return shadow
end

function Styling.FadeIn(frame, duration)
    if not frame then return end
    duration = duration or 0.25

    if not Styling.AnimationsEnabled() then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(1)
        frame:Show()
        return
    end

    frame:SetAlpha(0)
    frame:Show()

    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local progress = elapsed / duration
        if progress >= 1 then
            self:SetAlpha(1)
            self:SetScript("OnUpdate", nil)
        else
            self:SetAlpha(1 - (1 - progress) ^ 3)
        end
    end)
end

function Styling.FadeOut(frame, duration, hideOnComplete)
    if not frame then return end
    duration = duration or 0.2
    hideOnComplete = (hideOnComplete == nil) and true or hideOnComplete

    if not Styling.AnimationsEnabled() then
        frame:SetScript("OnUpdate", nil)
        frame:SetAlpha(0)
        if hideOnComplete then frame:Hide() end
        return
    end

    local startAlpha = frame:GetAlpha()
    local elapsed = 0
    frame:SetScript("OnUpdate", function(self, e)
        elapsed = elapsed + e
        local progress = elapsed / duration
        if progress >= 1 then
            self:SetAlpha(0)
            self:SetScript("OnUpdate", nil)
            if hideOnComplete then
                self:Hide()
            end
        else
            self:SetAlpha(startAlpha * (1 - progress) ^ 3)
        end
    end)
end

function Styling.ApplyPanelStyle(frame, width, height)
    if width then frame:SetWidth(width) end
    if height then frame:SetHeight(height) end

    if frame.SetBackdrop then
        frame:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
            insets = { left = 3, right = 3, top = 3, bottom = 3 },
        })
        frame:SetBackdropColor(Styling.BG_DARK[1], Styling.BG_DARK[2], Styling.BG_DARK[3], Styling.BG_DARK_A)
        frame:SetBackdropBorderColor(Styling.BORDER[1], Styling.BORDER[2], Styling.BORDER[3], Styling.BORDER[4])
    end

    Styling.CreateShadow(frame, 5, 0.4)
    Styling.CreateGradientTopBorder(frame)

    local bottomAccent = frame:CreateTexture(nil, "OVERLAY")
    bottomAccent:SetHeight(1)
    bottomAccent:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 3, 3)
    bottomAccent:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -3, 3)
    bottomAccent:SetTexture("Interface\\Buttons\\WHITE8x8")
    bottomAccent:SetVertexColor(Styling.ACCENT_DIM[1], Styling.ACCENT_DIM[2], Styling.ACCENT_DIM[3], 0.3)

    return frame
end

local breathDriver = CreateFrame("Frame")
local breathJobs = {}

local function JobIsVisible(job)
    return not job.parent or job.parent:IsVisible()
end

breathDriver:SetScript("OnUpdate", function(self, elapsed)
    local anim = Styling.AnimationsEnabled()
    local i = 1
    while i <= #breathJobs do
        local job = breathJobs[i]
        if not job.tex or not job.tex:GetTexture() then
            tremove(breathJobs, i)
        else
            if not anim then
                if not job.frozen then
                    job.tex:SetAlpha((job.minAlpha + job.maxAlpha) / 2)
                    job.frozen = true
                end
            elseif JobIsVisible(job) then
                job.frozen = nil
                job.elapsed = job.elapsed + elapsed
                local t = (job.elapsed % job.speed) / job.speed
                local a = job.minAlpha + (job.maxAlpha - job.minAlpha) * (0.5 + 0.5 * math.sin(t * 6.28318))
                job.tex:SetAlpha(a)
            end
            i = i + 1
        end
    end
    if #breathJobs == 0 then self:Hide() end
end)

function Styling.AddBreathingGlow(texture, minAlpha, maxAlpha, speed)
    minAlpha = minAlpha or 0.5
    maxAlpha = maxAlpha or 0.8
    speed = speed or 0.8

    tinsert(breathJobs, {
        tex = texture,
        parent = texture.GetParent and texture:GetParent() or nil,
        minAlpha = minAlpha,
        maxAlpha = maxAlpha,
        speed = speed,
        elapsed = math.random() * 100,
    })
    breathDriver:Show()
end

function Styling.GetILvlColor(itemLevel)
    if not itemLevel or itemLevel <= 0 then return 0.5, 0.5, 0.5 end
    if itemLevel >= 260 then
        return Styling.ACCENT_GLOW[1], Styling.ACCENT_GLOW[2], Styling.ACCENT_GLOW[3]
    elseif itemLevel >= 240 then
        return 0.2, 0.9, 0.2
    elseif itemLevel >= 200 then
        return 1.0, 0.82, 0.0
    elseif itemLevel >= 170 then
        return 1.0, 0.6, 0.0
    else
        return 0.8, 0.2, 0.2
    end
end

local sepDriver = CreateFrame("Frame")
local sepJobs = {}

sepDriver:SetScript("OnUpdate", function(self, elapsed)
    local anim = Styling.AnimationsEnabled()
    local i = 1
    while i <= #sepJobs do
        local job = sepJobs[i]
        if not job.dot or not job.dot:GetTexture() then
            tremove(sepJobs, i)
        else
            if not anim then
                if not job.frozen then
                    job.dot:Hide()
                    job.frozen = true
                end
            elseif JobIsVisible(job) then
                if job.frozen then
                    job.dot:Show()
                    job.frozen = nil
                end
                job.elapsed = job.elapsed + elapsed
                local p = (job.elapsed % (job.cycleTime * 2)) / job.cycleTime
                local t = p <= 1 and p or (2 - p)
                local parentWidth = job.parent:GetWidth() or 260
                local travel = parentWidth - 20 - job.dotWidth
                if travel < 0 then travel = 0 end
                local x = 10 + travel * t
                job.dot:ClearAllPoints()
                job.dot:SetPoint("TOPLEFT", job.parent, "TOPLEFT", x, job.y)
            end
            i = i + 1
        end
    end
    if #sepJobs == 0 then self:Hide() end
end)

function Styling.CreateAnimatedSeparator(parent, y, height)
    height = height or 1
    local S = Styling

    local base = parent:CreateTexture(nil, "ARTWORK")
    base:SetHeight(height)
    base:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    base:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, y)
    base:SetTexture("Interface\\Buttons\\WHITE8x8")
    base:SetGradientAlpha("HORIZONTAL",
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.55,
        S.ACCENT[1], S.ACCENT[2], S.ACCENT[3], 0.06)

    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetSize(40, height + 1)
    dot:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, y)
    dot:SetTexture("Interface\\Buttons\\WHITE8x8")
    dot:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.45)

    tinsert(sepJobs, {
        dot = dot,
        dotWidth = 40,
        parent = parent,
        y = y,
        elapsed = 0,
        cycleTime = 4.0,
    })
    sepDriver:Show()

    return { base = base, dot = dot }
end

local flashDriver = CreateFrame("Frame")
local flashJobs = {}

flashDriver:SetScript("OnUpdate", function(self, elapsed)
    local now = GetTime()
    local i = 1
    while i <= #flashJobs do
        local job = flashJobs[i]
        if not job.fs or not job.fs:GetFont() then
            tremove(flashJobs, i)
        else
            local t = (now - job.startTime) / job.duration
            if t >= 1 then
                job.fs:SetTextColor(job.endR, job.endG, job.endB)
                tremove(flashJobs, i)
            else
                local fade = t * t
                local r = job.startR * (1 - fade) + job.endR * fade
                local g = job.startG * (1 - fade) + job.endG * fade
                local b = job.startB * (1 - fade) + job.endB * fade
                job.fs:SetTextColor(r, g, b)
                i = i + 1
            end
        end
    end
    if #flashJobs == 0 then self:Hide() end
end)

function Styling.FlashValue(fontString, duration, endColor)
    if not fontString then return end
    duration = duration or 0.4
    local S = Styling
    local finish = endColor or S.TEXT_BRIGHT

    if not Styling.AnimationsEnabled() then
        fontString:SetTextColor(finish[1], finish[2], finish[3])
        return
    end

    for i = #flashJobs, 1, -1 do
        if flashJobs[i].fs == fontString then tremove(flashJobs, i) end
    end

    local r, g, b = fontString:GetTextColor()
    fontString:SetTextColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3])

    tinsert(flashJobs, {
        fs = fontString,
        startTime = GetTime(),
        duration = duration,
        startR = S.ACCENT_GLOW[1], startG = S.ACCENT_GLOW[2], startB = S.ACCENT_GLOW[3],
        endR = finish[1], endG = finish[2], endB = finish[3],
    })
    flashDriver:Show()
end

function Styling.CreateEnchantDot(parent, side)
    local dot = parent:CreateTexture(nil, "OVERLAY", nil, 3)
    dot:SetSize(6, 6)
    dot:SetTexture("Interface\\Buttons\\WHITE8x8")

    if side == "LEFT" then
        dot:SetPoint("BOTTOMRIGHT", parent, "BOTTOMLEFT", -4, 4)
    elseif side == "RIGHT" then
        dot:SetPoint("BOTTOMLEFT", parent, "BOTTOMRIGHT", 4, 4)
    else
        dot:SetPoint("TOP", parent, "BOTTOM", 14, -3)
    end

    dot:SetVertexColor(0.4, 0.4, 0.4, 0.5)
    return dot
end

function Styling.SetEnchantDotStatus(dot, status)
    if not dot then return end
    local S = Styling
    if status == "enchanted" then
        dot:SetVertexColor(S.ACCENT_GLOW[1], S.ACCENT_GLOW[2], S.ACCENT_GLOW[3], 0.8)
    elseif status == "missing" then
        dot:SetVertexColor(0.9, 0.2, 0.2, 0.8)
    else
        dot:SetVertexColor(0.4, 0.4, 0.4, 0.3)
    end
end

function Styling.CreateSectionRule(parent, anchorTo, width)
    local A = Styling.ACCENT
    local t = parent:CreateTexture(nil, "ARTWORK")
    t:SetHeight(1)
    t:SetTexture("Interface\\Buttons\\WHITE8x8")
    t:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", 0, -3)
    t:SetWidth(width or 260)
    t:SetGradientAlpha("Horizontal", A[1], A[2], A[3], 0.45, A[1], A[2], A[3], 0)
    return t
end
