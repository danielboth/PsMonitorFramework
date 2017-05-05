foreach ($item in Get-ChildItem -Path $PSScriptRoot\*.ps1) {
    . $item.FullName
}

enum Ensure {
    Present
    Absent
}

[DscResource()]
class PsScomMonitorFrameworkFile {
    [DscProperty(Key)]
    [string]$FilePath
    
    [DscProperty(Mandatory)]
    [Ensure]$Ensure
    
    [PsScomMonitorFrameworkFile] Get () {
    
        return [PsScomMonitorFrameworkFile]@{
            Ensure = $this.Ensure
            FilePath = $this.FilePath
        }
    }
    
    [bool] Test () {
        If($this.Ensure -eq 'Present') {
            return (Test-Path $this.FilePath)
        }
        Else {
            return -not(Test-Path $this.FilePath)
        }
    }
    
    [void] Set () {
        Try {
            If($this.Ensure -eq 'Present') {
                New-PsScomMonitorFrameworkFile -FilePath $this.FilePath -ErrorAction Stop
            }
            Else {
                Remove-Item -LiteralPath $this.FilePath -Force -ErrorAction Stop
            }
        }
        Catch {
            Write-Error "Failed to set PsScomMonitorFrameworkFile to state $($this.Ensure). Error: $_"
        }
    }
}


[DscResource()]
class PsScomServiceMonitor {
    
    #region class properties
    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Key)]
    [string]$FilePath
    
    [DscProperty(Mandatory)]
    [string]$AlertOwner

    [DscProperty()]
    [int]$MaxCpu

    [DscProperty()]
    [int]$NumCpuSamples
    
    [DscProperty()]
    [int]$MaxMemory

    [DscProperty()]
    [int]$NumMemorySamples
    
    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    #endregion
    
    #region Standard methods
    
    [PsScomServiceMonitor] Get () {
    
        Try {
            $service = (Import-PowerShellDataFile -Path $this.FilePath).service[$this.Name]
        }
        Catch {
            $service = $null
        }
        
        return [PsScomServiceMonitor]@{
            Name = $this.Name
            FilePath = $this.FilePath
            AlertOwner = $service.AlertOwner
            MaxCpu = $service.MaxCpu
            NumCpuSamples = $service.NumCpuSamples
            MaxMemory = $service.MaxMemory
            NumMemorySamples = $service.NumMemorySamples
        }
    }
    
    [bool] Test () {
        $service = $this.GetObject()
        
        Try {
            $changes = If($this.Ensure -eq 'Present') {
                Update-PsScomMonitorFrameworkFile -FilePath $this.FilePath -Service $service -Action Update -ReportOnly -ErrorAction Stop
            }
            else {
                Update-PsScomMonitorFrameworkFile -FilePath $this.FilePath -Service $service -Action Remove -ReportOnly -ErrorAction Stop
            }
        }
        Catch {
            # If we encounter errors here, probably better to just regenerate the file.
            return $false
        }
        
        If($changes) {
            $changes.Keys | ForEach-Object {
                Write-Verbose "Not in desired state: $($_) performing: $($changes[$_])"
            }
            return $false
        }
        
        return $true
    }
    
    [void] Set () {
        $service = $this.GetObject()
        Try{
            If($this.Ensure -eq 'Present') {
                Update-PsScomMonitorFrameworkFile -FilePath $this.FilePath -Service $service -Action Update -ErrorAction Stop
            }
            else {
                Update-PsScomMonitorFrameworkFile -FilePath $this.FilePath -Service $service -Action Remove -ErrorAction Stop
            }
        }
        Catch {
            Write-Error "Error updating SCOM Monitor Framework File: $_"
        }

    }
    
    [pscustomobject] GetObject () {
        $object = [pscustomobject]@{
            Name = $this.Name
            AlertOwner = $this.AlertOwner
            MaxCpu = $this.MaxCpu
            NumCpuSamples = $this.NumCpuSamples
            MaxMemory = $this.MaxMemory
            NumMemorySamples = $this.NumMemorySamples
        }
        
        return $object
    }
    
    #endregion
       
}

[DscResource()]
class PsScomPowerShellMonitor {
    
    #region class properties
    [DscProperty(Key)]
    [string]$Name

    [DscProperty(Mandatory)]
    [string]$FilePath
    
    [DscProperty(Mandatory)]
    [string]$AlertOwner

    [DscProperty(Mandatory)]
    [string]$Script

    [DscProperty(Mandatory)]
    [int]$IntervalSeconds
    
    [DscProperty(Mandatory)]
    [Ensure]$Ensure

    #endregion
    
    #region Standard methods
    
    [PsScomPowerShellMonitor] Get () {
        Try{    
            $powershell = (Import-PowerShellDataFile -Path $this.FilePath).powershell[$this.Name]
        }
        Catch {
            $powershell = $null
        }
        
        return [PsScomPowerShellMonitor]@{
            Name = $this.Name
            FilePath = $this.FilePath
            AlertOwner = $powershell.AlertOwner
            Script = $powershell.Script
            IntervalSeconds = $powershell.IntervalSeconds
        }
    }
    
    [bool] Test () {
        $powershell = $this.GetObject()
        
        Try{
            $changes = If($this.Ensure -eq 'Present') {
                Update-PsScomMonitorFrameworkFile -FilePath $this.FilePath -PowerShellMonitor $powershell -Action Update -ReportOnly -ErrorAction Stop
            }
            else {
                Update-PsScomMonitorFrameworkFile -FilePath $this.FilePath -PowerShellMonitor $powershell -Action Remove -ReportOnly -ErrorAction Stop
            }
        }
        Catch {
            # If we encounter errors here, probably better to just regenerate the file.
            return $false
        }
        
        If($changes) {
            $changes.Keys | ForEach-Object {
                Write-Verbose "Not in desired state: $($_) performing: $($changes[$_])"
            }
            return $false
        }
        
        return $true
    }
    
    [void] Set () {
        $powershell = $this.GetObject()
        
        Try {
            If($this.Ensure -eq 'Present') {
                Update-PsScomMonitorFrameworkFile -FilePath $this.FilePath -PowerShellMonitor $powershell -Action Update -ErrorAction Stop
            }
            else {
                Update-PsScomMonitorFrameworkFile -FilePath $this.FilePath -PowerShellMonitor $powershell -Action Remove -ErrorAction Stop
            }
        }
        Catch {
            Write-Error "Error updating SCOM Monitor Framework File: $_"
        }
    }
    
    [pscustomobject] GetObject () {
        $object = [pscustomobject]@{
            Name = $this.Name
            AlertOwner = $this.AlertOwner
            Script = [scriptblock]::Create("$($this.Script)")
            IntervalSeconds = $this.IntervalSeconds
        }
        
        return $object
    }
    
    #endregion
}