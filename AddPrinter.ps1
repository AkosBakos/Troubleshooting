<#
.SYNOPSIS
	This script performs the installation or uninstallation of an application(s).
	# LICENSE #
	PowerShell App Deployment Toolkit - Provides a set of functions to perform common application deployment tasks on Windows.
	Copyright (C) 2017 - Sean Lillis, Dan Cunningham, Muhammad Mashwani, Aman Motazedian.
	This program is free software: you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation, either version 3 of the License, or any later version. This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
	You should have received a copy of the GNU Lesser General Public License along with this program. If not, see <http://www.gnu.org/licenses/>.
.DESCRIPTION
	The script is provided as a template to perform an install or uninstall of an application(s).
	The script either performs an "Install" deployment type or an "Uninstall" deployment type.
	The install deployment type is broken down into 3 main sections/phases: Pre-Install, Install, and Post-Install.
	The script dot-sources the AppDeployToolkitMain.ps1 script which contains the logic and functions required to install or uninstall an application.
.PARAMETER DeploymentType
	The type of deployment to perform. Default is: Install.
.PARAMETER DeployMode
	Specifies whether the installation should be run in Interactive, Silent, or NonInteractive mode. Default is: Interactive. Options: Interactive = Shows dialogs, Silent = No dialogs, NonInteractive = Very silent, i.e. no blocking apps. NonInteractive mode is automatically set if it is detected that the process is not user interactive.
.PARAMETER AllowRebootPassThru
	Allows the 3010 return code (requires restart) to be passed back to the parent process (e.g. SCCM) if detected from an installation. If 3010 is passed back to SCCM, a reboot prompt will be triggered.
.PARAMETER TerminalServerMode
	Changes to "user install mode" and back to "user execute mode" for installing/uninstalling applications for Remote Destkop Session Hosts/Citrix servers.
.PARAMETER DisableLogging
	Disables logging to file for the script. Default is: $false.
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeployMode 'Silent'; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -AllowRebootPassThru; Exit $LastExitCode }"
.EXAMPLE
    powershell.exe -Command "& { & '.\Deploy-Application.ps1' -DeploymentType 'Uninstall'; Exit $LastExitCode }"
.EXAMPLE
    Deploy-Application.exe -DeploymentType "Install" -DeployMode "Silent"
.NOTES
	Toolkit Exit Code Ranges:
	60000 - 68999: Reserved for built-in exit codes in Deploy-Application.ps1, Deploy-Application.exe, and AppDeployToolkitMain.ps1
	69000 - 69999: Recommended for user customized exit codes in Deploy-Application.ps1
	70000 - 79999: Recommended for user customized exit codes in AppDeployToolkitExtensions.ps1
.LINK
	http://psappdeploytoolkit.com
#>
[CmdletBinding()]
Param (
	[Parameter(Mandatory=$false)]
	[ValidateSet('Install','Uninstall','Repair')]
	[string]$DeploymentType = 'Install',
	[Parameter(Mandatory=$false)]
	[ValidateSet('Interactive','Silent','NonInteractive')]
	[string]$DeployMode = 'Interactive',
	[Parameter(Mandatory=$false)]
	[switch]$AllowRebootPassThru = $false,
	[Parameter(Mandatory=$false)]
	[switch]$TerminalServerMode = $false,
	[Parameter(Mandatory=$false)]
	[switch]$DisableLogging = $false
)

Try {
	## Set the script execution policy for this process
	Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force -ErrorAction 'Stop' } Catch {}

	##*===============================================
	##* VARIABLE DECLARATION
	##*===============================================
	## Variables: Application
	[string]$appVendor = 'HP'
	[string]$appName = 'Universal Printing PCL 6'
	[string]$appVersion = '1.0'
	[string]$appArch = '64'
	[string]$appLang = 'EN'
	[string]$appRevision = '01'
	[string]$appScriptVersion = '1.0.0'
	[string]$appScriptDate = '28.02.2022'
	[string]$appScriptAuthor = 'Ákos Bakos, SmartCon GmbH'
	##*===============================================
	## Variables: Install Titles (Only set here to override defaults set by the toolkit)
	[string]$installName = ''
	[string]$installTitle = ''

	##* Do not modify section below
	#region DoNotModify

	## Variables: Exit Code
	[int32]$mainExitCode = 0

	## Variables: Script
	[string]$deployAppScriptFriendlyName = 'Deploy Application'
	[version]$deployAppScriptVersion = [version]'3.8.4'
	[string]$deployAppScriptDate = '26/01/2021'
	[hashtable]$deployAppScriptParameters = $psBoundParameters

	## Variables: Environment
	If (Test-Path -LiteralPath 'variable:HostInvocation') { $InvocationInfo = $HostInvocation } Else { $InvocationInfo = $MyInvocation }
	[string]$scriptDirectory = Split-Path -Path $InvocationInfo.MyCommand.Definition -Parent

	## Dot source the required App Deploy Toolkit Functions
	Try {
		[string]$moduleAppDeployToolkitMain = "$scriptDirectory\AppDeployToolkit\AppDeployToolkitMain.ps1"
		If (-not (Test-Path -LiteralPath $moduleAppDeployToolkitMain -PathType 'Leaf')) { Throw "Module does not exist at the specified location [$moduleAppDeployToolkitMain]." }
		If ($DisableLogging) { . $moduleAppDeployToolkitMain -DisableLogging } Else { . $moduleAppDeployToolkitMain }
	}
	Catch {
		If ($mainExitCode -eq 0){ [int32]$mainExitCode = 60008 }
		Write-Error -Message "Module [$moduleAppDeployToolkitMain] failed to load: `n$($_.Exception.Message)`n `n$($_.InvocationInfo.PositionMessage)" -ErrorAction 'Continue'
		## Exit the script, returning the exit code to SCCM
		If (Test-Path -LiteralPath 'variable:HostInvocation') { $script:ExitCode = $mainExitCode; Exit } Else { Exit $mainExitCode }
	}

	#endregion
	##* Do not modify section above
	##*===============================================
	##* END VARIABLE DECLARATION
	##*===============================================

	If ($deploymentType -ine 'Uninstall' -and $deploymentType -ine 'Repair') {
		##*===============================================
		##* PRE-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Installation'
	    Show-InstallationWelcome -CloseApps 'iexplore' -silent

		## <Perform Pre-Installation tasks here>

		##*===============================================
		##* INSTALLATION
		##*===============================================
		[string]$installPhase = 'Installation'

		## <Perform Installation tasks here>
		#Stage driver to driver store
		Try {
			Write-Log -Message "Stage driver files to Windows driver store"
			$INFARGS = @(
						"/add-driver"
						"$dirSupportFiles\hpypclms32_v4.inf"
					)
			#Execute-Process $dirSupportFiles\pcl6-x64-7.0.1.24923\Install.exe -Parameters "/infstage /h /q" -WindowStyle Hidden
			Start-Process pnputil.exe -ArgumentList $INFARGS -Wait -PassThru
		}   
		Catch {
			Write-Log -Message "Error staging driver to Driver Store"
			Write-Log -Message  "$($_.Exception.Message)"
		}

        #Write-Log -Message "Find driver full path"
        #Get-WindowsDriver -All -Online | Where-Object {$_.OriginalFileName -like '*eSf6u.inf'} | Select-Object -ExpandProperty OriginalFileName -OutVariable infPath

		#Install driver
		$DriverName = "HP Universal Printing PCL 6"
		Try {
			$DriverExist = Get-PrinterDriver -Name $DriverName -ErrorAction SilentlyContinue
			if (-not $DriverExist) {
				Write-Log -Message "Adding Printer Driver"
				Add-PrinterDriver -Name $DriverName -Confirm:$false
			}
			else {
				Write-Log -Message "Print Driver ""$($DriverName)"" already exists. Skipping driver installation."
			}
		}   
		Catch {
		Write-Log -Message "Error installing Printer Driver"
		Write-Log -Message  "$($_.Exception.Message)"
		}

		#Create Printer Port in room HE1 010
		$PortName = "IP_10.16.15.33"
		$PrinterIP = "10.16.15.33"
		Try {
			$PortExist = Get-Printerport -Name $PortName -ErrorAction SilentlyContinue
			if (-not $PortExist) {
				Write-Log -Message "Adding Port ""$($PortName)"""
				Add-PrinterPort -Name $PortName -PrinterHostAddress $PrinterIP -Confirm:$false
			}
			else {
				Write-Log -Message "Port ""$($PortName)"" already exists. Skipping Printer Port installation."
			}
		}
		Catch{
			Write-Log -Message "Error creating Printer Port"
			Write-Log -Message "$($_.Exception.Message)"
		}

		#Add printer
		$PrinterName = "GYMWG-PRN001"
		Try {
			$PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
			if (-not $PrinterExist) {
				Write-Log -Message "Adding Printer ""$($PrinterName)"""
				Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
			}
			else {
				Write-Log -Message "Printer ""$($PrinterName)"" already exists. Removing old printer..."
				Remove-Printer -Name $PrinterName -Confirm:$false
				Write-Log -Message "Adding Printer ""$($PrinterName)"""
				Add-Printer -Name $PrinterName -DriverName $DriverName -PortName $PortName -Confirm:$false
			}

			$PrinterExist2 = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
			if ($PrinterExist2) {
				Write-Log -Message "Printer ""$($PrinterName)"" added successfully"
			}
			else {
				Write-Log -Message "Error creating Printer"
				Write-Log -Message "Printer ""$($PrinterName)"" error creating printer"
			}
		}
		Catch{
			Write-Log -Message "Error creating Printer"
			Write-Log -Message "$($_.Exception.Message)"
		}

		##*===============================================
		##* POST-INSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Installation'
        
		## <Perform Post-Installation tasks here>
        Write-Log -Message "Create some detection rule"
        New-Item -Path C:\ProgramData\Microsoft\IntuneManagementExtension\Logs -Name "HP_Universal_Printer_Driver_installed.log" -ItemType File
        
		## Display a message at the end of the install
		If (-not $useDefaultMsi) { Show-InstallationPrompt -Message 'You can customize text to appear at the end of an install or remove it completely for unattended installations.' -ButtonRightText 'OK' -Icon Information -NoWait }
	}
	ElseIf ($deploymentType -ieq 'Uninstall')
	{
		##*===============================================
		##* PRE-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Pre-Uninstallation'
		
        Show-InstallationWelcome -CloseApps 'iexplore' -silent

		## Show Progress Message (with the default message)
		## Show-InstallationProgress

		## <Perform Pre-Uninstallation tasks here>

		##*===============================================
		##* UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Uninstallation'

		# <Perform Uninstallation tasks here>

		#Remove printer
		$PrinterName ="GYMWG-PRN001"
		try {
			$PrinterExist = Get-Printer -Name $PrinterName -ErrorAction SilentlyContinue
			if ($PrinterExist) {
				Remove-Printer -Name $PrinterName -Confirm:$false
			}
		}
		catch {
			Write-Log -Message "Error removing printer"
			Write-Log -Message "$($_.Exception.Message)"
		}

		#Remove printe rdriver
		try {
			Write-Log -Message "HP Universal Printing PCL 6"
			Remove-PrinterDriver -Name "HP Universal Printing PCL 6"
		}
		catch {
			Write-Log -Message "Error removing printer driver"
			Write-Log -Message "$($_.Exception.Message)"
		}

		##*===============================================
		##* POST-UNINSTALLATION
		##*===============================================
		[string]$installPhase = 'Post-Uninstallation'

		## <Perform Post-Uninstallation tasks here>
        Write-Log -Message "Remove detection rule"
        Remove-Item -Path "C:\ProgramData\Microsoft\IntuneManagementExtension\Logs\HP_Universal_Printer_Driver_installed.log"
	}
	ElseIf ($deploymentType -ieq 'Repair')
	{
		##*===============================================
		##* PRE-REPAIR
		##*===============================================
		[string]$installPhase = 'Pre-Repair'

		## Show Progress Message (with the default message)
		Show-InstallationProgress

		## <Perform Pre-Repair tasks here>

		##*===============================================
		##* REPAIR
		##*===============================================
		[string]$installPhase = 'Repair'

		# <Perform Repair tasks here>

		##*===============================================
		##* POST-REPAIR
		##*===============================================
		[string]$installPhase = 'Post-Repair'

		## <Perform Post-Repair tasks here>

    }
	##*===============================================
	##* END SCRIPT BODY
	##*===============================================

	## Call the Exit-Script function to perform final cleanup operations
	Exit-Script -ExitCode $mainExitCode
}
Catch {
	[int32]$mainExitCode = 60001
	[string]$mainErrorMessage = "$(Resolve-Error)"
	Write-Log -Message $mainErrorMessage -Severity 3 -Source $deployAppScriptFriendlyName
	Show-DialogBox -Text $mainErrorMessage -Icon 'Stop'
	Exit-Script -ExitCode $mainExitCode
}
