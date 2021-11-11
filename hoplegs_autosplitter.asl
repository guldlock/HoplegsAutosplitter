state("Hoplegs") {
	
}

start
{
	if(vars.Watchers["levelID"].Current == 100){
		return true;
	}
}

split
{
	if(vars.Watchers["levelID"].Current != vars.Watchers["levelID"].Old && vars.Watchers["levelID"].Current != 0){
		return true;
	}
}

isLoading
{
	if(vars.Watchers["isRunning"].Current == 0){
		return true;
	}
	if(vars.Watchers["isRunning"].Current == 1){
		return false;
	}
}

reset
{
	if(vars.Watchers["levelID"].Current == 0){
		return true;
	}
}

init
{
	vars.CancelSource = new CancellationTokenSource();
	vars.ScanThread = new Thread(() =>
	{
		Func<SigScanTarget, IntPtr> scanPages = (trg) =>
		{
			var ptr = IntPtr.Zero;
			foreach(var page in game.MemoryPages())
			{
				var scanner = new SignatureScanner(game, page.BaseAddress, (int)(page.RegionSize));
				if((ptr = scanner.Scan(trg)) != IntPtr.Zero)
					break;
			}

			return ptr;
		};

		var speedrunData = IntPtr.Zero;
		var srdTrg = new SigScanTarget(0x8, "37 13 37 13 37 13 37 13 00 00");

		var token = vars.CancelSource.Token;
		while(!token.IsCancellationRequested)
		{
			if((speedrunData = scanPages(srdTrg)) != IntPtr.Zero)
			{
				vars.Watchers = new MemoryWatcherList
				{
					new MemoryWatcher<float>(speedrunData + 0x0){Name = "inGameTime"},
					new MemoryWatcher<int>(speedrunData + 0x4){Name = "isRunning"},
					new MemoryWatcher<int>(speedrunData + 0x8){Name = "levelID"},
					new MemoryWatcher<int>(speedrunData + 0x12){Name = "isLoading"}
				};

				break;
			}

			//Thread.Sleep(2000);
		}
	});

	vars.ScanThread.Start();
}

update
{
	if(vars.ScanThread.IsAlive) return false;

	vars.Watchers.UpdateAll(game);
}
