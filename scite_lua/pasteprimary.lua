-- Select next or previous occurrence of currently selected word
-- ref: http://scintilla.org/PaneAPI.html

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
