-- fzfopen: launch a terminal window running fzf and open selected file(s)

-- possible improvements:
-- - option/different shortcut to search under root for current document (could launch from new doc to use
--  SciTE start directory or $HOME)
-- - could try running fzf inside scite (using spawner.new - see Scite-Debug)


function trim(s)
  local n = s:find("%S")
  return n and s:match(".*%S", n) or ""
end

-- get root for listing files
function getroot()
  local cmd = scite_GetProp('PLAT_GTK') and
      [[hg root 2> /dev/null || git rev-parse --show-toplevel 2> /dev/null || echo $HOME]] or
      [[hg root 2> nul || git rev-parse --show-toplevel 2> nul || echo D:\\home]]
  local f = spawner.popen(cmd)
  root = trim(f:read("*a"))
  f:close()
  return root
end

local root = getroot()

-- something like this should work on linux, since sp:run() uses forkpty(), but I don't think we can avoid
--  piping to file on windows, so just do it on both;  ref: https://github.com/mkottman/scite/
--sp = spawner.new([[sh -c 'xterm -e "fzf > $(tty)"']]); sp:set_output('_read_str_fn'); sp:run()
function fzf_open()
  local dir = root
  local drive = not scite_GetProp('PLAT_GTK') and string.match(dir, '^(%a:)') or nil
  drive = drive and drive.." && " or ''
  -- sh -c is needed for urxvt but not xterm; cmd /c is needed or redirection
  -- we could user fzf --prompt option if we want to show root dir with prompt
  local cmd = scite_GetProp('PLAT_GTK') and
      [[x-terminal-emulator -e sh -c "ag -g '' | fzf > /tmp/scitefzf" && cat /tmp/scitefzf]] or
      [[start /wait cmd /c ag -g "" ^| fzf --multi ^> %TEMP%\\scitefzf && type %TEMP%\\scitefzf]]
  local f = spawner.popen(drive.."cd "..dir.." && "..cmd)
  local s = f:read("*a")
  f:close()
  --print("fzf", dir, s)
  local files = split(s, '\n')
  for i, file in ipairs(files) do
    file = trim(file)
    if #file > 0 then
      scite.Open(dir.."/"..file)
    end
  end
end

scite_Command('Find Files (fzf)|fzf_open|Ctrl+P')


-- Abandoned user list approach (hg rev 25): use Scite user list (basically an autocomplete list), populated
--  by calling `fzf -f`; set editor.ReadOnly and use OnChar/OnKey to capture typing and prevent it from
--  modifying document (initially tried using undo to prevent document modification, but that's too fragile).
--  Use OnUpdateUI hook to ensure 2nd item is selected (first item shows query string), as AutoCSelect only
--  seemed to work when box is first opened.  Also makes it possible to prevent selection of first item
--  entirely.  Only major remaining problem is that if user switches tab when user list is open, we don't get
--  a chance to reset read-only , so we'd need a OnSwitch handler always running to check editor.ReadOnly when
--  tab is switched; tried adding OnClear to extman, but that is called after editor is switched to new buffer
-- Ultimately settled on opening terminal window to run fzf interactively.  This is more general (works for
--  any interactive application), supports more features (e.g. multi-select), and will be faster for large
-- directories since fzf only has to run once
