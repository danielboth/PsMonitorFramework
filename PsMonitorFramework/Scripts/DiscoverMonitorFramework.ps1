param (
	[string]$FilePath
)

$ErrorActionPreference = 'Stop'
$api = New-Object -ComObject MOM.ScriptAPI

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
		[string]$ScriptName = 'DiscoverMonitorFramework.ps1'
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

$discoveryData = $api.CreateDiscoveryData(0, '$MPElement$', '$Target/Id$')
If(Test-Path $FilePath){
	Try {
		$monitorData = Import-PowerShellDataFile -LiteralPath $Filepath
	}
	Catch {
		Write-OPScomEvent -Message "Failed to monitor datafile from path $FilePath - $_" -Severity 1 -EventId 2002
		throw $_
	}
}

If($monitorData){
	# Discover services
	$monitorData.service.GetEnumerator().ForEach({
		$instance = $discoveryData.CreateClassInstance('$MPElement[Name="Ps.MonitorFramework.Service"]$')

		$instance.AddProperty(
			'$MPElement[Name="MSNL!Microsoft.SystemCenter.NTService"]/ServiceName$',
			$_.Name
		)

		$instance.AddProperty(
			'$MPElement[Name="Windows!Microsoft.Windows.Computer"]/PrincipalName$',
			'$Target/Property[Type="Windows!Microsoft.Windows.Computer"]/PrincipalName$'
		)

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.Service"]/Name$', 
			$_.Name
		)

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.Service"]/AlertOwner$', 
			$_.Value['AlertOwner']
		)

		$maxCpuValue = If($_.Value['MaxCpu']){
			$_.Value['MaxCpu']
		}
		else {
			0
		}

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.Service"]/MaxCpu$', 
			$maxCpuValue
		)

		$numCpuSamplesValue = If($_.Value['numCpuSamples']){
			$_.Value['numCpuSamples']
		}
		else {
			0
		}

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.Service"]/numCpuSamples$', 
			$numCpuSamplesValue
		)


		$maxMemoryValue = If($_.Value['MaxMemory']){
			$_.Value['MaxMemory']
		}
		else {
			0
		}

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.Service"]/MaxMemory$', 
			$maxMemoryValue
		)

		$numMemorySamplesValue = If($_.Value['numMemorySamples']){
			$_.Value['numMemorySamples']
		}
		else {
			0
		}

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.Service"]/numMemorySamples$', 
			$numMemorySamplesValue
		)
    
		$instance.AddProperty(
			'$MPElement[Name="System!System.Entity"]/DisplayName$',
			"$($_.Name) Service"
		)

		Write-OPScomEvent -Message "Adding discoveryData for $($_.Name)" -Severity 0 -EventId 1000
		$discoveryData.AddInstance($instance)
	})

	# Discover PowerShell monitoring
	$monitorData.powerShell.GetEnumerator().ForEach({
		$instance = $discoveryData.CreateClassInstance('$MPElement[Name="Ps.MonitorFramework.PowerShell"]$')

		$instance.AddProperty(
			'$MPElement[Name="Windows!Microsoft.Windows.Computer"]/PrincipalName$',
			'$Target/Property[Type="Windows!Microsoft.Windows.Computer"]/PrincipalName$'
		)

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.PowerShell"]/Name$', 
			$_.Name
		)

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.PowerShell"]/FilePath$', 
			$FilePath
		)

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.PowerShell"]/AlertOwner$', 
			$_.Value['AlertOwner']
		)

		$instance.AddProperty(
			'$MPElement[Name="Ps.MonitorFramework.PowerShell"]/IntervalSeconds$', 
			$_.Value['IntervalSeconds']
		)

		$instance.AddProperty(
			'$MPElement[Name="System!System.Entity"]/DisplayName$',
			"$($_.Name)"
		)

		Write-OPScomEvent -Message "Adding discoveryData for $($_.Name)" -Severity 0 -EventId 1000
		$discoveryData.AddInstance($instance)
	})

	If($monitorData.powerShellRule) {
		$monitorData.powerShellRule.GetEnumerator().ForEach({
			$instance = $discoveryData.CreateClassInstance('$MPElement[Name="Ps.MonitorFramework.PowerShellRule"]$')

			$instance.AddProperty(
				'$MPElement[Name="Windows!Microsoft.Windows.Computer"]/PrincipalName$',
				'$Target/Property[Type="Windows!Microsoft.Windows.Computer"]/PrincipalName$'
			)

			$instance.AddProperty(
				'$MPElement[Name="Ps.MonitorFramework.PowerShellRule"]/Name$', 
				$_.Name
			)

			$instance.AddProperty(
				'$MPElement[Name="Ps.MonitorFramework.PowerShellRule"]/AlertOwner$', 
				$_.Value['AlertOwner']
			)

			$instance.AddProperty(
				'$MPElement[Name="Ps.MonitorFramework.PowerShellRule"]/IntervalSeconds$', 
				$_.Value['IntervalSeconds']
			)

			$instance.AddProperty(
				'$MPElement[Name="System!System.Entity"]/DisplayName$',
				"$($_.Name)"
			)

			Write-OPScomEvent -Message "Adding discoveryData for $($_.Name)" -Severity 0 -EventId 1000
			$discoveryData.AddInstance($instance)
		})
	}
	
	$discoveryData
}