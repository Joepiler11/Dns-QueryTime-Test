# DNS Testing Script

This PowerShell script is designed to test DNS records over a specified duration, logging the results to a CSV file.

## Usage

1. Clone or download the repository to your local machine.

2. Ensure you have PowerShell installed.

3. Place your DNS records in the `Settings.csv` file located in the `Settings` directory. Each record should have the following columns: `Record`, `RecordType`, and `NameServer`.

4. Optionally, you can modify the polling rate for DNS queries by changing the default value in the script.

5. Open a PowerShell terminal and navigate to the directory containing the script.

6. Run the script by executing the following command:
   ```powershell
   .\dns_testing_script.ps1
   ```

7. Follow the prompts to specify the number of days to run the test and optionally adjust the DNS record polling rate.

8. The script will start running and display test results in the terminal. It will also log the results to a CSV file named `Log_<timestamp>.csv` in the `Logs` directory.

9. Once the specified duration is over, the script will display a message and wait for user input before exiting.

## Notes

- Ensure that the PowerShell execution policy allows running scripts. You may need to set it to `RemoteSigned` or `Unrestricted` for the script to execute properly.
  
- Make sure you have necessary permissions to perform DNS queries and write to the log file directory.

- This script is provided as-is, without any warranties. Use it at your own risk.

- For more information on the script, refer to the comments within the script file.

## License

This project is licensed under the [MIT License](LICENSE).
