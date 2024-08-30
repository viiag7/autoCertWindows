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

# Verifica se o NuGet já está instalado
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
    # Instala o NuGet se não estiver instalado
    Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false
}

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
$logFile = "$env:HOMEDRIVE\auto-renew-cert\posh-acme.log"

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
        Get-PACertificate $Domain | Set-IISCertificateOld -SiteName 'Default Web Site' -Verbose
        Write-Output "Certificado configurado com sucesso no IIS."
    }

    # Definir novo certificado no RDGW, se especificado
    if ($R) {
        Get-PACertificate $Domain | Set-RDGWCertificate -Verbose
        Write-Verbose "Certificado configurado com sucesso no RDGW"
    }

    # Definir novo certificado no VPN-SSTP, se especificado
    if ($V) {
        Get-PACertificate $Domain | Set-RASSTPCertificate -Verbose
        Write-Verbose "Certificado configurado com sucesso no SSTP"
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

    if(Get-PAAccount){
        # Verificar se o certificado já existe
        $certificate = Get-PACertificate $Domain
    }else{
        New-PAAccount $Email -AcceptTOS
    }

    if ($certificate) {
            # Renovar o certificado existente
            Submit-Renewal $Domain
            Install-Certificate -Domain $Domain -I:$I -R:$R -V:$V
    }
    else {
            # Solicitar um novo certificado
            New-PACertificate -Domain $Domain -AcceptTOS -Contact $Email -CertKeyLength ec-256 -Plugin Azure -PluginArgs $pluginArgs -DnsSleep 2 -Verbose -ErrorAction SilentlyContinue
            Write-Output "Certificado solicitado com sucesso."
            Install-Certificate -Domain $Domain -I:$I -R:$R -V:$V
        }
}

# Chamar a função principal
Request-And-Install-Certificate -Domain $Domain -Email $Email -AZSUBSCRIPTIONID $AZSUBSCRIPTIONID -CLIENT_ID $CLIENT_ID -CLIENT_SECRET $CLIENT_SECRET -TENANT_ID $TENANT_ID -I:$I -R:$R -V:$V

# Parar a transcrição
Stop-Transcript