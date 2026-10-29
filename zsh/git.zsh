# Git aliases, defined here so they work even when oh-my-zsh (and its git
# plugin) is missing on a machine. Same names as the oh-my-zsh git plugin.

# main/master detection used by gcm / grbm; oh-my-zsh provides its own
if ! (( $+functions[git_main_branch] )); then
  git_main_branch() {
    local b
    for b in main trunk mainline master; do
      git show-ref -q --verify "refs/heads/$b" && { echo "$b"; return; }
    done
    echo main
  }
fi

alias g='git'

# status / log / diff
alias gst='git status'
alias gss='git status --short'
alias gd='git diff'
alias gds='git diff --staged'
alias glo='git log --oneline --decorate'
alias glog='git log --oneline --decorate --graph'

# add
alias ga='git add'
alias gA='git add --all'
alias gaa='git add --all'
alias gap='git add --patch'

# commit
alias gc='git commit --verbose'
alias gcmsg='git commit --message'
alias gca='git commit --verbose --all'
alias gc!='git commit --verbose --amend'
alias gcn!='git commit --verbose --no-edit --amend'

# branches
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gsw='git switch'
alias gswc='git switch --create'
alias gcm='git checkout $(git_main_branch)'

# remote
alias gf='git fetch'
alias gfa='git fetch --all --prune'
alias gl='git pull'
alias gpr='git pull --rebase'
alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpsup='git push --set-upstream origin $(git branch --show-current)'

# rebase / stash / misc
alias grb='git rebase'
alias grbm='git rebase $(git_main_branch)'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias gsta='git stash push'
alias gstp='git stash pop'
alias gstl='git stash list'
alias grs='git restore'
alias grst='git restore --staged'
alias gcp='git cherry-pick'
