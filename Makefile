# Makefile para gerenciamento do projeto com Docker Compose

# Variáveis ​​de configuração
PROJECT_NAME := travel-orders
BACKEND_CONTAINER := app
FRONTEND_CONTAINER := frontend
DB_CONTAINER := mysql
DB_USERNAME := laravel_user
DB_PASSWORD := secret123
DB_DATABASE := travel_orders

# Cores para saída no terminal
RED=\033[0;31m
GREEN=\033[0;32m
YELLOW=\033[0;33m
NC=\033[0m # No Color

.PHONY: clone-submodules help up down build rebuild start stop restart logs logs-backend logs-frontend \
		sh-backend sh-frontend sh-db ps status clean clean-all migrate fresh seed \
		install-backend install-frontend test-backend test-frontend

help: ## Exibe esta ajuda
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

update-submodules: ## Clona os repositórios de submódulos
	@echo "$(GREEN)Clonando repositórios de submódulos...$(NC)"
	@git submodule update --init --recursive --remote

up: ## Inicia os containers em modo detached (background)
	@echo "$(GREEN)Iniciando containers...$(NC)"
	@cp .env.example .env
	@docker-compose up -d
	@echo "$(GREEN)Containers iniciados:$(NC)"
	@make ps

down: ## Para e remove os containers
	@echo "$(YELLOW)Parando e removendo containers...$(NC)"
	@docker-compose down

build: ## Constrói/reconstrói os containers
	@echo "$(GREEN)Construindo containers...$(NC)"
	@cp .env.example .env
	@COMPOSE_HTTP_TIMEOUT=300 docker-compose build
	@echo "$(GREEN)Containers construídos. Execute 'make up' para iniciá-los.$(NC)"

rebuild: down build up ## Reconstroi os containers completamente (down + build + up)

start: ## Inicia os containers já construídos
	@docker-compose start

stop: ## Para os containers sem removê-los
	@docker-compose stop

restart: stop start ## Reinicia os containers

logs: ## Mostra os logs de todos os containers
	@docker-compose logs -f

logs-backend: ## Mostra os logs do back-end
	@docker-compose logs -f $(BACKEND_CONTAINER)

logs-frontend: ## Mostra os logs do front-end
	@docker-compose logs -f $(FRONTEND_CONTAINER)

sh-backend: ## Acessa o shell do container do back-end
	@docker-compose exec $(BACKEND_CONTAINER) sh

sh-frontend: ## Acessa o shell do container do front-end
	@docker-compose exec $(FRONTEND_CONTAINER) sh

sh-db: ## Acessa o shell do container do banco de dados	
	@docker-compose exec $(DB_CONTAINER) mysql -u $(DB_USERNAME) -p$(DB_PASSWORD) $(DB_DATABASE)

ps: ## Lista os containers do projeto
	@echo "$(YELLOW)Containers do projeto $(PROJECT_NAME):$(NC)"
	@docker-compose ps

status: ps ## Alias para ps

clean: ## Remove containers, networks e volumes não utilizados
	@echo "$(YELLOW)Limpando recursos não utilizados...$(NC)"
	@docker system prune -f

clean-all: ## Remove TUDO (containers, imagens, networks, volumes) - CUIDADO!
	@echo "$(RED)Removendo TODOS os recursos Docker...$(NC)"
	@docker system prune -a --volumes -f

migrate: ## Executa as migrações do Laravel
	@echo "$(GREEN)Executando migrações...$(NC)"
	@docker-compose exec $(BACKEND_CONTAINER) php artisan migrate

fresh: ## Recria o banco de dados (drop + migrate)
	@echo "$(RED)Recriando o banco de dados...$(NC)"
	@docker-compose exec $(BACKEND_CONTAINER) php artisan migrate:fresh

seed: ## Executa os seeders do banco de dados
	@echo "$(GREEN)Populando o banco de dados...$(NC)"
	@docker-compose exec $(BACKEND_CONTAINER) php artisan db:seed

install-backend: ## Instala as dependências do back-end (composer)
	@echo "$(GREEN)Instalando dependências do back-end...$(NC)"
	@cp ./backend/.env.example ./backend/.env
	@docker-compose exec $(BACKEND_CONTAINER) composer install

install-frontend: ## Instala as dependências do front-end (npm)
	@echo "$(GREEN)Instalando dependências do front-end...$(NC)"
	@docker-compose exec $(FRONTEND_CONTAINER) npm install

test-backend: ## Executa os testes do back-end
	@echo "$(GREEN)Executando testes do back-end...$(NC)"
	@docker-compose exec $(BACKEND_CONTAINER) php artisan test

test-frontend: ## Executa os testes do front-end
	@echo "$(GREEN)Executando testes do front-end...$(NC)"
	@docker-compose exec $(FRONTEND_CONTAINER) npm run test

# Comando para inicialização completa do projeto
init: update-submodules build up install-backend migrate seed ## Inicialização completa do projeto (build + up + instala dependências + migrações)
	@echo "$(GREEN)Projeto inicializado com sucesso!$(NC)"
	@echo "$(YELLOW)Backend: http://localhost:80$(NC)"
	@echo "$(YELLOW)Frontend: http://localhost:9000$(NC)"