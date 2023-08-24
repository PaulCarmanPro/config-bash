#!/usr/bin/bash
#
# ~/.bashrc executed by bash(1) for non-login shells.
#
# shellcheck disable=SC2155 # Declare and assign separately to avoid masking return values.
# shellcheck disable=SC2088 # Tilde does not expand in quotes. Use $HOME.
#

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
	   PS1+="\[$(tput setaf 15)\]\w " # $PWD
	   #  cause prompt to include exit code if non-zero
	   if [ 0 != "$zExitCode" ]; then
		   PS1+="\[$(tput setaf 1)\]($zExitCode)"
	   fi
      PS1+="\[$(tput sgr0)\]"
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

# NOT INTERACTIVE = DON'T DO ANYTHING (cannot use exit during startup)
# checking PS1 for any value also demonstrates an interactive shell
[[ "$-" != *i* ]] && exit

# print date/time
printf '%s...%s T %s...%s\n' \
       "$(tput setaf 7)" \
       "$(date +'%A %B %d, %Y')" \
       "$(timedatectl \
					| sed -nE 's/^[[:space:]]*Time zone:[[:space:]]*//p' \
					| sed -E 's/.*\((.*),[[:space:]](.*)\)/\1\2/')" \
       "$(tput sgr0)"

# shellcheck source=.bashrc.alias
. "$HOME/.bashrc.alias"
# shellcheck source=.bashrc.complete
. "$HOME/.bashrc.complete" # zsh like completion

CheckPrompt # function CheckPrompt not found after login shell
CheckShell # shopt settings do not survive after login shell
_bcpp --defaults # activate zsh like completion from .bashrc.complete

if [[ "-bash" != "$(basename -- "$0")" ]]; then
	: tput vpa "$(tput lines)" # do not move to bottom of console during login
   echo # simple skip looks better
fi
