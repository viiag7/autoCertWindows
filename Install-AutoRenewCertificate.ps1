<#PSScriptInfo

.VERSION 1.0.0

.GUID 06ac1728-6e55-4a52-a72a-13b18940b2fb

.AUTHOR Vinicius Aguiar

.COMPANYNAME vi7k.com.br

.COPYRIGHT

.TAGS SSL, Certificado, Automação, PowerShell, Agendamento

.LICENSEURI 

.PROJECTURI https://github.com/viiag7/autoCertWindows

.ICONURI 

.EXTERNALMODULEDEPENDENCIES

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES
Versão 1.0.0:   Primeira versão do script para automação de renovação de certificados SSL.
#>

<#
.DESCRIPTION
 Script para automatizar a renovação de certificados SSL usando agendamento de tarefas no Windows.

<#
.SYNOPSIS
    AUTO-RENEW-CERT 1.0 - (IIS, RDGW, VPN SSTP) by: Vinicius Aguiar

.DESCRIPTION
    Este script faz o download dos arquivos do repositório GitHub e cria uma tarefa agendada para executar o script `request-install-cert.ps1` no horário especificado.

.PARAMETER domain
    O domínio para o qual o certificado será solicitado.

.PARAMETER email
    O email para notificações e contato.

.PARAMETER installType
    O tipo de instalação: 
    - I: IIS
    - R: Remote Desktop Gateway
    - V: VPN SSTP

.PARAMETER dayOfWeek
    O dia da semana para a execução da tarefa agendada.

.PARAMETER time
    A hora de execução da tarefa agendada (formato HH:MM AM/PM).

.PARAMETER AZSUBSCRIPTIONID
    O ID da assinatura do Azure.

.PARAMETER CLIENT_ID
    O ID do cliente (Client ID) do Azure.

.PARAMETER CLIENT_SECRET
    O segredo do cliente (Client Secret) do Azure.

.PARAMETER TENANT_ID
    O ID do locatário (Tenant ID) do Azure.

.EXAMPLE
    .\Install-AutoRenewCertificate.ps1
    Este exemplo executa o script e solicita as entradas necessárias para configurar a tarefa agendada.

.NOTES
    Nome: Install-AutoRenewCertificate.ps1
    Versão: 1.0.0
    Autor: Vinicius Aguiar
    Data: 30/08/2024
    Descrição: Script para automatizar a renovação de certificados SSL usando agendamento de tarefas no Windows.
#>

# Descrição do aplicativo
Write-Host "### AUTO-RENEW-CERT 1.0 - (IIS, RDGW, VPN SSTP) by:Vinicius Aguiar ###" -BackgroundColor DarkGreen
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
Write-Host "Dia para agendamento de renovação:"
Write-Host "Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, Saturday"
$dayOfWeek = Read-Host "Por favor, insira o dia da semana para a execução"

# Solicita a hora de execução
$time = Read-Host "Por favor, insira a hora de execução (formato HH:MM AM/PM)"

# Solicita os atributos adicionais do Azure
$AZSUBSCRIPTIONID = Read-Host "Por favor, insira o AzSubscriptionID"
$CLIENT_ID = Read-Host "Por favor, insira o Client_ID"
$CLIENT_SECRET = Read-Host "Por favor, insira o Client_Secret"
$TENANT_ID = Read-Host "Por favor, insira o Tenant_ID"

# Define o caminho para salvar os arquivos
$destinationPath = "$env:HOMEDRIVE\auto-renew-cert"

# Cria o diretório se não existir
if (-Not (Test-Path -Path $destinationPath)) {
    New-Item -ItemType Directory -Path $destinationPath
}

# Baixa e extrai os arquivos do GitHub
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/viiag7/autoCertWindows/main/request-install-cert.ps1" -OutFile "$destinationPath\request-install-cert.ps1"

# Define os parâmetros adicionais
$additionalParams = switch ($installType) {
    "I" { "-I" }
    "R" { "-R" }
    "V" { "-V" }
    default { "" }
}

# Define a ação da tarefa com os parâmetros
$action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -WindowStyle Hidden -File $destinationPath\request-install-cert.ps1 -domain $domain -email $email $additionalParams" -WorkingDirectory $destinationPath

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
$azureVariablesPath = "$destinationPath\azure-variables.ps1"
$azureVariablesContent = @"
`$AZSUBSCRIPTIONID = '$AZSUBSCRIPTIONID'
`$CLIENT_ID = '$CLIENT_ID'
`$CLIENT_SECRET = '$CLIENT_SECRET'
`$TENANT_ID = '$TENANT_ID'
"@
Set-Content -Path $azureVariablesPath -Value $azureVariablesContent

Write-Host "Os atributos do Azure foram salvos em $azureVariablesPath"

# SIG # Begin signature block
# MIIFmAYJKoZIhvcNAQcCoIIFiTCCBYUCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCDr1qgkTAbb5r/d
# 3TQnLmz4CWHmvpQa3QmMkiP+4CO1g6CCAwwwggMIMIIB8KADAgECAhBWuR3GMKEN
# tk9swcznHdg7MA0GCSqGSIb3DQEBCwUAMBwxGjAYBgNVBAMMEU15Q29kZVNpZ25p
# bmdDZXJ0MB4XDTI0MDgzMDE0MTYxN1oXDTI1MDgzMDE0MzYxN1owHDEaMBgGA1UE
# AwwRTXlDb2RlU2lnbmluZ0NlcnQwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEK
# AoIBAQDXYdv2bUdJDWxVTAJw5SqfSfHAfOPsC/ZOmMcDxEFav51bSPx2oVTfH/F+
# lSU3DnCncfXejs3rU+RKyBw80GgD9m1ZPZ+QOEJE+8sxi2d2OI8UDrKhBVqpQK8I
# yJ7VwET4yURe/KBEL+H16Ye6pGfTyIOmKyRRNwkEHKLNquE1lTgEtexc6NDdDWNZ
# ZtwIr7TfJYHL7CVWqnULzTFwIqN5EQGSjsVjhxlOUcU91OOm2x9S852EynE/phoR
# xHtV1NCAJhNB9/uSc5yTcsCpEsSInjeCiNuOM0gF7gsaX7nsiHbbhGf9/wfzGJRJ
# pxJ2cN/wUvxzUvfBPi16lldLiVHVAgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDAT
# BgNVHSUEDDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUwQqoeAcyiQ8pg2gbc0P2kgMM
# IN4wDQYJKoZIhvcNAQELBQADggEBAHenXTWvOKcriSXMfAHZwiw5wdT6SUuTSKYJ
# a55dOMMQa9/56vSS1mNmDEp4stmtRsHF0Vr5q56HXajhvVOUmdXAYL4eXG4ndlhP
# gGjQP8aCa5NQQjHPD+2dXohSoRZskgkrGo6J1aUy6HVak7q+csmlo1Q81Qej/bGe
# U1hqoN7EXlh619HF+6YzyIFLDxDRZ2l0bhclTBBcI++Kr85rrWO/awFeZCYAU7cW
# G/YPTDVGRdOP6R/LPkN+HnadVigFMkFIVoR9twXI5C4LAq4B8RRH+eU8c7iHcCcd
# 9+gGTkeFWSXvrmEgvyGtZsZMhWtEWbM47EVfAUGhMpVw2fm6j8sxggHiMIIB3gIB
# ATAwMBwxGjAYBgNVBAMMEU15Q29kZVNpZ25pbmdDZXJ0AhBWuR3GMKENtk9swczn
# Hdg7MA0GCWCGSAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAw
# GQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisG
# AQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIKoB2DWTHkzMlpUb3EwvjsPvP98sCuHT
# WkFD3VjmmJBqMA0GCSqGSIb3DQEBAQUABIIBADfUCdIqEVVRT5kt6KnnZrDSM7c/
# HfKa3hPA2Nc7PAIdlfL8OSuVa8gFiauM+EdGbLD4cfOxzkBoVKD+45qy9XfdklX5
# psM9sc69UCcEm1s3AnMToz4+/y4aJQhg/7cIW64X9kb87Y3Y9gUd82oPDtLIB3sr
# 7KUl0BpEOa4SQc/2nfrIecKVni9/gm1fFYImsKJ6ngvJ2mFFvmB2PxJnxOYhErym
# smlWWk4I8J+dZYKHmDJiJt42ZwuqKOL5axrPFd23Wsm8ZY6YYKEiECchpBOSW35w
# k4A4GCRZPb3gl1+8zifnS1dKchNkAHa178cyyeN9xW0XEA67+fhxqTnZd8U=
# SIG # End signature block
