-- Dynamically generate autocomplete lists from possible identifiers in any file.
-- From http://lua-users.org/wiki/SciteAutoCompleteAnyLanguage
-- by Martin Stone
-- modified by Matt White to use Scite ExtMan and add toggle enable

local IGNORE_CASE = true
-- Number of chars to type before the autocomplete list appears:
local MIN_PREFIX_LEN = 3
-- Length of shortest word to add to the autocomplete list
local MIN_IDENTIFIER_LEN = 6
-- A list of string patterns for finding suggestions for the autocomplete menu.
local IDENTIFIER_PATTERNS = {"[%a_][%w_]+", "[%a_][%w_.]*[%w_]", "[%a_][%w_-]*[%w_]"}

local names = {}
local notempty = next
-- set the startup state of autocomplete here
local autocomplete_enabled = false

if IGNORE_CASE then
  normalize = string.lower
else
  normalize = function(word) return word end
end


function buildNames()
  names = {}
  local text = editor:GetText()
  for i, pattern in ipairs(IDENTIFIER_PATTERNS) do
    for word in string.gmatch(text, pattern) do
      if string.len(word) >= MIN_IDENTIFIER_LEN then
        names[word] = true
      end
    end
  end
end


function handleChar()
  if not editor:AutoCActive() then
    editor.AutoCIgnoreCase = IGNORE_CASE
    local pos = editor.CurrentPos
    local startPos = editor:WordStartPosition(pos, true)
    local len = pos - startPos
    if len >= MIN_PREFIX_LEN then
      local prefix = editor:textrange(startPos, pos)
      local menuItems = {}
      for name, v in pairs(names) do
        if normalize(string.sub(name, 1, len)) == normalize(prefix) then
          table.insert(menuItems, name)
        end
      end
      if notempty(menuItems) then
        table.sort(menuItems)
        editor:AutoCShow(len, table.concat(menuItems, " "))
      end
    end
  end
end

function toggleAutocomplete()
  -- second arg to scite_ is "remove callback?"
  scite_OnChar(handleChar, autocomplete_enabled);
  scite_OnSave(buildNames, autocomplete_enabled);
  scite_OnSwitchFile(buildNames, autocomplete_enabled);
  scite_OnOpen(buildNames, autocomplete_enabled);
  autocomplete_enabled = not autocomplete_enabled;
  buildNames();
end

-- startup state
if autocomplete_enabled then
  autocomplete_enabled = false;
  toggleAutocomplete();
end

scite_Command("Toggle autocomplete|toggleAutocomplete|F10");
