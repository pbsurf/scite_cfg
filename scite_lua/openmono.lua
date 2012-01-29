-- default to monospace font on open, while still retaining font settings for non-monospaced mode 
-- buffer table is normally empty - it is for our use

function setmonofont()
  if buffer and not buffer["MadeMonospace"] then  -- and props["FileExt"] ~= "txt", etc
    scite.MenuCommand(IDM_MONOFONT)
    buffer["MadeMonospace"] = true;
  end
end

-- OnOpen event generated when SciTE starts with new file, but not when File->New creates another new file tab.
--  also, SciTE calls OnOpen with empty string as argument on startup
scite_OnOpen(function(filename) if filename ~= "" then setmonofont(); end; end); -- for opening existing file
scite_OnSavePointLeft(setmonofont); -- first character typed in new file

--scite_OnSavePointReached(function() print("OnSavePointReached", buffer ~= nil); end)
--scite_OnSavePointLeft((function() print("OnSavePointLeft", buffer ~= nil); end))  
--scite_OnOpen((function(ff) print("OnOpen: ", ff == "", buffer ~= nil); end))  
-- set first file to mono also
--scite.MenuCommand(IDM_MONOFONT);  -- only event on startup is OnOpen, but with buffer undefined

-- might be useful for autosave:
--props['dwell.period'] = 500  -- ms
--scite_OnDwellStart(function(pos, wordundercursor) print("Dwell started: ", pos, wordundercursor); end)
