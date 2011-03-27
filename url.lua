-- Find URL
function open_url()
  -- read in entire line, search for urls, pick the one that contains the current position
  local row = editor.CurrentPos;  
  local line, column = editor:GetCurLine();
  local matchstrs = {"http[s]?://[^%s'\"<>]+", "www%.[^%s'\"<>]+", "ftp://[^%s'\"<>]+", "ftp%.[^%s'\"<>]+"};
  local start,stop = nil,1;
  local ii = 1;
  while ii <= #matchstrs do
    start, stop = string.find(line, matchstrs[ii], stop);
    if not start then
      stop = 1;
      ii = ii + 1;
    elseif start <= column and column <= stop then 
      break;
    end
  end

  if start then
    local lastchar = string.sub(line, stop, stop);
    if lastchar == "," then 
      -- exclude trailing comma
      stop = stop - 1; 
    elseif lastchar == ")" then
      -- determine if trailing ')' is part of URL
      -- can't use "%b()" since there is no requirement that parenthesis in URLs be balanced!
      if string.match( string.sub(line, 1, start-1), "%(%s*$" ) then
        stop = stop - 1;
      end
    end  

    linestart = editor:PositionFromLine(editor:LineFromPosition(editor.CurrentPos));
    editor:SetSel(start+linestart-1, stop+linestart);
    --print(os.date("%X").." URL Selected", start+linestart, stop+linestart); 
    -- select url, run IDM_OPENSELECTED, deselect
    scite.MenuCommand(IDM_OPENSELECTED)
    -- clear selection; this will move cursor to end of URL
    editor:SetSel(-1, editor.CurrentPos);
  end
end

-- Open URL by double click
scite_OnDoubleClick(open_url);