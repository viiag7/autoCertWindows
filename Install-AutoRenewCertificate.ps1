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
# MIIFjwYJKoZIhvcNAQcCoIIFgDCCBXwCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCB/80a6d0EY4ckU
# 7dt4XzjXOiPiMAOg4kcSjJmZ+FmnuaCCAwYwggMCMIIB6qADAgECAhBNkJWk527x
# q0E4QXd07HuRMA0GCSqGSIb3DQEBBQUAMBkxFzAVBgNVBAMMDlZpbmljaXVzQWd1
# aWFyMB4XDTI0MDgzMDE0MjkzMloXDTI1MDgzMDE0NDkzMlowGTEXMBUGA1UEAwwO
# VmluaWNpdXNBZ3VpYXIwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDK
# TOwSZVMDgjHkeFPqoRksEFMTuJQMeUAWTEq1S4nUQ85x4HudjYuNXcCJesHz5WZX
# fEj83YOk2MUD9R20xIzlijkYxn7EFIjnYTKcX9fgSBo3PVLAjUxMy0KRitHvgShK
# c/3y6Z7sa+3MJFaWpqtHsFayPyVO+nHm53UPYyS0CX+GonkMJKNy57p8BtXl1+Yd
# 2HirUxe56cR8GHkyqVUllbD0f6jqvCLAs4/RbXHim3NsFWEVWiANm5q3+kIF2+C3
# pVQVAMe0p2LVnN8IiE/mUa8Tiynt48S0Og7/kUBx+MF6C6gNM3oox8UpeJG6Gawo
# uo62JUgm8ScZGSSVQxo5AgMBAAGjRjBEMA4GA1UdDwEB/wQEAwIHgDATBgNVHSUE
# DDAKBggrBgEFBQcDAzAdBgNVHQ4EFgQUDfAS/QjNN1wrlT0Rjmhxsxug3KQwDQYJ
# KoZIhvcNAQEFBQADggEBAIWsfp6hBLBRqWCvI1eSpVG2V3qDenxi08ebu1g4F35Z
# M5LrVpiowhO3++xIXOmH2jVH7t/ws/cWAH6PxptsjaVM0H4q2F7MToOGx9kvnCUw
# 6cDUgy9cf2CxK1PFWkSCzU5M6Ua6y9CdUM10Bat1KJuvFC8G0BIVJRxHSyONjb7l
# dNjEb3A+mjGCcWOb5IAkH4AtM8vl5wbVq4vcIVNkM7973+FYfBMgp+bDj3oelDrl
# JZCSgN6MZnR3jJmXoOZ4+uii1eySM/WKwqPv0FEJPyxVHyEIEUpaqc11yjf1fBBS
# JyWHpJu+/qE61wEgjTJek29ql+EV4/vZjcfk+bDGcwYxggHfMIIB2wIBATAtMBkx
# FzAVBgNVBAMMDlZpbmljaXVzQWd1aWFyAhBNkJWk527xq0E4QXd07HuRMA0GCWCG
# SAFlAwQCAQUAoIGEMBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcN
# AQkDMQwGCisGAQQBgjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUw
# LwYJKoZIhvcNAQkEMSIEILi0LrAQVHjAIwagMat9Ol7jlFBAQKcnARVlyvOQcf4H
# MA0GCSqGSIb3DQEBAQUABIIBAHaNItmTg2xJDKaaGrKbeb4IfxX6EpsQgc/KtjlR
# 4Po71svzaU+gxmcrHwni/h8crlyvWVsOJqXyK1FtxX5Cooo91FTLqqZncPx9gBcY
# f7lmYB+P6LcbVu7g7b+rA7XZC4veWhF5xqB5cejCsa8i/BjnAmg08enho+NpTkkJ
# KgTpdL0DJB7A33I1F5Y99DH3Ik8r6GLIU2BwGPbNf3/K8crkTbq8F2W1H9Oei5Hd
# amY5uyvqhxlIlCw8NBCJWHIKrjaGauLf1jYyuXf+Oa4wxzVCG6GDjWEtGWKAIVDX
# n4Jtn1YRFQw7L7qdJywtdM8ekOcXJs/ByX2xuVDdtVGraCk=
# SIG # End signature block
