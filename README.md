# TIGestor - Sistema de Gestão de Ativos de TI

## 📌 Visão Geral
Projeto full-stack para gestão de ativos de TI com:
- Backend Java/Spring Boot
- Frontend Vue.js
- Banco MySQL
- Dockerizado

## 🛠 Tecnologias

### Backend
- Java 21
- Spring Boot 3.3
- Spring Data JPA
- Spring Security (LDAP + local)
- JWT Authentication
- Flyway (migrações)
- Swagger/OpenAPI 3

### Frontend
- Vue 3
- Vite
- Pinia (gerenciamento de estado)
- Vue Router

### Infra
- MySQL
- Docker Compose

## 📁 Estrutura do Projeto

```
TIGestor/
├── backend-springboot/ # Projeto Spring Boot
├── frontend-vue/ # Projeto Vue
├── docker/ # Docker Compose + configs
├── docs/ # Diagramas, specs
└── README.md # Este arquivo
```

## 🗃 Modelos de Dados Principais
- **User**: Gestão de usuários e acessos
- **Machine**: Dados de máquinas monitoradas
- **AccessLog**: Registros de acesso ao sistema
- **Asset**: Gestão de ativos físicos
- **ColetaHistorico**: Histórico de coletas de dados

## 🌐 Endpoints Iniciais
| Método | Endpoint                     | Descrição                     |
|--------|------------------------------|-------------------------------|
| POST   | `/api/collect`               | Coleta dados das máquinas     |
| GET    | `/api/status/ultima-coleta`   | Último status de coleta       |
| GET    | `/api/machines`              | Lista todas máquinas          |
| GET    | `/api/machines/{id}`         | Detalhes de máquina específica|
| POST   | `/auth/login`                | Autenticação com JWT          |

## 🚀 Roadmap
- [x] Estrutura inicial do projeto
- [ ] Configuração Docker
- [ ] Implementação endpoints básicos
- [ ] Painel admin web (Vue)
  - Listagem de máquinas
  - Filtros avançados
  - Gráficos analíticos
- [ ] Funcionalidades futuras:
  - IA para análise preditiva
  - Mapeamento de localização
  - Alertas automáticos
  - Exportação de relatórios

## 🐳 Docker
O projeto inclui configuração Docker Compose com serviços para:
- Banco MySQL
- Backend Spring Boot
- Frontend Vue

## 📊 Considerações de Design
- Armazenamento RAW apenas quando necessário
- Normalização de banco entre 2FN/3FN
- Arquitetura flexível para evolução
- Preparado para dashboards e auditoria

## ⚡ Próximos Passos
1. Gerar projeto Spring Boot inicial
2. Configurar Flyway e Docker
3. Implementar API `/collect`
