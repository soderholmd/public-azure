# Update-BlobTags.ps1

## Overview

This is a PowerShell script for writing index tags to blobs in Azure blob containers. [Blob index tags](https://learn.microsoft.com/en-us/azure/storage/blobs/storage-blob-index-how-to?tabs=azure-portal) are a great way to store additional metadata about blobs, that you can use for automation, Power BI reporting, or just storing extra info for other purposes. 

With this script, you can store all of the index tags for a specific blob in an Azure storage table, and then write them to the blobs. It came about because a customer was looking to use Azure Data Box to upload blobs, but Data Box does not support index tags as it uses an older version of the storage API. So, we needed a way to store the tags that we wanted, and once the blobs had been uploaded to Azure, write all of the tags to the correct blobs. You may find other uses; for example, if you routinely do an export of metadata from one system and want blob index tags to be updated.

The script connects to the specified subscription and storage account, retrieves a list of blobs in the specified container, and checks if each blob has tags. 
If the blob has tags, the script prompts the user to overwrite them. If the user chooses to overwrite the tags, the script updates the tags of the blob with data from the Azure Table. If the blob does not have tags, the script writes new tags to the blob.

I used table storage as a PoC, but it could equally be replaced by a CSV or any other convenient format.

## How to use it

1. Create a storage account with a blob container and a table
2. Decide what tags you want (up to 10, each up to 255 characters)
3. In the table, create the records you want. (You can use [Storage Explorer](https://azure.microsoft.com/en-gb/products/storage/storage-explorer), or find a way to import CSV, etc.) For example, you might want the fields `FileName`, `ReferenceNumber`, `CreationDate`, `Classification`, `FileOwner`. You can use `FileName` as the row key as it will be unique within a blob container, or you can have `FileName` as a separate field and use a numerical value as the row key. Note that all values must be of the `string` type, as index tags do not support other types

Example table:

|PartitionKey|RowKey|FileName|ReferenceNumber|CreationDate|Classification|FileOwner|
|---|---|---|---|---|---|---|
|partition1|1|file1.zip|ABC123|2023-01-01|Public|nromanoff|
|partition1|2|file2.zip|BCD234|2023-02-02|Secret|tstark|
|partition1|3|file3.zip|CDE345|2023-03-03|Superdupersecret|bbanner|

_Note: Azure will automatically insert a timestamp on each record, which can be ignored unless you want to use it for something_

4. Update the PowerShell script:

**Environment settings**
```
$subscriptionId = "xxxxxx-xxxxxx-xxxxxx"
$storageAccountName = "storageacct123"
$containerName = "blobcontainer"
$tablename = "index"
$resourceGroupName = "rg-storage-1"
$logfile = ".\log.txt"
```

**Tag names**
```
$tag1 = "FileName"
$tag2 = "ReferenceNumber"
$tag3 = "CreationDate"
$tag4 = "Classification"
$tag5 = "FileOwner"
```

5. Run the script (you may need to `Install-Module AzTable`, `Import-Module AzTable`, and/or `Connect-AzAccount` first)

### Options

The script has two flags:

- `-Check` will check each blob and each tag to see if they match and report on any mismatches, but will not overwrite tags
- `-Force` will overwrite all index tags using the values in the table

If you specify neither option (normal mode), it will tell you if a mismatch is found and ask if you want to skip or overwrite.

### Notes

- If you want to add more tags (up to a maximum of 10), first add them to the tags list (`$tag6`..`$tag10`), then add them to where those tags are being used: `$tagnames` array on line 98, `$tags` array on line 143, `$logstring` on line 199
- It's not very pretty because I'm not very good at PowerShell. Please forgive!
- It was originally created for a specific use case. I've tried to generalise it a bit but I'm not sure how useful it is to anyone else. Mostly publishing as a reminder as I couldn't find anything else that did the same job
- I've tested it in a few different scenarios and it seems to work the way I want it to, but please do your own tests and treat as sample code, not ready for production use
- You will need appropriate permissions on both the blob container and the table storage
- Tag values are case-sensitive, so `file1.zip` will NOT match `File1.zip` or `FILE1.ZIP`

### Todo

- Add parameterisation (if that would be useful?)
- Create a version that uses a CSV as the index instead of a storage table
- Write logs to Log Analytics instead of a local file
- Rewrite as a function based on a blob create trigger
- Optimise the script to reduce the number of transactions
