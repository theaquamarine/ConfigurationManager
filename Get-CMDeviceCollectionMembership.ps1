function Get-CMDeviceCollectionMembership {
    <#
    .SYNOPSIS
        Gets Configuration Manager collections a Configuration Manager device is a member of
    .EXAMPLE
        PS XYZ:\> Get-CMDeviceCollectionMembership -Name 'Device-123'
        Gets the collections Device-123 is a member of

        PS XYZ:\> Get-CMDeviceCollectionMembership -ResourceId 12345678
        Gets the collections the device with ID 123465678 is a member of
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        # The Name of the device
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name,
        # The Resource ID of the device
        [Parameter(Mandatory, ParameterSetName = 'ById')]
        [Alias('Id','DeviceId')]
        [string]$ResourceId
    )

    $currentDrive = (Get-Location).Drive
    if ($currentDrive.Provider.Name -ne 'CMSite') {throw 'This command cannot be run from the current drive. To run this command you must first connect to a Configuration Manager drive.'}
    $siteServer = $currentDrive.Root
    $siteCode = $currentDrive.Name

    $querySplat = @{
        Namespace = "root\sms\site_$siteCode"
    }

    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $querySplat['Query'] = "SELECT CollectionID FROM SMS_FullCollectionMembership WHERE Name = $Name"
    } elseif ($PSCmdlet.ParameterSetName -eq 'ByID' ) {
        $querySplat['Query'] = "SELECT CollectionID FROM SMS_FullCollectionMembership WHERE ResourceID = $ResourceID"
    }

    if ($siteServer -ne ([System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName)) {
        $querySplat['ComputerName'] = $siteServer
    }

    Get-CimInstance @querySplat | ForEach-Object {Get-CMDeviceCollection -Id $_.CollectionID}
}
