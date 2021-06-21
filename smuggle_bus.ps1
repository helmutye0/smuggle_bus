# smuggle bus

<## About

Welcome to Smuggle Bus, your ultimate (or at least pretty good) file type bypass tool

Smuggle Bus was created by Jason Caminsky--direct feedback to @helmutye0 on twitter

This tool was created purely for education, research, and legitimate use--if you do bad things with it, it's on you

Features remaining to be implemented:
	- auto upload (need to figure out a reliable way to do this--with lots of different auth types this might be tricky)
	- bash implementation (with mutual compatibility--smuggle buses created with powershell should be extractable via bash, and vice versa)

##>

<## Usage Instructions

Smuggle Bus takes "contraband" file(s) you specify and embed into a random jpg or other file you specify, or it extracts a file so embedded. You also have the option of creating an encrypted archive for one or more contraband files for enhanced obfuscation. The combination of mask file + embedded file is known in this script as a "smuggle bus".

Here is a detailed summary of parameters:
 	-mode : enter either on or off.	On mode embeds files. Off mode extracts them
 	-contraband : in On mode, this is the path to the file(s) you want to embed into your image mask. Supports wildcards (ex C:\path\*.xlsx). No function in Off mode
 	-busPath : Default current directory. This specifies where your smuggle buses will come out (in On mode) or where your smuggle buses to be extracted are (in Off mode)
	-outpath : Default current directory. This specifies where your extracted files will come out (in Off mode). No function in On mode
 	-archive : Default $false, supply value $true to enable. Option to zip up contraband file(s) in an encrypted archive in On mode. No function in Off mode. NOTE: archiving requires either 7zip or winRAR on host
	-archivePassword: Default get-random. The password used to encrypt the archive if archive is enabled
 	-maskFile : Default random jpg. Option to specify a specific file you want to embed your contraband file(s) in On mode. No function in Off mode
	-label : in Off mode, this is the label Smuggle Bus will use to find and extract smuggle buses in the busPath. Supports multiple labels separated by a comma (ex. -label 123,234,345). No function in On mode

 Here are some examples of useage:
	 * .\smuggle_bus.ps1 -mode on -contraband "C:\Path\to\File.exe" : Will embed File.exe into a random jpg and deposit it in current directory
	 * .\smuggle_bus.ps1 -mode on -contraband "C:\Path\to\File.exe" -busPath "C:\Other\Path\" :	Will embed File.exe into a random jpg and deposit it at C:\Other\Path\
	 * .\smuggle_bus.ps1 -mode on -contraband "C:\Path\to\File.exe" -busPath "C:\Other\Path\" -archive $true : Will archive File.exe into a randomly named zip file protected by a random password, then embed it into a random jpg and deposit it at C:\Other\Path\
	 * .\smuggle_bus.ps1 -mode on -contraband "C:\Path\to\*.xlsx" -busPath "C:\Other\Path\" -archive $true -archivePassword "wahoo" -maskFile "C:\path\to\mask\jamz.mp4 : Will archive all xlsx files in C:\Path\to\ directory into a randomly named zip file protected by the password "wahoo", then embed it into C:\path\to\mask\jamz.mp4 and deposit it at C:\Other\Path\
	 
	 * .\smuggle_bus.ps1 -mode off -label 123 : Will search current directory for all files labeled with 123 and attempt to extract the embedded file
	 * .\smuggle_bus.ps1 -mode off -busPath "C:\Other\Path\" -label 123 : Will search C:\Other\Path\ for any files labeled with 123 and attempt to extract the embedded file into the current directory
	 * .\smuggle_bus.ps1 -mode off -busPath "C:\Other\Path\" -outPath "C:\Still\another\Path\" -label 123 : Will search C:\Other\Path\ for any files labeled with 123 and	attempt to extract the embedded file into C:\Still\another\Path\
	 
Basic Smuggle Bus Useage is as follows:

	 .\smuggle_bus.ps1 -mode [on/off] -contraband [path to file/file(s) to smuggle] -busPath [path for smuggle buses; default is CWD] -outPath [path for extracted files; default is CWD] -archive [set to $true to enable archive mode] -archivePassword [password for encrypted archive; default is random password] -maskFile [specific mask file you want to use; default is random jpg] -label [smuggle bus file label] 

##>

## code

### params

Param (
	[string]$mode, # mask on / mask off mode switch
	[string]$contraband, # file(s) we're hiding
	[int32[]]$label, # the label(s) hidden inside smuggle buses that we use to recognize and extract them
	[string]$busPath=".\", # path in which to look for smuggle buses
	[string]$outPath=".\", # path to output extracted files in off mode
	[bool]$archive, # option to zip up contents of contraband path into encrypted archive before smuggling in on mode
	[string]$maskFile, # option to specify a particular mask file
	[string]$archivePassword=(Get-Random) # password for encrypted archive, only works if $archive is true
)

write-host "`n`n"

### mask on filters

if (($mode -eq "on") -and (!$contraband)) {
	write-host "!!! When using mask on mode, you must specify a -contraband file"
	break
}

if (($mode -eq "on") -and ($archive)) {
	$7zip = Test-Path "c:\Program Files\7-Zip\7z.exe"
	$winRAR= Test-Path "c:\Program Files\winRAR\winRAR.exe"
	
	if ((!$7zip) -and (!$winRAR)) {
		write-host "!!! Archive mode specified, but host does not have 7zip or winRAR"
		break
	}
	
	if ($archivePassword -match " ") {
		write-host "!!! Archive password contains spaces--this is not permitted by script. Please use password without spaces"
		break
	}
	
## archive
	
	if ($7zip) {
		$random = Get-Random
		$random2 = Get-Random
		$archiveFile = "$busPath\$random"
		$archiveFile2 = "$busPath\$random2"
		$command1 = "`"c:\Program Files\7-Zip\7z.exe`" a $archiveFile`.zip `"$contraband`""
		$command2 = "`"c:\Program Files\7-Zip\7z.exe`" a $archiveFile2`.zip $archiveFile -p$archivePassword"
		cmd.exe /c $command1
		Rename-Item -Path "$archiveFile`.zip" -NewName "$archiveFile"
		cmd.exe /c $command2
		Rename-Item -Path "$archiveFile2`.zip" -NewName "$archiveFile2"
		$contraband = (Get-ChildItem $archiveFile2).FullName
		write-host "*** archive file $archiveFile2 created`nArchive Password is `"$archivePassword`" (not including quotes)"
	}
	
	if ((!$7zip) -and ($winRAR)) {
		$random = Get-Random
		$random2 = Get-Random
		$archiveFile = "$busPath\$random`.zip"
		$archiveFile2 = "$busPath\$random2`.zip"
		$command1 = "`"c:\Program Files\winRAR\winRAR.exe`" a $archiveFile`.zip `"$contraband`""
		$command2 = "`"c:\Program Files\winRAR\winRAR.exe`" a $archiveFile2`.zip $archiveFile -p$archivePassword"
		cmd.exe /c $command1
		Rename-Item -Path "$archiveFile`.zip" -NewName "$archiveFile"
		cmd.exe /c $command2
		Rename-Item -Path "$archiveFile2`.zip" -NewName "$archiveFile2"
		$contraband = (Get-ChildItem $archiveFile2).FullName
		write-host "*** archive file $archiveFile2 created`nArchive Password is `"$archivePassword`" (not including quotes)"
	}	
}

if (($mode -eq "on") -and (!$archive)) {
	$archivePassword = "0"
}

### mask on

if ($mode -eq "on") {

#### prep

	$mask=""  # random jpg
	$contrabandCheck="" # check for presence of face file
	$contrabandLength="" # length of the file we're hiding
	$contrabandName="" # name of the file we're hiding
	$newName="" # name of combined random jpg and hidden file
	$embeddedFile="" # contents of the hidden file
	[byte]$combined="" # combined contents of random jpg and hidden file

#### action
	$contrabandFiles=@()
	$contrabandFiles += (Get-Childitem $contraband).FullName
	
	if (!$contrabandFiles) {
		write-host "XXX Specified contraband file not found"
		break
	} else {
		
		ForEach ($f in $contrabandFiles) {
			
			if (!$maskFile) {
				$mask = invoke-webrequest -Uri "https://picsum.photos/500"
				$mask = $mask.content
			} else {
				$mask = Get-Content -encoding byte $maskFile
			}
						
			$contrabandLength = (Get-ChildItem $f).Length
			$contrabandName = (Get-ChildItem $f).BaseName
			$contrabandName += (Get-ChildItem $f).Extension
			$newName = Get-Random
			$newName = "$newName`.jpg"
			$newName = "$busPath\$newName"

			$embeddedFile = get-content -encoding byte $f

			$mask | set-content -encoding byte -Path $newName
			$key = "$contrabandLength$contrabandLength$contrabandLength$contrabandLength$contrabandLength"
			$insert = "$key$contrabandName|$archivePassword$key"
			$insert | add-content -Path $newName
			$embeddedFile | add-content -encoding byte -Path $newName  # we now have a jpg that contains our face file

			$combinedFilePath = (Get-ChildItem $newName).FullName
			write-host "*** $contrabandName has boarded the smuggle bus $combinedFilePath`nTo extract it, use -label $contrabandLength"
			
			if ($archive) {
				del $archiveFile
				del $archiveFile2
			}
		}
	}
	
	write-host "`n`n"
	
}

## mask off filters

if (($mode -eq "off") -and (!$label)) {
	write-host "!!! You must specify a file label (or omit parameter--default value is `"smug`")`n"
	break
}

if (($mode -eq "off") -and ($label -match " ")) {
	write-host "!!! Label contains spaces--this is not permitted by script. Please use label without spaces`n"
	break
}

if (($mode -eq "off") -and (!$busPath)) {
	write-host "!!! When using mask off mode, you must specify a -path`n"
}

## mask off

if ($mode -eq "off") {

### prep

	$combinedFiles=@() # an array to store all labelled files
	$combinedFileName=""
	$contrabandFileName=""
	$fileLength=""
	$key=""
	
### action
	
	ForEach ($l in $label) {
	
		$key="$l$l$l$l$l"
		$combinedFiles=@()
		
		$combinedFiles += (Get-ChildItem $busPath\* | select-string $key).Path
	
		if (!$combinedFiles) {
			write-host "XXX No files with label (`"$l`") found`n"
		} else {

			ForEach ($f in $combinedFiles) {
				$combinedBytes = get-content -encoding byte -Path $f
				$combinedContent = get-content -Path $f
				$combinedFileName = (get-childitem $f).Name
				$pattern = "$key(.*)$key"
				$extract = ([regex]::match($combinedContent,$pattern).Groups[1].Value).Trim()
				$contrabandFileName = $extract.Split("|") | select -index 0
				$archivePasswordExtract = $extract.Split("|") | select -index 1
		
				$fileLength = $l
			
				set-content -Path $outPath\$contrabandFileName ([byte[]]($combinedBytes | select -last $fileLength)) -encoding byte
				write-host "`n*** file $outPath\$contrabandFileName has exited the smuggle bus"
			
				if ($archivePasswordExtract -ne "0") {
					write-host "*** ARCHIVE DETECTED"
				
					$7zip = Test-Path "c:\Program Files\7-Zip\7z.exe"
					$winRAR= Test-Path "c:\Program Files\winRAR\winRAR.exe"
	
					if ((!$7zip) -and (!$winRAR)) {
						write-host "!!! No obvious extraction utility present on current host"
					}
				
					if ($7zip) {
				
						write-host "*** Can unzip via following command:`n"
						write-host "cmd.exe /c `"c:\Program Files\7-Zip\7z.exe`" e $outPath\$contrabandFileName"
						write-host "Archive Password: $archivePasswordExtract"
				
					}
				
					if ((!$7zip) -and ($winRAR)) {
						write-host "*** Can unzip via following command:`n"
						write-host "cmd.exe /c `"c:\Program Files\winRAR\winRAR.exe`" x $outPath\$contrabandFileName"
						write-host "Archive Password: $archivePasswordExtract"
					}
				}
			
			}
		}
	}
	
	write-host "`n`n"
	
}
