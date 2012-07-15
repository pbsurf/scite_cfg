-- Select next or previous occurrence of currently selected word
-- ref: http://scintilla.org/PaneAPI.html

function select_next()
  if editor.Selections > 0 then
    -- selections are not ordered, so we must do this to find the last
    local last = editor.SelectionNEnd[0];
    for ii = 0,(editor.Selections-1) do
      last = math.max(last, editor.SelectionNEnd[ii]);
    end
    local txt = editor:textrange(editor.SelectionNStart[0], editor.SelectionNEnd[0]);
    local s,e = editor:findtext(txt, 0, last);
    if s then
      editor:AddSelection(s,e);
      -- scroll to the new selection
      editor:ScrollCaret();
    end
  end
end

function select_prev()
  if editor.Selections > 0 then
    -- selections are not ordered, so we must do this to find the first
    local start = editor.SelectionNStart[0];
    for ii = 0,(editor.Selections-1) do
      start = math.min(start, editor.SelectionNStart[ii]);
    end
    local txt = editor:textrange(editor.SelectionNStart[0], editor.SelectionNEnd[0]);
    -- end = -1 (< start) to search backwards
    local s,e = editor:findtext(txt, 0, start, -1);
    if s then
      editor:AddSelection(s,e);
      -- scroll to the new selection
      editor:ScrollCaret();
    end
  end
end

function this_is_a_test()
end

scite_Command("Select Next Occurrence|select_next|Ctrl+F3");
scite_Command("Select Previous Occurrence|select_prev|Ctrl+Shift+F3");
