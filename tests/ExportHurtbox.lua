--



-- automatic strip# resolution, delete nonmatching
-- auto 2xing for artc_, fx_?

local function exportHurtbox()
	local spr = app.activeSprite
	local pp = app.preferences.document(spr)
	local xpath = pp.sprite_sheet.texture_filename
	if xpath == "**filename**" then return end -- abort if not init
	
	local ext = app.fs.fileExtension(xpath)
	local dir = app.fs.filePath(xpath)
	local fn = app.fs.fileTitle(xpath)
	
	local base, strip
	for t, t2 in string.gmatch(fn, "(.+)(_strip%d+)") do base, strip = t, (t2 or "") break end
	
	local npath = app.fs.joinPath(dir, base .. "_hurt" .. strip .. "." .. ext)
	
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
	
end

exportHurtbox()
