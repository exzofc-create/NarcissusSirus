local addonName, NS = ...
local L = NS.L

local ScreenshotTool = {}

local format = string.format

function ScreenshotTool:Take(hideUI)
    if hideUI then
        local wasVisible = UIParent:IsShown()
        if wasVisible then
            UIParent:Hide()
        end

        NS.After(0.1, function()
            Screenshot()

            NS.After(0.5, function()
                if wasVisible then
                    UIParent:Show()
                end
                NS.Print(L["Скриншот сделан!"])
            end)
        end)
    else
        Screenshot()
        NS.Print(L["Скриншот сделан!"])
    end
end

function ScreenshotTool:TakeWithCountdown(seconds, hideUI)
    seconds = seconds or 3
    NS.Print(format(L["Скриншот через %d сек..."], seconds))

    local function countdown(remaining)
        if remaining <= 0 then
            self:Take(hideUI)
        else
            NS.Print(format("%d...", remaining))
            NS.After(1, function() countdown(remaining - 1) end)
        end
    end

    countdown(seconds)
end

NS.ScreenshotTool = ScreenshotTool
