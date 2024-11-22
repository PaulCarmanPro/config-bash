#!/usr/bin/bash
#
# ~/.bashrc executed by bash(1) for non-login shells.
#
# shellcheck disable=SC2155 # Declare and assign separately to avoid masking return values.

# NOT INTERACTIVE = DON'T DO ANYTHING (cannot use exit during startup)
# checking PS1 for any value also demonstrates an interactive shell
[[ "$-" != *i* ]] && exit

CheckPrompt() { # function CheckPrompt not found after login shell
   PromptCommand() { # Assigned to PROMPT_COMMAND to execute before printing PS1
      # Allows inclusion of last exit code in prompt
      # Could simply printf the prompt instead
      local zExitCode="$?"
      # shellcheck disable=SC1004 # This backslash+linefeed is literal. Break outside single quotes if you just want to break the line.
      # WHY DOES PS1=SINGLE-QUOTE... ACT SAME AS PS1=DOUBLE-QUOTE... ???
      PS1="\[$(tput setaf 14)\]>>> "
      PS1+="\[$(tput setaf 6)\]\d " # date
      PS1+="\[$(tput setaf 14)\]\A " # time
      PS1+="\[$(tput setaf 3)\]\u" # user-name
      PS1+="\[$(tput setaf 1)\]@"
      # cause prompt to include user@host:dir if not rooted
      if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
         PS1+="\[$(tput setaf 3)\];${debian_chroot:+($(cat /etc/debian_chroot))}"
         PS1+="\[$(tput setaf 1)\]:"
      fi
      PS1+='\[$(tput setaf 3)\]\h' # host
      PS1+='\[$(tput setaf 1)\]:'
      PS1+="\[$(tput setaf 15)\]\w" # $PWD
      #  cause prompt to include exit code if non-zero
      if [ 0 != "$zExitCode" ]; then
         PS1+='\[$(tput sgr0)\] '
         PS1+='\[$(tput setaf 15 setab 1)\]'
         PS1+="$zExitCode"
      fi
      PS1+="\[$(tput sgr0)\] "
   }
   export PromptCommand
   export PROMPT_COMMAND=PromptCommand
   export PS4='+${LINENO} ${BASH_SOURCE}: ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
}

CheckShell() { # shopt settings do not survive after login shill
   # stty werase undef # why set the erase character?
   bind '\C-w:unix-filename-rubout' # change to Alt-Backspace behavior
   # enable programmable completion features
   if ! shopt -oq posix; then
      if [ -f /usr/share/bash-completion/bash_completion ]; then
         . /usr/share/bash-completion/bash_completion
      elif [ -f /etc/bash_completion ]; then
         . /etc/bash_completion
      fi
   fi
   complete -F _command j # !!! NICE !!!
   stty -ixon # disables ^S/^Q (terminal suspend/resume) (very nice in terminator)
   set +o histexpand
   shopt -s autocd # In interactive shells, assume cd if  a command is the name of a directory.
   shopt -s checkwinsize # check values of LINES and COLUMNS after each command
   shopt -s cmdhist # attempt to save all lines of a multiple-line command in the same history entry
   shopt -s dotglob # cause * to include hidden files except . and ..
   shopt -s extdebug # cause $(declare -pF) to include source information
   shopt -s extglob # allow use of ?|*|+|@|!(pattern[|pattern...])
   shopt -s globstar # cause ** to include all descendants and **/ to exclude non-directories
   shopt -s histappend # cause history list to be appended to the file named by the value of $HISTFILE
   shopt -s histreedit # cause readline to give the user opportunity to re-edit a failed history substitution
   shopt -s histverify # cause readline to put results of history substitution into the editing buffer (bypass the shell parser)
   shopt -s hostcomplete # reaffirm readline performs hostname completion when a word containing a '@' is being completed
   shopt -s nocaseglob # ignore case during completion and globbing
   echo "* includes hidden:** is recursive:**/ directories only:extglob"
}

CheckBlesh() { # bash line editor to be sourced
   # @see https://github.com/akinomyoga/ble.sh
   [[ -e ~/.local/share/blesh/out/ble.sh ]] && return
   # root is not technically needed
   [[ -e ~/.local/share/blesh/Makefile ]] \
      || DoUntilKeypress "Installation of improved bash line editor (instead of GNU readline)" \
                         git clone \
                         --recursive \
                         --depth 1 \
                         --shallow-submodules \
                         https://github.com/akinomyoga/ble.sh.git \
                         ~/.local/share/blesh/
   cd ~/.local/share/blesh/ || return
   make
   cd - || return
   find ~/.local/share/blesh/out/ble.sh 2>/dev/null
}

################
# begin
################

# echo "Forget bash history..." && rm -f ~/.bash_history
# rm -f ~/.wget-hsts # forget wget secure connections history

[[ "$DISPLAY" && -e ~/.xinitrc ]] \
   && bash .xinitrc \
   && echo # reapply keyboard speed

if [[ -e /etc/bash_completion ]]; then
   . /etc/bash_completion
else
   echo "!!! Need to install package bash-completion"
fi

declare BLESH
# !!! keyboard and colors NEED redefined to keep blesh from totally SUCKING !!!
if false && BLESH=$(CheckBlesh); then
   # shellcheck source=.local/share/blesh/out/ble.sh
   . "$BLESH"
else
   # shellcheck source=.bashrc-complete
   . "$HOME/.bashrc-complete" # better, but still can't prefix command with *
   _bcpp --defaults # activate better completion from .bashrc-complete
fi

# print date/time # timedatectl list-timezones | set-timezone
tput setaf 7
timedatectl | sed -nE 's/^[[:space:]]*Time zone:[[:space:]]*//p'
date +'...%A %B %d, %Y...'
tput sgr0

CheckPrompt # function CheckPrompt not found after login shell
CheckShell # shopt settings do not survive after login shell

# shellcheck source=.bashrc-alias
. "$HOME/.bashrc-alias" # must be done last
