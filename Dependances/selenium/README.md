# Selenium Drivers Installation

## PowerShell - DotNet

Selenium need PowerShell 4.0 at least. If you run EOA on Windows7, please update PowerShell following this link: https://www.microsoft.com/fr-FR/download/details.aspx?id=40855.

You also need the Microsoft .NET Framework 4.5, available here: https://www.microsoft.com/fr-fr/download/details.aspx?id=30653

## C# Packages

EOA uses Selenium C# package, so you have to download and install it:
- Download Selenium Client & WebDriver Language Bindings, C# version: https://www.seleniumhq.org/download/
- Extract file (rename `.nupkg` to `.zip`)
- Copy `WebDriver.dll` and  `WebDriver.Support.dll` to the selenium folder

## Browser Packages

Selenium needs web browsers to work:
- Download IE, Firefox or Chrome driver from the Selenium download page: https://www.seleniumhq.org/download/
- Extract and copy drivers to the selenium folder
