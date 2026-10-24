# DoxIA's part of ~/.zshrc, sourced after Oh My Zsh (lib/install-zsh
# writes that line), so a git pull updates it: the PATH Fedora's ~/.bashrc sets,
# nvm and SDKMAN!, ~/.zshrc.d and the DoxIA greeting, the same as bash's.

typeset -U path
path=(~/.local/bin ~/bin $path)

source /usr/share/doxia/lib/dev-tools.sh

for rc in ~/.zshrc.d/*.zsh(N); do
  source "$rc"
done
unset rc

source /usr/share/doxia/lib/greeting.sh
