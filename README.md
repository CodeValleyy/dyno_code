# Dyno code

## Description

Dyno code est un service web qui permet de compiler et d'exécuter du code en ligne. Il est écrit en Rust et utilise le framework web actix-web.

## Fonctionnalités

- Compilation et exécution de code en ligne
- Support des langages de programmation suivants:
  - Python
  - Lua

## Déploiement sur Google Cloud

Voir [Déploiement sur Google Cloud](docs/google_cloud.md).

## Développement

### Prérequis

- Rust
- Docker

Attention, si vous souhaitez le lancer sans Docker, vous devez installer les dépendances suivantes:

- Python3 (voir [ici](https://www.python.org/downloads/))
- Lua (voir [ici](https://www.lua.org/download.html))
- Rutc (voir [ici](https://www.rust-lang.org/tools/install))

### Lancer le serveur

```bash
cargo run
```

### Lancer le serveur avec Docker

```bash
docker build -t dyno_code .
docker run -p 8080:8080 dyno_code
```	
