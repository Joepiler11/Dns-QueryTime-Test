# DNS Log Analyzer

This PowerShell script is designed to analyze DNS log files in CSV format. It allows users to filter, sort, and export DNS log data based on various criteria.

## Features

- Import multiple DNS log files at once.
- Filter logs based on query time, record type, or name server.
- Sort logs by timestamp, DNS query time, record type, name server, or record.
- Export filtered and sorted logs to a CSV file.
- User-friendly menu interface for selecting options.

## Usage

1. **Parameters:**
   - `-DnsTime`: Maximum DNS query time to filter logs (in milliseconds).
   - `-FilterBy`: Property by which to filter the logs (Record, Type, NameServer).
   - `-Filter`: Value to filter logs by (mandatory when using `-FilterBy`).
   - `-SortBy`: Property by which to sort the logs (TimeStamp, DnsTime, NameServer, Type, Record).
   - `-AllFiles`: Import all log files without prompting.
   
2. **Running the Script:**
   - Open PowerShell.
   - Navigate to the directory containing the script.
   - Run the script with appropriate parameters.

3. **Example:**
   ```powershell
   .\DNSLogAnalyzer.ps1 -DnsTime 100 -FilterBy Type -Filter "A" -SortBy TimeStamp
   ```

4. **Follow on-screen prompts to select log files, configure filters, and choose sorting options.**

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
