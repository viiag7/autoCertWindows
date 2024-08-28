# Registro de Aplicativo e Criação de Role no Azure

## Passo 1: Registro de Aplicativo

1. Acesse o Portal do Azure.
2. Navegue até **Azure Active Directory** > **App registrations** > **New registration**.
3. Preencha os detalhes do aplicativo:
   - **Name**: `posh-acme`
   - **Supported account types**: Selecione o tipo de conta apropriado.
   - **Redirect URI**: (opcional) Adicione se necessário.
4. Clique em **Register**.

## Passo 2: Criar uma Chave do Aplicativo

1. Após registrar o aplicativo, navegue até **Certificates & secrets**.
2. Clique em **New client secret**.
3. Adicione uma descrição e defina um período de expiração.
4. Clique em **Add** e copie o valor do client secret. **Salve este valor** pois ele não será mostrado novamente.

## Passo 3: Criação de Role com Permissões

1. No Portal do Azure, vá para **Azure Active Directory** > **Roles and administrators** > **New custom role**.
2. Preencha os detalhes da função:
   - **Name**: `posh-acme`
   - **Description**: Role personalizada para gerenciar zonas DNS e registros TXT.
3. Adicione as permissões necessárias:
   - `Microsoft.Network/dnsZones/read`
   - `Microsoft.Network/dnsZones/TXT/read`
   - `Microsoft.Network/dnsZones/TXT/write`
4. Defina o escopo da função:
   - **Scope**: `/subscriptions/{subscription-id}/resourceGroups/{resource-group}`
5. Clique em **Save**.

## Passo 4: Atribuir a Role ao Aplicativo

1. Vá para o **Resource Group** onde deseja atribuir a role.
2. Clique em **Access control (IAM)** > **Add** > **Add role assignment**.
3. Selecione a função `posh-acme` criada e atribua ao aplicativo `posh-acme`.

## Referências
- [Documentação do Azure sobre Registro de Aplicativos](https://learn.microsoft.com/pt-br/entra/identity-platform/quickstart-register-app?tabs=certificate)
- [Documentação do Azure sobre Criação de Roles Personalizadas](https://learn.microsoft.com/pt-br/azure/role-based-access-control/custom-roles-portal)
