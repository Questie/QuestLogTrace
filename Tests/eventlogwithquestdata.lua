QuestLogTest = {
  ["test"] = {
    ["events"] = {
      {
        ["message"] = "Event logging started",
        ["systemTimestamp"] = 540724.436,
        ["relativeTimestamp"] = 0,
        ["frameCounter"] = 0,
        ["id"] = 1,
        ["lineWithoutArguments"] = "|cff808080[001]|r |cffff8040--- Event logging started ---|r",
      }, -- [1]
      {
        ["relativeTimestamp"] = 4.15300000004936,
        ["id"] = 2,
        ["event"] = "PLAYER_CAMPING",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540728.589,
        ["formattedTimestamp"] = "00:04.153s (4.153s, 563)",
        ["frameCounter"] = 563,
        ["lineWithoutArguments"] = "|cff808080[002]|r PLAYER_CAMPING",
        ["arguments"] = "",
        ["args"] = {
          ["n"] = 0,
        },
        ["eventDelta"] = "(4.153s, 563)",
      }, -- [2]
      {
        ["relativeTimestamp"] = 24.19500000006519,
        ["id"] = 3,
        ["event"] = "CHANNEL_LEFT",
        ["formattedArguments"] = "|cff19ff19|cffff80401|r, |cff19ff19\"General - Dun Morogh\"|r|r",
        ["systemTimestamp"] = 540748.631,
        ["formattedTimestamp"] = "00:24.195s (20.042s, 1114)",
        ["frameCounter"] = 1677,
        ["lineWithoutArguments"] = "|cff808080[003]|r CHANNEL_LEFT",
        ["arguments"] = "|cffff80401|r, |cff19ff19\"General - Dun Morogh\"|r",
        ["args"] = {
          1,                      -- [1]
          "General - Dun Morogh", -- [2]
          ["n"] = 2,
        },
        ["eventDelta"] = "(20.042s, 1114)",
      }, -- [3]
      {
        ["relativeTimestamp"] = 24.19500000006519,
        ["id"] = 4,
        ["event"] = "CHANNEL_UI_UPDATE",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.631,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[004]|r CHANNEL_UI_UPDATE",
        ["formattedTimestamp"] = "00:24.195s ",
        ["arguments"] = "",
        ["frameCounter"] = 1677,
      }, -- [4]
      {
        ["relativeTimestamp"] = 24.19500000006519,
        ["id"] = 5,
        ["event"] = "CHAT_MSG_CHANNEL_NOTICE",
        ["formattedArguments"] =
        "|cff19ff19|cff19ff19\"SUSPENDED\"|r, |cff19ff19\"\"|r, |cff19ff19\"\"|r, |cff19ff19\"1. General - Dun Morogh\"|r, |cff19ff19\"\"|r, |cff19ff19\"\"|r, |cffff80401|r, |cffff80401|r, |cff19ff19\"General - Dun Morogh\"|r, |cffff80400|r, |cffff804061|r, |cff808080nil|r, |cffff80400|r, |cff66bbfffalse|r, |cff66bbfffalse|r, |cff66bbfffalse|r, |cff66bbfffalse|r|r",
        ["systemTimestamp"] = 540748.631,
        ["args"] = {
          "SUSPENDED",               -- [1]
          "",                        -- [2]
          "",                        -- [3]
          "1. General - Dun Morogh", -- [4]
          "",                        -- [5]
          "",                        -- [6]
          1,                         -- [7]
          1,                         -- [8]
          "General - Dun Morogh",    -- [9]
          0,                         -- [10]
          61,                        -- [11]
          nil,                       -- [12]
          0,                         -- [13]
          false,                     -- [14]
          false,                     -- [15]
          false,                     -- [16]
          false,                     -- [17]
          ["n"] = 17,
        },
        ["lineWithoutArguments"] = "|cff808080[005]|r CHAT_MSG_CHANNEL_NOTICE",
        ["formattedTimestamp"] = "00:24.195s ",
        ["arguments"] =
        "|cff19ff19\"SUSPENDED\"|r, |cff19ff19\"\"|r, |cff19ff19\"\"|r, |cff19ff19\"1. General - Dun Morogh\"|r, |cff19ff19\"\"|r, |cff19ff19\"\"|r, |cffff80401|r, |cffff80401|r, |cff19ff19\"General - Dun Morogh\"|r, |cffff80400|r, |cffff804061|r, |cff808080nil|r, |cffff80400|r, |cff66bbfffalse|r, |cff66bbfffalse|r, |cff66bbfffalse|r, |cff66bbfffalse|r",
        ["frameCounter"] = 1677,
      }, -- [5]
      {
        ["relativeTimestamp"] = 24.19500000006519,
        ["id"] = 6,
        ["event"] = "CHANNEL_LEFT",
        ["formattedArguments"] = "|cff19ff19|cffff804022|r, |cff19ff19\"LocalDefense - Dun Morogh\"|r|r",
        ["systemTimestamp"] = 540748.631,
        ["args"] = {
          22,                          -- [1]
          "LocalDefense - Dun Morogh", -- [2]
          ["n"] = 2,
        },
        ["lineWithoutArguments"] = "|cff808080[006]|r CHANNEL_LEFT",
        ["formattedTimestamp"] = "00:24.195s ",
        ["arguments"] = "|cffff804022|r, |cff19ff19\"LocalDefense - Dun Morogh\"|r",
        ["frameCounter"] = 1677,
      }, -- [6]
      {
        ["relativeTimestamp"] = 24.19500000006519,
        ["id"] = 7,
        ["event"] = "CHANNEL_UI_UPDATE",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.631,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[007]|r CHANNEL_UI_UPDATE",
        ["formattedTimestamp"] = "00:24.195s ",
        ["arguments"] = "",
        ["frameCounter"] = 1677,
      }, -- [7]
      {
        ["relativeTimestamp"] = 24.19500000006519,
        ["id"] = 8,
        ["event"] = "CHAT_MSG_CHANNEL_NOTICE",
        ["formattedArguments"] =
        "|cff19ff19|cff19ff19\"SUSPENDED\"|r, |cff19ff19\"\"|r, |cff19ff19\"\"|r, |cff19ff19\"3. LocalDefense - Dun Morogh\"|r, |cff19ff19\"\"|r, |cff19ff19\"\"|r, |cffff804022|r, |cffff80403|r, |cff19ff19\"LocalDefense - Dun Morogh\"|r, |cffff80400|r, |cffff804062|r, |cff808080nil|r, |cffff80400|r, |cff66bbfffalse|r, |cff66bbfffalse|r, |cff66bbfffalse|r, |cff66bbfffalse|r|r",
        ["systemTimestamp"] = 540748.631,
        ["args"] = {
          "SUSPENDED",                    -- [1]
          "",                             -- [2]
          "",                             -- [3]
          "3. LocalDefense - Dun Morogh", -- [4]
          "",                             -- [5]
          "",                             -- [6]
          22,                             -- [7]
          3,                              -- [8]
          "LocalDefense - Dun Morogh",    -- [9]
          0,                              -- [10]
          62,                             -- [11]
          nil,                            -- [12]
          0,                              -- [13]
          false,                          -- [14]
          false,                          -- [15]
          false,                          -- [16]
          false,                          -- [17]
          ["n"] = 17,
        },
        ["lineWithoutArguments"] = "|cff808080[008]|r CHAT_MSG_CHANNEL_NOTICE",
        ["formattedTimestamp"] = "00:24.195s ",
        ["arguments"] =
        "|cff19ff19\"SUSPENDED\"|r, |cff19ff19\"\"|r, |cff19ff19\"\"|r, |cff19ff19\"3. LocalDefense - Dun Morogh\"|r, |cff19ff19\"\"|r, |cff19ff19\"\"|r, |cffff804022|r, |cffff80403|r, |cff19ff19\"LocalDefense - Dun Morogh\"|r, |cffff80400|r, |cffff804062|r, |cff808080nil|r, |cffff80400|r, |cff66bbfffalse|r, |cff66bbfffalse|r, |cff66bbfffalse|r, |cff66bbfffalse|r",
        ["frameCounter"] = 1677,
      }, -- [8]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 9,
        ["event"] = "TAXIMAP_CLOSED",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["formattedTimestamp"] = "00:24.406s (0.211s, 6)",
        ["frameCounter"] = 1683,
        ["lineWithoutArguments"] = "|cff808080[009]|r TAXIMAP_CLOSED",
        ["arguments"] = "",
        ["args"] = {
          ["n"] = 0,
        },
        ["eventDelta"] = "(0.211s, 6)",
      }, -- [9]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 10,
        ["event"] = "MERCHANT_CLOSED",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[010]|r MERCHANT_CLOSED",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [10]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 11,
        ["event"] = "SECURE_TRANSFER_CANCEL",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[011]|r SECURE_TRANSFER_CANCEL",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [11]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 12,
        ["event"] = "ARENA_REGISTRAR_CLOSED",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[012]|r ARENA_REGISTRAR_CLOSED",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [12]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 13,
        ["event"] = "SOCKET_INFO_CLOSE",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[013]|r SOCKET_INFO_CLOSE",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [13]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 14,
        ["event"] = "INSTANCE_LOCK_STOP",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[014]|r INSTANCE_LOCK_STOP",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [14]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 15,
        ["event"] = "PLAYER_LEAVING_WORLD",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[015]|r PLAYER_LEAVING_WORLD",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [15]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 16,
        ["event"] = "SECURE_TRANSFER_CANCEL",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[016]|r SECURE_TRANSFER_CANCEL",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [16]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 17,
        ["event"] = "TRADE_SKILL_CLOSE",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[017]|r TRADE_SKILL_CLOSE",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [17]
      {
        ["relativeTimestamp"] = 24.40600000007544,
        ["id"] = 18,
        ["event"] = "PLAYER_LOGOUT",
        ["formattedArguments"] = "|cff19ff19|r",
        ["systemTimestamp"] = 540748.8420000001,
        ["args"] = {
          ["n"] = 0,
        },
        ["lineWithoutArguments"] = "|cff808080[018]|r PLAYER_LOGOUT",
        ["formattedTimestamp"] = "00:24.406s ",
        ["arguments"] = "",
        ["frameCounter"] = 1683,
      }, -- [18]
    },
    ["questlog"] = {
      [3] = {
        ["id"] = 233,
        ["data"] = {
          "Coldridge Valley Mail Delivery", -- [1]
          3,                                -- [2]
          nil,                              -- [3]
          false,                            -- [4]
          false,                            -- [5]
          1,                                -- [6]
          1,                                -- [7]
          233,                              -- [8]
          false,                            -- [9]
          false,                            -- [10]
          false,                            -- [11]
          false,                            -- [12]
          false,                            -- [13]
          false,                            -- [14]
          false,                            -- [15]
          false,                            -- [16]
          false,                            -- [17]
        },
        ["GetQuestObjectives"] = {
        },
      },
      [2] = {
        ["id"] = 170,
        ["data"] = {
          "A New Threat", -- [1]
          2,              -- [2]
          nil,            -- [3]
          false,          -- [4]
          false,          -- [5]
          nil,            -- [6]
          1,              -- [7]
          170,            -- [8]
          false,          -- [9]
          false,          -- [10]
          false,          -- [11]
          false,          -- [12]
          false,          -- [13]
          false,          -- [14]
          false,          -- [15]
          false,          -- [16]
          false,          -- [17]
        },
        ["GetQuestObjectives"] = {
          {
            ["type"] = "monster",
            ["numRequired"] = 6,
            ["text"] = "Rockjaw Trogg slain: 0/6",
            ["finished"] = false,
            ["numFulfilled"] = 0,
          }, -- [1]
          {
            ["type"] = "monster",
            ["numRequired"] = 6,
            ["text"] = "Burly Rockjaw Trogg slain: 0/6",
            ["finished"] = false,
            ["numFulfilled"] = 0,
          }, -- [2]
        },
      },
      [5] = {
        ["id"] = 3108,
        ["data"] = {
          "Etched Rune", -- [1]
          1,             -- [2]
          nil,           -- [3]
          false,         -- [4]
          false,         -- [5]
          1,             -- [6]
          1,             -- [7]
          3108,          -- [8]
          false,         -- [9]
          false,         -- [10]
          false,         -- [11]
          false,         -- [12]
          false,         -- [13]
          false,         -- [14]
          false,         -- [15]
          false,         -- [16]
          false,         -- [17]
        },
        ["GetQuestObjectives"] = {
        },
      },
    },
  },
}
