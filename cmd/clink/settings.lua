-- ============================================================================
-- Clink 体验与美化设置 (settings.lua)
-- 开启自动补全、输入着色、历史搜索与路径匹配优化
-- ============================================================================

-- 输入着色与补全建议
settings.set("autosuggest.enable", true)
settings.set("autosuggest.async", true)
settings.set("autosuggest.strategy", "match_prev_cmd history completion")
settings.set("clink.colorize_input", true)

-- 补全匹配模式
settings.set("match.substring", true)
settings.set("match.ignore_case", "relaxed")
settings.set("match.sort_dirs", "with")

-- 终端与符号支持
settings.set("terminal.color_emoji", "auto")
settings.set("terminal.east_asian_ambiguous", "auto")
settings.set("terminal.adjust_cursor_style", true)

-- 历史记录管理
settings.set("history.dupe_mode", "erase_prev")
settings.set("history.ignore_space", true)
settings.set("history.max_lines", 25000)
settings.set("history.save", true)
