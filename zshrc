# ~/.zshrc
#
# Main config file for ZSH

# {{{ ZSH settings
HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
setopt autocd extendedglob
setopt PROMPT_SUBST
setopt HIST_IGNORE_SPACE
unsetopt beep
unsetopt PROMPT_CR
autoload -Uz compinit
autoload -U colors && colors
zstyle :compinstall filename '/home/$USER/.zshrc'
compinit
bindkey -e
bindkey "^[[3~" delete-char
bindkey "^H"    backward-delete-word
bindkey "^[[7~" beginning-of-line
bindkey "^[Oc"  forward-word
bindkey "^[Od"  backward-word
bindkey "^[[A"  history-search-backward
bindkey "^[[B"  history-search-forward
# }}}

# {{{ Build environment
# Set TERM, if we're not in a vty
if [ "$TERM" != "linux" ]; then
	export TERM="screen-256color"
fi

export EDITOR='vim'
export PYTHONSTARTUP="$HOME/.pythonrc.py"
export PATH="$HOME/.bin:/usr/lib/colorgcc/bin:/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/opt/local/bin"
 # }}}

# {{{ Program aliases
# zsh aliases
alias ze="$EDITOR $HOME/.zshrc"
alias zr="source $HOME/.zshrc"

# things to ignore
alias rm=' rm'

# vim aliases
alias vi='vim'
alias vio='vim -O'
alias vir='vim -R'

# ls aliases
alias la='ls -A'
alias ll='ls -lh'
alias lla='ls -lhA'

# cd aliases
function cdl(){
	if [ -n "$1" ]; then
		cd "$1"
	else
		cd
	fi
	ls
}

function cdr(){
	TMP=$(mktemp)

	START="$PWD"
	if [ -n "$1" ]; then
		START="$1"
	fi

	ranger --choosedir="$TMP" "$START"
	cd "$(cat $TMP)"
	rm -f "$TMP"
}

alias cdd='cdl ~/Desktop/'

#screen aliases
alias t='tmux'
alias tls='tmux ls'
alias ta='tmux attach'

#git aliases
gitdifftig() {
  git diff $1 | tig
}

crbaseissueurl="http://cr.dev.fusi.io/"
githubissueurl="https://github.com/tomselvi/fusi/issues/"

githubaddcommit() {
  if [ -d .git ]; then
    echo "Please enter GitHub issue ID: "
    read id
    ghurl=$githubissueurl$id
    echo "Please enter commit message: "
    read message
    git add -A
    git commit -m "[$id] $message" -m "$ghurl"
  else
    git status
  fi;
}

githubcommit() {
  if [ -d .git ]; then
    echo "Please enter GitHub issue ID: "
    read id
    ghurl=$githubissueurl$id
    echo "Please enter commit message: "
    read message
    git commit -m "[$id] $message" -m "$ghurl"
  else
    git status
  fi;
}

githubcommitreview() {
  if [ -d .git ]; then
    echo "Please enter GitHub issue ID: "
    read id
    ghurl=$githubissueurl$id
    echo "Please enter commit message: "
    read message
    cr -t $message HEAD
    echo "Please enter the issue number from the CR link above: "
    read crid
    git commit -m "[$id] $message" -m "$ghurl" -m "$crbaseissueurl$crid"
  else
    git status
  fi;
}

githubcommitaddreview() {
  if [ -d .git ]; then
    echo "Please enter GitHub issue ID: "
    read id
    ghurl=$githubissueurl$id
    echo "Please enter commit message: "
    read message
    git add -A
    cr -t $message HEAD
    echo "Please enter the issue number from the CR link above: "
    read crid
    git commit -m "[$id] $message" -m "$ghurl" -m "$crbaseissueurl$crid"
  else
    git status
  fi;
}

alias ghac=githubaddcommit
alias ghc=githubcommit
alias ghcr=githubcommitreview
alias ghacr=githubcommitaddreview


alias g='git'
alias gi='git init'
alias gs='git status'
alias ga='git add'
alias gaa='git add -A'
alias gac='git add -A; git commit'
alias gf='git fetch --prune'
alias gr='git rebase'
alias grm='git rebase origin/master'
alias gc='git commit'
alias gb='git branch'
alias gk='git checkout'
alias gkm='git checkout master'
alias gkd='git checkout develop'
alias gkb='git checkout -b'
alias gds='git diff --stat HEAD~1'
alias gp='git push'
alias gpo='git push origin'
alias gpom='git push origin master'
alias gm='git merge'
alias gmm='git merge --no-ff'
alias gd=gitdifftig
alias gl='git log | tig'
alias gg='git log --graph --oneline --all'

# rsync aliases
alias pcp='rsync -arhP'
alias pmv='rsync -arhP --remove-source-files'

# misc aliases
alias less='less -r'
alias grep='grep --color=auto'
alias tree='tree -ACFr'
alias grind='valgrind --tool=memcheck --leak-check=full --show-reachable=yes --read-var-info=yes'
alias browse='nautilus --no-desktop "$PWD" &>/dev/null &!'
alias socks='ssh -fND'
alias ping-scan='nmap -sP -PE -R'
alias port-scan='nmap -p'

# fusi specific
alias cdf='cd ~/html/fusi'

# }}}

# {{{ Autolaunch
# (( $+commands[TODO] )) && TODO
# }}}

# {{{ Configure prompt
# {{{ Custom symbols
POWERLINE="1"

if [ "$POWERLINE" = "1" ]; then
	LSEP1='\xee\x82\xb0' # left thick seperator
	LSEP2='\xE2\xAE\x81\x00' # left thin seperator
	RSEP1='\xee\x82\xb2' # right thick seperator
	RSEP2='\xE2\xAE\x83\x00' # right thin seperator
else
	LSEP1=''
	LSEP2=''
	RSEP1=''
	RSEP2=''
fi
# }}}

# {{{ Git info
function info-git(){
	branch=$(git symbolic-ref HEAD 2>/dev/null | sed "s/refs\/heads\///g")
	if [[ -n "$branch" ]]; then
		changes=$(git status --porcelain 2>/dev/null | grep '^?? ')
		commits=$(git status --porcelain 2>/dev/null | grep -v '^?? ')
		symbol=""
		if [[ -n "$commits" ]]; then
			symbol+="!"
		else
			symbol+="."
		fi
		if [[ -n "$changes" ]]; then
			symbol+="?"
		else
			symbol+="."
		fi
		if [[ -n "$symbol" ]]; then
			if [ ! "$symbol" = ".." ]; then
				echo -ne "%F{red}$RSEP1%K{red}%f $symbol %K{red}%F{green}$RSEP1%K{green}%F{black} $branch %k%f"
			else
				echo -ne "%F{green}$RSEP1%K{green}%F{black} $branch %k%f"
			fi
		fi
	fi
}
# }}}

# {{{ Status info
function info-status(){
	STATUS="$?"
	if [ "$STATUS" = "0" ]; then
		echo -ne "%K{green}%F{black} + %K{black}%F{green}$LSEP1"
	else
		echo -ne "%K{red}%f $STATUS %K{black}%F{red}$LSEP1"
	fi
}
# }}}

# {{{ User info
function info-user(){
	UID="$(id -u)"
	if [[ "$UID" -eq 0 ]]; then
		echo -ne "%K{black}%B%F{red} %n%b%B%K{black}%F{black}@%b%B%K{black}%F{red}%M%b%K{black} %K{blue}%F{black}$LSEP1 %f%. %k%F{blue}$LSEP1"
	else
		echo -ne "%K{black}%B%F{blue} %n%b%B%K{black}%F{black}@%b%B%K{black}%F{blue}%M%b%K{black} %K{blue}%F{black}$LSEP1 %f%. %k%F{blue}$LSEP1"
	fi
}
# }}}

# {{{ Assemble prompt
if [[ "$(id -u)" -eq 0 ]]; then
	PROMPT=$(echo -ne '\n$(info-status)$(info-user)%f %B%F{black}#%b%f ')
else
	PROMPT=$(echo -ne '\n$(info-status)$(info-user)%f %B%F{black}$%b%f ')
fi

RPROMPT='$(info-git)%f'
# }}}
# }}}
export SSH_AUTH_SOCK="$HOME/.ssh/ssh_auth_sock"

# Your user settings here
CR_USER=''

if { [ -n "$CR_USER" ]; } then
  alias cr='python ~/.settings/upload.py -e $CR_USER'
else
  alias cr='python ~/.settings/upload.py'
  echo "\n\nWhen you have a chance, edit your ~/.zshrc file and enter your code review credentials to save some time and get rid of this message\n"
  echo -n "Press any key to continue..." && read
  clear
fi

if ! { [ -n "$TMUX" ]; } then
  while true; do
    clear
    python ~/.settings/image2term.py ~/.settings/fusi.jpg -t 100
    echo "\nStart a new TMUX session? (y/n) or enter session ID\n"
    tmux ls
    echo ""
    read yn
    clear
    case $yn in
      [Yy]* ) tmux; break;;
      [0-9]* ) tmux attach -t $yn; break;;
      [Nn]* ) break;;
      .* ) echo "Please give a valid response";;
    esac
  done
fi
