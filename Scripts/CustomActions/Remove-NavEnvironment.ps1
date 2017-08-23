if ($BranchSettings.instanceName -ne "") {
    Write-Host "Requesting removal of NAV Environment for branch" $Setupparameters.Branchname
    if ($BranchSettings.dockerContainerId -eq "") {
        Load-InstanceAdminTools -SetupParameters $Setupparameters
        Remove-NAVEnvironment -BranchSettings $BranchSettings
        UnLoad-InstanceAdminTools
    } else {
        $dockerContainer = Get-DockerContainers | Where-Object -Property Id -ieq $BranchSettings.dockerContainerName
        if ($dockerContainer) {
            Write-Host "Killing and removing Docker Container $($BranchSettings.dockerContainerName)..."
            $dockerContainerName = docker.exe kill $($BranchSettings.dockerContainerName)
            $dockerContainerName = docker.exe rm $($BranchSettings.dockerContainerName)

        }
        $BranchSettings = Clear-BranchSettings -BranchId $BranchSettings.branchId 
    }
}

