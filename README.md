# Sistema de Inventário de Hardware

Sistema completo para coleta, armazenamento e visualização de informações de hardware em ambientes corporativos.

## Funcionalidades

- **Coleta Automática** de informações de sistema via PowerShell
  - Hardware (CPU, RAM, Placa-mãe)
  - Armazenamento (HDD/SSD)
  - Monitores
  - Rede (adaptadores, IPs, MAC)
- **Organização Hierárquica** por:
  - Coligada
  - Departamento
  - Local físico
- **Dashboard Web** moderno e responsivo
  - Visualização por categorias
  - Gráficos de utilização
  - Busca e filtros
- **Autenticação Segura** via:
  - Active Directory (produção)
  - Usuários locais (desenvolvimento)
- **Informações Confidenciais** protegidas:
  - Senhas de administrador
  - IDs de acesso remoto
  - Números de patrimônio

## Componentes

1. `system_info_v1r3.ps1` - Script PowerShell para coleta de dados
2. `dashboard_v9r1.html` - Interface web do dashboard
3. `server_v2.py` - Servidor backend em Flask

## Pré-requisitos

- PowerShell 5.1+
- Python 3.8+
- Navegador moderno (Chrome, Edge, Firefox)
- Para autenticação AD:
  - Servidor Active Directory acessível
  - Credenciais com permissão de leitura
