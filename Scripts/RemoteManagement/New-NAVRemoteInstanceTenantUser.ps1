﻿Function New-NAVRemoteInstanceTenantUser {
    param (
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyname=$true)]
        [System.Management.Automation.Runspaces.PSSession]$Session,
        [Parameter(Mandatory=$True, ValueFromPipelineByPropertyname=$true)]
        [PSObject]$SelectedTenant
    )
    PROCESS 
    {
        $NewUser = New-UserDialog -Message "Enter details on new user." -User (New-UserObject)
        if ($NewUser.UserName -eq "") { break }     
        $NewPassword = Get-NewUserPassword 
        $Result = Invoke-Command -Session $Session -ScriptBlock `
            {
                param(
                    [String]$ServerInstance,
                    [String]$TenantId,
                    [PSObject]$User,                    
                    [String]$NewPassword,
                    [Switch]$ChangePasswordAtNextLogOn)
                Write-Verbose "Import Module from $($SetupParameters.navServicePath)..."
                Load-InstanceAdminTools -SetupParameters $SetupParameters
                $params = @{ 
                    ServerInstance = $ServerInstance
                    Tenant = $TenantId
                    UserName = $User.UserName
                    FullName = $User.FullName
                    AuthenticationEmail = $User.AuthenticationEmail
                    LicenseType = $User.LicenseType
                    State = $User.State
                    Password = (ConvertTo-SecureString -String $NewPassword -AsPlainText -Force) }
                if ($ChangePasswordAtNextLogOn) { $params.ChangePasswordAtNextLogOn = $true }
                New-NAVServerUser @params -Force
                UnLoad-InstanceAdminTools
            } -ArgumentList (
                $SelectedTenant.ServerInstance, 
                $SelectedTenant.Id, 
                $NewUser, 
                $NewPassword, 
                ($RemoteConfig.NAVSuperUser.ToUpper() -eq $User.UserName))

        $NewUser | Add-Member -MemberType NoteProperty -Name Password -Value $NewPassword
        Return $NewUser
    }    
}