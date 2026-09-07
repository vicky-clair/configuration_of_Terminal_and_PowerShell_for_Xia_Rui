-- ============================================================================
-- Clink 扩展脚本：Starship 跨平台提示符集成
-- 当 Clink 注入 cmd.exe 时，自动拉取 Starship 生成现代提示符
-- ============================================================================

local function init_starship()
    local p = io.popen('starship init cmd 2>nul')
    if p then
        local output = p:read("*a")
        p:close()
        if output and #output > 0 then
            load(output)()
        end
    end
end

init_starship()
