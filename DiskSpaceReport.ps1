$EmailServer = "vanwijk-exch01.evanwijk.local"
$EmailFrom = "info@evanwijk.com"
$EmailTo = "ict@evanwijk.com"
$ServerList = "C:\servers.txt"
$Warning = 20
$Critical = 10

$script:list = $ServerList
$freeSpaceFileName = "C:\FreeSpace.htm"
New-Item -ItemType file $freeSpaceFileNAme -Force


Function writeHtmlHeader
{
    param($fileName)
    $date = (Get-Date).ToString('dd/MM/yyyy')
    Add-Content $fileName "<html>"
    Add-Content $fileName "<head>"
    Add-Content $fileName "<meta http-equiv='Content-Type' content='text/html;charset=iso-8859-1'>"
    Add-Content $fileName "<title>DiskSpace Report</title>"
    Add-Content $fileName "<STYLE TYPE='text/css'>"
    Add-Content $fileName "td {"
    Add-Content $fileName "font-family: Tahoma;"
    Add-Content $fileName "font-size: 11px;"
    Add-Content $fileName "padding: 1px;"
    Add-Content $fileName "}"
    Add-Content $fileName "body {"
    Add-Content $fileName "margin: 5px 5px 0px 10px;"
    Add-Content $fileName "}"
    Add-Content $fileName "table {"
    Add-Content $fileName "border: thin solid #ddd;"
    Add-Content $fileName "border-collapse: collapse;"
    Add-Content $fileName "}"
    Add-Content $fileName "th, td {"
    Add-Content $fileName "padding: 5px;"
    Add-Content $fileName "}"
    Add-Content $fileName "th { "
    Add-Content $fileName "border-bottom: thin solid #ddd;"
    Add-Content $fileName "background-color: #3399ff;"
    Add-Content $fileName "color: #f2f2f2;"
    Add-Content $fileName "}"
    Add-Content $fileName "tbody tr:nth-child(odd) {"
    Add-Content $fileName "background-color: #cccccc;"
    Add-Content $fileName "}"
    Add-Content $fileName "</style>"
    Add-Content $fileName "</head>"
    Add-Content $fileName "<body>"
    Add-Content $fileName "<font face='tahoma' col size='4′><strong><center>DiskSpace Report – $date</center></strong></font>"
    Add-Content $fileName "<br>"
}

Function writeTableHeader
{
    param($fileName)
    Add-Content $fileName "<tr>"
    Add-Content $fileName "<td width='10%'>Drive</td>"
    Add-Content $fileName "<td width='50%'>Drive Label</td>"
    Add-Content $fileName "<td width='10%'>Total Capacity (GB)</td>"
    Add-Content $fileName "<td width='10%'>Used Capacity (GB)</td>"
    Add-Content $fileName "<td width='10%'>Free Space (GB)</td>"
    Add-Content $fileName "<td width='10%'>Freespace %</td>"
    Add-Content $fileName "</tr>"
}

Function writeHtmlFooter
{
    param($fileName)
    Add-Content $fileName "</body>"
    Add-Content $fileName "</html>"
}

Function writeDiskInfo
{
    param($fileName,$devId,$volName,$frSpace,$totSpace)
    $totSpace=[math]::Round(($totSpace/1073741824),2)
    $frSpace=[Math]::Round(($frSpace/1073741824),2)
    $usedSpace = $totSpace – $frspace
    $usedSpace=[Math]::Round($usedSpace,2)
    $freePercent = ($frspace/$totSpace)*100
    $freePercent = [Math]::Round($freePercent,0)
    if ($freePercent -gt $warning)
    {
        Add-Content $fileName "<tr>"
        Add-Content $fileName "<td>$devid</td>"
        Add-Content $fileName "<td>$volName</td>"
        Add-Content $fileName "<td>$totSpace</td>"
        Add-Content $fileName "<td>$usedSpace</td>"
        Add-Content $fileName "<td>$frSpace</td>"
        Add-Content $fileName "<td>$freePercent</td>"
        Add-Content $fileName "</tr>"
    }
    elseif ($freePercent -le $critical)
    {
        Add-Content $fileName "<tr>"
        Add-Content $fileName "<td>$devid</td>"
        Add-Content $fileName "<td>$volName</td>"
        Add-Content $fileName "<td>$totSpace</td>"
        Add-Content $fileName "<td>$usedSpace</td>"
        Add-Content $fileName "<td>$frSpace</td>"
        Add-Content $fileName "<td bgcolor='#FF0000′ align=center>$freePercent</td>"
        Add-Content $fileName "</tr>"
    }
    else
    {
        Add-Content $fileName "<tr>"
        Add-Content $fileName "<td>$devid</td>"
        Add-Content $fileName "<td>$volName</td>"
        Add-Content $fileName "<td>$totSpace</td>"
        Add-Content $fileName "<td>$usedSpace</td>"
        Add-Content $fileName "<td>$frSpace</td>"
        Add-Content $fileName "<td bgcolor='#FBB917′ align=center>$freePercent</td>"
        Add-Content $fileName "</tr>"
    }
}

writeHtmlHeader $freeSpaceFileName
foreach ($server in Get-Content $script:list)
{
    if(Test-Connection -ComputerName $server -Count 1 -ea 0) 
    {
        Add-Content $freeSpaceFileName "<table width='100%'>"
        Add-Content $freeSpaceFileName "<tbody>"
        Add-Content $freeSpaceFileName "<tr>"
        Add-Content $freeSpaceFileName "<th width='100%' align='center' colSpan=6><font face='tahoma' size='2′><strong> $server </strong></font></th>"
        Add-Content $freeSpaceFileName "</tr>"

        writeTableHeader $freeSpaceFileName

        $dp = Get-WmiObject win32_logicaldisk -ComputerName $server | Where-Object {$_.drivetype -eq 3 }
        foreach ($item in $dp)
        {
            Write-Host $item.DeviceID $item.VolumeName $item.FreeSpace $item.Size
            WriteDiskInfo $freeSpaceFileName $item.DeviceID $item.VolumeName $item.FreeSpace $item.Size

        }
    }
    Add-Content $freeSpaceFileName "</tbody>"
    Add-Content $freeSpaceFileName "</table>"
    Add-Content $freeSpaceFileName "<br>"
}

writeHtmlFooter $freeSpaceFileName
Function sendEmail
{
    param($from,$to,$subject,$smtphost,$htmlFileName)
    [string]$receipients="$EmailTo"
    $body = Get-Content $htmlFileName
    $body = New-Object System.Net.Mail.MailMessage $EmailFrom, $receipients, $subject, $body
    $body.IsBodyHTML = $true
    $EmailServer = $MailServer
    $smtp = new-object Net.Mail.SmtpClient($smtphost)
    $validfrom= Validate-IsEmail $EmailFrom
    if($validfrom -eq $TRUE)
    {
        $validTo= Validate-IsEmail $EmailTo
        if($validTo -eq $TRUE)
        {
            $smtp.Send($body)
            write-output "Email Sent!!"

        }
    }
    else
    {
        write-output "Invalid entries, Try again!!"
    }
}

function Validate-IsEmail ([string]$Email)
{
    return $Email -match "^(?("")("".+?""@)|(([0-9a-zA-Z]((\.(?!\.))|[-!#\$%&'\*\+/=\?\^`\{\}\|~\w])*)(?<=[0-9a-zA-Z])@))(?(\[)(\[(\d{1,3}\.){3}\d{1,3}\])|(([0-9a-zA-Z][-\w]*[0-9a-zA-Z]\.)+[a-zA-Z]{2,6}))$"
}
$date = ( get-date ).ToString(‘dd/MM/yyyy')
sendEmail -from $EmailFrom -to $EmailTo -subject "Disk Space Report – $Date" -smtphost $EmailServer -htmlfilename $freeSpaceFileName
