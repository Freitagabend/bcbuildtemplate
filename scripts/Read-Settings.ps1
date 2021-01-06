Param(
    [ValidateSet('AzureDevOps', 'Local', 'AzureVM')]
    [Parameter(Mandatory = $false)]
    [string] $buildEnv = "AzureDevOps",

    [Parameter(Mandatory = $false)]
    [string] $version = $ENV:VERSION,

    [Parameter(Mandatory = $false)]
    [string] $buildProjectFolder = $ENV:BUILD_REPOSITORY_LOCALPATH,

    [Parameter(Mandatory = $false)]
    [string] $appVersion = ""
)

if ($appVersion) {
    write-host "##vso[build.updatebuildnumber]$appVersion"
}


$settings = (Get-Content ((Get-ChildItem -Path $buildProjectFolder -Filter "build-settings.json" -Recurse).FullName) -Encoding UTF8 | Out-String | ConvertFrom-Json)
if ("$version" -eq "") {
    $version = $settings.versions[0].version
    Write-Host "Version not defined, using $version"
}

$imageName = "build"
$property = $settings.PSObject.Properties.Match('imageName')
if ($property.Value) {
    $imageName = $property.Value
}

$property = $settings.PSObject.Properties.Match('bccontainerhelperVersion')
if ($property.Value) {
    $bccontainerhelperVersion = $property.Value
}
else {
    $bccontainerhelperVersion = "latest"
}
Write-Host "Set bccontainerhelperVersion = $bccontainerhelperVersion"
Write-Host "##vso[task.setvariable variable=bccontainerhelperVersion]$bccontainerhelperVersion"

$appFolders = $settings.appFolders
Write-Host "Set appFolders = $appFolders"
Write-Host "##vso[task.setvariable variable=appFolders]$appFolders"

$testFolders = $settings.testFolders
Write-Host "Set testFolders = $testFolders"
Write-Host "##vso[task.setvariable variable=testFolders]$testFolders"

$property = $settings.PSObject.Properties.Match('azureBlob')
if ($property.Value) {
    Write-Host "Set azureStorageAccount = $($settings.azureBlob.azureStorageAccount)"
    Write-Host "##vso[task.setvariable variable=azureStorageAccount]$($settings.azureBlob.azureStorageAccount)"
    Write-Host "Set azureContainerName = $($settings.azureBlob.azureContainerName)"
    Write-Host "##vso[task.setvariable variable=azureContainerName]$($settings.azureBlob.azureContainerName)"            
}
else {
    Write-Host "Set azureStorageAccount = ''"
    Write-Host "##vso[task.setvariable variable=azureStorageAccount]''"
}

$imageversion = $settings.versions | Where-Object { $_.version -eq $version }
if ($imageversion) {
    Write-Host "Set artifact = $($imageVersion.artifact)"
    Write-Host "##vso[task.setvariable variable=artifact]$($imageVersion.artifact)"
    
    "reuseContainer" | ForEach-Object {
        $property = $imageVersion.PSObject.Properties.Match($_)
        if ($property.Value) {
            $propertyValue = $property.Value
        }
        else {
            $propertyValue = $false
        }
        Write-Host "Set $_ = $propertyValue"
        Write-Host "##vso[task.setvariable variable=$_]$propertyValue"
    }
    if ($imageVersion.PSObject.Properties.Match("imageName").Value) {
        $imageName = $imageversion.imageName
    }
}
else {
    throw "Unknown version: $version"
}

if ("$($ENV:AGENT_NAME)" -eq "Hosted Agent" -or "$($ENV:AGENT_NAME)" -like "Azure Pipelines*") {
    $containerNamePrefix = ""
    Write-Host "Set imageName = ''"
    Write-Host "##vso[task.setvariable variable=imageName]"
}
else {
    if ($imageName -eq "") {
        $containerNamePrefix = "bld-"
    }
    else {
        $containerNamePrefix = "$imageName-"
    }
    Write-Host "Set imageName = $imageName"
    Write-Host "##vso[task.setvariable variable=imageName]$imageName"
}
$containerName = "$($containerNamePrefix)$("$($ENV:AGENT_NAME)" -replace '[^a-zA-Z0-9]', '')"
Write-Host "Set containerName = $containerName"
Write-Host "##vso[task.setvariable variable=containerName]$containerName"

$testCompanyName = $settings.TestMethod.companyName
Write-Host "Set testCompanyName = $testCompanyName"
Write-Host "##vso[task.setvariable variable=testCompanyName]$testCompanyName"

$testCodeunitId = $settings.TestMethod.CodeunitId
Write-Host "Set testCodeunitId = $testCodeunitId"
Write-Host "##vso[task.setvariable variable=testCodeunitId]$testCodeunitId"

$testMethodName = $settings.TestMethod.MethodName
Write-Host "Set testMethodName = $testMethodName"
Write-Host "##vso[task.setvariable variable=testMethodName]$testMethodName"
