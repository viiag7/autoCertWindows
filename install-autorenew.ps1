# Descrição do aplicativo
Write-Host "Auto-CertRenew - Script para renovar certificados automaticamente"
Write-Host "Este script faz o download dos arquivos do repositório GitHub e cria uma tarefa agendada para executar o script request-install-cert.ps1 no horário especificado."
Write-Host ""

# Solicita o domínio
$domain = Read-Host "Por favor, insira o domínio"

# Solicita o email
$email = Read-Host "Por favor, insira o email"

# Solicita o tipo de instalação
Write-Host "Tipos de instalação disponíveis:"
Write-Host "I - IIS"
Write-Host "R - Remote Desktop Gateway"
Write-Host "V - VPN SSTP"
$installType = Read-Host "Por favor, insira o tipo de instalação (I, R ou V)"

# Solicita o dia da semana
Write-Host "Dias da semana disponíveis para instalação:"
Write-Host "Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday"
$dayOfWeek = Read-Host "Por favor, insira o dia da semana para a execução"

# Solicita a hora de execução
$time = Read-Host "Por favor, insira a hora de execução (formato HH:MM AM/PM)"

# Solicita os atributos adicionais do Azure
$AZSUBSCRIPTIONID = Read-Host "Por favor, insira o AZSUBSCRIPTIONID"
$CLIENT_ID = Read-Host "Por favor, insira o CLIENT_ID"
$CLIENT_SECRET = Read-Host "Por favor, insira o CLIENT_SECRET"
$TENANT_ID = Read-Host "Por favor, insira o TENANT_ID"

# Define o caminho para salvar os arquivos
$destinationPath = "$env:SystemRoot\cert-autorenew"

# Cria o diretório se não existir
if (-Not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath
}

# Baixa os arquivos do GitHub
Invoke-WebRequest -Uri "https://github.com/viiag7/autoCertWindows/archive/refs/heads/main.zip" -OutFile "$destinationPath\autoCertWindows.zip"
Expand-Archive -Path "$destinationPath\autoCertWindows.zip" -DestinationPath $destinationPath -Force

# Define os parâmetros adicionais
$additionalParams = ""
if ($installType -eq "I") { $additionalParams += "-I " }
elseif ($installType -eq "R") { $additionalParams += "-R " }
elseif ($installType -eq "V") { $additionalParams += "-V " }

# Define a ação da tarefa com os parâmetros
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -File $destinationPath\autoCertWindows-main\request-install-cert.ps1 -domain $domain -email $email $additionalParams"

# Define o gatilho da tarefa com o dia da semana e a hora especificados
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dayOfWeek -At $time

# Define as configurações da tarefa
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable

# Define o principal da tarefa (usuário que executará a tarefa)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Cria a tarefa agendada
Register-ScheduledTask -TaskName "AutoCertRenew" -Action $action -Trigger $trigger -Settings $settings -Principal $principal

# Executa a tarefa imediatamente
Start-ScheduledTask -TaskName "AutoCertRenew"

# Escreve os atributos do Azure no arquivo azure-variables.ps1
$azureVariablesPath = "$destinationPath\autoCertWindows-main\azure-variables.ps1"
$azureVariablesContent = @"
\$AZSUBSCRIPTIONID = '$AZSUBSCRIPTIONID'
\$CLIENT_ID = '$CLIENT_ID'
\$CLIENT_SECRET = '$CLIENT_SECRET'
\$TENANT_ID = '$TENANT_ID'
"@
Set-Content -Path $azureVariablesPath -Value $azureVariablesContent

Write-Host "Os atributos do Azure foram salvos em $azureVariablesPath"