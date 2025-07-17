@echo off
setlocal enabledelayedexpansion

:: Configuração do diretório e arquivo de saída
cd /d "%~dp0"
set "output_file=%cd%\system_info.json"
set "temp_file=%cd%\temp.tmp"

:: Limpeza de arquivos anteriores
if exist "%output_file%" del "%output_file%"
if exist "%temp_file%" del "%temp_file%"

:: Início do JSON
echo { > "%output_file%"
echo   "system_info": { >> "%output_file%"

:: 1. ESTAÇÃO DE TRABALHO
echo     "workstation": { >> "%output_file%"
for /f "tokens=1,* delims==" %%a in ('wmic computersystem get name /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%b')).Trim()"') do (
    echo       "computer_name": "%%v", >> "%output_file%"
  )
)

for /f "tokens=1,* delims==" %%a in ('wmic computersystem get domain /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%b')).Trim()"') do (
    echo       "domain": "%%v", >> "%output_file%"
  )
)

for /f "tokens=1,* delims==" %%a in ('wmic os get caption /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%b')).Trim()"') do (
    echo       "os_name": "%%v", >> "%output_file%"
  )
)

for /f "tokens=1,* delims==" %%a in ('wmic os get version /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%b')).Trim()"') do (
    echo       "os_version": "%%v" >> "%output_file%"
  )
)
echo     }, >> "%output_file%"

:: 2. PLACA-MÃE
echo     "motherboard": { >> "%output_file%"
for /f "tokens=1,* delims==" %%a in ('wmic baseboard get manufacturer /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%b')).Trim()"') do (
    echo       "manufacturer": "%%v", >> "%output_file%"
  )
)

for /f "tokens=1,* delims==" %%a in ('wmic baseboard get product /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%b')).Trim()"') do (
    echo       "model": "%%v", >> "%output_file%"
  )
)

for /f "tokens=1,* delims==" %%a in ('wmic baseboard get serialnumber /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%b')).Trim()"') do (
    echo       "serial_number": "%%v" >> "%output_file%"
  )
)
echo     }, >> "%output_file%"

:: 3. CPU (completo)
echo     "cpu": { >> "%output_file%"
for /f "tokens=1,* delims==" %%a in ('wmic cpu get name /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%b')).Trim()"') do (
    echo       "model": "%%v", >> "%output_file%"
  )
)

for /f "tokens=2 delims==" %%a in ('wmic os get osarchitecture /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%a')).Trim()"') do (
    echo       "architecture": "%%v", >> "%output_file%"
  )
)

for /f "tokens=2 delims==" %%a in ('wmic cpu get numberofcores /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%a')).Trim()"') do (
    echo       "cores": %%v, >> "%output_file%"
  )
)

for /f "tokens=2 delims==" %%a in ('wmic cpu get numberoflogicalprocessors /value ^| find "="') do (
  for /f "delims=" %%v in ('powershell -command "[System.Text.Encoding]::UTF8.GetString([System.Text.Encoding]::ASCII.GetBytes('%%a')).Trim()"') do (
    echo       "threads": %%v >> "%output_file%"
  )
)
echo     }, >> "%output_file%"

:: 4. MEMÓRIA RAM (CORRIGIDO)
echo     "memory": [ >> "%output_file%"
powershell -command "$memory = @(); Get-WmiObject Win32_PhysicalMemory | ForEach-Object { $module = @{ size_gb = [math]::Round($_.Capacity/1GB); Manufacturer = $_.Manufacturer; PartNumber = $_.PartNumber; SerialNumber = $_.SerialNumber }; $memory += $module }; ($memory | ConvertTo-Json -Compress) -replace '^\s*\[|\]\s*$', '' | Out-File -FilePath \"%output_file%\" -Append -Encoding ASCII" >nul
echo     ], >> "%output_file%"

:: 5. DISCOS (já estava correto)
echo     "disks": [ >> "%output_file%"
powershell -command "$disks = @(); Get-WmiObject Win32_DiskDrive | Where-Object { $_.MediaType -match 'Fixed' } | ForEach-Object { $disk = $_; $partitions = Get-WmiObject -Query \"ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} WHERE AssocClass = Win32_DiskDriveToDiskPartition\"; $sizeGB = [math]::Round($disk.Size/1GB); $freeGB = 0; $partitions | ForEach-Object { $logical = Get-WmiObject -Query \"ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($_.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition\"; $freeGB += [math]::Round($logical.FreeSpace/1GB) }; $type = if ($disk.MediaType -match 'SSD') {'SSD'} else { try { $driveType = (Get-PhysicalDisk -DeviceNumber $disk.Index).MediaType; if ($driveType -eq 'SSD') {'SSD'} else {'HDD'} } catch {'HDD'} }; $disks += @{ model = $disk.Model.Trim(); serial = $disk.SerialNumber.Trim(); type = $type; total_gb = $sizeGB; free_gb = $freeGB; free_percent = [math]::Round(($freeGB/$sizeGB)*100) } }; ($disks | ConvertTo-Json -Compress) -replace '^\s*\[|\]\s*$', '' | Out-File -FilePath \"%output_file%\" -Append -Encoding ASCII" >nul
echo     ], >> "%output_file%"

:: 6. MONITORES (CORRIGIDO)
echo     "monitors": [ >> "%output_file%"
powershell -command "$monitors = @(); $count=1; Get-WmiObject -Namespace root\wmi -Class WmiMonitorID | ForEach-Object { $m = $_; $manufacturer = (-join ($m.ManufacturerName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim(); $name = (-join ($m.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim(); $serial = (-join ($m.SerialNumberID | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim(); $product = (-join ($m.ProductCodeID | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim(); if ($name -ne '' -or $manufacturer -ne '') { $monitors += @{ id=$count; manufacturer=$manufacturer; name=$name; product=$product; serial=$serial }; $count++ } }; ($monitors | ConvertTo-Json -Compress) -replace '^\s*\[|\]\s*$', '' | Out-File -FilePath \"%output_file%\" -Append -Encoding ASCII" >nul
echo     ], >> "%output_file%"

:: 7. REDE (já estava correto)
echo     "network": [ >> "%output_file%"
powershell -command "$adapters = @(); Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | ForEach-Object { $adapter = $_; $adapterInfo = @{ Description = $adapter.Description; MACAddress = $adapter.MACAddress; IPAddress = @($adapter.IPAddress); IPSubnet = @($adapter.IPSubnet); DefaultIPGateway = @($adapter.DefaultIPGateway); DHCPServer = $adapter.DHCPServer; DNSDomain = $adapter.DNSDomain; DNSDomainSuffixSearchOrder = @($adapter.DNSDomainSuffixSearchOrder); DNSServerSearchOrder = @($adapter.DNSServerSearchOrder) }; $adapters += $adapterInfo }; ($adapters | ConvertTo-Json -Compress) -replace '^\s*\[|\]\s*$', '' | Out-File -FilePath \"%output_file%\" -Append -Encoding ASCII" >nul
echo     ], >> "%output_file%"

:: 8. INFORMAÇÕES MANUAIS
echo     "manual_info": { >> "%output_file%"
:input_anydesk
set /p anydesk_id=Por favor, digite o ID do Anydesk: 
if "%anydesk_id%"=="" (
    echo O ID do Anydesk não pode estar vazio!
    goto input_anydesk
)
echo       "anydesk_id": "%anydesk_id%", >> "%output_file%"

:input_password
set /p admin_password=Por favor, digite a senha do Admin: 
if "%admin_password%"=="" (
    echo A senha não pode estar vazia!
    goto input_password
)
echo       "admin_password": "%admin_password%", >> "%output_file%"

:input_patrimonio
set /p patrimonio=Por favor, digite o número do patrimônio: 
if "%patrimonio%"=="" (
    echo O número do patrimônio não pode estar vazio!
    goto input_patrimonio
)
echo       "patrimonio": "%patrimonio%" >> "%output_file%"
echo     } >> "%output_file%"

echo   } >> "%output_file%"
echo } >> "%output_file%"

:: Mensagem final
echo.
echo Sistema scaneado com sucesso!
echo Arquivo JSON gerado em: "%output_file%"
timeout /t 3