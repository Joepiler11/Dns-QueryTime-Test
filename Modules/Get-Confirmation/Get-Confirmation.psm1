<#
.SYNOPSIS
Prompts the user for a yes or no response and returns a Boolean value

.DESCRIPTION
If function is called with -default y then user is asked a question to reply Y/n if user enters 
without writing y or n function will assume answer is Yes.

If function is called with -default n then user is asked a question to reply y/N if user enters 
without writing y or n function will assume answer is No.

.PARAMETER Default
Specifies if the default answer should be y or n

.PARAMETER Question
The question you want to ask the user

.EXAMPLE
$Confirm = Get-Confirmation -Default y -Question "Are you sure you want to continue?"

.NOTES
General notes
#>
function Get-Confirmation {
    param ($Question, $Default)
    
        if ($Default -eq "y") {
            do {
                $Answer = Read-Host "$Question [Y/n]"
                switch ($Answer) {
                    {$_ -eq "y" -or $_ -eq ""} {
                        $Output = $true
                        break;
                    }
                    {$_ -eq "n"} {
                        $Output = $false
                        break;
                    }
                }
            } while ($Answer -ne "y" -and $Answer -ne "n" -and $Answer -ne "")
        }

        if ($Default -eq "n") {
            do {
                $Answer = Read-Host "$Question [y/N]"
                switch ($Answer) {
                    {$_ -eq "n" -or $_ -eq ""} {
                        $Output = $false
                        break;
                    }
                    {$_ -eq "y"} {
                        $Output = $true
                        break;
                    }
                }
            } while ($Answer -ne "y" -and $Answer -ne "n" -and $Answer -ne "")
        }

        if ($null -eq $Default -or $Default -eq "") {
            do {
            $Answer = Read-Host "$Question [y/n]"
            switch ($Answer) {
                {$_ -eq "n"} {
                    $Output = $false
                    break;
                }
                {$_ -eq "y"} {
                    $Output = $true
                    break;
                }
            }
            } while ($Answer -ne "y" -and $Answer -ne "n")
        }

    Return $Output
}