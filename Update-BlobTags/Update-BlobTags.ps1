<#
.SYNOPSIS
Updates the tags of blobs in a container based on data in an Azure Table.

.DESCRIPTION
This script updates the tags of blobs in a container based on data in an Azure Table. The script requires:

- A subscription ID
- A storage account name
- A container name
- A table name
- A resource group name
- A local log file to write changes to

The script connects to the specified subscription and storage account, retrieves a list of blobs in the specified container, and checks if each blob has tags. 
If the blob has tags, the script prompts the user to overwrite them. If the user chooses to overwrite the tags, the script updates the tags of the blob with data from the Azure Table. 
If the blob does not have tags, the script writes new tags to the blob.

.PARAMETER force
A switch parameter that specifies whether to overwrite all tags without being prompted. Cannot be used with the -check switch.

.PARAMETER check
A switch parameter that specifies whether to check the blobs in read-only mode, and report without making changes. Cannot be used with the -force switch.

.EXAMPLE
Update-IndexTags.ps1 -subscriptionId "xxxxxx-xxxxxx-xxxxxx" -storageAccountName "storageacct123" -containerName "blobcontainer" -tablename "index" -resourceGroupName "rg-storage-1" -logfile ".\log.txt" -force

This example updates the tags of blobs in the "blobcontainer" container of the "storageacct123" storage account based on data in the "index" table. The script overwrites all tags without prompting the user.

.NOTES
Version: 1.3
Author: Daniel Söderholm @ Microsoft UK Public Sector
Last Updated: 19/07/2023
Documented by: Github Copilot

Todo:

- Add parameterisation (if that would be useful?)
- Create a version that uses a CSV as the index instead of a storage table
- Write logs to Log Analytics instead of a local file
- Rewrite as a function based on a blob create trigger
- Optimise the script to reduce the number of transactions
#>

<#
# Do this stuff if you need to

Install-Module AzTable
Import-Module AzTable
Connect-AzAccount
#>

param (
    [switch]$Force = $false,
    [switch]$Check = $false
)

# Set your Azure subscription ID, storage account name, container name, table name, resource group name, and log file here

$subscriptionId = "xxxxxx-xxxxxx-xxxxxx"
$storageAccountName = "storageacct123"
$containerName = "blobcontainer"
$tablename = "index"
$resourceGroupName = "rg-storage-1"
$logfile = ".\log.txt"

# What tags do we want?
# Add more here (up to a maximum of 10) if you need to, but remember to add them to the $tags, $logstring, and $tagnames variables below as well

$tag1 = "FileName"
$tag2 = "ReferenceNumber"
$tag3 = "CreationDate"
$tag4 = "Classification"
$tag5 = "FileOwner"

# Thus beginneth the script

Write-Host "============================"
Write-Host "|  Blob Index Tag Updater  |"
Write-Host "============================"
Write-Host "Connecting to subscription: $($subscriptionId)"
Write-Host "Storage account: $($storageAccountName)"
Write-Host "Blob container: $($containerName)"
Write-Host "Index tag table: $($tablename)"
Write-Host "Log file: $($logfile)"
Write-Host "Force overwrite enabled: $($force)"
Write-Host "Table check enabled: $($check)"
Write-Host "==========================="

Set-AzContext -SubscriptionId $subscriptionId | Out-Null

$storageaccount = Get-AzStorageAccount -ResourceGroupName $resourceGroupName -AccountName $storageAccountName
$ctx = $storageaccount.Context
$storagetable = Get-AzStorageTable -Name $tablename -Context $ctx
$cloudtable = $storagetable.CloudTable
$bloblist = Get-AzStorageBlob -Container $containerName -Context $ctx
$tagnames = @($tag1, $tag2, $tag3, $tag4, $tag5)

if ($Force -eq $true -and $Check -eq $true)
{
    Write-Host "Force and check cannot be used together. Please specify only one of these parameters."
    exit
}

# If no blobs are found in the container, exit the script

if ($null -eq $bloblist)
    {
        Write-Host "No blobs found in container: $($containerName)"
        exit
    }

# Check for blobs that are present in the index table but missing from the blob container

Write-Host "Checking for missing blobs..."
$tablerows = Get-AzTableRow -table $cloudtable
foreach ($row in $tablerows)
{
    $blobName = $row.RowKey
    if ($blobname -in $bloblist.Name)
    {
        Write-Host "Blob found for record: $blobName"
        $logstring = "$(Get-Date) CHECK_BLOBS Blob found for record: $blobName"
    }
    else
    {
        Write-Host "Table record found but no matching blob exists in the container: $blobName"
        $logstring = "$(Get-Date) CHECK_BLOBS Table record found but no matching blob exists in the container: $blobName"
    }
    Add-Content $logfile -Value $logstring
}
Write-Host "==========================="

# Check for blobs that are present in the the container but do not have a corresponding entry in the index table

Write-Host "Checking for missing table rows..."

foreach ($blob in $bloblist)
{
    $blobname = $blob.Name
    $taglist = Get-AzTableRow -table $cloudtable -customFilter "(RowKey eq '$($blob.Name)')" -ErrorAction SilentlyContinue
    $tags = @{$tag1 = $taglist.$tag1; $tag2 = $taglist.$tag2; $tag3 = $taglist.$tag3; $tag4 = $taglist.$tag4; $tag5 = $taglist.$tag5}
    $tagsmatch = $true

    Write-Host "---"
    Write-Host "Checking blob: $blobname"

    # If blob has no tags and there is no entry in the index table, log it and skip to the next blob

    if ($null -eq $taglist)
    {
        Write-Host "Blob found but no matching table record exists: $blobname"
        $logstring = "$(Get-Date) CHECK_BLOBS Blob found but no matching table record exists: $blobname"
    }

    else

    # If there is a record in the index table, check it against the tags on the blob

    {
        Write-Host "Table record found for blob: $blobname"
        $logstring = "$(Get-Date) CHECK_BLOBS Table record found for blob: $blobname"
        Add-Content $logfile -Value $logstring
        Write-Host "Checking for missing or incorrect tags..."
        $currenttags = Get-AzStorageBlobTag -Context $ctx -Container $containerName -Blob $blob.Name

        # If blob has tags, check if they match the tags in the index table

            foreach ($tag in $tagnames)
            {
                if ($currenttags.$tag -ne $taglist.$tag)
                {
                    Write-Host "Blob $($blob.Name) found but tags are missing or incorrect: [$tag] (current value [$($currenttags.$tag)] should be [$($taglist.$tag)])"
                    $logstring = "$(Get-Date) CHECK_BLOBS Blob $($blob.Name) found but missing or incorrect tag: [$tag] (current value [$($currenttags.$tag)] should be [$($taglist.$tag)])"
                    $tagsmatch = $false
                    Add-Content $logfile -Value $logstring
                }
                elseif ($currenttags.$tag -eq $taglist.$tag)
                {
                    Write-Host "Blob $($blob.Name) found and tags match: [$tag] (current value [$($currenttags.$tag)] matches [$($taglist.$tag)])"
                    $logstring = "$(Get-Date) CHECK_BLOBS Blob $($blob.Name) found and tags match: [$tag] (current value [$($currenttags.$tag)] matches [$($taglist.$tag)])"
                    Add-Content $logfile -Value $logstring
                }
            }
        }

    if ($tagsmatch -ne $true -and $check -ne $true)
    {
        if ($force -ne $true)
        {
        Write-Host "Do you want to correct the tags for file $($blob.Name)? (Specify the -Force switch to overwrite all tags without being prompted.)"
        $overwrite = Read-Host -Prompt "(Y/y to continue, any other key to skip)"
        }
        if ($overwrite -eq "Y" -or $overwrite -eq "y" -or $force -eq $true)
        {
            Write-Host "Overwriting tags..."
            Set-AzStorageBlobTag -Context $ctx -Container $containerName -Blob $blob.Name -Tag $tags | Out-Null
            $logstring = "$(Get-Date) OVERWRITE_TAG Blob: $($blobname) $($tag1): $($taglist.$tag1) $($tag2): $($taglist.$tag2) $($tag3): $($taglist.$tag3) $($tag4): $($taglist.$tag4) $($tag5): $($taglist.$tag5) Force: $($force)"
            Add-Content $logfile -Value $logstring
        }
        else
        {
            Write-Host "No changes made to blob: $($blob.Name)"
        }
    }
}

Write-Host "==========================="
Write-Host "|   Blob check complete   |"
Write-Host "==========================="
