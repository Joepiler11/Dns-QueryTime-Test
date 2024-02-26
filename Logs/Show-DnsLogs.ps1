param (
    [int]$DnsTime,  # The maximum DNS query time to filter logs
    [ValidateSet("Record","Type","NameServer")]
    [string]$FilterBy,  # Property by which to filter the logs
    [string]$Filter,  # Value to filter logs by, optional
    [ValidateSet("TimeStamp","DnsTime","NameServer","Type","Record")]
    [string]$SortBy,  # Property by which to sort the logs
    [switch]$AllFiles  # Switch to indicate whether to import all log files
)

Clear-Host

# Store the original title of the host window
$OriginalTitle = $Host.UI.RawUI.WindowTitle

# Store the script name for later use
$ScriptName = $MyInvocation.MyCommand.Name

# Set the window title to the script name
$Host.UI.RawUI.WindowTitle = $ScriptName

$ModulesPath = "..\Modules"

$Modules = (Get-ChildItem $ModulesPath -Directory).Name
$ActiveModules = (Get-Module).Name

foreach ($Module in $Modules) {
    if ($Module -notin $ActiveModules) {
        Import-Module "$ModulesPath\$Module\$Module.psm1"  # Import any module not already imported
    }
}

if ($FilterBy -and -not $Filter) {  # Check if filter parameter is provided without value
    Write-Error "Error: The -Filter parameter is mandatory when -FilterBy is used."  # Display error message
    exit 1
}

try {
    $LogFiles = (Get-ChildItem -Filter "log*.csv").Name  # Get names of all log files
    Write-Host "Found $(($LogFiles | Measure-Object).Count) logfiles.`n" -ForegroundColor Yellow  # Display number of log files found
    Write-Host "Do you want to import all files?"  # Ask user if they want to import all log files
    $ConfirmAllFiles = Get-Confirmation -Default Y  # Get user confirmation
    if ($ConfirmAllFiles -eq $true) {  # If user confirms, set AllFiles switch to true
        $AllFiles = $true
    }
    Write-Host ""

    if ($AllFiles -eq $true) {  # If AllFiles switch is true, select all log files
        $SelectedLogFiles = $LogFiles
    } elseif (($LogFiles | Measure-Object).Count -eq 1) {  # If only one log file, select it automatically
        $SelectedLogFiles = $LogFiles
    } elseif (($LogFiles | Measure-Object).Count -lt 1) {  # If no log files found, exit script
        Write-Host "No files found, exiting." -ForegroundColor Red
        Exit
    } else {  # If multiple log files found, prompt user to select which to import
        $SelectedLogFiles = Write-Menu -Title "Which logfiles do you want to import?" -Entries $LogFiles -MultiSelect
        $Host.UI.RawUI.WindowTitle = $ScriptName
    }

    $FileCount = ($SelectedLogFiles | Measure-Object).Count  # Count selected log files
    Write-Host "Importing $FileCount logfiles, please be patient." -ForegroundColor Yellow  # Display importing message
    $FileNr = 0
    $TotalImportTime = 0

    foreach ($LogFile in $SelectedLogFiles) {  # Loop through selected log files
        $ImportTime = Measure-Command{  # Measure time to import each log file
            $Log = Import-Csv "$LogFile"  # Import log file as CSV
            $Log | ForEach-Object {  # Convert timestamp to DateTime object
                $_.timestamp = [DateTime]::Parse($_.timestamp)
            }
            $Log | ForEach-Object {  # Convert DnsTime to integer
                $_.dnstime = [int]$_.dnstime
            }
            $CombinedLogs += $Log  # Combine logs
        }
        $ImportTime = [math]::Round($ImportTime.Totalseconds)
        $FileNr ++
        Write-Host "---Finished importing '$LogFile' in $ImportTime seconds. ($FileNr/$FileCount)" -ForegroundColor Green  # Display import completion message
        $TotalImportTime += $ImportTime
    }
    $LineCount = ($CombinedLogs | Measure-Object).Count  # Count total lines imported
    Write-Host "Imported $LineCount lines in $TotalImportTime seconds.`n" -ForegroundColor Yellow  # Display total import statistics

    if (-not $DnsTime) {  # If DnsTime not provided, prompt user to filter results based on query time
        Write-Host "Do you want to filter out results based on query time?"
        $ConfirmDnsTime = Get-Confirmation -Default Y  # Get user confirmation
        Write-Host ""
        Write-Host "Checking min/max DnsTime, please be patient.`n" -ForegroundColor Yellow  # Display message
        if ($ConfirmDnsTime -eq $true) {  # If user confirms, calculate min/max DnsTime
            $MeasurePropertyDnsTime = $CombinedLogs.DnsTime | Measure-Object -Maximum -Minimum
            Write-Host "Minimum DnsTime: $($MeasurePropertyDnsTime.Minimum) ms" -ForegroundColor Green  # Display minimum DnsTime
            Write-Host "Maximum DnsTime: $($MeasurePropertyDnsTime.Maximum) ms`n" -ForegroundColor Red  # Display maximum DnsTime
            [int]$DnsTime = Read-Host "Exclude results with query time less than (milliseconds)"  # Prompt user for minimum DnsTime
        }
    }

    if (-not $FilterBy) {  # If FilterBy not provided, prompt user to filter results by property
        Write-Host "`nDo you want to filter results by property?"
        $ConfirmFilterBy = Get-Confirmation -Default N  # Get user confirmation
        if ($ConfirmFilterBy -eq $true) {  # If user confirms, prompt user to select property to filter by
            $FilterBy = Write-Menu -Title "Do you want to filter results by property?" -Entries @("Record","Type","NameServer")
            $Host.UI.RawUI.WindowTitle = $ScriptName
            Write-Host "Building filter array, please be patient." -ForegroundColor Yellow  # Display message
            $FilterArray = ($CombinedLogs | Group-Object $FilterBy).Name  # Group logs by selected property
            $Filter = Write-Menu -Title "Choose your filter" -Entries $FilterArray  # Prompt user to choose filter value
            $Host.UI.RawUI.WindowTitle = $ScriptName
        }
    }

    if (-not $SortBy) {  # If SortBy not provided, prompt user to sort results by property
        Write-Host "`nDo you want to sort results by property?"
        $ConfirmSortBy = Get-Confirmation -Default N  # Get user confirmation
        Write-Host ""
        if ($ConfirmSortBy -eq $true) {  # If user confirms, prompt user to select property to sort by
            $SortBy = Write-Menu -Title "Do you want to sort results by property?" -Entries @("TimeStamp","DnsTime","NameServer","Type","Record")
            $Host.UI.RawUI.WindowTitle = $ScriptName
        }
    }

    if ($DnsTime) {  # If DnsTime provided, filter logs by DnsTime
        Write-Host "Filtering logs with dns time >= $($DnsTime)ms, please be patient." -ForegroundColor Yellow  # Display filtering message
        $CombinedLogs = $CombinedLogs | Where-Object {$_.DnsTime -ge $DnsTime}
    }

    if ($Filter) {  # If Filter provided, filter logs by selected property and value
        Write-Host "Filtering logs where $FilterBy = $Filter, please be patient." -ForegroundColor Yellow  # Display filtering message
        if ($FilterBy -eq "Record") {  # Filter logs by Record property
            $CombinedLogs = $CombinedLogs | Where-Object {$_.Record -eq $Filter}
        }
        if ($FilterBy -eq "Type") {  # Filter logs by Type property
            $CombinedLogs = $CombinedLogs | Where-Object {$_.Type -eq $Filter}
        }
        if ($FilterBy -eq "NameServer") {  # Filter logs by NameServer property
            $CombinedLogs = $CombinedLogs | Where-Object {$_.NameServer -eq $Filter}
        }
    }

    if ($SortBy) {  # If SortBy provided, sort logs by selected property
        Write-Host "Sorting logs by $SortBy" -ForegroundColor Yellow  # Display sorting message
    }

    $FinalLineCount = ($CombinedLogs | Measure-Object).Count  # Count final matched lines
    $MatchPercentage = [Math]::Round(($FinalLineCount / $LineCount) * 100, 2)  # Calculate match percentage
    Write-Host "`n$FinalLineCount / $LineCount matched your search ($MatchPercentage%)`n" -ForegroundColor Green  # Display match statistics
    Pause

    if ($SortBy -eq "TimeStamp") {  # If sorting by TimeStamp, sort logs by TimeStamp
        $SortedLogs = $CombinedLogs | Sort-Object TimeStamp
        $SortedLogs | Format-Table
    } elseif ($SortBy -eq "DnsTime") {  # If sorting by DnsTime, sort logs by DnsTime descending
        $SortedLogs = $CombinedLogs | Sort-Object DnsTime -Descending
        $SortedLogs | Format-Table
    } elseif ($SortBy -eq "Type") {  # If sorting by Type, sort logs by Type
        $SortedLogs = $CombinedLogs | Sort-Object -Type
        $SortedLogs | Format-Table
    } elseif ($SortBy -eq "NameServer") {  # If sorting by NameServer, sort logs by NameServer
        $SortedLogs = $CombinedLogs | Sort-Object NameServer
        $SortedLogs | Format-Table
    } elseif ($SortBy -eq "Record") {  # If sorting by Record, sort logs by Record
        $SortedLogs = $CombinedLogs | Sort-Object Record
        $SortedLogs | Format-Table
    } else {  # If no sorting specified, display logs as is
        $SortedLogs = $CombinedLogs
        $SortedLogs | Format-Table
    }

    Write-Host "Do you want to export this result?"  # Ask user if they want to export the result
    $ConfirmExport = Get-Confirmation  # Get user confirmation
    if ($ConfirmExport -eq $true) {  # If user confirms, export result to CSV
        $ExportTime = Get-Date -Format "dd-MM-yyyy_HH-mm-ss"  # Get current date and time for export file name
        $ExportFileName = "Export_$ExportTime.csv"  # Define export file name
        $ExportFileFolder = "Exports"  # Define export file folder
        $ExportFilePath = ".\$ExportFileFolder\$ExportfileName"  # Define export file path
        if (-not (Test-Path $ExportFileFolder)) {  # If export folder doesn't exist, create it
            New-Item -Name $ExportFileFolder -ItemType Directory
        }
        $SortedLogs | Export-Csv $ExportFilePath -Append  # Export sorted logs to CSV file
        Write-Host ""
        Write-Host "---Exported result to $ExportFilePath`n" -ForegroundColor Green  # Display export confirmation message
    }

} finally {
    Pause
    
    # Restore the original window title
    $Host.UI.RawUI.WindowTitle = $OriginalTitle       
}
