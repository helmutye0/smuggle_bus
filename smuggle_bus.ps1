# smuggle bus

<## About

Welcome to Smuggle Bus, your ultimate (or at least pretty good) file type bypass tool

Smuggle Bus was created by Jason Caminsky

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
	[string]$busPath=".\", # path in which to look for files
	[string]$outPath=".\", # path to output extracted files in off mode
	[bool]$archive, # option to zip up contents of specified path into encrypted archive before smuggling, specify password
	[string]$maskFile, # option to specify a particular mask file
	[string]$archivePassword="", # password for encrypted archive, only works if $archive is true
	[bool]$autoExtract # in off mode, automatically extract any archived files
)

write-host "`n`n"

### mask on filters

if (($mode -eq "on") -and (!$contraband)) {
	write-host "!!! When using mask on mode, you must specify a -contraband file`n"
	break
}

if (($mode -eq "on") -and ($maskFile) -and ((Get-ChildItem $maskFile).Length -lt 16000)) {
	write-host "!!! The minimum size for a mask file is 16,000 bytes`n"
	break
}

if (($mode -eq "on") -and ($archive)) {
	$7zip = Test-Path "c:\Program Files\7-Zip\7z.exe"
	$winRAR= Test-Path "c:\Program Files\winRAR\winRAR.exe"
	
	if ((!$7zip) -and (!$winRAR)) {
		write-host "!!! Archive mode specified, but host does not have 7zip or winRAR`n"
		break
	}
	
	if ($archivePassword -match " ") {
		write-host "!!! Archive password contains spaces--this is not permitted by script. Please use password without spaces`n"
		break
	}
	
	if (!$archivePassword) {
		$passChars = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789()_-,.()_-,.()_-,.()_-,.()_-,.@#$%^*()_+-=[];:'\,<.>/?".ToCharArray()
		1..5 | ForEach {  $archivePassword+= $passChars | Get-Random }
	}
	
	if ($7zip) {
		$chars = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789()_-,()_-,()_-,()_-,()_-,".ToCharArray()
		$charsEnd = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray()
		$random=""
		$random2=""
		1..10 | ForEach {  $random+= $chars | Get-Random }
		$random+= $charsEnd | Get-Random
		1..10 | ForEach {  $random2+= $chars | Get-Random }
		$random2+= $charsEnd | Get-Random
		
		$archiveFile = "$busPath\$random"
		$archiveFile2 = "$busPath\$random2"
		$command1 = "`"c:\Program Files\7-Zip\7z.exe`" a $archiveFile`.zip `"$contraband`" -p$archivePassword"
		$command2 = "`"c:\Program Files\7-Zip\7z.exe`" a $archiveFile2`.zip $archiveFile -p$archivePassword"
		cmd.exe /c $command1
		Rename-Item -Path "$archiveFile`.zip" -NewName "$archiveFile"
		cmd.exe /c $command2
		Rename-Item -Path "$archiveFile2`.zip" -NewName "$archiveFile2"
		$contraband = (Get-ChildItem $archiveFile2).FullName
		write-host "*** archive file $archiveFile2 created`nArchive Password is `"$archivePassword`" (not including quotes)"
	}
	
	if ((!$7zip) -and ($winRAR)) {
		$chars = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789()_-,()_-,()_-,()_-,()_-,".ToCharArray()
		$charsEnd = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray()
		$random=""
		$random2=""
		1..10 | ForEach {  $random+= $chars | Get-Random }
		$random+= $charsEnd | Get-Random
		1..10 | ForEach {  $random2+= $chars | Get-Random }
		$random2+= $charsEnd | Get-Random
		
		$archiveFile = "$busPath\$random"
		$archiveFile2 = "$busPath\$random2"
		$command1 = "`"c:\Program Files\winRAR\winRAR.exe`" a $archiveFile`.zip `"$contraband`" -p$archivePassword"
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
	[byte]$nullByte = 0x00

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
				$newName = Get-Random
				$newName = "$newName`.jpg"
				$newName = "$busPath\$newName"
				$mask | set-content -encoding byte -Path $newName
			} else {
				$mask = Get-Content -encoding byte $maskFile
				$newName = (Get-ChildItem $maskFile).Name
				$newName = "$busPath\$newName"
				copy $maskFile $newName
			}
						
			$contrabandLength = (Get-ChildItem $f).Length
			$contrabandName = (Get-ChildItem $f).BaseName
			$contrabandName += (Get-ChildItem $f).Extension
			$contrabandExtension = (Get-ChildItem $f).Extension
			
			if (!$contrabandExtension) { $contrabandExtension = "0" }

			$embeddedFile = get-content -encoding byte $f

			$maskLength = (Get-ChildItem $newName).Length
			$combinedLength = $maskLength*$contrabandLength
			
#### begin label config
			
			#$1key = $contrabandLength
			#$2key = $contrabandLength*2
			#$3key = $contrabandLength*3
			#$4key = $contrabandLength*4
			#$5key = $contrabandLength*5
			#$6key = $contrabandLength*6
			$7key = $contrabandLength*7
			#$8key = $contrabandLength*8
			#$9key = $contrabandLength*9
			
			#$11key = $contrabandLength
			#$22key = $contrabandLength*2
			#$33key = $contrabandLength*3
			#$44key = $contrabandLength*4
			$55key = $contrabandLength*5
			#$66key = $contrabandLength*6
			$77key = $contrabandLength*7
			#$88key = $contrabandLength*8
			#$99key = $contrabandLength*9
			
			$key = "$1key$2key$3key$4key$5key$6key$7key$8key$9key"
			$keyHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::New([System.Text.Encoding]::ASCII.GetBytes($key)))).Hash
			$key = $keyHash.Substring(0,3)
			$key += $keyHash.Substring(($keyHash.length - 5),3)
			$key2 = "$11key$22key$33key$44key$55key$66key$77key$88key$99key"
			$key2Hash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::New([System.Text.Encoding]::ASCII.GetBytes($key2)))).Hash
			$key2 = $key2Hash.Substring(0,3)
			$key2 += $key2Hash.Substring(($key2Hash.length - 5),3)
			
#### end label config			
			
			$insert = "$archivePassword!$contrabandExtension"
			#$insertEncoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($insert))
			$insertEncoded = $insert
			$insertArray = $insertEncoded -split '(?<=\D)(?=\d)'
			1..24|%{[byte](Get-Random -Minimum ([byte]::MinValue) -Maximum ([byte]::MaxValue))} | add-content -Path $newName -encoding byte -NoNewLine
			$key | add-content -NoNewLine -Path $newName
			1..4|%{[byte](Get-Random -Minimum 0 -Maximum 30)} | add-content -Path $newName -encoding byte -NoNewLine
			
			ForEach ($i in $insertArray) {
				$i | add-content -NoNewLine -Path $newName
				1..4|%{[byte](Get-Random -Minimum 0 -Maximum 30)} | add-content -Path $newName -encoding byte -NoNewLine
			}
			
			1..4|%{[byte](Get-Random -Minimum 0 -Maximum 30)} | add-content -Path $newName -encoding byte -NoNewLine
			$key2 | add-content -NoNewLine -Path $newName
			1..52|%{[byte](Get-Random -Minimum ([byte]::MinValue) -Maximum ([byte]::MaxValue))} | add-content -Path $newName -encoding byte -NoNewLine			
			$embeddedFile | add-content -encoding byte -Path $newName  # we now have a jpg that contains our face file
			$mask | select -last 16000 | add-content -encoding byte -Path $newName

			$combinedFilePath = (Get-ChildItem $newName).FullName
			write-host "*** $contrabandName has boarded the smuggle bus $combinedFilePath`nTo extract it, use -label $contrabandLength"
			
			if ($archive) {
				Remove-Item $archiveFile
				Remove-Item $archiveFile2
			}
		}
	}
	
	write-host "`n`n"
	
}

## mask off filters

if (($mode -eq "off") -and (!$label)) {
	write-host "!!! You must specify a file label`n"
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
	
	ForEach ($contrabandLength in $label) {
		
#### begin label config
			
			#$1key = $contrabandLength
			#$2key = $contrabandLength*2
			#$3key = $contrabandLength*3
			#$4key = $contrabandLength*4
			#$5key = $contrabandLength*5
			#$6key = $contrabandLength*6
			$7key = $contrabandLength*7
			#$8key = $contrabandLength*8
			#$9key = $contrabandLength*9
			
			#$11key = $contrabandLength
			#$22key = $contrabandLength*2
			#$33key = $contrabandLength*3
			#$44key = $contrabandLength*4
			$55key = $contrabandLength*5
			#$66key = $contrabandLength*6
			$77key = $contrabandLength*7
			#$88key = $contrabandLength*8
			#$99key = $contrabandLength*9
			
			$key = "$1key$2key$3key$4key$5key$6key$7key$8key$9key"
			$keyHash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::New([System.Text.Encoding]::ASCII.GetBytes($key)))).Hash
			$key = $keyHash.Substring(0,3)
			$key += $keyHash.Substring(($keyHash.length - 5),3)
			$key2 = "$11key$22key$33key$44key$55key$66key$77key$88key$99key"
			$key2Hash = (Get-FileHash -InputStream ([System.IO.MemoryStream]::New([System.Text.Encoding]::ASCII.GetBytes($key2)))).Hash
			$key2 = $key2Hash.Substring(0,3)
			$key2 += $key2Hash.Substring(($key2Hash.length - 5),3)
			
#### end label config
		
		$combinedFiles=@()
		
		$combinedFiles += ((Get-ChildItem $busPath\* | select-string $key).Path | Get-ChildItem | select-string $key2).Path
	
		if (!$combinedFiles) {
			write-host "XXX No files with label (`"$contrabandLength`") found`n"
		} else {

			ForEach ($f in $combinedFiles) {
				$combinedBytes = get-content -encoding byte -Path $f
				$combinedContent = get-content -Path $f
				$combinedFileName = (get-childitem $f).Name
				$combinedFileLength = (get-childitem $f).Length
				$pattern = "$key(.*)$key2"
				$extractRaw = ([regex]::match($combinedContent,$pattern).Groups[1].Value)
				$extractTrim = $extractRaw.Trim()
				$extractTrim = $extractTrim -replace "[^ -x7e]",""
				#$extractDecoded = [System.Text.Encoding]::Unicode.Getstring([System.Convert]::FromBase64String($extractTrim))
				$extractDecoded = $extractTrim
				$contrabandFileName = $extractDecoded.Split("!") | select -index 1
				$contrabandFileName = $contrabandFileName.Trim()
				if ($contrabandFileName = "0") { $contrabandFileName = "" }
				$archivePasswordExtract = $extractDecoded.Split("!") | select -index 0
				$archivePasswordExtract = $archivePasswordExtract.Trim()
		
				$fileLength = $contrabandLength
				$contrabandOutRandom = Get-Random
				
				#$extractLength = $combinedFileLength - $combinedLength - $fileLength - 16000
			
				set-content -Path "$outPath\$contrabandOutRandom$contrabandFileName" ([byte[]]($combinedBytes | select -last ($fileLength + 16000) | select -first $fileLength)) -encoding byte
				write-host "`n*** file $outPath\$contrabandOutRandom$contrabandFileName has exited the smuggle bus"
			
				if ($archivePasswordExtract -ne "0") {
					write-host "*** ARCHIVE DETECTED"
				
					$7zip = Test-Path "c:\Program Files\7-Zip\7z.exe"
					$winRAR= Test-Path "c:\Program Files\winRAR\winRAR.exe"
	
					if ((!$7zip) -and (!$winRAR)) {
						write-host "!!! No obvious extraction utility present on current host"
					}
				
					if ($7zip) {
						
						if ($autoExtract) {
							$extractCommand = "`"c:\Program Files\7-Zip\7z.exe`" e `"$outPath\$contrabandOutRandom$contrabandFileName`" -p$archivePasswordExtract -o$outPath\*"
							$extractCommand2 = "`"c:\Program Files\7-Zip\7z.exe`" e `"$outPath\$contrabandOutRandom$contrabandFileName~`" -p$archivePasswordExtract -o$outPath\*"
							cmd /c $extractCommand
							cmd /c $extractCommand2
							Remove-Item "$outPath\$contrabandOutRandom$contrabandFileName" -Recurse
							Remove-Item "$outPath\$contrabandOutRandom$contrabandFileName~" -Recurse
							$extractDir = (Get-Childitem "$outPath\*~" | sort LastWriteTime | select -last 1).FullName
							Copy-Item -Path "$extractDir/*" -Destination $outPath -Recurse
							Remove-Item $extractDir -Recurse
						} else {
				
						write-host "*** Can unzip via following command:`n"
						write-host "cmd.exe /c `"c:\Program Files\7-Zip\7z.exe`" e $outPath\$contrabandOutRandom$contrabandFileName"
						write-host "Archive Password: $archivePasswordExtract"
						}
					}
				
					if ((!$7zip) -and ($winRAR)) {
						
						if ($autoExtract) {
							$extractCommand = "`"c:\Program Files\winRAR\winRAR.exe`" e $outPath\$contrabandOutRandom$contrabandFileName -p$archivePasswordExtract -o$outPath\*"
							$extractCommand2 = "`"c:\Program Files\winRAR\winRAR.exe`" e $outPath\$contrabandOutRandom$contrabandFileName~ -p`"$archivePasswordExtract`" -o$outPath\*"
							cmd /c $extractCommand
							cmd /c $extractCommand2
							Remove-Item "$outPath\$contrabandOutRandom$contrabandFileName" -Recurse
							Remove-Item "$outPath\$contrabandOutRandom$contrabandFileName~" -Recurse
							$extractDir = (Get-Childitem "$outPath\*~" | sort LastWriteTime | select -last 1).FullName
							Copy-Item -Path "$extractDir/*" -Destination $outPath -Recurse
							Remove-Item $extractDir -Recurse
						} else {
							
						write-host "*** Can unzip via following command:`n"
						write-host "cmd.exe /c `"c:\Program Files\winRAR\winRAR.exe`" x $outPath\$contrabandOutRandom$contrabandFileName"
						write-host "Archive Password: $archivePasswordExtract"
						}
					}
				}
			
			}
		}
	}
	
	write-host "`n`n"
	
}
