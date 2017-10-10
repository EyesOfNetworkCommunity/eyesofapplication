#*********************************************************************************************************************************************#
#*                                                                                                                                           *#
#* Powershell                                                                                                                                *#
#* Author:LEVY Jean-Philippe                                                                                                                 *#
#*                                                                                                                                           *#
#* Script Function: Purge des images de debug EON4APPPS Purge debug pictures of EON4APPS                                                                                      *#
#*                                                                                                                                           *#
#*********************************************************************************************************************************************#

# Path recovery
$ScriptPath = (Split-Path ((Get-Variable MyInvocation).Value).MyCommand.Path) 

# Variables and Fonctions
$Init = $ScriptPath + "\init.ps1"
If (!(Test-Path $Init)){ throw [System.IO.FileNotFoundException] "$Init not found" }
. $Init

# Purge
$Minutes="60"
Get-ChildItem -Path $Path\log\ -Filter *.bmp -Force | Where-Object { $_.CreationTime -lt (Get-Date).AddMinutes(-$Minutes) } | Remove-Item -Force -Recurse