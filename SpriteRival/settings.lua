import "json"

local settings = { }

local tag = "<SpriteRival>"
local defaults = {
	exportScale = 1,
	hurt2x = true,
}

local function gsl(spr)
	for i, l in ipairs(spr.layers) do
		if l.data and string.find(l.data, tag) == 1 then
			return l
		end
	end
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
	local l = gsl(spr)
	if not l then return end -- TEMP
	l.data = tag .. json.encode(s)
end

















return settings
