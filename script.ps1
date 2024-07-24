$OutfilePath="C:\Users\$env:USERNAME\Documents\NEW_USER $(Get-Date -Format "MM-dd-yyyy").txt"

do
{
    # Prompt user for information
    write-host
    $FirstName=read-host -Prompt "First Name"
    $LastName=read-host -Prompt "Last Name"
    $ID=read-host -Prompt "Employee ID"
    $Password=powershell .\PasswordGenerator.ps1 -Repeat n
    $SecurePassword=ConvertTo-SecureString $Password -AsPlainText -Force
    write-host -ForegroundColor Green "Done!"

    # Create user
    $Username="$($FirstName.ToLower()).$($LastName.ToLower())"
    $Email=$Username+"@corp.com"
    write-host -ForegroundColor Cyan -NoNewline "`tCreating `"$Email`"..."
    $Name="$FirstName $LastName"
    $Attributes=@{
    "Company"="myCorp, Inc.";
    "DisplayName"=$Name;
    "DistinguishedName"="CN=$Name,OU=Employees,DC=corp,DC=com";
    "Division"="Employees";
    "EmployeeID"="$ID";
    "GivenName"="$FirstName";
    "mail"="$Email";
    "physicalDeliveryOfficeName"="Office";
    "sn"="$LastName";
    "userPrincipalname"=$Email;
    }
    try
    {
        New-ADUser -Name $Name -SAMAccountName $Username -AccountPassword $SecurePassword -Enabled $True -OtherAttributes $Attributes
        write-host -ForegroundColor Green "Done!"
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityAlreadyExistsException] #User with that name exists
    {
        $ExistingUser = Get-ADUser $Username -Properties *

        if($ExistingUser.EmployeeID -eq $ID) #Re-hire
        {
            Move-ADObject -Identity $ExistingUser.DistinguishedName -TargetPath "OU=Employees,DC=corp,DC=com"
            Remove-ADGroupMember -Identity Terminated -Members $ExistingUser.SamAccountName
            write-host -ForegroundColor Green -NoNewline "Done!"
            write-host -ForegroundColor Yellow " (User is re-hire, removed from Terminated group and moved to Employees OU)"
        }
        else #Not a re-hire, but someone already exists with that name
        {
            write-host -ForegroundColor Red "Failed! (User `"$Username`" already exists with different EmployeeID)"
            exit
        }
    }

    # Add user to appropriate AD groups
    write-host -ForegroundColor Cyan -NoNewline "`tSetting group memberships for `"$Username@corp.com`"..."
    $Groups=@("Group1","Group2","Group3","Group4","Group5")
    foreach($Group in $Groups)
    {
        Add-ADGroupMember -Identity $Group -Members "$Username"
    }
    write-host -ForegroundColor Green "Done!"

    # Write information to text file
    write-host -ForegroundColor Cyan -NoNewline "`tWriting to `"$Outfilepath`"..."
    echo "Name:`t`t$Name" | out-file $OutfilePath -Append
    echo "Employee ID:`t$ID" | out-file $OutfilePath -Append
    echo "Email:`t`t$Email" | out-file $OutfilePath -Append
    echo "Password:`t$Password" | out-file $OutfilePath -Append
    echo "" | out-file $OutfilePath -Append
    write-host -ForegroundColor Green "Done!"
    write-host

    # Prompt user if they want to add another user
    do
    {
        $continue=read-host -Prompt "Add another user? (y/n)"
    }while(($continue -ne "y") -AND ($continue -ne "n"));
}while($continue -eq "y");
