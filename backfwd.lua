-- Make it easy to jump to previous positions within document, without
--  needing to set markers in advance

-- minimum number delta lines considered a jump
local JUMP_THRESHOLD = 20;

-- limited depth stack; oldest items discarded if size reaches limit
function stack_t(modulus)
  modulus = modulus or 20;

  local s = {};
  local idx = 1;  -- points to next avail slot
  local this = {};

  local function modidx(x)
    return ((x - 1) % modulus) + 1;
  end

  function this.push(x)
     s[idx] = x;
     idx = modidx(idx + 1);
     s[idx] = false;  -- everything past current pos is now invalid
  end

  function this.back()
    local newidx = modidx(idx - 1);
    if s[newidx] then
      idx = newidx;
    end
    return s[newidx];
  end

  function this.fwd()
    local newidx = modidx(idx + 1);
    if s[idx] then
      idx = newidx;
    end    
    return s[idx] and s[newidx];
  end

  -- returns true if fwd will fail AND back will succeed (implies non-empty stack)
  function this.atend()
    return s[modidx(idx - 1)] and not s[idx];
  end

  return this;
end


function backfwdsavepos()
  if not buffer.backfwd then
    buffer.backfwd = {stack=stack_t(20), prevline=0, lastpos=0, tail=nil};
  end
  local bf = buffer.backfwd;

  local currline = editor:LineFromPosition(editor.CurrentPos);
  if math.abs(currline - bf.prevline) > JUMP_THRESHOLD then
    --print("Saving "..bf.lastpos);
    bf.stack.push(bf.lastpos);
    bf.tail = nil;
  end
  bf.lastpos = editor.CurrentPos;
  bf.prevline = currline;
end

function jump_back()
  local bf = buffer.backfwd;
  if bf then
    if bf.stack.atend() then
      bf.tail = editor.CurrentPos;
      --print("Tail saved as "..bf.tail);
    end
  
    local pos = bf.stack.back();
    if(pos) then
      --print("Back to "..pos);
      bf.prevline = editor:LineFromPosition(pos);
      editor:GotoPos(pos);
    end
  end
end

function jump_fwd()
  local bf = buffer.backfwd;
  if bf then
    local pos = bf.stack.fwd() or bf.tail;
    if(pos) then
      --print("Fwd to "..pos.." bf tail is "..bf.tail);
      bf.prevline = editor:LineFromPosition(pos);
      editor:GotoPos(pos);
    end
  end
end


scite_OnUpdateUI(backfwdsavepos);
-- 
scite_Command("Jump back|jump_back|Ctrl+,");  -- Ctrl + <
scite_Command("Jump foward|jump_fwd|Ctrl+.");  -- Ctrl + >
