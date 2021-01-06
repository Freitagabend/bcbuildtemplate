Param(
    [ValidateSet('AzureDevOps','Local','AzureVM')]
    [Parameter(Mandatory=$false)]
    [string] $buildEnv = "AzureDevOps",

    [Parameter(Mandatory=$false)]
    [string] $containerName = $ENV:CONTAINERNAME,

    [Parameter(Mandatory=$false)]
    [string] $buildProjectFolder = $ENV:BUILD_REPOSITORY_LOCALPATH,

    [switch] $skipVerification
)

$settings = (Get-Content ((Get-ChildItem -Path $buildProjectFolder -Filter "settings.json" -Recurse).FullName) | ConvertFrom-Json)
$settings.dependencies | ForEach-Object {
    Write-Host "Publishing $_"
    Publish-BCContainerApp -containerName $containerName -appFile $_ -skipVerification:$skipVerification -sync -install
}