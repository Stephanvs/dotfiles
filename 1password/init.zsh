
if [[ "$OSTYPE" == "darwin"* ]]; then
  # Only use 1Password agent if we're not in an SSH session with forwarded agent
  if [[ -z "$SSH_CLIENT" ]] && [[ -z "$SSH_TTY" ]]; then
    export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
  fi
fi;

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  # Only use 1Password agent if we're not in an SSH session with forwarded agent
  if [[ -z "$SSH_CLIENT" ]] && [[ -z "$SSH_TTY" ]]; then
    export SSH_AUTH_SOCK=~/.1password/agent.sock
  fi
fi
