
if [[ "$OSTYPE" == "darwin"* ]]; then
  export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
fi;

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  export SSH_AUTH_SOCK=~/.1password/agent.sock
fi
