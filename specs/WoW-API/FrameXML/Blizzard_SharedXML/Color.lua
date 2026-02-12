---@meta _

---@class ColorRGBData
---@field r number
---@field g number
---@field b number
---@field colorStr? string

---@class ColorRGBAData : ColorRGBData
---@field a number

---@class colorRGB : ColorRGBData, ColorMixin
---@class colorRGBA : ColorRGBAData, colorRGB

