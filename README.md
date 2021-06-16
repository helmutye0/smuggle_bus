# smuggle_bus
file type evasion tool

## About

Welcome to Smuggle Bus, your ultimate (or at least pretty good) file type bypass tool

Smuggle Bus was created by Jason Caminsky--direct feedback to @helmutye0 on twitter

This tool was created purely for education, research, and legitimate use--if you do bad things with it, it's on you

### Features remaining to be implemented:

- auto upload (need to figure out a reliable way to do this--with lots of different auth types this might be tricky)
- bash implementation (with mutual compatibility--smuggle buses created with powershell should be extractable via bash, and vice versa)

## Usage Instructions

Smuggle Bus takes "contraband" file(s) you specify and embed into a random jpg or other file you specify, or it extracts a file so embedded. You also have the option of creating an encrypted archive for one or more contraband files for enhanced obfuscation. The combination of mask file + embedded file is known in this script as a "smuggle bus".

### Basic Smuggle Bus Useage is as follows:

	.\smuggle_bus.ps1 -mode [on/off] -contraband [path to file(s) to smuggle] -busPath [path for smuggle buses; default is CWD] -outPath [path for extracted files; default is CWD] -archive [set to $true to enable archive mode] -archivePassword [password for encrypted archive; default is random password] -maskFile [specific mask file you want to use; default is random jpg] -label [smuggle bus file label]

### Here is a detailed summary of parameters:
- mode : enter either on or off.	On mode embeds files. Off mode extracts them
- contraband : in On mode, this is the path to the file(s) you want to embed into your image mask. Supports wildcards (ex C:\path\*.xlsx). No function in Off mode
- busPath : Default current directory. This specifies where your smuggle buses will come out (in On mode) or where your smuggle buses to be extracted are (in Off mode)
- outpath : Default current directory. This specifies where your extracted files will come out (in Off mode). No function in On mode
- archive : Default $false, supply value $true to enable. Option to zip up contraband file(s) in an encrypted archive in On mode. No function in Off mode. NOTE: archiving requires either 7zip or winRAR on host
- archivePassword: Default get-random. The password used to encrypt the archive if archive is enabled
 - maskFile : Default random jpg. Option to specify a specific file you want to embed your contraband file(s) in On mode. No function in Off mode
- label : in Off mode, this is the label Smuggle Bus will use to find and extract smuggle buses in the busPath. Supports multiple labels separated by a comma (ex. -label 123,234,345). No function in On mode

### Here are some examples of useage:
- .\smuggle_bus.ps1 -mode on -contraband "C:\Path\to\File.exe" : Will embed File.exe into a random jpg and deposit it in current directory
- .\smuggle_bus.ps1 -mode on -contraband "C:\Path\to\File.exe" -busPath "C:\Other\Path\" :	Will embed File.exe into a random jpg and deposit it at C:\Other\Path\
- .\smuggle_bus.ps1 -mode on -contraband "C:\Path\to\File.exe" -busPath "C:\Other\Path\" -archive $true : Will archive File.exe into a randomly named zip file protected by a random password, then embed it into a random jpg and deposit it at C:\Other\Path\
- .\smuggle_bus.ps1 -mode on -contraband "C:\Path\to\*.xlsx" -busPath "C:\Other\Path\" -archive $true -archivePassword "wahoo" -maskFile "C:\path\to\mask\jamz.mp4 : Will archive all xlsx files in C:\Path\to\ directory into a randomly named zip file protected by the password "wahoo", then embed it into C:\path\to\mask\jamz.mp4 and deposit it at C:\Other\Path\
- .\smuggle_bus.ps1 -mode off -label 123 : Will search current directory for all files labeled with 123 and attempt to extract the embedded file
- .\smuggle_bus.ps1 -mode off -busPath "C:\Other\Path\" -label 123 : Will search C:\Other\Path\ for any files labeled with 123 and attempt to extract the embedded file into the current directory
- .\smuggle_bus.ps1 -mode off -busPath "C:\Other\Path\" -outPath "C:\Still\another\Path\" -label 123 : Will search C:\Other\Path\ for any files labeled with 123 and	attempt to extract the embedded file into C:\Still\another\Path\
