Clear-Host

# Store the original title of the host window
$OriginalTitle = $Host.UI.RawUI.WindowTitle

# Store the script name for later use
$ScriptName = $MyInvocation.MyCommand.Name

# Set the window title to the script name
$Host.UI.RawUI.WindowTitle = $ScriptName

$ModulesPath = ".\Modules"

# Get a list of module names in the specified directory
$Modules = (Get-ChildItem $ModulesPath -Directory).Name

# Get the names of currently active modules
$ActiveModules = (Get-Module).Name

# Loop through each module and import it if it's not already active
foreach ($Module in $Modules) {
    if ($Module -notin $ActiveModules) {
        Import-Module "$ModulesPath\$Module\$Module.psm1"
    }
}

# Import settings from a CSV file named Settings.csv in the current directory
$Settings = Import-Csv ".\Settings\Settings.csv"

# Get the current timestamp in the format "dd-mm-yyyy hh:mm:ss" for log file naming
$StartTime = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"
$LogFileName = "Log_$StartTime.csv"
$LogFileFolder = "Logs"
$LogFilePath = ".\$LogFileFolder\$LogfileName"

# Create Logs folder if it doesn't exist
if (-not (Test-Path $LogFileFolder)) {
    New-Item -Name $LogFileFolder -ItemType Directory
}

# Prompt the user to enter the number of days to run the test and convert it to an integer
[int]$DaysToRun = Read-Host "How many days do you want to test?"
Write-Host ""

# Prompt the user to change DNS record polling rate if desired
Write-Host "Do you want to change the DNS record polling rate? (Default = 500ms)"
$ConfirmPollingRate = Get-Confirmation -Default N
Write-Host ""

# Set the polling rate to user input or default to 500ms
if ($ConfirmPollingRate -eq $true) {
    [int]$PollingRate = Read-Host "How many milliseconds between each DNS query?"
} else {
    [int]$PollingRate = 500
}

# Calculate the end date based on the current date and the number of days specified
$EndDate = (Get-Date).AddDays($DaysToRun)

# Loop until the current date is greater than or equal to the end date
do {
    # Pause execution for a random number of milliseconds between 1 and 10
    Start-Sleep -Milliseconds $PollingRate

    # Select a random test record from the imported settings
    $TestRecord = Get-Random $Settings

    # Get the current timestamp in the format "dd-mm-yyyy hh:mm:ss"
    $TimeStamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"

    $ErrorInfo = $null  # Initialize $ErrorInfo outside of the try-catch block

    try {        
        # Measure the time taken to resolve the DNS query using the specified DNS server and record type
        $DnsTime = (Measure-Command {Resolve-DnsName $($TestRecord.Record) -Type $($TestRecord.RecordType) -Server $($TestRecord.NameServer) -DnsOnly -ErrorAction Stop})
    }
    catch {
        $ErrorInfo = $_.Exception.Message
    }
    finally {
        # Create a custom object with the test results
        $Output = [PSCustomObject]@{
            TimeStamp = $TimeStamp
            Record = $TestRecord.Record
            Type = $TestRecord.RecordType
            NameServer = $TestRecord.NameServer
            DnsTime = [math]::Round($DnsTime.TotalMilliseconds)
            Error = $ErrorInfo
        }
    }

    # Output the test results if DNS time is greater than or equal 500
    if ([math]::Round($DnsTime.TotalMilliseconds) -ge 500) {
        $Output
    }

    # Append the test results to a CSV file named log.csv
    $Output | Export-Csv $LogFilePath -Append

# Repeat the loop until the end date is reached
} until ((Get-Date) -ge $EndDate)

# Display a message and wait for user input before exiting
Write-Host ""
Pause

# Restore the original window title
$Host.UI.RawUI.WindowTitle = $OriginalTitle
