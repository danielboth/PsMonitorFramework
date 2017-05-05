param (
	# The name of the PowerShell Monitor to execute
	[Parameter(Mandatory)]
    [string]$Name,

	# The path to the PSD1 file where the PowerShell Monitor can be found.
	[Parameter(Mandatory)]
    [string]$FilePath
)

function Write-OPScomEvent {
    param (
        # Messsage that will be used in the event
        [Parameter(Mandatory)]
        [string]$Message,

        # Int for level: 0 -> Information, 1 -> Error, 2 ->  Warning
        [ValidateRange(0,2)]
        [Int]$Severity = 0,

        # Id of event in the event log
        [Int]$EventId = 1001,

        # Name of the script where event happened
        [string]$ScriptName = 'MonitorPowerShell.ps1'
    )
    # Information is written only if there is registry key for the current script...
    if (
        $Severity -ne 0 -or
        (Test-Path -LiteralPath "HKLM:\SOFTWARE\Ps\MonitorFramework\$ScriptName") 
    ) {
        $api.LogScriptEvent(
            $ScriptName,
            $EventId,
            $Severity,
            $Message
        )
    } 
}

$api = New-Object -ComObject MOM.ScriptAPI

$ErrorActionPreference = 'Stop'

# Get the PowerShell script code to run from the MonitorData file.
$powerShellMonitor = (Import-PowerShellDataFile -LiteralPath $FilePath).powerShell[$Name]

If(-not($powerShellMonitor)) {
	Write-OPScomEvent -Message "Could not find PowerShell Monitor $Name on path $FilePath. Check is not executed" -Severity 2 -EventId 2005
	exit
}

Try {
	[string]$script = & $powerShellMonitor.script
	$scriptOutput = & ([scriptblock]::Create($script))
}
Catch {
	 Write-OPScomEvent -Message "Error executing MonitorFramework PowerShell check $Name. Error: $_. Please review the script." -Severity 1 -EventId 2005
	 Throw "Error executing MonitorFramework PowerShell check $Name. Error: $_. Please review the script."
}

# Check the scriptOutput, if any items are not of type int, string or bool, cast them to string.
$dataTypes = @(
	'String',
	'Int32',
	'Boolean'
)

$AlertDescription = If($scriptOutput.alertDescription.GetType().Name -notin $dataTypes) {
    ($scriptOutput.alertDescription -as [string])
} else {
    $scriptOutput.alertDescription
}

$result = If(-not($scriptOutput.Result -is [int])) {
    ($scriptOutput.Result -as [int])
} else {
    $scriptOutput.Result
}

If($scriptOutput.alertLevel -notin 'Healthy','Warning','Critical') {
    Write-OPScomEvent -Message "PowerShell check $Name did not output any of the expected health states (Healthy, Warning, Critical). Please review the script." -Severity 1 -EventId 2004
    Throw "PowerShell check $Name did not output any of the expected health states (Healthy, Warning, Critical). Please review the script."
}

$bag = $api.CreatePropertyBag()
$bag.AddValue('AlertDescription',$AlertDescription)
$bag.AddValue('AlertLevel',$scriptOutput.alertLevel)
$bag.AddValue('Result',$result)

Write-Output $bag