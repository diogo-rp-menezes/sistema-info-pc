from flask import Flask, jsonify, send_from_directory
import os
import json

app = Flask(__name__, static_folder='.', static_url_path='')

# Configuração do diretório base
BASE_DIR = os.path.join(os.path.dirname(__file__), 'levantamento')

@app.after_request
def add_no_cache_headers(response):
    """Adiciona headers para evitar cache no navegador"""
    response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "0"
    return response

def validate_json_file(filepath):
    """Valida se um arquivo JSON é válido, tratando BOM (Byte Order Mark)"""
    try:
        with open(filepath, 'r', encoding='utf-8-sig') as f:
            json.load(f)
        return True
    except (json.JSONDecodeError, IOError, UnicodeDecodeError) as e:
        print(f"Erro ao validar JSON {filepath}: {str(e)}")
        return False

@app.route('/list_jsons')
def list_jsons():
    """Lista todos os arquivos JSON válidos no diretório de levantamentos"""
    try:
        # Verifica se o diretório base existe
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
        print(f"Erro crítico ao listar JSONs: {str(e)}")
        return jsonify([])

@app.route('/')
def index():
    """Rota principal que serve o dashboard"""
    return send_from_directory('.', 'dashboard_v9r1.html')

@app.route('/<path:filename>')
def serve_json(filename):
    """Serve arquivos JSON com validação, tratando BOM (Byte Order Mark)"""
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
        print(f"Erro ao servir arquivo {filename}: {str(e)}")
        return jsonify({"error": f"Erro ao servir arquivo: {str(e)}"}), 500

if __name__ == '__main__':
    app.run(
        host='0.0.0.0', 
        port=5000, 
        debug=True,
        threaded=True
    )