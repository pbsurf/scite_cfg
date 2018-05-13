-- Use xsel to read primary selection and paste it into editor
-- use Shift+Ins shortcut to match terminal behavior
-- see fzfopen.lua for discussion of popen methods

function paste_primary()
  -- `timeout` necessary to prevent freeze if scite owns primary selection; `xsel -t 100` didn't work
  local f = io.popen("timeout 1 xsel -o")
  local s = f:read("*a");
  f:close();
  if s ~= "" then
    editor:ReplaceSel(s);
  end
end

if scite_GetProp('PLAT_GTK') then
  scite_Command("Paste Primary Selection|paste_primary|Shift+Insert");
end
