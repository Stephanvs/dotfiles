alias d='docker'
alias dc='docker-compose'
alias dcl='docker-compose logs -f'
alias dcu='docker-compose up -d'
alias dcps='docker-compose ps'

alias ctop='docker run --rm -ti \
  --name=ctop \
  -v /var/run/docker.sock:/var/run/docker.sock \
  quay.io/vektorlab/ctop:latest'