json = dofile "json.lua"

for k,v in pairs(_ENV) do
	--print(k)
end

function err(txt, title)
	Dialog { title = title or "Error" } : label { text = txt } : button { text = "OK" } : show()
	return false
end

function warn(txt, title)
	Dialog { title = title or "Warning" } : label { text = txt } : button { text = "OK" } : show()
	return false
end

function validPath(p)
	if not p or p == "" or p == "**filename**" then return false end
	return true
end

function exportHurtbox(spr)
	spr = spr or app.activeSprite
	if not spr then return false end
	local pp = app.preferences.document(spr)
	local xpath = pp.sprite_sheet.texture_filename
	if not validPath(xpath) then return err "Sprite has not been exported." end -- abort if not init
	
	local ext = app.fs.fileExtension(xpath)
	local dir = app.fs.filePath(xpath)
	local fn = app.fs.fileTitle(xpath)
	
	local base, strip
	for t, t2 in string.gmatch(fn, "(.+)(_strip%d+)") do base, strip = t, (t2 or "") break end
	
	local npath = app.fs.joinPath(dir, base .. "_hurt" .. strip .. "." .. ext)
	
	-- copy to a new sprite
	local nspr = Sprite(spr)
	
	-- delete all invisible and !nhb layers
	local del = { }
	for i, l in ipairs(nspr.layers) do
		if string.find(l.name, "!nhb") then l.isVisible = false end
		if not l.isVisible then table.insert(del, l) end
	end
	for _, l in pairs(del) do nspr:deleteLayer(l) end
	
	-- merge and scale
	nspr:flatten()
	nspr:resize(nspr.width * 2, nspr.height * 2)
	
	for i, c in ipairs(nspr.cels) do -- mask everything out green
		for px in c.image:pixels() do
			px(app.pixelColor.rgba(0, 255, 0, app.pixelColor.rgbaA(px())))
		end
	end
	
	app.activeSprite = nspr
	app.command.ExportSpriteSheet {
		ui = false,
		askOverwrite = false,
		type = SpriteSheetType.HORIZONTAL,
		textureFilename = npath,
		dataFilename = "",
	}
	
	app.activeSprite = spr
	nspr:close()
	
	return true
end


function init(plugin)
	--print("this works")

	-- plugin.preferences serialized table
	
	local function hasSpr() return not not app.activeSprite end

	
	plugin:newCommand {
		id = "export",
		title = "Export (SR)",
		group = "file_export",
		onclick = function() end,
		onenabled = hasSpr,
	}
	
	plugin:newCommand {
		id = "exportAs",
		title = "Export As... (SR)",
		group = "file_export",
		onclick = function() end,
		onenabled = hasSpr,
	}
	
	plugin:newCommand {
		id = "exportHurtbox",
		title = "Export Hurtbox (SR)",
		group = "file_export",
		onclick = function() exportHurtbox() end,
		onenabled = hasSpr,
	}
end

function exit(plugin)
	--[[print("Aseprite is closing my plugin, MyFirstCommand was called "
	      .. plugin.preferences.count .. " times")]]
end
