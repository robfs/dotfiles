# source ~/.bash_profile
# eval "$(oh-my-posh prompt init zsh --config 'https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/bubblesline.omp.json')"
# export PYENV_ROOT="$HOME/.pyenv"
# command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"
# eval "$(pyenv init -)"
# export XDG_CONFIG_HOME="$HOME/.config/"

# Created by `pipx` on 2022-07-27 18:29:22
# export PATH="$PATH:/Users/robsimms/.local/bin"

# export NVM_DIR="$HOME/.config//nvm"
# [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


export PATH="/usr/local/sbin:$PATH"

eval "$(starship init zsh)"

[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
