/* TIGestor - Setup Inicial do Projeto */

// Linguagens & Frameworks
- Backend: Java 17 + Spring Boot 3.3
- Frontend: Vue 3 + Vite + Pinia + Vue Router
- Banco: MySQL
- ORM: Spring Data JPA + Flyway
- Segurança: Spring Security (LDAP + local)
- API Docs: Swagger/OpenAPI 3
- Auth: JWT

// Docker
- docker-compose com: mysql, backend, frontend

// Diretórios GitHub
TIGestor/
├── backend-springboot/         # Projeto Spring Boot
├── frontend-vue/              # Projeto Vue
├── docker/                    # Docker Compose + configs
├── docs/                      # Diagramas, specs
└── README.md                  # Instruções

// Entidades iniciais
- User (id, login, nome, papel, senha, status)
- Machine (id, hostname, ip, dataColeta, jsonRaw, status)
- AccessLog (id, usuario, data, metodo, sucesso)
- Asset (id, patrimonio, tipo, localizacao, responsavel, vinculo_com_maquina)
- ColetaHistorico (id, machine_id, hash_config, timestamp)

// Primeiros endpoints
POST /api/collect
GET /api/status/ultima-coleta
GET /api/machines
GET /api/machines/{id}
POST /auth/login (JWT)

// Admin web (futuro)
- Listagem de máquinas
- Filtros: por coligada, status, data da última coleta
- Gráficos: saúde dos equipamentos, setores, comparativo

// Considerações futuras
- IA para análises (como sugerido)
- Controle de ativos não digitais
- Mapa de localização (Leaflet)
- Exportação PDF/Excel
- Alertas automáticos (RAM/disco/etc)

// Observações
- RAW armazenado apenas se necessário
- Normalização entre 2FN/3FN
- Flexível para evolução com dashboards e auditoria

// Ações imediatas
- Gerar projeto Spring Boot com estrutura inicial
- Configurar Flyway e Docker
- Preparar API `/collect`
