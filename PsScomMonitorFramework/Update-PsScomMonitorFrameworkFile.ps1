function Update-PsScomMonitorFrameworkFile {
    <#
            .Synopsis
            Updates a monitoring object in an existing Monitor Framework file.

            .Description
            Function to update an object in the Monitor Framework file. If the monitor framework file does not exist, this function will create it as well.
            As this function is intended to run from a DSC resource a separate parameter ReportOnly is available to test the output of the function, for humans -WhatIf support is available.

            .Example
            $service = [pscustomobject]@{
                Name = 'W32Time'
                AlertOwner = 'Servers'
                MaxCpu = 5
                NumCpuSamples = 2 
                MaxMemory = 0 
                NumMemorySamples = 0
            }

            Update-PsScomMonitorFrameworkFile -Service $service -Action Update -FilePath D:\scom\monitordata.psd1

            This add / updates the service W32time in monitordata.psd1. If the service does not exist in the file it will get added, otherwise update the properties (if required).

            .Example
            $service = [pscustomobject]@{
                Name = 'W32Time'
                AlertOwner = 'Servers'
                MaxCpu = 5
                NumCpuSamples = 2 
                MaxMemory = 0 
                NumMemorySamples = 0
            }

            Update-PsScomMonitorFrameworkFile -Service $service -Action Remove -FilePath D:\scom\monitordata.psd1

            This removes the service W32time from monitordata.psd1.

    #>

    [CmdletBinding(
            SupportsShouldProcess,
            ConfirmImpact = 'Low'
    )]
    [OutputType([System.IO.FileInfo])]
    param (
        # Name of the service to add or remove.
        [Parameter(
                Mandatory,
                ParameterSetName = 'service'
        )]
        [object]$Service,
        
        # Name of the PowerShell monitor to add or remove.
        [Parameter(
                Mandatory,
                ParameterSetName = 'powershell'
        )]
        [object]$PowerShellMonitor,
        
        # The update action to perform, either Remove all or Update all, Update will also perform additions
        [Parameter(
                Mandatory
        )]
        [ValidateSet(
                'Update',
                'Remove'
        )]
        [string]$Action,
        
        # The path where to output the Monitor Framework file
        [Parameter(
                Mandatory
        )]
        [string]$FilePath,
        
        # Switch to output only a hashtable with changes that would be made by the script.
        [Parameter()]
        [switch]$ReportOnly
    )
    
    Function Update-MonitorFileInput {
        [CmdletBinding()]
        Param (
            [Parameter(Mandatory)]
            [AllowNull()]
            $CurrentData,
            
            [Parameter(Mandatory)]
            $UpdatedData,
            
            [Parameter(Mandatory)]
            [string]$Action,
            
            [Parameter()]
            [hashtable]$Changes
        )
        
        if($Action -eq 'Remove') {
            If($UpdatedData.Name -in $CurrentData.Name) {
                $CurrentData | Where-Object {
                    $_.Name -notin $UpdatedData.Name
                }
                $changes.Add("$($UpdatedData.Name)",'Remove')
            }
        }
        elseif($Action -eq 'Update') {

            If($currentService = $CurrentData | Where-Object {$_.Name -eq $UpdatedData.Name}) {
                # This monitor already exists, do we need to update anything?
                    
                $UpdatedData.psobject.properties.name | ForEach-Object {
                    $property = $_
                    Switch ($UpdatedData.$_.GetType().Name) {
                        'ScriptBlock' {
                            $currentScriptBlock = ($currentService.$property.ToString().Split("`r`n").TrimStart(' ') | Where-Object {-not([string]::IsNullOrWhiteSpace($_))}) -join "`r`n"
                            $updatedScriptBlock = ($updatedData.$property.ToString().Split("`r`n").TrimStart(' ') | Where-Object {-not([string]::IsNullOrWhiteSpace($_))}) -join "`r`n"
                            
                            If($currentScriptBlock -ne $updatedScriptBlock) {
                                $changes.Add("$($UpdatedData.Name).$_","Change current value: $currentScriptBlock, new value: $updatedScriptBlock")
                            }
                        }
                        default {
                            If($currentService.$property -ne $UpdatedData.$property) {
                                $changes.Add("$($UpdatedData.Name).$property","Change current value: $($currentService.$property), new value: $($UpdatedData.$property)")
                            }
                        }
                    }
                }
                    
                If($changes.count -gt 0) {
                    [array]$updatedService = $CurrentData | Where-Object {
                        $_.Name -notin $UpdatedData.Name
                    }
                        
                    $updatedService += $UpdatedData
                    $updatedService
                }
            }
            else {
                # New service, just add
                $changes.Add("$($UpdatedData.Name)",'Add')
                $CurrentData += $UpdatedData
                $CurrentData
            }
        }
    }

    try {
        $allData = Import-PowerShellDataFile -Path $FilePath -ErrorAction Stop
    } catch {
        Write-Warning "Failed to read file $filePath - $_"
    }

   
    # Creating hash table that will be used to call New-PsScomMonitorFrameworkFile - first mandatory parameters...
    
    $splat = @{
        ErrorAction = 'Stop'
        FilePath = $FilePath
    }
    
    # Creating hash table to track changes
    $changes = @{}

    [array]$allServices = Try {
            $allData.service.Keys | ForEach-Object {
            $serviceName = $_
            $allData.service[$_] | ForEach-Object { 
                $_.Add('Name',$serviceName)
                [pscustomobject]$_
            }
        }
    }
    Catch {
        Write-Verbose "No service monitors found in $FilePath"
    }
    
    $splat.service = 
        if ($Service) {
            Update-MonitorFileInput -CurrentData $allServices -UpdatedData $Service -Action $Action -Changes $changes
        }
        else {
            $allServices
        }
    
    If($splat.service.count -eq 0) {
        $splat.Remove('service')
    }

    [array]$allPowerShell = Try {
        $allData.powershell.Keys | ForEach-Object {
            $powerShellMonitorName = $_
            $allData.powershell[$_] | ForEach-Object { 
                $_.Add('Name',$powerShellMonitorName)
                $_['Script'] = [scriptblock]::Create(
                    ($_['Script']).ToString().TrimStart('{').TrimEnd('}')
                )
                [pscustomobject]$_
            }
        }
    }
    Catch {
        Write-Verbose "No powershell monitors found in $FilePath"
    }
    
    $splat.powershell = 
        if ($PowerShellMonitor) {
            Update-MonitorFileInput -CurrentData $allPowerShell -UpdatedData $PowerShellMonitor -Action $Action -Changes $changes
        } else {
            $allPowerShell
        }
    
    If($splat.powershell.count -eq 0) {
        $splat.Remove('powershell')
    }

    If($changes.Count -gt 0) {
        $changes.Keys | ForEach-Object {
            If($PSCmdlet.ShouldProcess(
                    $_,
                    $changes[$_]
            )) {}
        }
        
        If($ReportOnly) {
            Write-Output $changes
        }
        Else {
            if ($PSCmdlet.ShouldProcess(
                    $FilePath,
                    "Save Monitor Framework configuration file"
            )) {
                try {
                    New-PsScomMonitorFrameworkFile @splat
                } catch {
                    throw "Failed to save Monitor Framework file to $FilePath - $_"
                }
            }
        }
    }
}