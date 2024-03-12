# Local Development

1. `nix develop`
2. `docker-compose up -d` - to start postgres
3. OPTIONAL `mix ecto.setup` create database - only first time
4. `iex -S mix phx.server` run server

Server runs at http://localhost:4000

Initial account is `jeff@jeffjewiss.com` : `pass1234`


## Staging environment

https://staging.notfarfromthetree.org

### To deploy
1. Commit and push to the branch we're in
2. `./scripts/deploy_staging`