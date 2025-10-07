bootstrap:
	./bootstrap.sh

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
