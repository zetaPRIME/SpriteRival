import "json"

local settings = { }

local tag = "<SpriteRival>"
local defaults = {
	exportScale = 1,
	hurt2x = true,
}

local function gsl(spr) -- get storage layer
	for i, l in ipairs(spr.layers) do
		if l.data and string.find(l.data, tag) == 1 then
			return l
		end
	end
end

local function gslc(spr) -- get storage layer candidate
	local sl = gsl(spr)
	if sl then return sl end
	local function nd(l) return not l.data or l.data == "" end
	-- try reference layer
	for i, l in ipairs(spr.layers) do
		if nd(l) and l.isReference then return l end
	end
	-- then just do whatever layer has no other data
	for i, l in ipairs(spr.layers) do if nd(l) then return l end end
	-- can return nil
end

function settings.get(spr)
	local l = gsl(spr)
	local s
	if l then
		s = json.decode(string.sub(l.data, #tag + 1))
	else s = { } end
	for k,v in pairs(defaults) do if s[k] == null then s[k] = v end end
	return s
end

function settings.store(spr, s)
	local sl = gslc(spr)
	if not sl then return false end -- storage failed; no candidate
	sl.data = tag .. json.encode(s)
	
	-- clean up duplicate entries
	for i, l in ipairs(spr.layers) do
		if l ~= sl then
			if l.data and string.find(l.data, tag) == 1 then l.data = "" end
		end
	end
	return true
end

function settings.showDialog(spr)
	if not spr then spr = app.activeSprite end
	if not spr then return end
	
	local st = settings.get(spr)
	
	local dlg = Dialog "SpriteRival Properties"
	
	dlg:combobox { id = "exportScale",
		label = "Export scale",
		options = { "1x", "2x", "4x" },
		option = st.exportScale .. "x",
	}
	dlg:check { id = "hurt2x",
		label = "Export hurtbox at 2x scale",
		selected = st.hurt2x,
	}
	
	-- end stuff
	dlg:separator() -- match style
	dlg:button { id = "ok", text = "OK" }
	dlg:button { text = "Cancel" }
	
	dlg:show()
	
	if dlg.data.ok then
		st.exportScale = tonumber(dlg.data.exportScale:sub(1,1))
		st.hurt2x = dlg.data.hurt2x
		
		if not settings.store(spr, st) then
			err "Couldn't store settings: no layers without non-SpriteRival data"
		end
	end
	
end

















return settings
