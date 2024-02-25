param (
    [int]$DnsTime,
    [ValidateSet("Record","Type","NameServer")]
    [string]$FilterBy,
    [string]$Filter,
    [ValidateSet("TimeStamp","DnsTime","NameServer","Type","Record")]
    [string]$SortBy
)

Clear-Host

if ($FilterBy -and -not $Filter) {
    Write-Error "Error: The -Filter parameter is mandatory when -FilterBy is used."
    exit 1
  }

$LogFiles = (Get-ChildItem -Filter "log*.csv").Name

$FileCount = ($LogFiles | Measure-Object).Count
Write-Host "Importing $FileCount logfiles, please be patient." -ForegroundColor Yellow
$FileNr = 0
$TotalImportTime = 0

foreach ($LogFile in $LogFiles) {
    $ImportTime = (Measure-Command{
        $Log = Import-Csv "$LogFile"
        $Log | ForEach-Object {
            $_.timestamp = [DateTime]::Parse($_.timestamp)
        }
        $Log | ForEach-Object {
            $_.dnstime = [int]$_.dnstime
        }
        $CombinedLogs += $Log
    }).Seconds
    $FileNr ++
    Write-Host "---Finished importing '$LogFile' in $ImportTime seconds. ($FileNr/$FileCount)" -ForegroundColor Green
    $TotalImportTime += $ImportTime
}
 $LineCount = ($CombinedLogs | Measure-Object).Count
Write-Host "Imported $LineCount lines in $TotalImportTime seconds." -ForegroundColor Yellow

if ($DnsTime) {
    Write-Host "Filtering logs with dns time >= $($DnsTime)ms, please be patient." -ForegroundColor Yellow
    $CombinedLogs = $CombinedLogs | Where-Object {$_.DnsTime -ge $DnsTime}
}

if ($Filter) {
    Write-Host "Filtering logs where $FilterBy = $Filter, please be patient." -ForegroundColor Yellow
    if ($FilterBy -eq "Record") {
        $CombinedLogs = $CombinedLogs | Where-Object {$_.Record -eq $Filter}
    }
    if ($FilterBy -eq "Type") {
        $CombinedLogs = $CombinedLogs | Where-Object {$_.Type -eq $Filter}
    }
    if ($FilterBy -eq "NameServer") {
        $CombinedLogs = $CombinedLogs | Where-Object {$_.NameServer -eq $Filter}
    }
}

if ($SortBy) {
    Write-Host "Sorting logs by $SortBy" -ForegroundColor Yellow
}

$FinalLineCount = ($CombinedLogs | Measure-Object).Count
$MatchPercentage = [Math]::Round(($FinalLineCount / $LineCount) * 100, 2)
Write-Host "`n$FinalLineCount / $LineCount matched your search ($MatchPercentage%)" -ForegroundColor Green
Pause

if ($SortBy -eq "TimeStamp") {
    $CombinedLogs | Sort-Object TimeStamp | Format-Table
} elseif ($SortBy -eq "DnsTime") {
    $CombinedLogs | Sort-Object DnsTime -descending | Format-Table
} elseif ($SortBy -eq "Type") {
    $CombinedLogs | Sort-Object Type | Format-Table
} elseif ($SortBy -eq "NameServer") {
    $CombinedLogs | Sort-Object NameServer | Format-Table
} elseif ($SortBy -eq "Record") {
    $CombinedLogs | Sort-Object Record | Format-Table
} else {
    $CombinedLogs | Format-Table
}

Pause