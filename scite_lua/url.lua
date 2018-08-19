-- Find URL
-- Jan 2013: add support for links to local files in [[ ]]
-- Jun 2018: add support for common URLs w/o protocol and DOIs

function run_cmd(cmd)
  if spawner then
    -- spawner.popen has the advantage of not showing terminal window; see discussion in fzfopen.lua
    local f = spawner.popen(cmd);
    f:close();
  else
    os.execute(cmd);
  end
end

function find_around(line, column, prefix, suffix)
  local start,stop = nil,1;
  local capture = nil;
  local cleanend = true;  -- do we ever not want this?

  while true do
    start, stop, capture = string.find(line, prefix, stop);
    if not start or start > column then
      break;
    end
    if suffix then
      _, suffix_stop = string.find(string.sub(line, stop+1), '^'..suffix);
      stop = suffix_stop and (suffix_stop + stop) or stop;
    end
    if start <= column and column <= stop then
      if cleanend then
        local lastchar = string.sub(line, stop, stop);
        if lastchar == "," or lastchar == "." or lastchar == ":" or lastchar == ";" then
          -- exclude trailing punctuation
          stop = stop - 1;
          lastchar = string.sub(line, stop, stop);
          -- fall through to ')' check to handle '),' etc.
        end
        if lastchar == ")" then
          -- determine if trailing ')' is part of URL by checking for a '(' immediately before URL
          -- can't use "%b()" since there is no requirement that parenthesis in URLs be balanced!
          if string.match( string.sub(line, 1, start-1), "%(%s*$" ) then
            stop = stop - 1;
          end
        end
      end
      return start, stop, capture or string.sub(line, start, stop);
    end
  end
end

function open_url()
  -- read in entire line, search for urls, pick the one that contains the current position
  local row = editor.CurrentPos;
  local line, column = editor:GetCurLine();
  local start, stop, target, section;
  local scite_exts = {["mdwn"]=1, ["txt"]=1};

  -- wiki-style link to local file
  start, stop, target = find_around(line, column, "%[%[([^%]]+)%]%]");
  if target then
    target, section = string.match(target, "^([^#]+)#?(.*)$");
    -- FileDir does not include trailing slash according to scite docs
    local dir = props['FileDir'];
    while dir do
      for _, ext in ipairs({"", ".mdwn", ".txt"}) do
        --print("Looking for "..dir.."/"..target..ext);
        local fullpath = dir.."/"..target..ext;
        if scite_FileExists(fullpath) then
          if scite_GetProp('PLAT_GTK') or scite_exts[string.match(fullpath, '%.(%a+)$')] then
            editor:SetSel(-1, editor.CurrentPos);
            scite.Open(fullpath);
            -- can't figure out how to prevent uncommanded creation of selection in new doc
            if section and string.len(section) then
              editor:SearchNext(0, "# "..section.." #");
            end
          else
            run_cmd('start "Open file" "'..fullpath..'"');
          end
          return;
        end
      end
      -- try to find in parent directory; this works because string.match is greedy
      dir = string.match(dir, "(.+)[%/\\]");
    end
    return;
  end

  -- URL with protocol
  start, stop, target = find_around(line, column, "[a-z]+://[%w%-%.]+", "/[^%s'\"<>]+");
  if start then
    local linestart = editor:PositionFromLine(editor:LineFromPosition(editor.CurrentPos));
    editor:SetSel(start+linestart-1, stop+linestart);
    --print(os.date("%X").." URL Selected", start+linestart, stop+linestart);
    -- select url, run IDM_OPENSELECTED, deselect
    scite.MenuCommand(IDM_OPENSELECTED)
    -- clear selection; this will move cursor to end of URL
    editor:SetSel(-1, editor.CurrentPos);
    return;
  end

  -- URL w/o protocol - scite Open Selected won't work so assume http and use `start`
  local url_prefixes = {"[%w%-%.]+%.com", "[%w%-%.]+%.org", "[%w%-%.]+%.edu", "[%w%-%.]+%.net", "www%.[%w%-%.]+"}
  for _, prefix in ipairs(url_prefixes) do
    start, stop, target = find_around(line, column, prefix, "/[^%s'\"<>]+");
    if target then
      run_cmd('start "Open URL" "http://'..target..'"');
      return;
    end
  end

  -- DOI
  -- consider prepending ' ' to line and '[%s%p]' to pattern
  start, stop, target = find_around(line, column, "10%.%d+/[%w%-%.%(%)/:_;]+");
  if target then
    -- don't use Sci-hub for DOIs for open access journals
    local no_scihub = {["10.1371"]=1};
    local doi_prefix = string.match(target, "^(10%.%d+)");
    if no_scihub[doi_prefix] then
      run_cmd('start "Open DOI" "http://dx.doi.org/'..target..'"');
    else
      run_cmd('start "Open Sci-Hub" "https://sci-hub.tw/'..target..'"');
    end
    return;
  end
end

-- Open URL by double click
scite_OnDoubleClick(open_url);

function google_selection()
  -- on Linux, we would use xdg-open instead of start
  local s = props.CurrentSelection;
  if s ~= "" then
    run_cmd('start "Google Search" "www.google.com/search?hl=en&q='..string.gsub(s, "%s", "+")..'"');
  end
end

-- no web browser in my Linux VMs
if not scite_GetProp('PLAT_GTK') then
  scite_Command('Google|google_selection|Context')
end
