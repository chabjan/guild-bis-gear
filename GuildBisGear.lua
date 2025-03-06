-- Register our addon message prefix
local ADDON_PREFIX = "ITEMPICK"
local success = C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)
if not success then
    print("Failed to register addon message prefix!")
end

-- List of items available for selection
local items = { "Sword", "Shield", "Potion", "Armor" }

-------------------------------------------------
-- Create the main addon frame with tabs
-------------------------------------------------
local mainFrame = CreateFrame("Frame", "ItemPickerFrame", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(600, 400)
mainFrame:SetPoint("CENTER")
mainFrame:SetMovable(true)
mainFrame:EnableMouse(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", mainFrame.StartMoving)
mainFrame:SetScript("OnDragStop", mainFrame.StopMovingOrSizing)

-- Title for the frame
mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY")
mainFrame.title:SetFontObject("GameFontHighlight")
mainFrame.title:SetPoint("CENTER", mainFrame.TitleBg, "CENTER", 0, 0)
mainFrame.title:SetText("Item Picker")

-- Tab 1: Picker
local tab1 = CreateFrame("Button", mainFrame:GetName().."Tab1", mainFrame, "CharacterFrameTabButtonTemplate")
tab1:SetID(1)
tab1:SetText("Picker")
-- Anchor the first tab relative to the top left of the main frame (adjust offsets as needed)
tab1:SetPoint("BOTTOMLEFT", mainFrame, "BOTTOMLEFT", 10, -25)

-- Tab 2: Party Selections
local tab2 = CreateFrame("Button", mainFrame:GetName().."Tab2", mainFrame, "CharacterFrameTabButtonTemplate")
tab2:SetID(2)
tab2:SetText("The Picks")
-- Anchor the second tab to the right of the first tab
tab2:SetPoint("LEFT", tab1, "RIGHT", -15, 0)

-- Initialize the tabs on the main frame
PanelTemplates_SetNumTabs(mainFrame, 2)
PanelTemplates_SetTab(mainFrame, 1)

-- Create two child frames for each tab's content
mainFrame.picker = CreateFrame("Frame", nil, mainFrame)
mainFrame.picker:SetAllPoints(mainFrame)

mainFrame.party = CreateFrame("Frame", nil, mainFrame)
mainFrame.party:SetAllPoints(mainFrame)
mainFrame.party:Hide()

-- Tab switching scripts
tab1:SetScript("OnClick", function()
    PanelTemplates_SetTab(mainFrame, 1)
    mainFrame.picker:Show()
    mainFrame.party:Hide()
end)

tab2:SetScript("OnClick", function()
    PanelTemplates_SetTab(mainFrame, 2)
    mainFrame.picker:Hide()
    mainFrame.party:Show()
end)

-------------------------------------------------
-- Picker Tab: List of Items (Custom Components)
-------------------------------------------------

items = { "Sword", "Shield", "Potion", "Armor" }

-- (Make sure you have the SendItemSelection function defined as below)
local function SendItemSelection(item)
    -- For example, sending via PARTY for debugging; change as needed
    C_ChatInfo.SendAddonMessage(ADDON_PREFIX, item, "PARTY")
end

-- Create a scroll frame to hold the item list
local scrollFrame = CreateFrame("ScrollFrame", "ItemListScrollFrame", mainFrame.picker, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", mainFrame.picker, "TOPLEFT", 10, -10)
scrollFrame:SetPoint("BOTTOMRIGHT", mainFrame.picker, "BOTTOMRIGHT", -30, 10)

-- Create a content frame that will be scrolled
local content = CreateFrame("Frame", "ItemListContent", scrollFrame)
-- Set a width and height for the content frame (adjust height as needed to accommodate all items)
content:SetSize(500, 400)
scrollFrame:SetScrollChild(content)

-- Table to hold our custom entry buttons
content.entries = {}

-- Function to create a custom list entry for an item
local function CreateItemEntry(parent, itemText, index)
    local entry = CreateFrame("Button", nil, parent)
    entry:SetSize(200, 30)  -- Adjust width/height as needed

    -- Position entries vertically with some spacing
    if index == 1 then
        entry:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    else
        entry:SetPoint("TOPLEFT", parent.entries[index - 1], "BOTTOMLEFT", 0, -5)
    end

    -- Create a background texture for visual feedback
    entry.bg = entry:CreateTexture(nil, "BACKGROUND")
    entry.bg:SetAllPoints(entry)
    entry.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Create a text label for the item
    entry.text = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    entry.text:SetPoint("CENTER", entry, "CENTER")
    entry.text:SetText(itemText)

    -- Set a click handler that sends the selection and highlights the entry
    entry:SetScript("OnClick", function()
        -- Reset highlight for all entries
        for i, btn in ipairs(parent.entries) do
            btn.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
        end
        -- Highlight this entry to indicate it's selected
        entry.bg:SetColorTexture(0.5, 0.5, 0.5, 0.8)
        -- Send the item selection
        SendItemSelection(itemText)
        print("Selected: " .. itemText)
    end)

    return entry
end

-- Populate the list with our items
for i, item in ipairs(items) do
    local entry = CreateItemEntry(content, item, i)
    table.insert(content.entries, entry)
end

-------------------------------------------------
-- Party Selections Tab: Scrolling Message Frame
-------------------------------------------------
local msgFrame = CreateFrame("ScrollingMessageFrame", nil, mainFrame.party)
msgFrame:SetPoint("TOPLEFT", 10, -30)
msgFrame:SetPoint("BOTTOMRIGHT", -10, 10)
msgFrame:SetFontObject("ChatFontNormal")
msgFrame:SetJustifyH("LEFT")
msgFrame:SetFading(false)
msgFrame:SetMaxLines(100)
msgFrame:SetScript("OnMouseWheel", function(self, delta)
    if delta > 0 then
        self:ScrollUp()
    else
        self:ScrollDown()
    end
end)
mainFrame.party.msgFrame = msgFrame

-------------------------------------------------
-- Event Handling: Receiving addon messages
-------------------------------------------------
mainFrame:RegisterEvent("CHAT_MSG_ADDON")
mainFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "CHAT_MSG_ADDON" then
        local prefix, message, channel, sender = ...
        if prefix == ADDON_PREFIX then
            local text = sender .. " picked: " .. message
            if mainFrame.party.msgFrame then
                mainFrame.party.msgFrame:AddMessage(text)
            end
        end
    end
end)
