using module ..\PsScomMonitorFramework\PsScomMonitorFramework.psd1

InModuleScope PsScomMonitorFramework {
    $module = Get-Module -Name PsScomMonitorFramework
    $resources = $module.ExportedDscResources

    switch($resources) {
        PsScomMonitorFrameworkFile {
            $PsScomMonitorFrameworkFile = [PsScomMonitorFrameworkFile]::new()
            $PsScomMonitorFrameworkFile.Ensure = 'Present'
            $PsScomMonitorFrameworkFile.FilePath = 'TestDrive:\data.psd1'

            Describe "Testing $_ methods" {
                Context 'Testing Test Method' {
                    It 'When a file is not present, set should return false' {
                        $PsScomMonitorFrameworkFile.Test() | Should be $false
                    }
                }
            
                Context 'Testing Set Method' {
                    $PsScomMonitorFrameworkFile.Set()
                    It 'Set should generate a valid PowerShell Data File' {
                        {Import-PowerShellDataFile -LiteralPath 'TestDrive:\data.psd1'} | Should not throw
                    }
                }
            }
            $PsScomMonitorFrameworkFile = $null
        }
        
        PsScomServiceMonitor {
            $PsScomServiceMonitor = [PsScomServiceMonitor]::new()
            $PsScomServiceMonitor.Name = 'W32Time'
            $PsScomServiceMonitor.Ensure = 'Present'
            $PsScomServiceMonitor.FilePath = 'TestDrive:\data.psd1'
            $PsScomServiceMonitor.AlertOwner = 'Servers'
            $PsScomServiceMonitor.MaxCpu = 20
            $PsScomServiceMonitor.NumCpuSamples = 2
            $PsScomServiceMonitor.MaxMemory = 200
            $PsScomServiceMonitor.NumMemorySamples = 5
            
            Describe "Testing $_ methods" {
                Context 'Testing Test Method' {
                    It 'When a file is not present, test should return false' {
                        $PsScomServiceMonitor.Test() | Should be $false
                    }
                    
                    $PsScomServiceMonitor.Set()
                    It 'When the service monitor is present in the desired state Test should return true' {
                        $PsScomServiceMonitor.Test() | Should be $true
                    }
                    
                    $PsScomServiceMonitor.AlertOwner = 'Office'
                    It 'If a property on the service changes, test should return false' {
                        $PsScomServiceMonitor.Test() | Should be $false
                    }
                    $PsScomServiceMonitor.AlertOwner = 'Servers'
                    
                    $PsScomServiceMonitor.Ensure = 'Absent'
                    It 'When ensure is absent and the monitor is currently present in the configuration, set should return false' {
                        $PsScomServiceMonitor.Test() | Should be $false
                    }
                    $PsScomServiceMonitor.Ensure = 'Present'
                }
                
                Context 'Testing Set Method' {
                    
                    $PsScomServiceMonitor.Set()
                    It 'Set should generate a valid PowerShell Data File' {
                        {Import-PowerShellDataFile -LiteralPath 'TestDrive:\data.psd1'} | Should not throw
                    }
                    
                    $import = Import-PowerShellDataFile -LiteralPath 'TestDrive:\data.psd1'
                    It 'Service monitor should be present in the file' {
                        $import.service[$PsScomServiceMonitor.Name] | should BeOfType object
                    }
                    
                    $PsScomServiceMonitor.Ensure = 'Absent'
                    $PsScomServiceMonitor.Set()
                    $import = Import-PowerShellDataFile -LiteralPath 'TestDrive:\data.psd1'
                    
                    It 'Service monitor should be absent in the file if Ensure is set to absent' {
                        $import.service[$PsScomServiceMonitor.Name] | should be $null
                    }
                    $PsScomServiceMonitor.Ensure = 'Present'
                }
            }
            $PsScomServiceMonitor = $null
        }
        
        PsScomPowerShellMonitor {
            $PsScomPowerShellMonitor = [PsScomPowerShellMonitor]::new()
            $PsScomPowerShellMonitor.Name = 'W32Time'
            $PsScomPowerShellMonitor.Ensure = 'Present'
            $PsScomPowerShellMonitor.FilePath = 'TestDrive:\data.psd1'
            $PsScomPowerShellMonitor.AlertOwner = 'Servers'
            $PsScomPowerShellMonitor.IntervalSeconds = 900
            $PsScomPowerShellMonitor.Script = {
                # Just an example scriptblock that doesn't make any sense :)
                $scriptError = Get-Content D:\CriticalLogfile.txt | Where-Object {
                    $_ -like 'Error'
                }

                $alertLevel = If($scriptError) {
                    'Warning'
                }
                else {
                    'Healthy'
                }
        
                [pscustomobject]@{
                    result = $scriptError
                    alertLevel = $alertLevel
                    alertDescription = "An error was detected in CriticalLogfile. These were the lines captured: $scriptError"
                }
            }
            
            Describe "Testing $_ methods" {
                Context 'Testing Test Method' {
                    It 'When a file is not present, test should return false' {
                        $PsScomPowerShellMonitor.Test() | Should be $false
                    }
                    
                    $PsScomPowerShellMonitor.Set()
                    
                    It 'When the PowerShell monitor is present in the desired state Test should return true' {
                        $PsScomPowerShellMonitor.Test() | Should be $true
                    }
                    
                    $PsScomPowerShellMonitor.AlertOwner = 'Office'
                    It 'If a property on the PowerShell monitor changes, test should return false' {
                        $PsScomPowerShellMonitor.Test() | Should be $false
                    }
                    $PsScomPowerShellMonitor.AlertOwner = 'Servers'
                    
                    $PsScomPowerShellMonitor.Ensure = 'Absent'
                    It 'When ensure is absent and the monitor is currently present in the configuration, set should return false' {
                        $PsScomPowerShellMonitor.Test() | Should be $false
                    }
                    $PsScomPowerShellMonitor.Ensure = 'Present'
                }
            
                Context 'Testing Set Method' {
                    $PsScomPowerShellMonitor.Set()
                    It 'Set should generate a valid PowerShell Data File' {
                        {Import-PowerShellDataFile -LiteralPath 'TestDrive:\data.psd1'} | Should not throw
                    }
                    
                    $import = Import-PowerShellDataFile -LiteralPath 'TestDrive:\data.psd1'
                    It 'PowerShell monitor should be present in the file' {
                        $import.powershell[$PsScomPowerShellMonitor.Name] | should BeOfType object
                    }
                    
                    $PsScomPowerShellMonitor.Ensure = 'Absent'
                    $PsScomPowerShellMonitor.Set()
                    $import = Import-PowerShellDataFile -LiteralPath 'TestDrive:\data.psd1'
                    
                    It 'PowerShell monitor should be absent in the file if Ensure is set to absent' {
                        $import.powershell[$PsScomPowerShellMonitor.Name] | should be $null
                    }
                    $PsScomPowerShellMonitor.Ensure = 'Present'
                }
            }
            $PsScomPowerShellMonitor = $null
        }
    }
    
    
    Describe New-PsScomMonitorFrameworkFile {
        $service = [pscustomobject]@{
            Name = 'W32Time'
            AlertOwner = 'Servers'
            MaxCpu = 10
            NumCpuSamples = 2 
            MaxMemory = 0 
            NumMemorySamples = 0
        }
            
        $powershell = [pscustomobject]@{
            Name = 'TestPs'
            AlertOwner = 'OfficeGroup'
            IntervalSeconds = 900
            Script = {
                $scriptError = Get-Content D:\CriticalLogfile.txt | Where-Object {
                    $_ -like 'Error'
                }

                $alertLevel = If($scriptError) {
                    'Critical'
                }
                else {
                    'Healthy'
                }
        
                [pscustomobject]@{
                    result = $scriptError
                    alertLevel = $alertLevel
                    alertDescription = "An error was detected in CriticalLogfile. These were the lines captured: $scriptError"
                }
            }
        }
        $filepath = "TestDrive:\data.psd1"
    
        Context 'New file generated' {
            
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            
            It 'Should be a valid psd1 file' {
                {Import-PowerShellDataFile -Path $filepath} | Should not throw
            }
            
            $import = Import-PowerShellDataFile -Path $filepath
            It 'Service W32Time is in the monitored items list' {
                $import.service['W32time'] | Should not be $null
            }
            
            $testcases = @()
            $service.psobject.Properties.Name | Where-Object {$_ -ne 'Name'} | ForEach-Object {
                $testcases += @{'Parameter' = $_}
            }
            It 'Property <parameter> is set correctly on the service W32time' {
                Param (
                    $Parameter
                )
                
                $import.service['W32time'][$Parameter] | should Be $service.$Parameter
            } -TestCases $testcases
            
            It 'Powershell monitor TestPs is added' {
                $import.powershell['TestPs'] | Should not be $null
            }
            
            $testcases = @()
            $powershell.psobject.Properties.Name | Where-Object {$_ -notin 'Name','Script'} | ForEach-Object {
                $testcases += @{'Parameter' = $_}
            }
            It 'Property <parameter> is set correctly on the PowerShell Monitor TestPs' {
                Param (
                    $Parameter
                )
                
                $import.powershell['TestPs'][$Parameter] | should Be $powershell.$Parameter
            } -TestCases $testcases
            
            It 'Script is PowerShell monitor is a ScriptBlock' {
                $powershell.Script.GetType().Name | should be ScriptBlock
            }
        }
    }
    
    Describe Update-PsScomMonitorFrameworkFile {
        $service = [pscustomobject]@{
            Name = 'W32Time'
            AlertOwner = 'Servers'
            MaxCpu = 10
            NumCpuSamples = 2 
            MaxMemory = 0 
            NumMemorySamples = 0
        }
        
        $serviceChange = [pscustomobject]@{
            Name = 'W32Time'
            AlertOwner = 'OfficeGroup'
            MaxCpu = 20
            NumCpuSamples = 5
            MaxMemory = 50 
            NumMemorySamples = 2
        }
        
        $serviceAdd = [pscustomobject]@{
            Name = 'bits'
            AlertOwner = 'OfficeGroup'
            MaxCpu = 20
            NumCpuSamples = 5
            MaxMemory = 50 
            NumMemorySamples = 2
        }
        
        $powershell = [pscustomobject]@{
            Name = 'TestPs'
            AlertOwner = 'OfficeGroup'
            IntervalSeconds = 900
            Script = {
                $scriptError = Get-Content D:\CriticalLogfile.txt | Where-Object {
                    $_ -like 'Error'
                }

                $alertLevel = If($scriptError) {
                    'Critical'
                }
                else {
                    'Healthy'
                }
        
                [pscustomobject]@{
                    result = $scriptError
                    alertLevel = $alertLevel
                    alertDescription = "An error was detected in CriticalLogfile. These were the lines captured: $scriptError"
                }
            }
        }
            
        $powershellChange = [pscustomobject]@{
            Name = 'TestPs'
            AlertOwner = 'OfficeGroup'
            IntervalSeconds = 1800
            Script = {
                $scriptError = Get-Content D:\CriticalLogfile.txt | Where-Object {
                    $_ -like 'Error'
                }

                $alertLevel = If($scriptError) {
                    'Warning'
                }
                else {
                    'Healthy'
                }
        
                [pscustomobject]@{
                    result = $scriptError
                    alertLevel = $alertLevel
                    alertDescription = "An error was detected in CriticalLogfile. These were the lines captured: $scriptError"
                }
            }
        }
        
        $powershellAdd = [pscustomobject]@{
            Name = 'secondTestPs'
            AlertOwner = 'Servers'
            IntervalSeconds = 1800
            Script = {
                $scriptError = Get-Content D:\CriticalLogfile.txt | Where-Object {
                    $_ -like 'Error'
                }

                $alertLevel = If($scriptError) {
                    'Warning'
                }
                else {
                    'Healthy'
                }
        
                [pscustomobject]@{
                    result = $scriptError
                    alertLevel = $alertLevel
                    alertDescription = "An error was detected in CriticalLogfile. These were the lines captured: $scriptError"
                }
            }
        }
        
        $filepath = "TestDrive:\data.psd1"
        
        Context 'Service updated' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            Update-PsScomMonitorFrameworkFile -Service $serviceChange -FilePath $filepath -Action Update
            
            $import = Import-PowerShellDataFile $filepath
            
            $testcases = @()
            $serviceChange.psobject.Properties.Name | Where-Object {$_ -ne 'Name'} | ForEach-Object {
                $testcases += @{'Parameter' = $_}
            }
            It 'Property <parameter> is updated on the service W32time' {
                Param (
                    $Parameter
                )
                
                $import.service['W32time'][$Parameter] | should Be $serviceChange.$Parameter
            } -TestCases $testcases
        }
        
        Context 'Service removed' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            Update-PsScomMonitorFrameworkFile -Service $serviceChange -FilePath $filepath -Action Remove
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'Service is no longer present in the monitoring file' {
                $import.service['W32time'] | should be $null
            }
        }
        
        Context 'Service added' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            Update-PsScomMonitorFrameworkFile -Service $serviceAdd -FilePath $filepath -Action Update
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'Service is added to the monitoring file' {
                $import.service.count| should be 2
            }
            
            $testcases = @()
            $serviceAdd.psobject.Properties.Name | Where-Object {$_ -ne 'Name'} | ForEach-Object {
                $testcases += @{'Parameter' = $_}
            }
            It 'Property <parameter> is set on the added service' {
                Param (
                    $Parameter
                )
                
                $import.service['bits'][$Parameter] | should Be $serviceChange.$Parameter
            } -TestCases $testcases
        }
        
       Context 'Service added to non existing Scom Monitor Framework File - this should just generate the file' {
            Update-PsScomMonitorFrameworkFile -Service $serviceAdd -FilePath $filepath -Action Update
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'Service is added to the monitoring file' {
                $import.service.count| should be 1
            }
            
            $testcases = @()
            $serviceAdd.psobject.Properties.Name | Where-Object {$_ -ne 'Name'} | ForEach-Object {
                $testcases += @{'Parameter' = $_}
            }
            It 'Property <parameter> is set on the added service' {
                Param (
                    $Parameter
                )
                
                $import.service['bits'][$Parameter] | should Be $serviceChange.$Parameter
            } -TestCases $testcases
        }
        
        Context 'PowerShell Monitor updated' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            Update-PsScomMonitorFrameworkFile -PowerShellMonitor $powerShellChange -FilePath $filepath -Action Update
            
            $import = Import-PowerShellDataFile $filepath
            
            $testcases = @()
            $powerShellChange.psobject.Properties.Name | Where-Object {$_ -notin 'Name','Script'} | ForEach-Object {
                $testcases += @{'Parameter' = $_}
            }
            It 'Property <parameter> is updated on the PowerShell monitor TestPs' {
                Param (
                    $Parameter
                )
                
                $import.powershell['TestPs'][$Parameter] | should Be $powerShellChange.$Parameter
            } -TestCases $testcases
            
            It 'The scriptblock in the PowerShell monitor got updated' {
                $currentScriptBlock = ($import.powershell['testPs'].script.StartPosition.Content.ToString().Split("`r`n").TrimStart(' ') | Where-Object {-not([string]::IsNullOrWhiteSpace($_))}) -join "`r`n"
                $updatedScriptBlock = ($powerShellChange.script.StartPosition.Content.ToString().Split("`r`n").TrimStart(' ') | Where-Object {-not([string]::IsNullOrWhiteSpace($_))}) -join "`r`n"
                
                $currentScriptBlock | should be $updatedScriptBlock
            }
        }
        
        Context 'PowerShell Monitor removed' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            Update-PsScomMonitorFrameworkFile -PowerShellMonitor $powerShellChange -FilePath $filepath -Action Remove
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'PowerShell monitor is no longer present in the monitoring file' {
                $import.powershell['TestPs'] | should be $null
            }
        }
        
        Context 'PowerShell Monitor added' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            Update-PsScomMonitorFrameworkFile -PowerShellMonitor $powerShellAdd -FilePath $filepath -Action Update
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'PowerShell monitor is added to the monitoring file' {
                $import.powershell.count| should be 2
            }
            
            $testcases = @()
            $powerShellAdd.psobject.Properties.Name | Where-Object {$_ -notin 'Name','Script'} | ForEach-Object {
                $testcases += @{'Parameter' = $_}
            }
            It 'Property <parameter> is set on the added service' {
                Param (
                    $Parameter
                )
                
                $import.powershell['secondTestPs'][$Parameter] | should Be $powerShellAdd.$Parameter
            } -TestCases $testcases
        }
        
        Context 'Running update with WhatIf' {
            
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            Update-PsScomMonitorFrameworkFile -Service $serviceAdd -FilePath $filepath -Action Update -WhatIf
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'Service is not added to the monitoring file (the file is not updated)' {
                $import.service.count| should be 1
            }
        }
        
        Context 'Running update with ReportOnly' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            $report = Update-PsScomMonitorFrameworkFile -Service $serviceChange -FilePath $filepath -Action Update -ReportOnly
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'Parameters on the service should not have changed' {
                $import.service.count| should be 1
            }
            It 'Report is generated with the changes' {
                $report['W32Time.AlertOwner'] | Should not be $null
            }
        }
        
        Context 'Running removal with ReportOnly' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            $report = Update-PsScomMonitorFrameworkFile -Service $service -FilePath $filepath -Action Remove -ReportOnly
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'Service is not removed from the monitoring file' {
                $import.service.count| should be 1
            }
            It 'Report is generated with the changes' {
                $report['W32Time'] | Should not be $null
            }
        }
        
        Context 'Running addition with ReportOnly' {
            New-PsScomMonitorFrameworkFile -Service $service -PowerShellMonitor $powershell -FilePath $filepath
            $report = Update-PsScomMonitorFrameworkFile -Service $serviceAdd -FilePath $filepath -Action Update -ReportOnly
            
            $import = Import-PowerShellDataFile $filepath
            
            It 'Service is not added to the monitoring file' {
                $import.service.count| should be 1
            }
            It 'Report is generated with the changes' {
                $report['bits'] | Should not be $null
            }
        }
    }
}