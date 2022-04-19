if _G.CrazyUpdater then
	return
end

_G.CrazyUpdater = { Callbacks = {} }

function CrazyUpdater:DownloadFile(url, path)
	DownloadFileAsync(url, path, function() end)
end

function CrazyUpdater:Trim(s)
	local from = s:match("^%s*()")
	return from > #s and "" or s:match(".*%S", from)
end

function CrazyUpdater:ReadFile(path)
	local result = {}
	local file = io.open(path, "r")
	if file then
		for line in file:lines() do
			local str = self:Trim(line)
			if #str > 0 then
				table.insert(result, str)
			end
		end
		file:close()
	end
	return result
end

function CrazyUpdater:New(args)
	local updater = {}
	function updater:__init()
		self.Step = 1
		self.Version = type(args.version) == "number" and args.version or tonumber(args.version)
		self.VersionUrl = args.versionUrl
		self.VersionPath = args.versionPath
		self.ScriptUrl = args.scriptUrl
		self.ScriptPath = args.scriptPath
		self.ScriptName = args.scriptName
		self.VersionTimer = GetTickCount()
		self:DownloadVersion()
	end
	function updater:DownloadVersion()
		if not FileExist(self.ScriptPath) then
			self.Step = 4
			CrazyUpdater:DownloadFile(self.ScriptUrl, self.ScriptPath)
			self.ScriptTimer = GetTickCount()
			return
		end
		CrazyUpdater:DownloadFile(self.VersionUrl, self.VersionPath)
	end
	function updater:OnTick()
		if self.Step == 0 then
			return
		end
		if self.Step == 1 then
			if GetTickCount() > self.VersionTimer + 1 then
				local response = CrazyUpdater:ReadFile(self.VersionPath)
				if #response > 0 and tonumber(response[1]) > self.Version then
					self.Step = 2
					self.NewVersion = response[1]
					CrazyUpdater:DownloadFile(self.ScriptUrl, self.ScriptPath)
					self.ScriptTimer = GetTickCount()
				else
					self.Step = 3
				end
			end
		end
		if self.Step == 2 then
			if GetTickCount() > self.ScriptTimer + 1 then
				self.Step = 0
				print(
					self.ScriptName
						.. " - new update found! ["
						.. tostring(self.Version)
						.. " -> "
						.. self.NewVersion
						.. "] Please 2xf6!"
				)
			end
			return
		end
		if self.Step == 3 then
			self.Step = 0
			return
		end
		if self.Step == 4 then
			if GetTickCount() > self.ScriptTimer + 1 then
				self.Step = 0
				print(self.ScriptName .. " - downloaded! Please 2xf6!")
			end
		end
	end
	updater:__init()
	table.insert(self.Callbacks, updater)
end

local Updated
Callback.Add("Tick", function()
	if not Updated then
		local ok = true
		for i = 1, #GGUpdate.Callbacks do
			local updater = GGUpdate.Callbacks[i]
			updater:OnTick()
			if updater.Step > 0 then
				ok = false
			end
		end
		if ok then
			Updated = true
		end
	end
end)
