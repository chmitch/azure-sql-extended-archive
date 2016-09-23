# Notes
# ------------------------------------------------------------------------------------------ 
# You can copy a database to a new resource group and server if you'd like but I 
# don't expect this database to be around long so I find that level of abstraction
# unnecessary and place the database in the existing resoruce group.
# ------------------------------------------------------------------------------------------ 

# Sign in to Azure and set the subscription to work with
$subscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
Add-AzureRmAccount
Set-AzureRmContext -SubscriptionId $subscriptionId


# Define the source datbase, server, and resoruce group
$sourceDatabase = "<source database>"
$sourceServer = "<source server>"
$sourceResourceGroup = "<source resource group>"

# Define output location for bacpac
$storageAccount = "<blob account>.blob.core.windows.net"
$storageContainer = "<blob container>"
$storageKeyType = "StorageAccessKey"
$storageKey = "<storage key>"

# Admin credentials for the database
$adminUser = "<admin user name>"
$adminPassword = "<admin password>"

# Generating a unique name for the databse copy and the uri for the bacpac.
$destinationDatabase = $sourceDatabase + (Get-Date).ToString("yyyyMMddHHmm") 
$bacpacUri = "https://" + $storageAccount + "/" + $storageContainer + "/" + $destinationDatabase + ".bacpac"

# Execute the copy command
New-AzureRmSqlDatabaseCopy -ResourceGroupName $sourceResourceGroup `
                           -ServerName $sourceServer `
                           -DatabaseName $sourceDatabase `
                           -CopyDatabaseName $destinationDatabase


# Note:  Exporting to a bacpac requires you to have an account and password for an admin.
#        If you do not include this the command will ask for it at execution time.
$exportRequest = New-AzureRmSqlDatabaseExport   –ResourceGroupName $sourceResourceGroup `
                                                –ServerName $sourceServer `
                                                –DatabaseName $destinationDatabase `
                                                –StorageKey $storageKey `
                                                -StorageUri $BacpacUri `
                                                –StorageKeytype $storageKeyType `
                                                –AdministratorLogin $adminUser `
                                                –AdministratorLoginPassword $adminPassword

# The DatabaseExport command is async so check status of the export every 10 seconds
do
{
    $status = Get-AzureRmSqlDatabaseImportExportStatus -OperationStatusLink $exportRequest.OperationStatusLink
    Write-Host $status.StatusMessage
    Start-Sleep -s 10
} while($status.Status -eq "InProgress")


#Now that the export is done, delete the databse.
Remove-AzureRmSqlDatabase  -ResourceGroupName $sourceResourceGroup `
                           -ServerName $sourceServer `
                           -DatabaseName $destinationDatabase