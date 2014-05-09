-- Find URL
-- Jan 2013: Now supports links to local files in [[ ]]

function open_url()
  -- read in entire line, search for urls, pick the one that contains the current position
  local row = editor.CurrentPos;
  local line, column = editor:GetCurLine();
  local matchstrs = {"http[s]?://[^%s'\"<>]+", "www%.[^%s'\"<>]+", "ftp://[^%s'\"<>]+", "ftp%.[^%s'\"<>]+", "%[%[([^%]]+)%]%]"};
  local start,stop = nil,1;
  local target = nil;
  local ii = 1;
  while ii <= #matchstrs do
    start, stop, target = string.find(line, matchstrs[ii], stop);
    if not start then
      stop = 1;
      ii = ii + 1;
    elseif start <= column and column <= stop then
      break;
    end
  end

  if start then
    -- for now, the only capture is for a [[ ]] link to local file; let's try to find the file
    if target then
      -- FileDir does not include trailing slash according to scite docs
      local dir = props['FileDir'];
      while dir do
        for _, ext in ipairs({"", ".mdwn", ".txt"}) do
          --print("Looking for "..dir.."/"..target..ext);
          if scite_FileExists(dir.."/"..target..ext) then
            editor:SetSel(-1, editor.CurrentPos);
            scite.Open(dir.."/"..target..ext);
            -- can't figure out how to prevent uncommanded creation of selection in new doc
            return;
          end
        end
        -- try to find in parent directory; this works because string.match is greedy
        dir = string.match(dir, "(.+)[%/\\]");
      end
    else
      local lastchar = string.sub(line, stop, stop);
      if lastchar == "," or lastchar == "." then
        -- exclude trailing comma or period
        stop = stop - 1;
      elseif lastchar == ")" then
        -- determine if trailing ')' is part of URL by checking for a '(' immediately before URL
        -- can't use "%b()" since there is no requirement that parenthesis in URLs be balanced!
        if string.match( string.sub(line, 1, start-1), "%(%s*$" ) then
          stop = stop - 1;
        end
      end

      local linestart = editor:PositionFromLine(editor:LineFromPosition(editor.CurrentPos));
      editor:SetSel(start+linestart-1, stop+linestart);
      --print(os.date("%X").." URL Selected", start+linestart, stop+linestart);
      -- select url, run IDM_OPENSELECTED, deselect
      scite.MenuCommand(IDM_OPENSELECTED)
      -- clear selection; this will move cursor to end of URL
      editor:SetSel(-1, editor.CurrentPos);
    end
  end
end

-- Open URL by double click
scite_OnDoubleClick(open_url);

function google_selection()
  -- on Linux, we would use xdg-open instead of start
  local s = props.CurrentSelection;
  if s ~= "" then
    local cmd = 'start "Google Search" "www.google.com/search?hl=en&q='..string.gsub(s, "%s", "+")..'"';
    if spawner then
      -- this has the advantage of not showing terminal window;
      -- not using scite_Popen since it creates a temp file to get output when falling back to os.execute
      spawner.popen(cmd);
    else
      os.execute(cmd);
    end
  end
end

scite_Command('Google|google_selection|Context')
