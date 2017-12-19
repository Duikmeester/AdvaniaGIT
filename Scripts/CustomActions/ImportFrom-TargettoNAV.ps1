Check-NAVServiceRunning -SetupParameters $SetupParameters -BranchSettings $BranchSettings 
if ($BranchSettings.dockerContainerId -gt "") {
    Start-DockerCustomAction -BranchSettings $BranchSettings -ScriptName $MyInvocation.MyCommand.Name -BuildSettings $BuildSettings
} else {    
    Load-ModelTools -SetupParameters $SetupParameters
    
    Write-Host "Importing from Target.txt to $($BranchSettings.databaseName)"
    $logFile = (Join-Path $SetupParameters.LogPath "navimport.log")
    if ($SetupParameters.BuildMode) {
        $SetupParameters.workFolder = Join-Path (Join-Path $SetupParameters.workFolder $SetupParameters.BranchId) 'Target.txt'
    } else {
        $Path = (Join-Path $SetupParameters.workFolder 'Target.txt')
    }
    $command = "Command=ImportObjects`,ImportAction=Overwrite`,SynchronizeSchemaChanges=No`,File=`"$Path`""                 

    Run-NavIdeCommand -SetupParameters $SetupParameters `
                        -BranchSettings $BranchSettings `
                        -Command $command `
                        -LogFile $logFile `
                        -ErrText "Error while importing from $(Split-Path $Path)" `
                        -Verbose:$VerbosePreference

    if (Test-Path $logFile) {
        Write-Host -ForegroundColor Red (Get-Content -Path $logfile)
        throw
    }
    Write-Host "Import complete"
    Compile-NAVApplicationGITObject -SetupParameters $SetupParameters -BranchSettings $BranchSettings -Filter "Type=1;Id=2000000006" -SynchronizeSchemaChanges No
    Compile-NAVApplicationGITObject -SetupParameters $SetupParameters -BranchSettings $BranchSettings -Filter "Type=1;Id=2000000000..2000000005" -SynchronizeSchemaChanges Force
    Compile-NAVApplicationGITObject -SetupParameters $SetupParameters -BranchSettings $BranchSettings -Filter "Type=1;Id=2000000007.." -SynchronizeSchemaChanges Force
    Compile-NAVApplicationGITObject -SetupParameters $SetupParameters -BranchSettings $BranchSettings -Filter "Type=7" -SynchronizeSchemaChanges Force
    UnLoad-ModelTools
}