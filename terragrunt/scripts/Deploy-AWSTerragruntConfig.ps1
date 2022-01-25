# This script takes parameters used to build the filepath to start a terragrunt deployment.
# It is required that this script be at the root of the Terragrunt parameters folder.
# It is designed to be run in ADO with parameter values set by variables

# NOTE: Due to the way Powershell and ADO handles stderr/redirection, this task
# needs to be run in ErrorActionPreference = 'Continue' and then we check
# $LASTEXITCODE on operations to make sure there's no failure.

[CmdletBinding()]
param (
    [string]
    $AccountName = $env:tgAccountName,

    [string]
    $Region = $env:tgRegion,

    [string]
    $Environment = $env:tgEnvironment,

    [string]
    $ServiceName = $env:tgServiceName,

    # Only run plan if you want
    [bool]
    $PlanOnly = $false
)

# Set env var to tell Terraform it's running in automation pipeline
$env:TF_IN_AUTOMATION = 'true'

# Create a low-level folder for the TG cache so that we don't run in to errors with long files names
$tgCachePath = 'c:\tgcache'
$null = New-Item -Path $tgCachePath -Force -ItemType Directory
$env:TERRAGRUNT_DOWNLOAD = $tgCachePath

# Build path for terragrunt config file
$terragruntPath = Join-Path -Path $PSScriptRoot -ChildPath $AccountName -AdditionalChildPath @($Region, $Environment, $ServiceName)

Write-Host "Setting location to $terragruntPath"
$null = Set-Location -Path $terragruntPath
Write-Host 'Running terragrunt init'
& terragrunt init --terragrunt-source-update

Write-Host 'Running terragrunt plan'
& terragrunt plan -out=tfplan -input=false
if ($LASTEXITCODE -ne 0) {
    throw 'Terragrunt plan failed.'
}

if (! $PlanOnly) {
    Write-Host 'Running terragrunt apply'
    & terragrunt apply -auto-approve -input=false tfplan
    if ($LASTEXITCODE -ne 0) {
        throw "Terragrunt apply failed."
    }
}

