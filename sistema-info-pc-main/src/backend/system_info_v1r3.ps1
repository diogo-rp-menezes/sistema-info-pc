<#
.SYNOPSIS
    Script para coleta de informações de sistema (versão final corrigida)
.DESCRIPTION
    Gera JSON válido compatível com o dashboard HTML e servidor
.VERSION
    4.5
#>

# Configurações básicas
$baseDir = Join-Path -Path (Split-Path -Parent $MyInvocation.MyCommand.Path) -ChildPath "..\frontend\levantamento"

# Função para menu simplificado
function Get-MenuSelection {
    param (
        [string]$title,
        [hashtable]$options
    )
    
    Clear-Host
    Write-Host "===== $title ====="
    $options.GetEnumerator() | Sort-Object Name | ForEach-Object { 
        Write-Host "$($_.Name.PadRight(5)) - $($_.Value)" 
    }
    
    do {
        $choice = Read-Host "`nInforme o número da opção"
    } until ($options.ContainsKey($choice))
    
    return $options[$choice]
}

# Mapeamento de fabricantes de monitores
$monitorManufacturerMap = @{
    'AAC'='AcerView'; 'ACR'='Acer'; 'ACT'='Targa'; 'ADI'='ADI Corporation'
    'AIC'='AG Neovo'; 'APP'='Apple'; 'ART'='ArtMedia'; 'AST'='AST Research'
    'AUO'='AU Optronics'; 'BNQ'='BenQ'; 'CMO'='Acer'; 'CPL'='Compal'
    'CPQ'='Compaq'; 'CTX'='CTX'; 'DEC'='DEC'; 'DEL'='Dell'
    'DON'='Denon'; 'DNY'='Disney'; 'ENV'='EIZO'; 'EIZ'='EIZO'
    'ELS'='ELSA'; 'EPI'='EPI'; 'FUS'='Fujitsu-Siemens'; 'GSM'='LG Electronics'
    'GWY'='Gateway'; 'HEI'='Hyundai'; 'HIT'='Hitachi'; 'HSD'='HannStar'
    'HTC'='Hitachi'; 'HWP'='HP'; 'IBM'='IBM'; 'ICL'='Fujitsu ICL'
    'IVM'='Iiyama'; 'LEN'='Lenovo'; 'LGD'='LG Display'; 'LPL'='LG Philips'
    'MAX'='Belinea'; 'MEI'='Panasonic'; 'MEL'='Mitsubishi'; 'NEC'='NEC'
    'NOK'='Nokia'; 'NVD'='Fujitsu'; 'OPT'='Optoma'; 'PHL'='Philips'
    'PIO'='Pioneer'; 'PRI'='Prolink'; 'PRO'='Proview'; 'QDS'='Quanta'
    'SAM'='Samsung'; 'SAN'='Sanyo'; 'SEC'='Seiko Epson'; 'SGI'='SGI'
    'SNY'='Sony'; 'SRC'='Shamrock'; 'SUN'='Sun Microsystems'; 'TAT'='Tatung'
    'TOS'='Toshiba'; 'TSB'='Toshiba'; 'VSC'='ViewSonic'; 'WTC'='Wen'
    'ZCM'='Zenith'; 'PZG'='HQ'; 'UNK'='Unknown'
}

# Coleta de dados do sistema
function Get-SystemData {
    # Informações básicas
    $os = Get-CimInstance Win32_OperatingSystem
    $computer = Get-CimInstance Win32_ComputerSystem
    $processor = Get-CimInstance Win32_Processor | Select-Object -First 1
    $baseboard = Get-CimInstance Win32_BaseBoard
    
    # Memória RAM - garantindo que retorne um array
    $memoryModules = @(Get-CimInstance Win32_PhysicalMemory | ForEach-Object {
        @{
            "SerialNumber" = $_.SerialNumber.Trim()
            "Manufacturer" = if ([string]::IsNullOrWhiteSpace($_.Manufacturer)) { "Unknown" } else { $_.Manufacturer.Trim() }
            "size_gb" = [math]::Round($_.Capacity/1GB)
            "PartNumber" = if ([string]::IsNullOrWhiteSpace($_.PartNumber)) { "Undefined" } else { $_.PartNumber.Trim() }
        }
    })
    
    # Discos - com verificação melhorada do tipo (HDD/SSD)
    $disks = @(Get-CimInstance Win32_DiskDrive | Where-Object { $_.MediaType -match 'Fixed' } | ForEach-Object {
        $disk = $_
        $partitions = Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskDrive.DeviceID='$($disk.DeviceID)'} WHERE AssocClass = Win32_DiskDriveToDiskPartition"
        $freeGB = 0
        
        foreach ($partition in $partitions) {
            $logical = Get-CimInstance -Query "ASSOCIATORS OF {Win32_DiskPartition.DeviceID='$($partition.DeviceID)'} WHERE AssocClass = Win32_LogicalDiskToPartition"
            $freeGB += [math]::Round($logical.FreeSpace/1GB)
        }
        
        # Verificação melhorada do tipo de disco
        $type = if ($disk.MediaType -match 'SSD') { 
            'SSD' 
        } else { 
            try {
                # Tenta usar o cmdlet Get-PhysicalDisk para detecção mais precisa
                $driveType = (Get-PhysicalDisk -DeviceNumber $disk.Index).MediaType
                if ($driveType -eq 'SSD') { 'SSD' } else { 'HDD' }
            } catch {
                # Fallback para HDD se não conseguir determinar
                'HDD'
            }
        }
        
        @{
            "model" = $disk.Model.Trim()
            "serial" = $disk.SerialNumber.Trim()
            "type" = $type
            "total_gb" = [math]::Round($disk.Size/1GB)
            "free_gb" = $freeGB
            "free_percent" = [math]::Round(($freeGB/($disk.Size/1GB))*100)
        }
    })
    
    # Monitores - garantindo que retorne um array
    $monitors = @(Get-CimInstance -Namespace root/wmi -Class WmiMonitorID | ForEach-Object {
        $m = $_
        $manufacturerCode = (-join ($m.ManufacturerName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim()
        $manufacturer = if ($manufacturerCode -and $monitorManufacturerMap.ContainsKey($manufacturerCode)) { 
            $monitorManufacturerMap[$manufacturerCode] 
        } else { 
            $manufacturerCode 
        }
        
        @{
            "manufacturer" = $manufacturer
            "name" = (-join ($m.UserFriendlyName | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim()
            "product" = (-join ($m.ProductCodeID | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim()
            "serial" = (-join ($m.SerialNumberID | Where-Object { $_ -ne 0 } | ForEach-Object { [char]$_ })).Trim()
            "id" = ($monitors.Count + 1)
        }
    })
    
    # Rede - garantindo que retorne um array
    $networkAdapters = @(Get-CimInstance Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } | ForEach-Object {
        @{
            "Description" = $_.Description
            "MACAddress" = $_.MACAddress
            "IPAddress" = @($_.IPAddress)
            "IPSubnet" = @($_.IPSubnet)
            "DefaultIPGateway" = @($_.DefaultIPGateway)
            "DHCPServer" = $_.DHCPServer
            "DNSDomain" = $_.DNSDomain
            "DNSDomainSuffixSearchOrder" = @($_.DNSDomainSuffixSearchOrder)
            "DNSServerSearchOrder" = @($_.DNSServerSearchOrder)
        }
    })
    
    # CPU
    $cpuInfo = @{
        "model" = $processor.Name
        "architecture" = $os.OSArchitecture
        "cores" = $processor.NumberOfCores
        "threads" = $processor.NumberOfLogicalProcessors
    }
    
    # Retorna todos os dados garantindo arrays
    return @{
        "workstation" = @{
            "computer_name" = $env:COMPUTERNAME
            "domain" = $computer.Domain
            "os_name" = $os.Caption
            "os_version" = $os.Version
        }
        "motherboard" = @{
            "manufacturer" = $baseboard.Manufacturer
            "model" = $baseboard.Product
            "serial_number" = $baseboard.SerialNumber
        }
        "cpu" = $cpuInfo
        "memory" = $memoryModules
        "disks" = $disks
        "monitors" = $monitors
        "network" = $networkAdapters
    }
}

# Fluxo principal
try {
    # Dados organizacionais
    $coligada = Get-MenuSelection -title "COLIGADA" -options @{
        "1" = "Galois LePetit"
        "2" = "Galois 601"
        "3" = "Galois Aguas Claras"
    }

    $departamento = Get-MenuSelection -title "DEPARTAMENTO" -options @{
        "1" = "Infantil"
        "2" = "Fundamental"
        "3" = "Secretaria"
        "4" = "Estendido"
        "5" = "Administrativo"
        "6" = "TI"
        "7" = "Portaria"
    }

    do {
        $local = Read-Host "Informe o local"
    } while ([string]::IsNullOrWhiteSpace($local))

    # Cria estrutura de diretórios
    $subpath = Join-Path -Path $coligada -ChildPath (Join-Path -Path $departamento -ChildPath $local)
    $fullPath = Join-Path -Path $baseDir -ChildPath $subpath
    
    if (-not (Test-Path -Path $fullPath)) {
        New-Item -Path $fullPath -ItemType Directory -Force | Out-Null
    }

    # Nome do arquivo
    $filename = "${coligada}_${departamento}_${local}_$(Get-Date -Format 'dd-MM-yyyy').json"
    $outputFile = Join-Path -Path $fullPath -ChildPath $filename

    # Coleta de dados
    $systemData = @{
        "system_info" = @{
            "organization" = @{
                "coligada" = $coligada
                "departamento" = $departamento
                "local" = $local
            }
        }
    }

    # Adiciona informações de hardware garantindo arrays
    $hardwareData = Get-SystemData
    $systemData.system_info += $hardwareData

    # Informações manuais
    $systemData.system_info["manual_info"] = @{
        "anydesk_id" = Read-Host "Digite o ID do Anydesk"
        "admin_password" = Read-Host "Digite a senha do Admin"
        "patrimonio" = Read-Host "Digite o número do patrimônio"
        "additional_equipment" = [System.Collections.ArrayList]@()
    }

    # Equipamentos adicionais
    do {
        $addMore = Read-Host "Deseja adicionar um equipamento adicional? (S/N)"
        if ($addMore -eq 'S') {
            $eqName = Read-Host "Digite o nome do equipamento"
            $eqType = Read-Host "Digite o tipo do equipamento"
            $eqPatrimonio = Read-Host "Digite o número de patrimônio"
            $eqNotes = Read-Host "Digite observações (opcional)"

            $equipment = @{
                "name" = $eqName
                "type" = $eqType
                "patrimony" = $eqPatrimonio
                "notes" = $eqNotes
            }

            [void]$systemData.system_info.manual_info.additional_equipment.Add($equipment)
        }
    } while ($addMore -eq 'S')

    # Geração do JSON
    $jsonContent = $systemData | ConvertTo-Json -Depth 6 -Compress
    
    # Remove caracteres especiais e BOM
    $jsonContent = $jsonContent -replace '[^\x20-\x7E]', ''
    
    # Grava o arquivo com codificação UTF-8 sem BOM
    [System.IO.File]::WriteAllText($outputFile, $jsonContent, [System.Text.Encoding]::UTF8)

    Write-Host "`n[SUCESSO] Relatório gerado em: $outputFile" -ForegroundColor Green
    Write-Host "Tamanho do arquivo: $((Get-Item $outputFile).Length) bytes" -ForegroundColor Cyan
}
catch {
    Write-Host "`n[ERRO] Falha ao gerar relatório: $($_.Exception.Message)" -ForegroundColor Red
    if (Test-Path $outputFile) { Remove-Item $outputFile -Force }
    exit 1
}