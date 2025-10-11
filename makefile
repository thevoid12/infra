
ifndef SECRET_KEY # SECRET_KEY: uses the environment variable if set (for production/GitHub secrets)
SECRET_KEY := $(shell grep '^SECRET_KEY=' .env | cut -d'=' -f2)
endif

all-local: make-local deploy-local  # after make commit the code for the enc secrets

all-prod: make-prod deploy-prod

bootstrap:
	./bootstrap.sh\

make-local:
	@echo "Setting up for local environment..."
	@echo "Copying local woodpecker env....."
	@cp woodpecker/local/*.env woodpecker/
	@echo "Copying local nginx configurations....."
	@cp -r nginx/conf.d/local/. nginx/conf.d/
	@make enc-wpsecrets

make-prod:
	@echo "Setting up for production environment..."
	@cp woodpecker/prod/*.env woodpecker/
	@echo "Copying prod nginx configurations....."
	@cp -r nginx/conf.d/prod/. nginx/conf.d/
	@make enc-wpsecrets

deploy-local:
	@echo "Deploying to local..."
	@$(MAKE) commit-files
	@./deploy.sh local

deploy-prod:
	@echo "Deploying to prod..."
	@$(MAKE) commit-files
	@./deploy.sh prod

commit-files:
	@echo "Committing files to github..."
	@git add .
	@git commit -m "configs updated"
	@git push

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


