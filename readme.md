 # infra
 - this is my main infra repo which I use for my deployment.
 - i use woodpecker to manage my ci/cd instead of writing scripts and managing overhead
 - I have my woodpecker secrets encrypted (aes) which we need to decrypt to use
 -
 ## Bootstrapping
 To bootstrap the infra on a new server or RPi:
 1. Clone this repo
 2. Copy `.env.template` to `.env` and edit with your deployment config and `SECRET_KEY`
 3. For local development: Run `make make-local` (sets up with localhost host)
    For production: Run `make deploy-prod` (automates SSH deployment using `.env` values)
    This copies the appropriate env files and encrypts them.
 4. Run `make bootstrap` or `./bootstrap.sh`
 This will decrypt secrets and start all services.

 For automated deployment, use `make deploy-local` or `make deploy-prod`. Config in `.env`. SECRET_KEY from `.env` for both. Uses SSH key auth or password from `.password`.

 ## Secret Management

 Configuration Steps:
Create GitHub Personal Access Token:

Go to GitHub Settings > Developer settings > Personal access tokens
Create a new token with repo scope
Copy the token
Add SECRET_KEY to GitHub Actions Secrets:

In your GitHub repo, go to Settings > Secrets and variables > Actions
Add a new repository secret named SECRET_KEY with your encryption key value
Configure Woodpecker for GitHub Secret Syncing:

I've updated woodpecker/woodpecker-server.env to include:
WOODPECKER_SECRET_ENDPOINT=https://api.github.com
WOODPECKER_SECRET_TOKEN=your_github_personal_access_token
Replace your_github_personal_access_token with the PAT from step 1
Automatic Syncing:

Once Woodpecker starts with these settings, it will automatically sync secrets from your GitHub repo's Actions secrets
The SECRET_KEY will be available in pipelines via from_secret: SECRET_KEY

 Woodpecker is configured to sync secrets from GitHub Actions secrets automatically.

 To set up:
 1. Create a GitHub Personal Access Token (PAT) with `repo` scope.
 2. In your GitHub repo settings, add the SECRET_KEY as an Actions secret.
 3. Update `woodpecker/woodpecker-server.env` with your GitHub PAT as `WOODPECKER_SECRET_TOKEN`.
 4. Woodpecker will automatically sync the SECRET_KEY and other secrets from GitHub.

 ## Woodpecker Configuration

 - Woodpecker supports local and production configurations.
 - Local: Host set to `http://localhost:8000` for development on the same machine.
 - Production: Host set to `https://ci.example.com` for external access.
 - Use `make make-local` or `make make-prod` to switch configurations.
 - For production, add a DNS record for `ci.example.com` pointing to your server's IP address.

 ### Filling Woodpecker Environment Variables

 For GitHub integration using Personal Access Token (no OAuth client needed for local):

 - **WOODPECKER_GITHUB**: true
 - **WOODPECKER_GITHUB_CLIENT**: (leave empty)
 - **WOODPECKER_GITHUB_SECRET**: (leave empty)
 - **WOODPECKER_ADMIN**: your_github_username
 - **WOODPECKER_SECRET_TOKEN**: your_github_personal_access_token (repo scope)
 - **WOODPECKER_HOST**: http://rpi-ip:8000 (for local access)
 - **WOODPECKER_AGENT_SECRET**: some_random_secret_string

 For local, remove secret syncing lines (WOODPECKER_SECRET_ENDPOINT and WOODPECKER_SECRET_TOKEN duplicate) as CI is not used. For prod, keep for automatic secret syncing from GitHub Actions.

 ## CI/CD
 - The infra repo has a .woodpecker.yml for manual deployment.
 - New projects with .woodpecker.yml will be automatically detected by Woodpecker via GitHub integration.
 - No manual intervention needed for new projects.