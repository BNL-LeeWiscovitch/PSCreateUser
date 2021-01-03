###VARIABLES###

#Active Directory domain name - expecting "name.tld"
$DomainName   = "wiscovitch.org"

#Name of the OU to create to contain Customers, created at the root of $DomainName
$CustomerRoot = "Customers"

#Names of Customers to create - Each entry seperated by a comma
$Customers    = "WiscoTECH","Jaguars","Census","CDC"

###FUNCTIONS###

#CreateOU -Name "Groups" -Path "DC=domain,DC=org" -Description "Custom container for user groups"
function CreateOU ([string]$Name,[string]$Path,[string]$Description) {
    #Format variables into valid Distinguished Name.
    $DistinguishedName = "OU=$Name,$Path"

    #Check to see if OU already exists.
    try {
        Get-ADOrganizationalUnit -Identity $DistinguishedName | Out-Null
        Write-Host "CreateOU - OU Already Existed: $DistinguishedName"
    }

    #Create OU if does not exist
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Host "CreateOU - Creating new OU: $DistinguishedName"
        New-ADOrganizationalUnit -Name $Name -Path $Path -Description $Description
        Write-Host "CreateOU - OU Created: $DistinguishedName"
    }

    <#
        .SYNOPSIS
        Creates a new Active Directory Organizational Unit (OU).

        .DESCRIPTION
        Checks to see if the OU exists at the Path provided.
        If it does, then the function logs results and exits.
        If it does not, then the OU is created and the function logs results.

        .PARAMETER Name
        Specifies the name of the OU to be created.

        .PARAMETER Path
        Specifies the location to create the OU.

        .PARAMETER Description
        Specifies the text description to apply to the OU when created.

        .INPUTS
        None.

        .OUTPUTS
        System.String. Function will report the results of the process.

        .EXAMPLE
        CreateOU -Name "Groups" -Path "DC=domain,DC=org" -Description "Custom container for user groups"
            CreateOU - Creating new OU: OU=Groups,DC=domain,DC=org
            CreateOU - OU Created: OU=Groups,DC=domain,DC=org

        .EXAMPLE
        CreateOU -Name "Groups" -Path "DC=domain,DC=org" -Description "Custom container for user groups"
            CreateOU - OU Already Existed: OU=Groups,DC=domain,DC=org

    #>
}

#CreateGroup -Name "TestGroup" -Path "OU=Groups,DC=domain,DC=org" -Description "Test Group"
function CreateGroup ([string]$Name,[string]$Path,[string]$Description,[string]$Type="Security",[string]$Scope="Global") {
    #Format variables into valid Distinguished Name.
    $DistinguishedName = "OU=$Name,$Path"

    #Check to see if Group already exists.
    try {
        Get-ADGroup -Identity $Name | Out-Null
        Write-Host "CreateGroup - Group Already Existed: $Name"
    }

    #Create Group if does not exist
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        Write-Host "CreateGroup - Creating new Group: $Name"
        New-ADGroup -Name $Name -SamAccountName $Name -GroupCategory $Type -Path $Path -Description $Description -GroupScope Global
        Write-Host "CreateGroup - Group Created: $DistinguishedName"
    }

    <#
        .SYNOPSIS
        Creates a new Active Directory Group.

        .DESCRIPTION
        Checks to see if the Group exists at the Path provided.
        If it does, then the function logs results and exits.
        If it does not, then the Group is created and the function logs results.

        .PARAMETER Name
        Specifies the name of the Group to be created.
        Specifies the Security Account Manager (SAM) account name of the group.
        For maximum compatiblity, do not use more than 20 characters.

        .PARAMETER Path
        Specifies the location to create the Group.

        .PARAMETER Description
        Specifies the text description to apply to the Group when created.

        .PARAMETER Type
        Specifies the type of Group to create.
        Defaults to "Security", but you can pass "Distrobution" if desired.

        .PARAMETER Scope
        Specifies the scope the group is configured for.
        Defaults to "Global", but you can pass "DomainLocal" or "Universal" if desired.

        .INPUTS
        None.

        .OUTPUTS
        System.String. Function will report the results of the process.

        .EXAMPLE
        CreateGroup -Name "TestGroup" -Path "OU=Groups,DC=domain,DC=org" -Description "Test Group"
            CreateGroup - Creating new Group: TestGroup
            CreateGroup - Group Created: OU=TestGroup,OU=Groups,DC=domain,DC=org

        .EXAMPLE
        CreateOU -Name "Groups" -Path "DC=domain,DC=org" -Description "Custom container for user groups"
            CreateGroup - Group Already Existed: TestGroup

    #>
}

#CreateCustomer -Name "CustomerName" -Domain "domain.org"
function CreateCustomer ([string]$Name,[string]$Domain) {
    #Active Directory domain name broken down into DN syntax - uses function's $Domain value
    $DomainRoot = ("DC={0},DC={1}" -f ($Domain -split "\.")[0], ($Domain -split "\.")[1])

    #Format variables into valid Distinguished Name.
    $DistinguishedName = "OU=$Name,$Path"

    #Create "CustomerRoot" OU:
    CreateOU -Name $CustomerRoot -Path $DomainRoot -Description "Custom OU for $CustomerRoot"

    #Create "CustomerName" OU in the "CustomerRoot":
    CreateOU -Name $Name -Path "OU=$CustomerRoot,$DomainRoot" -Description "Custom OU for $Name"

    #Create "Computers" OU in "CustomerName" OU:
    CreateOU -Name "Computers" -Path "OU=$Name,OU=$CustomerRoot,$DomainRoot" -Description "Custom OU for $Name\Computers"

    #Create "Groups" OU in "CustomerName" OU:
    CreateOU -Name "Groups" -Path "OU=$Name,OU=$CustomerRoot,$DomainRoot" -Description "Custom OU for $Name\Groups"

    #Create "Users" OU in "CustomerName" OU:
    CreateOU -Name "Users" -Path "OU=$Name,OU=$CustomerRoot,$DomainRoot" -Description "Custom OU for $Name\Users"

    #Create "Projects" OU in "CustomerName" OU:
    CreateOU -Name "Projects" -Path "OU=$Name,OU=$CustomerRoot,$DomainRoot" -Description "Custom OU for $Name\Projects"


    <#
        .SYNOPSIS
        Creates custom OU structure for a Customer.

        .DESCRIPTION
        Creates custom OU structure for a Customer using existing custom functions.
        Please see custom function code for more information.

        .PARAMETER Name
        Specifies the name of the Customer

        .PARAMETER Domain
        Specifies the name of the Active Directory domain.
        Expects "name.tld"

        .INPUTS
        None.

        .OUTPUTS
        System.String. Function will report the results of the process.

        .EXAMPLE
        CreateCustomer -Name "WiscoTECH" -Domain "domain.org"
            CreateOU - Creating new OU: OU=Customers,DC=domain,DC=org
            CreateOU - OU Created: OU=Customers,DC=domain,DC=org
            CreateOU - Creating new OU: OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Created: OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - Creating new OU: OU=Computers,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Created: OU=Computers,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - Creating new OU: OU=Groups,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Created: OU=Groups,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - Creating new OU: OU=Users,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Created: OU=Users,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - Creating new OU: OU=Projects,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Created: OU=Projects,OU=WiscoTECH,OU=Customers,DC=domain,DC=org

        .EXAMPLE
        CreateCustomer -Name "WiscoTECH" -Domain "domain.org"
            CreateOU - OU Already Existed: OU=Customers,DC=domain,DC=org
            CreateOU - OU Already Existed: OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Already Existed: OU=Computers,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Already Existed: OU=Groups,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Already Existed: OU=Users,OU=WiscoTECH,OU=Customers,DC=domain,DC=org
            CreateOU - OU Already Existed: OU=Projects,OU=WiscoTECH,OU=Customers,DC=domain,DC=org

    #>
}

###SCRIPT###

#Create Customers - Invoke CreateCustomer function once per $Customer entry
ForEach ($Customer in $Customers) {
    CreateCustomer -Name $Customer -Domain $DomainName
}

###END###
