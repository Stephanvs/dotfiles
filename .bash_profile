
# path to the DC/OS CLI binary
if [[ "$PATH" != *"/Users/stephanvs/.dcos/bin"* ]];
  then export PATH=$PATH:/Users/stephanvs/.dcos/bin;
fi

# path to the DC/OS CLI binary
if [[ "$PATH" != *"/Users/stephanvs/.dcos/bin"* ]];
  then export PATH=$PATH:/Users/stephanvs/.dcos/bin;
fi

export PATH="$HOME/.cargo/bin:$PATH"

# editing and reloading bash profile
alias ebash='vim ~/.bash_profile'
alias rbash='source ~/.bash_profile'

# Weather
alias weather='curl -4 http://wttr.in/Eindhoven'
alias moon='curl -4 http://wttr.in/Moon'

# bat
alias cat='bat'

