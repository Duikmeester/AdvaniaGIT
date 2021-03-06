﻿# Inspired by
# https://www.axians-infoma.com/navblog/dynamics-365-bc-extension-build-in-tfs-vsts-using-containers/
#

if ($SetupParameters.BuildMode) {
    $BranchWorkFolder = Join-Path $SetupParameters.rootPath "Log\$($SetupParameters.BranchId)"
    $AlPackageOutParent = (Join-Path $BranchWorkFolder 'out')
    New-Item -Path $BranchWorkFolder -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null
    Remove-Item -Path $AlPackageOutParent -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -Path $AlPackageOutParent -ItemType Directory -Force -ErrorAction SilentlyContinue | Out-Null

    $ALPackageCachePath = (Join-Path $BranchWorkFolder 'Symbols')
    $ALCompilerPath = (Join-Path $BranchWorkFolder 'vsix\extension\bin\alc.exe')
    
    foreach ($ALPath in (Get-ALPaths -SetupParameters $SetupParameters)) {

        $ALProjectFolder = $ALPath.FullName
        $ExtensionAppJsonFile = Join-Path $ALProjectFolder 'app.json'
        $ExtensionAppJsonObject = Get-Content -Raw -Path $ExtensionAppJsonFile | ConvertFrom-Json
        $Publisher = $ExtensionAppJsonObject.Publisher
        $Name = $ExtensionAppJsonObject.Name
        if (![String]::IsNullOrEmpty($SetupParameters.buildId)) {
            $Version = $ExtensionAppJsonObject.Version.SubString(0,$ExtensionAppJsonObject.Version.LastIndexOf('.'))
            $ExtensionAppJsonObject.Version = $Version+'.' + $SetupParameters.buildId
        }
        $ExtensionName = (Clean-NAVFileName -FileName ($Publisher + '_' + $Name + '_' + $ExtensionAppJsonObject.Version + '.app')).Replace(" ","_")    
        $ExtensionAppJsonObject | ConvertTo-Json | set-content $ExtensionAppJsonFile
        Write-Host "Using Symbols Folder: " $ALPackageCachePath
        Write-Host "Using Compiler: " $ALCompilerPath
        $AlPackageOutPath = Join-Path $AlPackageOutParent $ExtensionName
        Write-Host "Using Output Folder: " $AlPackageOutPath
        Write-Host "Using Source Folder: " $ALProjectFolder
        Set-Location -Path $ALProjectFolder
        & $ALCompilerPath /project:.\ /packagecachepath:$ALPackageCachePath /out:$AlPackageOutPath
        if (-not (Test-Path $AlPackageOutPath)) {
            Write-Host "##vso[task.logissue type=error;sourcepath=$AlPackageOutPath;]No app file was generated!"
            throw        
        } else {
            Copy-Item -Path $AlPackageOutPath -Destination $ALPackageCachePath
        } 
    }    
}
