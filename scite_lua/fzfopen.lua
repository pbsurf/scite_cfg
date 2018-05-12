-- fzfopen: fuzzy file search using fzf and SciTE's user list feature

-- Summary of user list approach:
-- Use Scite user list (basically an autocomplete list), populated by calling `fzf -f`; set editor.ReadOnly and use OnChar/OnKey to capture typing and prevent it from modifying document (initially tried using undo to prevent document modification, but that was too fragile).  Use OnUpdateUI hook to ensure 2nd item is selected (first item shows query string), as AutoCSelect only seemed to work when box is first opened.  Also makes it possible to prevent selection of first item entirely.  Only major remaining problem is that if user switches tab when user list is open, we don't get a chance to reset read-only , so we'd need a OnSwitch handler always running to check editor.ReadOnly when tab is switched.
-- Ultimately settled on opening terminal window to run fzf interactively.  This is more general (works for any interactive application), supports more features (e.g. multi-select), and will be faster for large directories since fzf only has to run once

function trim(s)
  local n = s:find("%S");
  return n and s:match(".*%S", n) or "";
end

-- get root for listing files
function getroot()
  --local f = spawner.popen("hg root 2> nul || git rev-parse --show-toplevel 2> nul || echo .")  -- windows
  local f = spawner.popen("hg root 2> /dev/null || git rev-parse --show-toplevel 2> /dev/null || echo $HOME")
  root = trim(f:read("*a"))
  f:close()
  return root
end

local query = ''
local root = getroot()
local savedpos

-- neither ripgrep nor fd support .hgignore - only .ignore or .gitignore
function queryfzf(dir, str)
  --local f = spawner.popen('fzf -f "lua"');
  --local f = spawner.popen('fzf -f "'..str..'"');
  --local f2, f = spawner.popen2('find . -iname *');
  --local f = spawner.popen("./wrapper.sh");  -- works
  --local f = io.popen("ag --nocolor -g '' | fzf -f '"..str.."' | head -10");  -- works
  local f = io.popen("cd "..dir.." && ag --nocolor -g '' | fzf -f '"..str.."' | head -10")
  --local f = spawner.popen("find . -iname '*' | fzf -f 'lua'"); -- works
  local s = f:read("*a")
  f:close()
  --print("fzf returned: ", s)
  return split(s, '\n')
end


function onUserListSel(str)
  print("read only canceled for editor", editor)
  editor.ReadOnly = false
  scite_OnChar(fzfOnChar, true)
  scite_OnKey(fzfOnKey, true)
  scite_OnUpdateUI(fzfUpdateUI, true)
  --scite_OnOpenSwitch(fzfUpdateUI, true)
  --editor.CurrentPos = savedpos
  editor:SetEmptySelection(savedpos)
  if str and #str > 0 and not string.match(str, '^>') then
    print("Opening ", root.."/"..str)
    scite.Open(root.."/"..str)
  end
end


function fzfUpdateUI()
  if not editor:AutoCActive() then
    onUserListSel(nil)
    return
  end
  if editor.AutoCCurrent < 1 then
    editor:AutoCSelect('1')
  end
end


function fzfOnKey(key, shift, ctrl, alt)
  print("fzfOnKey called! Key: ", key)
  if not editor:AutoCActive() then
    onUserListSel(nil)
    return
  end
  -- backspace; we don't worry about delete since home/end move inside list and left/right arrow closes it!
  if key == 65288 then
    query = string.sub(query, 1, -2)
    fzfOnChar('')
  end
end


function fzfOnChar(c)
  print("fzfOnChar called!")
  print("AutoCCurrent before: ", editor.AutoCCurrent, editor.AutoCCurrentText)
  if not editor:AutoCActive() then
    onUserListSel(nil)
    return
  end

  --editor:AutoCCancel()

  query = query..c
  local hits = queryfzf(root, query)
  table.insert(hits, 1, '('..root..') >> '..query)
  --scite_UserListShow(hits, 1, onUserListSel)


  for i, hit in ipairs(hits) do
    hits[i] = tostring(i-1)..hit
  end
  local s = table.concat(hits, '@')
  --_UserListSelection = fn
  editor.AutoCSeparator = string.byte('@')
  editor:UserListShow(13, s)



  editor.AutoCAutoHide = false
  editor:AutoCSelect('1') --string.sub(hits[2], 1, 1))
  print("AutoCCurrent after: ", editor.AutoCCurrent, editor.AutoCCurrentText)
end


function do_buffer_list_old()
  savedpos = editor.CurrentPos
  local topline = editor.FirstVisibleLine
  editor:SetEmptySelection(editor:PositionFromLine(topline + 1))
  editor.ReadOnly = true
  print("read only set for editor", editor)

  editor.AutoCMaxHeight = 10
  --editor.AutoCOrder = 2  -- unsorted/do not sort

  print("Root: ", root)

  query = ''
  local hits = queryfzf(root, ' ')
  table.insert(hits, 1, '('..root..') >> ')
  --scite_UserListShow(hits, 1, onUserListSel)

  for i, hit in ipairs(hits) do
    hits[i] = tostring(i-1)..hit
  end
  local s = table.concat(hits, '@')
  --_UserListSelection = fn
  editor.AutoCSeparator = string.byte('@')
  editor:UserListShow(13, s)

  ---scite.StripShow("'Choose Buffer:'{}")  --prepend '!' to show close button on Windows
  ---scite.StripSetList(1, table.concat(hits, '\n'))


  editor.AutoCAutoHide = false
  editor:AutoCSelect(string.sub(hits[2], 1, 1))
  print("AutoCCurrent after: ", editor.AutoCCurrent, editor.AutoCCurrentText)
  scite_OnKey(fzfOnKey)
  scite_OnChar(fzfOnChar)
  scite_OnUpdateUI(fzfUpdateUI)
  --scite_OnOpenSwitch(fzfUpdateUI)
end




function do_buffer_list_output()
  scite.MenuCommand(IDM_TOGGLEOUTPUT)
  output:GrabFocus()
  savedpos = output.CurrentPos
  local topline = output.FirstVisibleLine
  output:SetEmptySelection(output:PositionFromLine(topline + 1))
  output.ReadOnly = true
  --print("read only set for output", output)

  output.AutoCMaxHeight = 10
  --output.AutoCOrder = 2  -- unsorted/do not sort

  --print("Root: ", root)

  query = ''
  local hits = queryfzf(root, ' ')
  table.insert(hits, 1, '('..root..') >> ')
  --scite_UserListShow(hits, 1, onUserListSel)

  for i, hit in ipairs(hits) do
    hits[i] = tostring(i-1)..hit
  end
  local s = table.concat(hits, '@')
  --_UserListSelection = fn
  output.AutoCSeparator = string.byte('@')
  output:UserListShow(13, s)

  ---scite.StripShow("'Choose Buffer:'{}")  --prepend '!' to show close button on Windows
  ---scite.StripSetList(1, table.concat(hits, '\n'))


  output.AutoCAutoHide = false
  output:AutoCSelect(string.sub(hits[2], 1, 1))
  --print("AutoCCurrent after: ", output.AutoCCurrent, output.AutoCCurrentText)
  scite_OnKey(fzfOnKey)
  scite_OnChar(fzfOnChar)
  scite_OnUpdateUI(fzfUpdateUI)
  --scite_OnOpenSwitch(fzfUpdateUI)
end


function do_buffer_list()
  dir = root
  str = ' '
  --local f = io.popen("cd "..dir.." && ag --nocolor -g '' | fzf -f '"..str.."' | head -10")
  --local f = spawner.popen("cd "..dir.." && xterm -e fzf")
  -- sh -c is need for urxvt but not xterm
  local f = spawner.popen([[x-terminal-emulator -e sh -c "ag -g '' | fzf > /tmp/scitefzf" && cat /tmp/scitefzf]])
  local s = f:read("*a")
  f:close()
  print("Returned: ", s)
end

function _gcc_processChunk(s)
	print("Captured: ", s)
end

-- something like this should work on linux, since spawner_obj:run() uses forkpty()
-- but I don't think we can avoid piping to file on windows, so just do it on both
function do_buffer_list_fdsafds()
  spawner_obj = spawner.new([[sh -c 'xterm -e "fzf > $(tty)"']])
  -- good practice to mangle these function names since they are global!
  spawner_obj:set_output('_gcc_processChunk')
  spawner_obj:run()
end




--- Next:
-- sadly onclear doesn't get called before editor is changed, so let's set a permanent scite_OnSwitch
--  handler to clear editor.ReadOnly when switching to buffer; we can save props['FilePath'] to keep track of
--  which buffers have it set


function myOnClear(element, change)
  print("OnClear: editor.ReadOnly is", editor.ReadOnly)
end

--scite_OnClear(myOnClear)

scite_Command('Find File|do_buffer_list|Ctrl+T')
