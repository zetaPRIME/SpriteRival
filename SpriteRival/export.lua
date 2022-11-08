function init(plugin)
	--print("this works")

	-- plugin.preferences serialized table

	--
	plugin:newCommand {
		id = "exportHurtbox",
		title = "Export Hurtbox",
		group = "file_export",
		onclick=function()
			print "this has been modified"
			os.execute "echo lol internet"
		end
	}
end

function exit(plugin)
	--[[print("Aseprite is closing my plugin, MyFirstCommand was called "
	      .. plugin.preferences.count .. " times")]]
end
