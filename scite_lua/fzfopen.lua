-- fzfopen: launch a terminal window running fzf and open selected file(s)

-- possible improvements:
-- - option/different shortcut to search under root for current document (could launch from new doc to use
--  SciTE start directory or $HOME)
-- - could try running fzf inside scite (using spawner.new - see Scite-Debug)

-- ag (silver searcher)'s handling of ignore files is a disaster; rg (ripgrep) supports full .gitignore
--  syntax; doesn't yet have .hgignore support, but coming soon: https://github.com/BurntSushi/ripgrep/pull/733

-- spawner reference: https://github.com/mkottman/scite/tree/master/scite/custom/scite-debug
-- Note that scite_Popen in extman creates a temp file to get output when falling back to os.execute if
--  spawner if not available

-- Windows: main issue is whether a terminal window is displayed
-- - io.popen: visible terminal window - messes up focus if not desired, but can capture output
-- - spawner.popen: no terminal window (can use start /wait cmd /c to open one, but can't capture output)
-- - spawner.run: untested
-- - os.execute: visible terminal window

-- Linux: main issue is whether a defunct sh process is left
-- - io.popen: uses popen/pclose, and pclose() wait()s for process, so no defunct process is left behind
-- - spawner.popen: uses fork() and execl(), discards pid, and never wait()s, leaving defunct process
-- - spawner.run: uses forkpty(), so it is possible to redirect output from children to the pty, e.g.
--  sp = spawner.new([[sh -c 'xterm -e "fzf > $(tty)"']]); sp:set_output('_read_str_fn'); sp:run()
-- - os.execute: wait()s before returning, so no defunct process


function trim(s)
  local n = s:find("%S")
  return n and s:match(".*%S", n) or ""
end

-- get root for listing files
function getroot()
  local f = nil
  if scite_GetProp('PLAT_GTK') then
    -- use `pwd` instead of `echo $HOME` to default to directory where SciTE was launched
    -- try git before hg because hg will pick up ~/.hg if nothing else
    f = io.popen([[git rev-parse --show-toplevel 2> /dev/null || hg root 2> /dev/null || pwd]])
  else
    f = spawner.popen([[hg root 2> nul || git rev-parse --show-toplevel 2> nul || echo D:\\home]])
  end
  root = trim(f:read("*a"))
  f:close()
  return root
end

local root = getroot()

-- spawner.new()/run() should work on linux, but I don't think we can avoid piping to file on windows
function fzf_open()
  local dir = root
  local f
  if scite_GetProp('PLAT_GTK') then
    -- sh -c is needed for urxvt but not xterm; cmd /c is needed or redirection
    -- we could user fzf --prompt option if we want to show root dir with prompt
    -- redirection trick is from https://unix.stackexchange.com/questions/256480/
    f = io.popen("cd "..dir..[[ && x-terminal-emulator -e sh -c "rg --files | fzf >&3" 3>&1]])
  else
    local drive = string.match(dir, '^(%a:)') or 'cd .'
    -- io.popen() opens terminal on windows, which is exactly what we want in this case
    f = io.popen(drive.." && cd "..dir..[[ && ag -g "" | fzf --multi]])
  end
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
--  directories since fzf only has to run once.  Initially redirected output from fzf to temp file, but then
--  found that capture worked with io.popen() on Windows (unlike spawner.popen()) and found >&3 ... 3>&1
--  redirection trick for Linux
