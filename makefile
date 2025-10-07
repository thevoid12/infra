ifneq (,$(wildcard .env))
include .env
export
endif

all-local: make-local deploy-local bootstrap # after make commit the code for the enc secrets

all-prod: make-prod deploy-prod bootstrap

bootstrap:
	./bootstrap.sh\

make-local:
	@echo "Setting up for local environment..."
	@cp woodpecker/local/*.env woodpecker/
	@make enc-wpsecrets

make-prod:
	@echo "Setting up for production environment..."
	@cp woodpecker/prod/*.env woodpecker/
	@make enc-wpsecrets

deploy-local:
	@echo "Deploying to local..."
	@./deploy.sh local

deploy-prod:
	@echo "Deploying to prod..."
	@./deploy.sh prod
	
enc-wpsecrets:
	@echo "Encrypting woodpecker secrets..."
	@openssl aes-256-cbc -salt -in woodpecker/woodpecker-server.env -out woodpecker/woodpecker-server.env.enc -k $(SECRET_KEY)
	@openssl aes-256-cbc -salt -in woodpecker/woodpecker-agent.env -out woodpecker/woodpecker-agent.env.enc -k $(SECRET_KEY)
	@echo "Encryption woodpecker secrets complete."

dec-wpsecrets:
	@echo "Decrypting woodpecker secrets..."
	@openssl aes-256-cbc -d -salt -in woodpecker/woodpecker-server.env.enc -out woodpecker/woodpecker-server.env -k $(SECRET_KEY)
	@openssl aes-256-cbc -d -salt -in woodpecker/woodpecker-agent.env.enc -out woodpecker/woodpecker-agent.env -k $(SECRET_KEY)
	@echo "Decryption woodpecker secrets complete."


