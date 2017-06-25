-- Use Shift+Ins to paste primary selection via xsel, matching terminal behavior
-- note that you can alternatively copy to normal clipboard from terminal with Ctrl+Alt+C

function paste_primary()
  local f = spawner.popen("xsel")
  local s = f:read("*a");
  f:close();
  if s ~= "" then
    editor:ReplaceSel(s);
  end
end

if scite_GetProp('PLAT_GTK') then
  scite_Command("Paste Primary Selection|paste_primary|Shift+Insert");
end
