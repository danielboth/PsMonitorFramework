@{
    service = @{
        'W32Time' = @{
        
            AlertOwner = 'ServersDelivery'
            MaxCpu = 40
            numCpuSamples = 5
        }
        'bits' = @{
            AlertOwner = 'ServersDelivery'
        }
    }
    event = @{
	}

    powershell = @{
        
        'PowerShell Log monitor' = @{

            # The PowerShell script should output 3 properties:
            # AlertLevel = Healthy, Warning, Critical - The script must implement at least 2 of the 3 levels, always including Healthy
            # AlertDescription = The description used in the generated alert
            # Result = The raw result of the script
            script = {
                $result, $alertLevel = If(Get-Content d:\temp\scom\test.log | Where-Object {$_ -match 'Error'}) {
                    1, 'Critical'
                }
                else {
                    0, 'Healthy'
                }

                [pscustomobject]@{
                    result = $result
                    alertLevel = $alertLevel
                    alertDescription = 'The error in the logfile'
                }
            }

            AlertOwner = 'ServersDelivery'
            IntervalSeconds = 900
        }

        'DevEnv memory usage' = @{
            script = {
                $devEnvMemory = Get-Process -Name devenv | Where-Object {$_.WorkingSet -ge 200000000 }

                If($devEnvMemory){
                    $result = $devEnvMemory.WorkingSet
                    $alertLevel = 'Warning'
                    [string]$alertDescription += "DevEnv processes found with a memory usage higher than the threshold:"
                    [string]$alertDescription += $devEnvMemory | ForEach-Object {
                        "`n`r Process ID: $($_.Id) - Usage: $([int]($_.WorkingSet/1MB)) MB"
                    }
                }
                Else {
                    $alertLevel = 'Healthy'
                    $result = 'OK'
                    $alertDescription = 'No DevEnv processes with high memoryusage'
                }

                [pscustomobject]@{
                    result = $result
                    alertLevel = $alertLevel
                    alertDescription = $alertDescription
                }
            }

            AlertOwner = 'ServersDelivery'
            IntervalSeconds = 900
        }
    }
}