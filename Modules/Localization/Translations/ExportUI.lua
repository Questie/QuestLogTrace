---@class QuestieTraceCore
local Core = QuestieTraceCore

---@type l10n
local l10n = Core.l10n

local exportUILocales = {
  ["QuestieTrace Export"] = {
    ["enUS"] = true,
    ["deDE"] = "QuestieTrace Export",
    ["esES"] = "Exportar QuestieTrace",
    ["esMX"] = "Exportar QuestieTrace",
    ["frFR"] = "Export QuestieTrace",
    ["koKR"] = "QuestieTrace 내보내기",
    ["ptBR"] = "Exportar QuestieTrace",
    ["ruRU"] = "Экспорт QuestieTrace",
    ["zhCN"] = "QuestieTrace 导出",
    ["zhTW"] = "QuestieTrace 匯出",
  },
  ["Select all (Ctrl+A), copy (Ctrl+C), and share this text with us."] = {
    ["enUS"] = true,
    ["deDE"] = "Alles auswählen (Strg+A), kopieren (Strg+C) und diesen Text mit uns teilen.",
    ["esES"] = "Selecciona todo (Ctrl+A), copia (Ctrl+C) y comparte este texto con nosotros.",
    ["esMX"] = "Selecciona todo (Ctrl+A), copia (Ctrl+C) y comparte este texto con nosotros.",
    ["frFR"] = "Sélectionnez tout (Ctrl+A), copiez (Ctrl+C) et partagez ce texte avec nous.",
    ["koKR"] = "모두 선택(Ctrl+A) 후 복사(Ctrl+C)하여 이 텍스트를 저희와 공유해 주세요.",
    ["ptBR"] = "Selecione tudo (Ctrl+A), copie (Ctrl+C) e compartilhe este texto conosco.",
    ["ruRU"] = "Выделите всё (Ctrl+A), скопируйте (Ctrl+C) и поделитесь этим текстом с нами.",
    ["zhCN"] = "全选 (Ctrl+A)，复制 (Ctrl+C)，并将此文本分享给我们。",
    ["zhTW"] = "全選 (Ctrl+A)，複製 (Ctrl+C)，並將此文字分享給我們。",
  },
  ["Close"] = {
    ["enUS"] = true,
    ["deDE"] = "Schließen",
    ["esES"] = "Cerrar",
    ["esMX"] = "Cerrar",
    ["frFR"] = "Fermer",
    ["koKR"] = "닫기",
    ["ptBR"] = "Fechar",
    ["ruRU"] = "Закрыть",
    ["zhCN"] = "关闭",
    ["zhTW"] = "關閉",
  },
  ["ERROR: Client does not have required codec support (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)"] = {
    ["enUS"] = true,
    ["deDE"] = "FEHLER: Der Client verfügt nicht über die erforderliche Codec-Unterstützung (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
    ["esES"] = "ERROR: El cliente no tiene el soporte de códec necesario (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
    ["esMX"] = "ERROR: El cliente no tiene el soporte de códec necesario (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
    ["frFR"] = "ERREUR : Le client ne dispose pas du support de codec requis (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
    ["koKR"] = "오류: 클라이언트에 필요한 코덱 지원이 없습니다 (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
    ["ptBR"] = "ERRO: O cliente não possui o suporte de codec necessário (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
    ["ruRU"] = "ОШИБКА: клиент не поддерживает необходимые кодеки (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
    ["zhCN"] = "错误：客户端缺少所需的编解码支持 (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
    ["zhTW"] = "錯誤：用戶端缺少所需的編解碼支援 (C_EncodingUtil, Enum.CompressionMethod, LibDeflate)",
  },
}

for k, v in pairs(exportUILocales) do
  l10n.translations[k] = v
end
