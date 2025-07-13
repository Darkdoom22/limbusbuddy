_addon.name = "LimbusBuddy"
_addon.author = "Uwu/Darkdoom"
_addon.command = "limbusbuddy"
_addon.version = "0.0.1"

local texts = require('texts')
local packets = require('packets')
local dialog = require('dialog')
local bit = require('bit')
local ItemRes = require('resources').items
require('sets')

local DefaultSettings = {
    ["flags"] = {
        ["draggable"] = true
    },
    ["pos"] = {
        ["x"] = 40,
        ["y"] = 600
    },
    ["text"] = {
        ["font"] = 'Consolas',
        ["size"] = 11,
        ["alpha"] = 255,
        ["red"] = 249,
        ["green"] = 236,
        ["blue"] = 236,
        ["stroke"] = {
            ["alpha"] = 175,
            ["red"]   = 11,
            ["green"] = 16,
            ["blue"]  = 15,
            ["width"] = 2.0
        },
        ["flags"] = {
            ["bold"] = true
        }
    },
    ["bg"] = {
        ["alpha"] = 160,
        ["red"]   = 55,
        ["green"] = 50,
        ["blue"]  = 50
    }
}

local DefaultSettings2 = {
    ["flags"] = {
        ["draggable"] = true
    },
    ["pos"] = {
        ["x"] = 40,
        ["y"] = 745
    },
    ["text"] = {
        ["font"] = 'Consolas',
        ["size"] = 11,
        ["alpha"] = 255,
        ["red"] = 249,
        ["green"] = 236,
        ["blue"] = 236,
        ["stroke"] = {
            ["alpha"] = 175,
            ["red"]   = 11,
            ["green"] = 16,
            ["blue"]  = 15,
            ["width"] = 2.0
        },
        ["flags"] = {
            ["bold"] = true
        }
    },
    ["bg"] = {
        ["alpha"] = 160,
        ["red"]   = 55,
        ["green"] = 50,
        ["blue"]  = 50
    }
}

local LimbusBuddy = {
    ["TextDisplay"] = texts.new(DefaultSettings),
    ["TempsDisplay"] = texts.new(DefaultSettings2),
    ["PointsThisHour"] = 0,
    ["CurrentPoints"] = 0,
    ["RemainingWeeklyCap"] = 0,
    ["ZoneCap"] = 0,
    ["StartTime"] = os.clock(),
    ["TemenosMessageId"] = 0,
    ["ApollyonMessageId"] = 0,
}

local Constants = {
    ["TextFormatString"] = [[${Zone} - \cs(79, 209, 173)${ILvl}\cs(255, 255, 255)
${Wing} - \cs(79, 209, 173)${Floor}\cs(255, 255, 255)
Data Progress: \cs(79, 209, 173)${DataProgress}/100\cs(255, 255, 255)
Points This Hour: \cs(79, 209, 173)${PointsThisHour} - ${PointsPerHour}/hr\cs(255, 255, 255)
Current Points: \cs(79, 209, 173)${CurrentPoints}\cs(255, 255, 255)
Zone Cap: \cs(79, 209, 173)${ZoneCap}\cs(255, 255, 255)
Remaining Weekly Cap: \cs(79, 209, 173)${RemainingWeeklyCap}\cs(255, 255, 255)]],
    ["TemenosZoneId"] = 37,
    ["ApollyonZoneId"] = 38,
    ["TemenosTemps"] = {
        ["North"] = {
            9956,
            9957,
            9958,
            9959,
            9960,
            9961,
            9962
        },
        ["West"] = {
            9963,
            9964,
            9965,
            9966,
            9967,
            9968,
            9969
        },
        ["East"] = {
            9970,
            9971,
            9972,
            9973,
            9974,
            9975,
            9976
        },
        ["Center"] = {
            9977,
            9978,
            9979,
            9980
        }
    },
    ["ApollyonTemps"] = {
        ["NW"] = {
            9981,
            9982,
            9983,
            9984,
            9985
        },
        ["SW"] = {
            9986,
            9986,
            9988,
            9989
        },
        ["NE"] = {
            9990,
            9991,
            9992,
            9993,
            9994
        },
        ["SE"] = {
            9995,
            9996,
            9997,
            9998
        }
    },
    ["TemenosMessageHex"] = "C1E3F1F5E9F2E5E4A0D4E5EDE5EEEFF3A0D5EEE9F4F3BAA08A80AE87D2E5EDE1E9EEE9EEE7A0D4E5EDE5EEEFF3A0D5EEE9F4F3BAA08A81AE87D4EFF4E1ECA0D4E5EDE5EEEFF3A0D5EEE9F4F3BAA08A82AF8A83AEFFB18087",
    ["ApollyonMessageHex"] = "C1E3F1F5E9F2E5E4A0C1F0EFECECF9EFEEA0D5EEE9F4F3BAA08A80AE87D2E5EDE1E9EEE9EEE7A0C1F0EFECECF9EFEEA0D5EEE9F4F3BAA08A81AE87D4EFF4E1ECA0C1F0EFECECF9EFEEA0D5EEE9F4F3BAA08A82AF8A83AEFFB18087"
}

function LimbusBuddy:AcquireMessageIds()
    local temenosDialogDat = dialog.open_dat_by_zone_id(Constants.TemenosZoneId, 'english')
    local apollyonDialogDat = dialog.open_dat_by_zone_id(Constants.ApollyonZoneId, 'english')

    local temenosMessageId = table.it(dialog.get_ids_matching_entry(temenosDialogDat, Constants.TemenosMessageHex:parse_hex()))()
    local apollyonMessageId = table.it(dialog.get_ids_matching_entry(apollyonDialogDat, Constants.ApollyonMessageHex:parse_hex()))()

    self["TemenosMessageId"] = temenosMessageId
    self["ApollyonMessageId"] = apollyonMessageId

    temenosDialogDat:close()
    apollyonDialogDat:close()
end

function LimbusBuddy:HandleBarUpdate(data)
    local zoneId = windower.ffxi.get_info().zone

    if(S{Constants.TemenosZoneId, Constants.ApollyonZoneId}:contains(zoneId) == false)then
        return
    end

    local packet = packets.parse('incoming', data)

    local zoneStr = packet["Bar String 1"]

    if(not zoneStr)then return end

    local splitZoneStr = zoneStr:split('_')

    self["TextDisplay"]["Zone"] = splitZoneStr[1] or "Unknown"
    self["TextDisplay"]["ILvl"] = splitZoneStr[2] or "Unknown"

    local wingStr = packet["Bar String 2"]
    local splitWingStr = wingStr:split('_')
    local wing = splitWingStr[1] and splitWingStr[2] and splitWingStr[1] .. " " .. splitWingStr[2] or "Unknown"

    self["TextDisplay"]["Wing"] = wing
    self["TextDisplay"]["Floor"] = splitWingStr[3] or "Unknown"

    local dataProgress = packet["Bar Progress 2"] and packet["Bar Progress 2"] ~= 255 and packet["Bar Progress 2"] or 0
    self["TextDisplay"]["DataProgress"] = dataProgress
end

function LimbusBuddy:HandleRestingMessageUpdate(data)
    local zoneId = windower.ffxi.get_info().zone

    if(S{Constants.TemenosZoneId, Constants.ApollyonZoneId}:contains(zoneId) == false)then
        return
    end

    local packet = packets.parse('incoming', data)

    if(S{self["TemenosMessageId"], self["ApollyonMessageId"]}:contains(bit.band(packet["Message ID"], 0x3FFF)))then
        local pointsGained = packet["Param 1"] or 0
        self["PointsThisHour"] = self["PointsThisHour"] + pointsGained

        local remainingZonePoints = packet["Param 2"] or 0
        self["RemainingWeeklyCap"] = remainingZonePoints

        local currentZonePoints = packet["Param 3"] or 0
        self["CurrentPoints"] = currentZonePoints

        local zoneCap = packet["Param 4"] or 0
        self["ZoneCap"] = zoneCap

        self["TextDisplay"]["PointsThisHour"] = self["PointsThisHour"]
        self["TextDisplay"]["CurrentPoints"] = self["CurrentPoints"]
        self["TextDisplay"]["RemainingWeeklyCap"] = self["RemainingWeeklyCap"]
        self["TextDisplay"]["ZoneCap"] = self["ZoneCap"]
    end
end

local function HasTempItem(inventory, itemId)
    for _, item in ipairs(inventory) do
        if(item.id == itemId)then
            return true
        end
    end
    return false
end

windower.register_event('load', function()
    LimbusBuddy:AcquireMessageIds()

    LimbusBuddy["TextDisplay"]:show()
    LimbusBuddy["TextDisplay"]:text(Constants.TextFormatString)

    LimbusBuddy["TextDisplay"]["Zone"] = "Waiting.."
    LimbusBuddy["TextDisplay"]["ILvl"] = "Waiting.."
    LimbusBuddy["TextDisplay"]["Wing"] = "Waiting.."
    LimbusBuddy["TextDisplay"]["Floor"] = "Waiting.."

    LimbusBuddy["TextDisplay"]["PointsThisHour"] = "Waiting.."
    LimbusBuddy["TextDisplay"]["CurrentPoints"] = "Waiting.."
    LimbusBuddy["TextDisplay"]["RemainingWeeklyCap"] = "Waiting.."
    LimbusBuddy["TextDisplay"]["ZoneCap"] = "Waiting.."

    LimbusBuddy["TextDisplay"]["DataProgress"] = 0

    LimbusBuddy["TempsDisplay"]:show()
    LimbusBuddy["TempsDisplay"]:text("Temps: Waiting..")
end)

windower.register_event('incoming chunk', function(id, data)
    if(id == 0x075)then
        LimbusBuddy:HandleBarUpdate(data)
    end

    if(id == 0x02A)then
        LimbusBuddy:HandleRestingMessageUpdate(data)
    end
end)

windower.register_event('prerender', function()
    local timeDiff = os.clock() - LimbusBuddy["StartTime"]
    if(timeDiff >= 3600)then
        LimbusBuddy["StartTime"] = os.clock()
        LimbusBuddy["PointsThisHour"] = 0
    end

    local pointsPerHour = (LimbusBuddy["PointsThisHour"] / timeDiff) * 3600
    LimbusBuddy["TextDisplay"]["PointsPerHour"] = string.format("%.2f", pointsPerHour)

    local zoneId = windower.ffxi.get_info().zone
    if(zoneId == Constants.TemenosZoneId)then
        local playerTempInventory = windower.ffxi.get_items().temporary
        local str = "Temenos Temps\n"

        local wingsPopulated = 0

        for k,v in pairs(Constants.TemenosTemps) do
            str = string.format("%s%s: ", str, k)
            for _, temp in ipairs(v) do
                if(ItemRes[temp])then
                    if(HasTempItem(playerTempInventory, temp))then
                        str = str .. "\\cs(0, 255, 0)" .. ItemRes[temp].name:match("%S+%s+%S%S(.+)") .. ", "
                    else
                        str = str .. "\\cs(255, 0, 0)" .. ItemRes[temp].name:match("%S+%s+%S%S(.+)") .. ", "
                    end
                end
            end

            str = str:sub(1, -3)
            wingsPopulated = wingsPopulated + 1
            if(wingsPopulated ~= 4) then
                str = string.format("%s\n\\cs(255, 255, 255)", str)
            end
        end

        LimbusBuddy["TempsDisplay"]:text(str)
    elseif(zoneId == Constants.ApollyonZoneId)then
        local playerTempInventory = windower.ffxi.get_items().temporary
        local str = "Apollyon Temps\n"

        local wingsPopulated = 0

        for k,v in pairs(Constants.ApollyonTemps) do
            str = string.format("%s%s: ", str, k)
            for _, temp in ipairs(v) do
                if(ItemRes[temp])then
                    if(HasTempItem(playerTempInventory, temp))then
                        str = str .. "\\cs(0, 255, 0)" .. ItemRes[temp].name:match("%S+%s+%S+%s+(.+)") .. ", "
                    else
                        str = str .. "\\cs(255, 0, 0)" .. ItemRes[temp].name:match("%S+%s+%S+%s+(.+)") .. ", "
                    end
                end
            end

            str = str:sub(1, -3)
            wingsPopulated = wingsPopulated + 1
            if(wingsPopulated ~= 4) then
                str = string.format("%s\n\\cs(255, 255, 255)", str)
            end
        end

        LimbusBuddy["TempsDisplay"]:text(str)
    else
        LimbusBuddy["TempsDisplay"]:text("Temps: Not In Correct Zone!")
    end
end)