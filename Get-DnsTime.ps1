# Import settings from a CSV file named Settings.csv in the current directory
$Settings = Import-Csv .\Settings.csv
$StartTime = Get-Date -Format "dd-MM-yyyy"
$LogFileName = "Log $StartTime.csv"

# Prompt the user to enter the number of days to run the test and convert it to an integer
[int]$DaysToRun = Read-Host "How many days do you want to test?"

# Calculate the end date based on the current date and the number of days specified
$EndDate = (Get-Date).AddDays($DaysToRun)

# Loop until the current date is greater than or equal to the end date
do {
    # Pause execution for a random number of seconds between 1 and 10
    Start-Sleep -Milliseconds 500

    # Select a random test record from the imported settings
    $TestRecord = Get-Random $Settings

    # Get the current timestamp in the format "dd-mm-yyyy hh:mm:ss"
    $TimeStamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"


    $ErrorInfo = $null  # Initialize $ErrorInfo outside of the try-catch block

    try {        
        # Measure the time taken to resolve the DNS query using the specified DNS server and record type
        $DnsTime = (Measure-Command {Resolve-DnsName $($TestRecord.Record) -Type $($TestRecord.RecordType) -Server $($TestRecord.NameServer) -DnsOnly -ErrorAction Stop}).Milliseconds
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
            DnsTime = $DnsTime
            Error = $ErrorInfo
        }
    }

    if ($DnsTime -ge 500) {
        $Output
    }

    # Append the test results to a CSV file named log.csv
    $Output | Export-Csv ./$LogfileName -Append

# Repeat the loop until the end date is reached
} until ((Get-Date) -ge $EndDate)