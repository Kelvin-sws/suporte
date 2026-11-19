# Garante execucao como Administrador
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Execute o PowerShell como Administrador!" -ForegroundColor Red
    Pause
    Exit
}

$Host.UI.RawUI.WindowTitle = "Painel de Suporte TI"
$PC = $env:COMPUTERNAME
$UsuarioLogado = (Get-CimInstance -ClassName Win32_ComputerSystem).UserName
$UserPasta = if ($UsuarioLogado) { $UsuarioLogado.Split("\")[-1] } else { $env:USERNAME }

$PastaLog = "C:\Temp"
if (-not (Test-Path $PastaLog)) { New-Item -ItemType Directory -Path $PastaLog | Out-Null }
$ArquivoLog = "$PastaLog\Log_SuporteTI.txt"

function Registrar-Log ($Acao) {
    $Data = Get-Date -Format "dd/MM/yyyy HH:mm:ss"
    Add-Content -Path $ArquivoLog -Value "[$Data] [$PC] [$UsuarioLogado] $Acao"
}

function Mostrar-Menu {
    Clear-Host
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host "                PAINEL DE SUPORTE DA TI               " -ForegroundColor White
    Write-Host "======================================================" -ForegroundColor Cyan
    Write-Host " PC: $PC  |  Usuario logado: $UsuarioLogado" -ForegroundColor Gray
    Write-Host ""
    Write-Host "--- MANUTENCAO DO SISTEMA ---" -ForegroundColor Yellow
    Write-Host " [ 1] Limpeza de arquivos temporarios"
    Write-Host " [ 2] Limpeza de disco avancada"
    Write-Host " [ 3] Verificar e reparar arquivos do Windows (SFC)"
    Write-Host " [ 4] Reparar a imagem do Windows (DISM)"
    Write-Host " [ 5] Verificar o disco C:"
    Write-Host " [ 6] Saude do disco (HD/SSD)"
    Write-Host ""
    Write-Host "--- REDE E INTERNET ---" -ForegroundColor Yellow
    Write-Host " [ 7] Reset de rede (IP, Winsock e DNS)"
    Write-Host " [ 8] Informacoes de rede"
    Write-Host " [ 9] Testes de conectividade"
    Write-Host " [10] Limpar cache de DNS"
    Write-Host " [11] Abrir Conexoes de Rede"
    Write-Host ""
    Write-Host "--- IMPRESSAO ---" -ForegroundColor Yellow
    Write-Host " [12] Limpar fila de impressao travada"
    Write-Host " [13] Listar impressoras"
    Write-Host ""
    Write-Host "--- DIAGNOSTICO ---" -ForegroundColor Yellow
    Write-Host " [14] Informacoes do sistema"
    Write-Host " [15] Monitor de recursos e processos"
    Write-Host ""
    Write-Host "--- DRIVERS E ATUALIZACOES ---" -ForegroundColor Yellow
    Write-Host " [16] Dispositivos com erro"
    Write-Host " [17] Atualizar drivers (Windows Update)"
    Write-Host " [18] Backup dos drivers"
    Write-Host " [19] Procurar atualizacoes do Windows"
    Write-Host ""
    Write-Host "--- TI ---" -ForegroundColor Yellow
    Write-Host " [20] Ver registro de acoes deste PC"
    Write-Host " [21] Esvaziar Lixeira"
    Write-Host ""
    Write-Host " [ 0] Sair" -ForegroundColor Red
    Write-Host ""
}

do {
    Mostrar-Menu
    $Opcao = Read-Host "Escolha uma opcao"

    switch ($Opcao) {
        "1" {
            Write-Host "Limpando arquivos temporarios..." -ForegroundColor Green
            Remove-Item -Path "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "C:\Users\$UserPasta\AppData\Local\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Registrar-Log "Limpeza de arquivos temporarios"
            Write-Host "Concluido." -ForegroundColor Green
            Pause
        }
        "2" {
            Write-Host "Abrindo Limpeza de Disco (cleanmgr)..." -ForegroundColor Green
            Start-Process cleanmgr.exe -ArgumentList "/d C:"
            Registrar-Log "Aberta Limpeza de Disco avancada"
            Pause
        }
        "3" {
            sfc /scannow
            Registrar-Log "Executado SFC /scannow"
            Pause
        }
        "4" {
            DISM /Online /Cleanup-Image /RestoreHealth
            Registrar-Log "Executado DISM RestoreHealth"
            Pause
        }
        "5" {
            $Confirma = Read-Host "Isso agendara o CHKDSK no C: na proxima reinicializacao. Continuar? (S/N)"
            if ($Confirma -match "^[Ss]$") {
                chkdsk C: /f /r
                Registrar-Log "Verificacao de disco C: (CHKDSK)"
            }
            Pause
        }
        "6" {
            Write-Host "Verificando saude dos discos..." -ForegroundColor Green
            Get-PhysicalDisk | Format-Table FriendlyName, MediaType, HealthStatus, OperationalStatus, Size -AutoSize
            Registrar-Log "Verificacao de saude do disco"
            Pause
        }
        "7" {
            $Confirma = Read-Host "Isso vai resetar IP, Winsock e DNS. Continuar? (S/N)"
            if ($Confirma -match "^[Ss]$") {
                ipconfig /flushdns
                netsh winsock reset
                netsh int ip reset
                Registrar-Log "Reset de rede (IP, Winsock e DNS)"
                Write-Host "Concluido. Reinicie o PC para aplicar totalmente." -ForegroundColor Yellow
            }
            Pause
        }
        "8" {
            ipconfig /all
            Registrar-Log "Consulta de informacoes de rede"
            Pause
        }
        "9" {
            Write-Host "Testando Gateway e Internet (8.8.8.8 / google.com)..." -ForegroundColor Green
            $Gateway = (Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object -First 1).NextHop
            if ($Gateway) {
                Write-Host "`nPing Gateway ($Gateway):" -ForegroundColor Cyan
                Test-Connection -ComputerName $Gateway -Count 2 -ErrorAction SilentlyContinue
            }
            Write-Host "`nPing Google DNS (8.8.8.8):" -ForegroundColor Cyan
            Test-Connection -ComputerName 8.8.8.8 -Count 2 -ErrorAction SilentlyContinue
            Write-Host "`nResolucao DNS (google.com):" -ForegroundColor Cyan
            Resolve-DnsName google.com -Type A -ErrorAction SilentlyContinue | Format-Table Name, IPAddress -AutoSize
            Registrar-Log "Testes de conectividade"
            Pause
        }
        "10" {
            ipconfig /flushdns
            Registrar-Log "Limpeza de cache DNS"
            Pause
        }
        "11" {
            Start-Process ncpa.cpl
            Registrar-Log "Aberto Conexoes de Rede (ncpa.cpl)"
        }
        "12" {
            Write-Host "Reiniciando Spooler e limpando fila..." -ForegroundColor Green
            Stop-Service -Name Spooler -Force
            Remove-Item -Path "C:\Windows\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
            Start-Service -Name Spooler
            Registrar-Log "Limpeza de fila de impressao"
            Write-Host "Fila limpa com sucesso." -ForegroundColor Green
            Pause
        }
        "13" {
            Get-Printer | Format-Table Name, DriverName, PortName, PrinterStatus -AutoSize
            Registrar-Log "Listagem de impressoras"
            Pause
        }
        "14" {
            Write-Host "`nColetando informacoes do PC..." -ForegroundColor Cyan
            $OS = Get-CimInstance Win32_OperatingSystem
            $CS = Get-CimInstance Win32_ComputerSystem
            $BIOS = Get-CimInstance Win32_BIOS
            $CPU = Get-CimInstance Win32_Processor | Select-Object -First 1
            $RAMTotal = [math]::Round($CS.TotalPhysicalMemory / 1GB, 2)
            $Pentes = Get-CimInstance Win32_PhysicalMemory
            $GPU = (Get-CimInstance Win32_VideoController).Name -join ", "
            $IP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -notlike "169.254.*" } | Select-Object -First 1).IPAddress
            $Uptime = (Get-Date) - $OS.LastBootUpTime

            Write-Host "======================================================" -ForegroundColor Cyan
            Write-Host "               RESUMO DO EQUIPAMENTO                  " -ForegroundColor White
            Write-Host "======================================================" -ForegroundColor Cyan
            Write-Host " Computador : $PC ($($CS.Manufacturer) $($CS.Model))"
            Write-Host " Serie/Tag  : $($BIOS.SerialNumber)"
            Write-Host " Sistema    : $($OS.Caption) (Build $($OS.BuildNumber))"
            Write-Host " Processador: $($CPU.Name.Trim())"
            Write-Host " Memoria RAM: $RAMTotal GB ($($Pentes.Count) pente(s))"
            Write-Host " Placa Video: $GPU"
            Write-Host " IP Local   : $IP"
            Write-Host " Ligado ha  : $($Uptime.Days)d $($Uptime.Hours)h $($Uptime.Minutes)m"
            Write-Host ""
            Write-Host "--- DISCOS FISICOS (HD / SSD) ---" -ForegroundColor Yellow
            Get-PhysicalDisk | Select-Object FriendlyName, MediaType, @{Name="Tamanho(GB)";Expression={[math]::Round($_.Size/1GB, 0)}}, HealthStatus | Format-Table -AutoSize
            Write-Host "--- ESPACO EM DISCO (PARTICOES) ---" -ForegroundColor Yellow
            Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | Select-Object DeviceID, VolumeName, @{Name="Total(GB)";Expression={[math]::Round($_.Size/1GB, 1)}}, @{Name="Livre(GB)";Expression={[math]::Round($_.FreeSpace/1GB, 1)}} | Format-Table -AutoSize

            Registrar-Log "Consulta de informacoes completas do sistema"
            Pause
        }
        "15" {
            Start-Process resmon.exe
            Registrar-Log "Aberto Monitor de Recursos"
        }
        "16" {
            Write-Host "Buscando dispositivos com erro..." -ForegroundColor Green
            $Erros = Get-PnpDevice | Where-Object { $_.Status -ne "OK" }
            if ($Erros) {
                $Erros | Format-Table Status, Class, FriendlyName -AutoSize
            } else {
                Write-Host "Nenhum dispositivo com erro encontrado." -ForegroundColor Green
            }
            Registrar-Log "Verificacao de dispositivos com erro"
            Pause
        }
        "17" {
            Write-Host "Abrindo pagina de atualizacoes opcionais / drivers..." -ForegroundColor Green
            Start-Process "ms-settings:windowsupdate-optionalupdates"
            Registrar-Log "Aberto Windows Update (Drivers)"
            Pause
        }
        "18" {
            $PastaBackup = "C:\Backup_Drivers_$PC"
            $Confirma = Read-Host "Exportar drivers para $PastaBackup ? (S/N)"
            if ($Confirma -match "^[Ss]$") {
                if (-not (Test-Path $PastaBackup)) { New-Item -ItemType Directory -Path $PastaBackup | Out-Null }
                Export-WindowsDriver -Online -Destination $PastaBackup
                Registrar-Log "Backup de drivers salvo em $PastaBackup"
                Write-Host "Backup concluido em $PastaBackup" -ForegroundColor Green
            }
            Pause
        }
        "19" {
            Write-Host "Abrindo Windows Update e iniciando verificacao..." -ForegroundColor Green
            Start-Process "ms-settings:windowsupdate"
            UsoClient StartInteractiveScan
            Registrar-Log "Busca de atualizacoes do Windows"
            Pause
        }
        "20" {
            if (Test-Path $ArquivoLog) {
                Get-Content $ArquivoLog
            } else {
                Write-Host "Nenhum registro encontrado neste PC." -ForegroundColor Yellow
            }
            Pause
        }
        "21" {
            $Confirma = Read-Host "Tem certeza que deseja esvaziar a Lixeira? Essa acao nao pode ser desfeita (S/N)"
            if ($Confirma -match "^[Ss]$") {
                Write-Host "Esvaziando Lixeira..." -ForegroundColor Green
                Clear-RecycleBin -Force -ErrorAction SilentlyContinue
                Registrar-Log "Lixeira esvaziada"
                Write-Host "Lixeira esvaziada com sucesso." -ForegroundColor Green
            }
            Pause
        }
        "0" { Write-Host "Saindo..." }
        Default {
            Write-Host "Opcao invalida." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
} while ($Opcao -ne "0")
