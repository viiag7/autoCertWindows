# Definição dos parâmetros obrigatórios e opcionais
param (
    [Parameter(Mandatory = $true)]
    [string]$Domain, # Nome do domínio
    [Parameter(Mandatory = $true)]
    [string]$Email,  # Email de contato
    [switch]$I,      # Para IIS
    [switch]$R,      # Para RDGW
    [switch]$V       # Para VPN-SSTP
)

#  Instalar dependência do Nuget
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false

# Instalar os módulos necessários
$modules = @("Posh-ACME", "Posh-ACME.Deploy")
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Install-Module -Name $module -Scope AllUsers -Force
    }
}

# Incluir variáveis do Azure
. ./azure-variables.ps1

# Defina o caminho do arquivo de log
$logFile = "$env:TEMP\posh-acme.log"

# Redirecione a saída verbose para o arquivo de log
Start-Transcript -Path $logFile -Append

# Função para instalar o certificado nas aplicações especificadas
function Install-Certificate {
    param (
        [string]$Domain,
        [switch]$I,
        [switch]$R,
        [switch]$V
    )

    # Definir novo certificado no IIS, se especificado
    if ($I) {
        try {
            Get-PACertificate $Domain | Set-IISCertificate -SiteName 'Default Web Site' -Verbose
            Write-Output "Certificado configurado com sucesso no IIS."
        }
        catch {
            Write-Error "Ocorreu um erro ao configurar o certificado no IIS: $_"
        }
    }

    # Definir novo certificado no RDGW, se especificado
    if ($R) {
        try {
            Get-PACertificate $Domain | Set-RDGWCertificate -Verbose
            Write-Verbose "Certificado configurado com sucesso no RDGW"
        }
        catch {
            Write-Error "Ocorreu um erro ao configurar o certificado no RDGW: $_"
        }
    }

    # Definir novo certificado no VPN-SSTP, se especificado
    if ($V) {
        try {
            Get-PACertificate $Domain | Set-RASSTPCertificate -Verbose
            Write-Verbose "Certificado configurado com sucesso no SSTP"
        }
        catch {
            Write-Error "Ocorreu um erro ao configurar o certificado no SSTP: $_"
        }
    }
}

# Função principal para solicitar e instalar o certificado
function Request-And-Install-Certificate {
    param (
        [string]$Domain,
        [string]$Email,
        [string]$AZSUBSCRIPTIONID,
        [string]$CLIENT_ID,
        [string]$CLIENT_SECRET,
        [string]$TENANT_ID,
        [switch]$I,
        [switch]$R,
        [switch]$V
    )

    # Conectar-se ao Azure usando App Registration
    $secureClientSecret = ConvertTo-SecureString $CLIENT_SECRET -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($CLIENT_ID, $secureClientSecret)

    # Configurar o servidor ACME (Let's Encrypt)
    Set-PAServer LE_PROD -Verbose

    # Solicitar o certificado
    $pluginArgs = @{
        AZSubscriptionId = $AZSUBSCRIPTIONID
        AzTenantId       = $TENANT_ID
        AzappCred        = $credential
    }

    # Verificar se o certificado já existe
    $certificate = Get-PACertificate $Domain

    if ($certificate) {
        try {
            # Renovar o certificado existente
            Submit-Renewal $Domain
            Install-Certificate -Domain $Domain -I:$I -R:$R -V:$V
        }
        catch {
            Write-Error "WARNING: $_"
        }
    }
    else {
        try {
            if(Get-PAAccount){
                Write-Output "PAAccount existente"
            }else{
                New-PAAccount $Email -AcceptTOS
            }
            #Aceita termos de uso Lets Encrypt
            New-PAAccount $Email -AcceptTOS -
            # Solicitar um novo certificado
            New-PACertificate -Domain $Domain -AcceptTOS -Contact $Email -CertKeyLength ec-256 -Plugin Azure -PluginArgs $pluginArgs -DnsSleep 2 -Verbose -ErrorAction SilentlyContinue
            Write-Output "Certificado solicitado com sucesso."
            Install-Certificate -Domain $Domain -I:$I -R:$R -V:$V
        }
        catch {
            Write-Error "ERROR: Ocorreu um erro ao solicitar o certificado: $_"
        }
    }
}

# Chamar a função principal
Request-And-Install-Certificate -Domain $Domain -Email $Email -AZSUBSCRIPTIONID $AZSUBSCRIPTIONID -CLIENT_ID $CLIENT_ID -CLIENT_SECRET $CLIENT_SECRET -TENANT_ID $TENANT_ID -I:$I -R:$R -V:$V

# Parar a transcrição
Stop-Transcript