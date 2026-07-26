# //
# JUJUTSU (jj) PROMPT SEGMENT
# //
# adds a `jj` segment to the bullet-train theme, mirroring the built-in `git`
# segment and standing in for it inside a jj workspace.
#
# > usage:
#   - add `jj` to BULLETTRAIN_PROMPT_ORDER, just before `git`

# //
# JJ
# //
if [ ! -n "${BULLETTRAIN_JJ_BG+1}" ]; then
  BULLETTRAIN_JJ_BG=white
fi
if [ ! -n "${BULLETTRAIN_JJ_FG+1}" ]; then
  BULLETTRAIN_JJ_FG=black
fi

# //
# JJ PROMPT
# //
if [ ! -n "${BULLETTRAIN_JJ_PREFIX+1}" ]; then
  # \ue0a0 is the powerline branch glyph, matching the git segment prefix
  BULLETTRAIN_JJ_PREFIX=$'\ue0a0 '
fi
if [ ! -n "${BULLETTRAIN_JJ_SUFFIX+1}" ]; then
  BULLETTRAIN_JJ_SUFFIX=""
fi
# the verdict, mirroring git's clean/dirty pair. an empty change is one that
# does not differ from its parent, which is jj's equivalent of a clean tree
if [ ! -n "${BULLETTRAIN_JJ_CLEAN+1}" ]; then
  BULLETTRAIN_JJ_CLEAN=" %F{green}✔%F{black}"
fi
if [ ! -n "${BULLETTRAIN_JJ_DIRTY+1}" ]; then
  BULLETTRAIN_JJ_DIRTY=" %F{red}✘%F{black}"
fi
# per-file states, borrowing git's symbols
if [ ! -n "${BULLETTRAIN_JJ_ADDED+1}" ]; then
  BULLETTRAIN_JJ_ADDED=" %F{green}✚%F{black}"
fi
if [ ! -n "${BULLETTRAIN_JJ_MODIFIED+1}" ]; then
  BULLETTRAIN_JJ_MODIFIED=" %F{blue}✹%F{black}"
fi
if [ ! -n "${BULLETTRAIN_JJ_DELETED+1}" ]; then
  BULLETTRAIN_JJ_DELETED=" %F{red}✖%F{black}"
fi
# no description set yet. jj auto-tracks files, so there is nothing to map
# git's UNTRACKED onto — an undescribed change is the nearest "not yet
# recorded" state. only meaningful once the change has content
if [ ! -n "${BULLETTRAIN_JJ_NODESC+1}" ]; then
  BULLETTRAIN_JJ_NODESC=" %F{yellow}✭%F{black}"
fi
# git's UNMERGED and DIVERGED symbols, for the states that genuinely match
if [ ! -n "${BULLETTRAIN_JJ_CONFLICT+1}" ]; then
  BULLETTRAIN_JJ_CONFLICT=" ═"
fi
if [ ! -n "${BULLETTRAIN_JJ_DIVERGED+1}" ]; then
  BULLETTRAIN_JJ_DIVERGED=" ⬍"
fi
# the change is immutable, per the immutable_heads() revset
if [ ! -n "${BULLETTRAIN_JJ_IMMUTABLE+1}" ]; then
  BULLETTRAIN_JJ_IMMUTABLE=" %F{cyan}≡%F{black}"
fi
# shown when the workspace exists but has no working-copy commit
if [ ! -n "${BULLETTRAIN_JJ_STALE+1}" ]; then
  BULLETTRAIN_JJ_STALE="%F{red}stale%F{black}"
fi

# a bookmark usually lags a few changes behind @, so pick up the nearest
# ancestor carrying one — that is the closest equivalent to a git branch name.
# unioning it with @ keeps this to a single jj invocation
BULLETTRAIN_JJ_REVSET='latest(::@ & bookmarks()) | @'

# emits one `<kind>|<change id>|<bookmarks>|<flags>` row per revision, with
# flags one letter per state, in display order. \x1f separates the fields
# because tab is IFS whitespace, which would collapse the empty ones
BULLETTRAIN_JJ_TEMPLATE='
  if(current_working_copy, "w", "b") ++ "\x1f"
  ++ change_id.shortest() ++ "\x1f"
  ++ local_bookmarks.join(",") ++ "\x1f"
  ++ if(current_working_copy,
       if(empty, "k", "x")
       ++ if(self.diff().files().filter(|f| f.status() == "added").len() > 0, "a")
       ++ if(self.diff().files().filter(|f| f.status() == "modified").len() > 0, "m")
       ++ if(self.diff().files().filter(|f| f.status() == "removed").len() > 0, "r")
       ++ if(!empty && description == "", "d")
       ++ if(conflict, "c")
       ++ if(divergent, "v")
       ++ if(immutable, "i"))
  ++ "\n"'

# in a colocated repo both .jj and .git are present, and git sees a detached
# HEAD at the @- commit, so let the jj segment stand in for the git one.
#
# this is done per render rather than by wrapping prompt_git at source time:
# .zshrc re-sources oh-my-zsh.sh, which reloads the theme and restores the
# original prompt_git, silently undoing any wrapper installed here. build_prompt
# runs inside a command substitution, so redefining prompt_git is scoped to the
# current prompt and cannot leak into the interactive shell
bullettrain_suppress_git() {
  prompt_git() { : }
}

prompt_jj() {
  command -v jj >/dev/null 2>&1 || return

  local out kind id marks flags glyphs
  local change bookmark ancestor
  local -A glyph_of

  # --ignore-working-copy keeps this at ~20ms and, crucially, stops every
  # prompt redraw from snapshotting the working copy into a new operation
  if ! out=$(jj log --ignore-working-copy --no-graph --color=never \
    -r $BULLETTRAIN_JJ_REVSET -T $BULLETTRAIN_JJ_TEMPLATE 2>/dev/null); then
    # no working-copy commit means a stale workspace rather than a plain
    # "not a jj repo", so only then is the extra lookup worth paying for
    jj root --ignore-working-copy >/dev/null 2>&1 || return

    bullettrain_suppress_git
    prompt_segment $BULLETTRAIN_JJ_BG $BULLETTRAIN_JJ_FG
    echo -n ${BULLETTRAIN_JJ_PREFIX}${BULLETTRAIN_JJ_STALE}${BULLETTRAIN_JJ_SUFFIX}

    return
  fi

  bullettrain_suppress_git

  while IFS=$'\x1f' read -r kind id marks flags; do
    if [[ $kind == w ]]; then
      change=$id
      bookmark=$marks
      glyphs=""

      glyph_of=(
        k $BULLETTRAIN_JJ_CLEAN
        x $BULLETTRAIN_JJ_DIRTY
        a $BULLETTRAIN_JJ_ADDED
        m $BULLETTRAIN_JJ_MODIFIED
        r $BULLETTRAIN_JJ_DELETED
        d $BULLETTRAIN_JJ_NODESC
        c $BULLETTRAIN_JJ_CONFLICT
        v $BULLETTRAIN_JJ_DIVERGED
        i $BULLETTRAIN_JJ_IMMUTABLE
      )
      for flag in ${(s::)flags}; do
        glyphs+=$glyph_of[$flag]
      done
    else
      ancestor=$marks
    fi
  done <<< $out

  # @ carrying its own bookmark collapses the revset union to a single row,
  # so prefer that over the ancestor lookup
  [[ -z $bookmark ]] && bookmark=$ancestor
  [[ -n $bookmark ]] && bookmark+=" "

  prompt_segment $BULLETTRAIN_JJ_BG $BULLETTRAIN_JJ_FG
  echo -n ${BULLETTRAIN_JJ_PREFIX}${bookmark}${change}${glyphs}${BULLETTRAIN_JJ_SUFFIX}
}
