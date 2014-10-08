-- misc functions for dealing with whitespace, esp. spaces vs. tabs
-- <pane>:match() is documented at http://www.scintilla.org/SciTELua.html

function tabs_to_spaces()
  -- replace one tab tab followed by one or more (space or tab)
  -- but obey tabstops (preserves alignment)
  for m in editor:match("[\\t][\\t ]*", SCFIND_REGEXP) do
    local posColumn = ( scite.SendEditor(SCI_GETCOLUMN, (m.pos ) ) )
    local poslenColumn = ( scite.SendEditor(SCI_GETCOLUMN, (m.pos + m.len) ) )
    m:replace(string.rep(' ', poslenColumn - posColumn ))
  end
end

function spaces_to_tabs()
  -- replace leading spaces with tabs
  for m in editor:match("^[ ]+", SCFIND_REGEXP) do
    local ntabs = m.len/props["tabsize"];
    if ntabs >= 1 then
      m:replace(string.rep('\t', ntabs));
    end
  end
end

function toggle_tabs()
  editor.UseTabs = not editor.UseTabs;
end

scite_Command('All tabs to spaces|tabs_to_spaces');
scite_Command('Leading spaces to tabs|spaces_to_tabs');
scite_Command('Toggle use.tabs|toggle_tabs');
