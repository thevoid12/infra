SECRET_KEY ?= $(shell cat .secret_key 2>/dev/null)

bootstrap:
	./bootstrap.sh\

make-local:
	@echo "Setting up for local environment..."
	@cp woodpecker/local/*.env woodpecker/
	@make enc-secrets

make-prod:
	@echo "Setting up for production environment..."
	@cp woodpecker/prod/*.env woodpecker/
	@make enc-secrets

deploy-local:
	@echo "Deploying to local..."
	@./deploy.sh local

deploy-prod:
	@echo "Deploying to prod..."
	@./deploy.sh prod
	
enc-secrets:
	@echo "Encrypting woodpecker secrets..."
	@openssl aes-256-cbc -salt -in woodpecker/woodpecker-server.env -out woodpecker/woodpecker-server.env.enc -k $(SECRET_KEY)
	@openssl aes-256-cbc -salt -in woodpecker/woodpecker-agent.env -out woodpecker/woodpecker-agent.env.enc -k $(SECRET_KEY)
	@echo "Encryption complete."

dec-secrets:
	@echo "Decrypting woodpecker secrets..."
	@openssl aes-256-cbc -d -salt -in woodpecker/woodpecker-server.env.enc -out woodpecker/woodpecker-server.env -k $(SECRET_KEY)
	@openssl aes-256-cbc -d -salt -in woodpecker/woodpecker-agent.env.enc -out woodpecker/woodpecker-agent.env -k $(SECRET_KEY)
	@echo "Decryption complete."


