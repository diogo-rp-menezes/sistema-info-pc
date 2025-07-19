from flask import Flask, jsonify, send_from_directory, request
import os
import json
from datetime import datetime
from ldap3 import Server, Connection, ALL

app = Flask(__name__, static_folder='.', static_url_path='')

# Configurações
BASE_DIR = os.path.join(os.path.dirname(__file__), 'levantamento')
AUTH_CONFIG_FILE = 'config/auth.json'
LOG_FILE = 'logs/access.log'

# Configurações AD (genéricas - substitua com seus valores)
AD_CONFIG = {
    'server': 'seu.servidor.ad',
    'domain': 'dominio.local',
    'search_tree': 'OU=Users,DC=dominio,DC=local'
}

# Criar diretórios necessários
os.makedirs('config', exist_ok=True)
os.makedirs('logs', exist_ok=True)

@app.after_request
def add_no_cache_headers(response):
    """Headers para evitar cache"""
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

def log_access(username, success, auth_method):
    """Registra tentativas de acesso"""
    with open(LOG_FILE, 'a') as f:
        f.write(f"{datetime.now().isoformat()} | {username} | {'SUCCESS' if success else 'FAILED'} | {auth_method}\n")

def validate_json_file(filepath):
    """Valida se um arquivo JSON é válido"""
    try:
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            json.load(f)
        return True
    except (json.JSONDecodeError, IOError, UnicodeDecodeError) as e:
        app.logger.error(f"Erro ao validar JSON {filepath}: {str(e)}")
        return False

def load_auth_config():
    """Carrega configurações de autenticação"""
    config = {
        'use_ad': True,  # Padrão: tenta autenticação AD
        'local_users': {}  # Usuários apenas para modo DEV
    }
    
    if os.path.exists(AUTH_CONFIG_FILE) and validate_json_file(AUTH_CONFIG_FILE):
        with open(AUTH_CONFIG_FILE, 'r') as f:
            config.update(json.load(f))
    
    return config

@app.route('/auth', methods=['POST'])
def auth():
    """Endpoint de autenticação unificado"""
    data = request.json
    username = data.get('username', '').strip()
    password = data.get('password', '').strip()

    if not username or not password:
        log_access('', False, 'INVALID_REQUEST')
        return jsonify({"success": False}), 400

    auth_config = load_auth_config()

    # Modo de desenvolvimento
    if os.environ.get('DEV_MODE') == 'true':
        if username in auth_config['local_users'] and auth_config['local_users'][username] == password:
            log_access(username, True, 'DEV')
            return jsonify({"success": True}), 200
        
        log_access(username, False, 'DEV')
        return jsonify({"success": False}), 401

    # Modo produção - autenticação AD
    if auth_config.get('use_ad', True):
        try:
            server = Server(AD_CONFIG['server'], get_info=ALL)
            conn = Connection(server, 
                            user=f"{username}@{AD_CONFIG['domain']}", 
                            password=password)
            
            if conn.bind():
                conn.unbind()
                log_access(username, True, 'AD')
                return jsonify({"success": True}), 200
                
        except Exception as e:
            app.logger.error(f"Erro AD: {str(e)}")

    log_access(username, False, 'AD')
    return jsonify({"success": False}), 401

# Rotas existentes mantidas intactas
@app.route('/list_jsons')
def list_jsons():
    """Lista todos os arquivos JSON válidos no diretório de levantamentos"""
    try:
        if not os.path.exists(BASE_DIR):
            os.makedirs(BASE_DIR, exist_ok=True)
            return jsonify([])

        json_files = []
        for root, dirs, files in os.walk(BASE_DIR):
            for file in files:
                if file.lower().endswith('.json'):
                    file_path = os.path.join(root, file)
                    if validate_json_file(file_path):
                        rel_path = os.path.relpath(file_path, os.path.dirname(__file__))
                        json_files.append({
                            'path': rel_path.replace('\\', '/'),
                            'name': rel_path.replace('\\', ' → ').replace('levantamento/', '')
                        })
        
        return jsonify(json_files)
    
    except Exception as e:
        app.logger.error(f"Erro ao listar JSONs: {str(e)}")
        return jsonify([])

@app.route('/')
def index():
    """Rota principal que serve o dashboard"""
    return send_from_directory('.', 'dashboard_v9r1.html')

@app.route('/<path:filename>')
def serve_json(filename):
    """Serve arquivos JSON com validação"""
    try:
        filepath = os.path.join(BASE_DIR, filename)
        if not os.path.isfile(filepath):
            return jsonify({"error": "Arquivo não encontrado"}), 404
        
        if not validate_json_file(filepath):
            return jsonify({"error": "JSON inválido"}), 500
            
        response = send_from_directory(BASE_DIR, filename)
        response.headers['Cache-Control'] = 'no-store'
        return response
        
    except Exception as e:
        app.logger.error(f"Erro ao servir arquivo {filename}: {str(e)}")
        return jsonify({"error": f"Erro ao servir arquivo: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(
        host='0.0.0.0', 
        port=5000, 
        debug=True,
        threaded=True
    )