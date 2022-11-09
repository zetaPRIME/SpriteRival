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

function dlgExport(path)
	local c = false
	local dlg
	dlg = Dialog { title = "Export..." } : file { id = "file", save = true, focus = true, filename = path, onclick = function()
		c = true
		dlg:close()
	end }
	local d = dlg:show().data
	return c and d.file
end

function validPath(p)
	if not p or p == "" or p == "**filename**" then return false end
	return true
end

function delFile(p)
	p = app.fs.normalizePath(p)
	if not app.fs.isFile(p) then return end
	if app.fs.pathSeparator == "/" then -- unix syntax
		os.execute('rm -f "' .. p:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"')
	else -- we windows now
		-- TODO verify this
		os.execute('del /q "' .. p:gsub('"', '\\"') .. '"')
	end
end

function splitStripPath(p)
	p = app.fs.fileTitle(p)
	local base, num
	for t, t2 in string.gmatch(p, "(.+)_strip(%d+)$") do base, num = t, (t2 or "") break end
	if not base then base, num = p, nil end
	return base, tonumber(num)
end
function setStripPath(p, num)
	local dir = app.fs.filePath(p)
	local ext = app.fs.fileExtension(p) -- this will almost always be png, but we keep it intact just in case
	p = splitStripPath(p) -- baseify
	local strip = ""
	if num then strip = "_strip" .. num end
	return app.fs.joinPath(dir, p .. strip .. "." .. ext)
end

function hurtboxPath(p)
	local dir = app.fs.filePath(p)
	local ext = app.fs.fileExtension(p)
	local base, num = splitStripPath(p)
	return app.fs.joinPath(dir, base .. "_hurt_strip" .. num .. "." .. ext)
end

function exportSettings(spr, ui)
	local sp = app.preferences.document(spr).sprite_sheet
	local new = not sp.defined or not validPath(sp.texture_filename)
	return {
		-- UI
		ui = ui, askOverwrite = ui,
		openGenerated = ui and sp.open_generated,
		-- metrics
		type = sp.type,
		columns = sp.columns, rows = sp.rows,
		width = sp.width, height = sp.height,
		borderPadding = sp.border_padding,
		shapePadding = sp.shape_padding,
		innerPadding = sp.inner_padding,
		-- modifiers
		trimSprite = sp.trim_sprite,
		trim = sp.trim,
		trimByGrid = sp.trim_by_grid,
		extrude = sp.extrude,
		mergeDuplicates = sp.merge_duplicates,
		ignoreEmpty = sp.ignore_empty,
		-- selectors
		layer = sp.layer,
		tag = sp.frame_tag,
		-- file
		textureFilename = sp.texture_filename,
		dataFilename = sp.data_filename, dataFormat = sp.data_format,
		-- not implemented: split_*, list_*
	}
end

function exportSheet(spr, saveAs)
	spr = spr or app.activeSprite
	if not spr then return false end
	local pp = app.preferences.document(spr)
	local sp = pp.sprite_sheet
	local nxp = not validPath(sp.texture_filename)
	if nxp or saveAs then
		-- prompt for export properties
		app.activeSprite = spr
		local sst = sp.type
		if sst == SpriteSheetType.NONE then sst = SpriteSheetType.HORIZONTAL end
		print(app.command.ExportSpriteSheet(exportSettings(spr, true)))
	end
	if not validPath(sp.texture_filename) then return false end -- canceled
	
	-- TODO: don't try to do Rivals things if sheet type isn't horizontal
	
	local needs2x = false -- TODO
	local needsHurtbox = false -- we detect this later
	
	local base, nf = splitStripPath(sp.texture_filename)
	
	if nf then -- strip export
		local hbPath = hurtboxPath(sp.texture_filename)
		needsHurtbox = app.fs.isFile(hbPath)
		
		local numFrames = #spr.frames
		if sp.frame_tag ~= "" then -- count tag frames instead of sprite ones
			local tag
			for k,t in pairs(sprite.tags) do if t.name == sp.frame_tag then tag = t break end end
			if tag then numFrames = tag.frames end
		end
		if numFrames ~= nf then -- correct the number automatically
			local oldPath = sp.texture_filename -- keep this to remove later
			sp.texture_filename = setStripPath(sp.texture_filename, numFrames) -- set new filename accordingly
			-- and now we remove the old strips
			delFile(oldPath)
			if needsHurtbox then delFile(hbPath) end
		end
	end
	
	if needs2x then
		-- TODO
	else
		app.activeSprite = spr
		app.command.ExportSpriteSheet(exportSettings(spr, false))
	end
	if needsHurtbox then exportHurtbox(spr) end
	
	app.activeSprite = spr -- make sure we come back to this at the end
end

function exportHurtbox(spr)
	spr = spr or app.activeSprite
	if not spr then return false end
	local pp = app.preferences.document(spr)
	local xpath = pp.sprite_sheet.texture_filename
	if not validPath(xpath) then return err "Sprite has not been exported." end -- abort if not init
	
	local npath = hurtboxPath(xpath)
	
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
	app.preferences.document(nspr).sprite_sheet.texture_filename = npath
	app.command.ExportSpriteSheet(exportSettings(nspr, false))
	
	app.activeSprite = spr
	nspr:close()
	
	return true
end


function init(plugin)
	-- plugin.preferences serialized table
	
	--os.execute("echo SpriteRival needs script execution in order to remove strips with incorrect frame count. Checking \"full trust\" will make this a lot less annoying.")
	
	local function hasSpr() return not not app.activeSprite end
	
	plugin:newCommand {
		id = "export",
		title = "SpriteRival Export",
		group = "file_export",
		onclick = function() exportSheet() end,
		onenabled = hasSpr,
	}
	
	plugin:newCommand {
		id = "exportAs",
		title = "SR Export As...",
		group = "file_export",
		onclick = function() exportSheet(nil, true) end,
		onenabled = hasSpr,
	}
	
	plugin:newCommand {
		id = "exportHurtbox",
		title = "SR Export Hurtbox",
		group = "file_export",
		onclick = function() exportHurtbox() end,
		onenabled = hasSpr,
	}
end

function exit(plugin)
	--[[print("Aseprite is closing my plugin, MyFirstCommand was called "
	      .. plugin.preferences.count .. " times")]]
end
