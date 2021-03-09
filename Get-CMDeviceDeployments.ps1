function Get-CMDeviceDeployments {
    <#
    .SYNOPSIS
        Gets Configuration Manager deployments for a device and collections it is in
    .EXAMPLE
        PS XYZ:\> Get-CMDeviceDeployments -Name 'Device-123'
        Gets the deployments for collections Device-123 is a member of

        PS XYZ:\> Get-CMDeviceDeployments -ResourceId 12345678
        Gets the deployments for collections the device with ID 123465678 is a member of
    .NOTES
        Based on Paul Winstanley's query to find collection membership for a device from https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
    #>

    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        # The name of the device to get deployments for
        [Parameter(Mandatory, ParameterSetName = 'ByName')]
        [string]$Name,
        # The resource ID of the device to get deployments for
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

    # https://sccmentor.com/2015/04/16/find-collection-membership-for-a-device-with-powershell/
    # Get-CMDeployment needs collection name. Not sure if these have any advantages over Get-CMDriveCollectionMembership
    if ($PSCmdlet.ParameterSetName -eq 'ByName') {
        $querySplat['Query'] = "SELECT SMS_Collection.* FROM SMS_FullCollectionMembership, SMS_Collection WHERE name = '$Name' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID"
    } elseif ($PSCmdlet.ParameterSetName -eq 'ByID' ) {
        $querySplat['Query'] = "SELECT SMS_Collection.* from SMS_FullCollectionMembership,SMS_Collection WHERE ResourceID = '$ResourceID' and SMS_FullCollectionMembership.CollectionID = SMS_Collection.CollectionID"
    }

    if ($siteServer -ne ([System.Net.Dns]::GetHostEntry($env:COMPUTERNAME).HostName)) {
        $querySplat['ComputerName'] = $siteServer
    }

    Get-CimInstance @querySplat | ForEach-Object {Get-CMDeployment -CollectionName $_.Name}
}
