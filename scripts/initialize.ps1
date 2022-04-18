param(
    [Parameter(Mandatory=$True, Position=0, ValueFromPipeline=$false)]
    [System.String]
    $env,
    [Parameter(Mandatory=$True, Position=1, ValueFromPipeline=$false)]
    [System.String]
    $client_id,
    [Parameter(Mandatory=$True, Position=2, ValueFromPipeline=$false)]
    [System.String]
    $client_secret,
    [Parameter(Mandatory=$True, Position=3, ValueFromPipeline=$false)]
    [System.String]
    $tenant_id,
    [Parameter(Mandatory=$True, Position=4, ValueFromPipeline=$false)]
    [System.String]
    $subscription_id
)
$tf = New-Object PSObject -Property @{
    RESOURCE_GROUP_NAME = 'terraform-state-'+$env
    STORAGE_ACCOUNT_NAME = 'terraformstate'+$env #storage account name
    STORAGE_CONTAINER_NAME = 'terraform-state-'+$env #STORAGE_CONTAINER_NAME name
    LOCATION_NAME = 'australiasoutheast' #location
}

Write-Host 'Environemt:' $env

# login to the azure using service principal, you can use many other options to login to az cli'
Write-Output 'Login to tenant: ' $tenant_id
az login --service-principal -u $client_id -p $client_secret --tenant $tenant_id

Write-Host 'Set subscription id: '  $subscription_id
az account set --subscription $subscription_id

function Add-Resources() { 

    #******** CREATE RESOURCE GROUP ************#
    try{
        Write-Host 'Creating resource group: '$tf.RESOURCE_GROUP_NAME
        # create resource group
        az group create --name $tf.RESOURCE_GROUP_NAME --location $tf.LOCATION_NAME
        Write-Output $tf.RESOURCE_GROUP_NAME ' resource group created sucessfully!.'
    }
    catch{
        Write-Output 'Unable to create resources group ' $tf.RESOURCE_GROUP_NAME
        Write-Output $_
    }

    #******** CREATE STORAGE ACCOUNT ************#
    try {
        Write-Host 'Creating storage account: '$tf.STORAGE_ACCOUNT_NAME
        # create storage account
        az storage account create --resource-group $tf.RESOURCE_GROUP_NAME --name $tf.STORAGE_ACCOUNT_NAME --sku 'Standard_LRS' --encryption-services 'blob'
        Write-Output $tf.STORAGE_ACCOUNT_NAME ' storage account created sucessfully!.'
    }
    catch{
        Write-Output 'Unable to create storage account ' $tf.STORAGE_ACCOUNT_NAME
        Write-Output $_
    }

    #******** CREATE STORAGE CONTAINER ************#
    try {
        Write-Host 'Creating container: '$tf.STORAGE_CONTAINER_NAME
        # create storage container
        az storage container create --name $tf.STORAGE_CONTAINER_NAME --account-name $tf.STORAGE_ACCOUNT_NAME
        Write-Host $tf.STORAGE_CONTAINER_NAME ' container created sucessfully!.'
    }
    catch{
        Write-Output 'Unable to create container ' $tf.STORAGE_CONTAINER_NAME
        Write-Output $_
    }
}

try{

    Write-Host 'Checking whether resource group exixts...'
    $rsgExists = az group exists -n $tf.RESOURCE_GROUP_NAME

    if ($rsgExists -eq 'false') {
        Write-Host 'Resource group does not exists and creating the resources for terraform...'
        Add-Resources
    }
    else
    {
        Write-Host 'Resource group ' $tf.RESOURCE_GROUP_NAME ' already exists!. Exiting.'
    }

}
catch{
    Write-Output 'Exception raised while cheking container exists'
    Write-Output $_
}
