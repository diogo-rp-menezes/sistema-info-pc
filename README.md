# Sistema de Inventário de Hardware

## Visão Geral

Este projeto é um sistema completo para coleta, armazenamento e visualização de informações de hardware em uma rede corporativa.

## 📋 Componentes Principais

| Componente | Descrição |
|------------|-----------|
| `system_info_v1r3.ps1` | Script PowerShell para coleta de dados |
| `dashboard_v9r1.html` | Interface web para visualização |
| `server_v2.py` | Servidor Flask para servir os dados |

## ✨ Funcionalidades

- ✅ Coleta automática de informações de hardware
- 🏢 Organização por coligada/departamento/local
- 📊 Dashboard interativo
- 🔒 Armazenamento seguro de dados sensíveis

## 🛠️ Instalação

1. Clone o repositório:
```bash
git clone [URL_DO_REPOSITORIO]
```

2. Instale as dependências:
```bash
pip install flask
```

3. Execute o servidor:
```bash
python server_v2.py
```

## 🖥️ Uso

1. Execute o script PowerShell:
```powershell
.\system_info_v1r3.ps1
```

2. Siga as instruções para fornecer:
   - Informações organizacionais
   - Dados manuais (patrimônio, senhas)

3. Acesse o dashboard:
```
http://localhost:5000
```

## 📂 Estrutura de Arquivos

```
/
├── levantamento/
│   ├── Coligada1/
│   │   ├── Departamento1/
│   │   │   ├── Local1/
│   │   │   │   └── arquivo.json
│   │   │   └── Local2/
│   │   └── Departamento2/
├── dashboard_v9r1.html
├── server_v2.py
└── system_info_v1r3.ps1
```

## ⚠️ Segurança

**Atenção:** As informações confidenciais são armazenadas nos arquivos JSON. Recomenda-se:

- Proteger o diretório `levantamento` com permissões adequadas
- Restringir acesso ao servidor Flask

## 🤝 Contribuição

Contribuições são bem-vindas! Siga estes passos:

1. Faça um fork do projeto
2. Crie sua branch (`git checkout -b feature/nova-feature`)
3. Faça commit das alterações (`git commit -m 'Adiciona nova feature'`)
4. Faça push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

## 📄 Licença

[MIT](LICENSE)
