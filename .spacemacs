auto-mode-alist :?;; -*- mode: emacs-lisp -*-
;; This file is loaded by Spacemacs at startup.
;; It must be stored in your home directory.

(defun dotspacemacs/layers ()
  "Configuration Layers declaration.
You should not put any user code in this function besides modifying the variable
values."
  (setq-default
   ;; Base distribution to use. This is a layer contained in the directory
   ;; `+distribution'. For now available distributions are `spacemacs-base'
   ;; or `spacemacs'. (default 'spacemacs)
   dotspacemacs-distribution 'spacemacs
   ;; Lazy installation of layers (i.e. layers are installed only when a file
   ;; with a supported type is opened). Possible values are `all', `unused'
   ;; and `nil'. `unused' will lazy install only unused layers (i.e. layers
   ;; not listed in variable `dotspacemacs-configuration-layers'), `all' will
   ;; lazy install any layer that support lazy installation even the layers
   ;; listed in `dotspacemacs-configuration-layers'. `nil' disable the lazy
   ;; installation feature and you have to explicitly list a layer in the
   ;; variable `dotspacemacs-configuration-layers' to install it.
   ;; (default 'unused)
   dotspacemacs-enable-lazy-installation 'unused
   ;; If non-nil then Spacemacs will ask for confirmation before installing
   ;; a layer lazily. (default t)
   dotspacemacs-ask-for-lazy-installation t
   ;; If non-nil layers with lazy install support are lazy installed.
   ;; List of additional paths where to look for configuration layers.
   ;; Paths must have a trailing slash (i.e. `~/.mycontribs/')
   dotspacemacs-configuration-layer-path '()
   ;; List of configuration layers to load.
   dotspacemacs-configuration-layers
   '(
     rust
     yaml
     ;; for emacs
     emacs-lisp

     ;; for data science
     python
     (ipython-notebook :variables ein:jupyter-default-server-command
                       "/usr/local/bin/jupyter"
                       ein:jupyter-server-args (list "--no-browser"))
     ;; for general development
     docker
     html
     javascript
     typescript
     ;; (shell :variables
     ;;        shell-default-height 30
     ;;        shell-default-position 'bottom)

     ;; for writing
     markdown

     ;; essential functional layers
     auto-completion
     colors
     git
     (ibuffer :variables
              ibuffer-group-buffers-by 'projects)
     ivy
     org
     ranger
     semantic
     spell-checking
     (syntax-checking :variables syntax-checking-use-original-bitmaps t)
     (version-control :variables
                      version-control-diff-tool 'git-gutter
                      version-control-global-margin t))
   ;; List of additional packages that will be installed without being
   ;; wrapped in a layer. If you need some configuration for these
   ;; packages, then consider creating a layer. You can also put the
   ;; configuration in `dotspacemacs/user-config'.
   dotspacemacs-additional-packages '(
     indent-tools
     prettier-js
     smart-shift
     smart-mode-line
     osx-clipboard
     windmove)
   ;; A list of packages that cannot be updated.
   dotspacemacs-frozen-packages '()
   ;; A list of packages that will not be installed and loaded.
   dotspacemacs-excluded-packages '()
   ;; Defines the behaviour of Spacemacs when installing packages.
   ;; Possible values are `used-only', `used-but-keep-unused' and `all'.
   ;; `used-only' installs only explicitly used packages and uninstall any
   ;; unused packages as well as their unused dependencies.
   ;; `used-but-keep-unused' installs only the used packages but won't uninstall
   ;; them if they become unused. `all' installs *all* packages supported by
   ;; Spacemacs and never uninstall them. (default is `used-only')
   dotspacemacs-install-packages 'used-only))

(defun dotspacemacs/init ()
  "Initialization function.
This function is called at the very startup of Spacemacs initialization
before layers configuration.
You should not put any user code in there besides modifying the variable
values."
  ;; This setq-default sexp is an exhaustive list of all the supported
  ;; spacemacs settings.
  (setq-default
   ;; If non nil ELPA repositories are contacted via HTTPS whenever it's
   ;; possible. Set it to nil if you have no way to use HTTPS in your
   ;; environment, otherwise it is strongly recommended to let it set to t.
   ;; This variable has no effect if Emacs is launched with the parameter
   ;; `--insecure' which forces the value of this variable to nil.
   ;; (default t)
   dotspacemacs-elpa-https t
   ;; Maximum allowed time in seconds to contact an ELPA repository.
   dotspacemacs-elpa-timeout 5
   ;; If non nil then spacemacs will check for updates at startup
   ;; when the current branch is not `develop'. Note that checking for
   ;; new versions works via git commands, thus it calls GitHub services
   ;; whenever you start Emacs. (default nil)
   dotspacemacs-check-for-update t
   ;; If non-nil, a form that evaluates to a package directory. For example, to
   ;; use different package directories for different Emacs versions, set this
   ;; to `emacs-version'.
   dotspacemacs-elpa-subdirectory nil
   ;; One of `vim', `emacs' or `hybrid'.
   ;; `hybrid' is like `vim' except that `insert state' is replaced by the
   ;; `hybrid state' with `emacs' key bindings. The value can also be a list
   ;; with `:variables' keyword (similar to layers). Check the editing styles
   ;; section of the documentation for details on available variables.
   ;; (default 'vim)
   dotspacemacs-editing-style 'emacs
   ;; If non nil output loading progress in `*Messages*' buffer. (default nil)
   dotspacemacs-verbose-loading nil
   ;; Specify the startup banner. Default value is `official', it displays
   ;; the official spacemacs logo. An integer value is the index of text
   ;; banner, `random' chooses a random text banner in `core/banners'
   ;; directory. A string value must be a path to an image format supported
   ;; by your Emacs build.
   ;; If the value is nil then no banner is displayed. (default 'official)
   dotspacemacs-startup-banner 'official
   ;; List of items to show in startup buffer or an association list of
   ;; the form `(list-type . list-size)`. If nil then it is disabled.
   ;; Possible values for list-type are:
   ;; `recents' `bookmarks' `projects' `agenda' `todos'."
   ;; List sizes may be nil, in which case
   ;; `spacemacs-buffer-startup-lists-length' takes effect.
   dotspacemacs-startup-lists '((recents . 5)
                                (projects . 7))
   ;; True if the home buffer should respond to resize events.
   dotspacemacs-startup-buffer-responsive t
   ;; Default major mode of the scratch buffer (default `text-mode')
   dotspacemacs-scratch-mode 'text-mode
   ;; List of themes, the first of the list is loaded when spacemacs starts.
   ;; Press <SPC> T n to cycle to the next theme in the list (works great
   ;; with 2 themes variants, one dark and one light)
   dotspacemacs-themes '(sanityinc-tomorrow-night
                         spacemacs-dark
                         spacemacs-light)
   ;; If non nil the cursor color matches the state color in GUI Emacs.
   dotspacemacs-colorize-cursor-according-to-state t
   ;; Default font, or prioritized list of fonts. `powerline-scale' allows to
   ;; quickly tweak the mode-line size to make separators look not too crappy.
   dotspacemacs-default-font '("Mono Input"
                               :size 13
                               :weight normal
                               :width normal
                               :powerline-scale 1.1)
   ;; The leader key
   dotspacemacs-leader-key "SPC"
   ;; The key used for Emacs commands (M-x) (after pressing on the leader key).
   ;; (default "SPC")
   dotspacemacs-emacs-command-key "SPC"
   ;; The key used for Vim Ex commands (default ":")
   dotspacemacs-ex-command-key ":"
   ;; The leader key accessible in `emacs state' and `insert state'
   ;; (default "M-m")
   dotspacemacs-emacs-leader-key "M-m"
   ;; Major mode leader key is a shortcut key which is the equivalent of
   ;; pressing `<leader> m`. Set it to `nil` to disable it. (default ",")
   dotspacemacs-major-mode-leader-key ","
   ;; Major mode leader key accessible in `emacs state' and `insert state'.
   ;; (default "C-M-m")
   dotspacemacs-major-mode-emacs-leader-key "C-M-m"
   ;; These variables control whether separate commands are bound in the GUI to
   ;; the key pairs C-i, TAB and C-m, RET.
   ;; Setting it to a non-nil value, allows for separate commands under <C-i>
   ;; and TAB or <C-m> and RET.
   ;; In the terminal, these pairs are generally indistinguishable, so this only
   ;; works in the GUI. (default nil)
   dotspacemacs-distinguish-gui-tab nil
   ;; If non nil `Y' is remapped to `y$' in Evil states. (default nil)
   dotspacemacs-remap-Y-to-y$ nil
   ;; If non-nil, the shift mappings `<' and `>' retain visual state if used
   ;; there. (default t)
   dotspacemacs-retain-visual-state-on-shift t
   ;; If non-nil, J and K move lines up and down when in visual mode.
   ;; (default nil)
   dotspacemacs-visual-line-move-text nil
   ;; If non nil, inverse the meaning of `g' in `:substitute' Evil ex-command.
   ;; (default nil)
   dotspacemacs-ex-substitute-global nil
   ;; Name of the default layout (default "Default")
   dotspacemacs-default-layout-name "Default"
   ;; If non nil the default layout name is displayed in the mode-line.
   ;; (default nil)
   dotspacemacs-display-default-layout nil
   ;; If non nil then the last auto saved layouts are resume automatically upon
   ;; start. (default nil)
   dotspacemacs-auto-resume-layouts nil
   ;; Size (in MB) above which spacemacs will prompt to open the large file
   ;; literally to avoid performance issues. Opening a file literally means that
   ;; no major mode or minor modes are active. (default is 1)
   dotspacemacs-large-file-size 1
   ;; Location where to auto-save files. Possible values are `original' to
   ;; auto-save the file in-place, `cache' to auto-save the file to another
   ;; file stored in the cache directory and `nil' to disable auto-saving.
   ;; (default 'cache)
   dotspacemacs-auto-save-file-location 'cache
   ;; Maximum number of rollback slots to keep in the cache. (default 5)
   dotspacemacs-max-rollback-slots 5
   ;; If non nil, `helm' will try to minimize the space it uses. (default nil)
   dotspacemacs-helm-resize nil
   ;; if non nil, the helm header is hidden when there is only one source.
   ;; (default nil)
   dotspacemacs-helm-no-header nil
   ;; define the position to display `helm', options are `bottom', `top',
   ;; `left', or `right'. (default 'bottom)
   dotspacemacs-helm-position 'bottom
   ;; Controls fuzzy matching in helm. If set to `always', force fuzzy matching
   ;; in all non-asynchronous sources. If set to `source', preserve individual
   ;; source settings. Else, disable fuzzy matching in all sources.
   ;; (default 'always)
   dotspacemacs-helm-use-fuzzy 'always
   ;; If non nil the paste micro-state is enabled. When enabled pressing `p`
   ;; several times cycle between the kill ring content. (default nil)
   dotspacemacs-enable-paste-transient-state nil
   ;; Which-key delay in seconds. The which-key buffer is the popup listing
   ;; the commands bound to the current keystroke sequence. (default 0.4)
   dotspacemacs-which-key-delay 0.4
   ;; Which-key frame position. Possible values are `right', `bottom' and
   ;; `right-then-bottom'. right-then-bottom tries to display the frame to the
   ;; right; if there is insufficient space it displays it at the bottom.
   ;; (default 'bottom)
   dotspacemacs-which-key-position 'bottom
   ;; If non nil a progress bar is displayed when spacemacs is loading. This
   ;; may increase the boot time on some systems and emacs builds, set it to
   ;; nil to boost the loading time. (default t)
   dotspacemacs-loading-progress-bar t
   ;; If non nil the frame is fullscreen when Emacs starts up. (default nil)
   ;; (Emacs 24.4+ only)
   dotspacemacs-fullscreen-at-startup nil
   ;; If non nil `spacemacs/toggle-fullscreen' will not use native fullscreen.
   ;; Use to disable fullscreen animations in OSX. (default nil)
   dotspacemacs-fullscreen-use-non-native nil
   ;; If non nil the frame is maximized when Emacs starts up.
   ;; Takes effect only if `dotspacemacs-fullscreen-at-startup' is nil.
   ;; (default nil) (Emacs 24.4+ only)
   dotspacemacs-maximized-at-startup nil
   ;; A value from the range (0..100), in increasing opacity, which describes
   ;; the transparency level of a frame when it's active or selected.
   ;; Transparency can be toggled through `toggle-transparency'. (default 90)
   dotspacemacs-active-transparency 60
   ;; A value from the range (0..100), in increasing opacity, which describes
   ;; the transparency level of a frame when it's inactive or deselected.
   ;; Transparency can be toggled through `toggle-transparency'. (default 90)
   dotspacemacs-inactive-transparency 90
   ;; If non nil show the titles of transient states. (default t)
   dotspacemacs-show-transient-state-title t
   ;; If non nil show the color guide hint for transient state keys. (default t)
   dotspacemacs-show-transient-state-color-guide t
   ;; If non nil unicode symbols are displayed in the mode line. (default t)
   dotspacemacs-mode-line-unicode-symbols t
   ;; If non nil smooth scrolling (native-scrolling) is enabled. Smooth
   ;; scrolling overrides the default behavior of Emacs which recenters point
   ;; when it reaches the top or bottom of the screen. (default t)
   dotspacemacs-smooth-scrolling t
   ;; Control line numbers activation.
   ;; If set to `t' or `relative' line numbers are turned on in all `prog-mode' and
   ;; `text-mode' derivatives. If set to `relative', line numbers are relative.
   ;; This variable can also be set to a property list for finer control:
   ;; '(:relative nil
   ;;   :disabled-for-modes dired-mode
   ;;                       doc-view-mode
   ;;                       markdown-mode
   ;;                       org-mode
   ;;                       pdf-view-mode
   ;;                       text-mode
   ;;   :size-limit-kb 1000)
   ;; (default nil)
   dotspacemacs-line-numbers '(:relative nil
                                         :disabled-for-modes
                                         dired-mode
                                         doc-view-mode
                                         markdown-mode
                                         org-mode
                                         pdf-view-mode
                                         ;; text-mode
                                         :size-limit-kb 1000)
   ;; Code folding method. Possible values are `evil' and `origami'.
   ;; (default 'evil)
   dotspacemacs-folding-method 'evil
   ;; If non-nil smartparens-strict-mode will be enabled in programming modes.
   ;; (default nil)
   dotspacemacs-smartparens-strict-mode nil
   ;; If non-nil pressing the closing parenthesis `)' key in insert mode passes
   ;; over any automatically added closing parenthesis, bracket, quote, etc…
   ;; This can be temporary disabled by pressing `C-q' before `)'. (default nil)
   dotspacemacs-smart-closing-parenthesis nil
   ;; Select a scope to highlight delimiters. Possible values are `any',
   ;; `current', `all' or `nil'. Default is `all' (highlight any scope and
   ;; emphasis the current one). (default 'all)
   dotspacemacs-highlight-delimiters 'all
   ;; If non nil, advise quit functions to keep server open when quitting.
   ;; (default nil)
   dotspacemacs-persistent-server nil
   ;; List of search tool executable names. Spacemacs uses the first installed
   ;; tool of the list. Supported tools are `ag', `pt', `ack' and `grep'.
   ;; (default '("ag" "pt" "ack" "grep"))
   dotspacemacs-search-tools '("ag" "pt" "ack" "grep")
   ;; The default package repository used if no explicit repository has been
   ;; specified with an installed package.
   ;; Not used for now. (default nil)
   dotspacemacs-default-package-repository nil
   ;; Delete whitespace while saving buffer. Possible values are `all'
   ;; to aggressively delete empty line and long sequences of whitespace,
   ;; `trailing' to delete only the whitespace at end of lines, `changed'to
   ;; delete only whitespace for changed lines or `nil' to disable cleanup.
   ;; (default nil)
   dotspacemacs-whitespace-cleanup nil
   ))

(defun dotspacemacs/user-init ()
  ;; delete trailing line break
  (defun delete-trailing-linebreak ()
    "Deletes all blank lines at the end of the file, even the last one"
    (interactive)
    (save-excursion
      (save-restriction
        (widen)
        (goto-char (point-max))
        (delete-blank-lines)
        (let ((trailnewlines (abs (skip-chars-backward "\n\t"))))
          (if (> trailnewlines 0)
              (progn
                (delete-char trailnewlines)))))))

  ;; closing minibuffers
  (defun minibuffer-keyboard-quit ()
    "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
    (interactive)
    (if (and delete-selection-mode transient-mark-mode mark-active)
        (setq deactivate-mark  t)
      (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
      (abort-recursive-edit)))

  ;; file operations
  (defun rename-current-buffer-file ()
    "Renames current buffer and file it is visiting."
    (interactive)
    (let ((name (buffer-name))
          (filename (buffer-file-name)))
      (if (not (and filename (file-exists-p filename)))
          (error "Buffer '%s' is not visiting a file!" name)
        (let ((new-name (read-file-name "New name: " filename)))
          (if (get-buffer new-name)
              (error "A buffer named '%s' already exists!" new-name)
            (rename-file filename new-name 1)
            (rename-buffer new-name)
            (set-visited-file-name new-name)
            (set-buffer-modified-p nil)
            (message "File '%s' successfully renamed to '%s'"
                     name (file-name-nondirectory new-name)))))))

  (defun delete-current-buffer-file ()
    "Removes file connected to current buffer and kills buffer."
    (interactive)
    (let ((filename (buffer-file-name))
          (buffer (current-buffer))
          (name (buffer-name)))
      (if (not (and filename (file-exists-p filename)))
          (ido-kill-buffer)
        (when (yes-or-no-p "Are you sure you want to remove this file? ")
          (delete-file filename)
          (kill-buffer buffer)
          (message "File '%s' successfully removed" filename)))))

  ;; magit
  (defun magit-fetch-all-repositories ()
    "Run `magit-fetch-all' in all repositories returned by `magit-list-repos`."
    (interactive)
    (dolist (repo (magit-list-repos))
      (message "Fetching in %s..." repo)
      (let ((default-directory repo))
        (magit-fetch-all (magit-fetch-arguments)))
      (message "Fetching in %s...done" repo)))

  (defadvice magit-status (around magit-fullscreen activate)
    (window-configuration-to-register :magit-fullscreen)
    ad-do-it
    (delete-other-windows))

  (defun magit-quit-session ()
    "Restores the previous window configuration and kills the magit buffer"
    (interactive)
    (kill-buffer)
    (jump-to-register :magit-fullscreen))

  ;; line number
  (defun linum-format-func (line)
    (concat
      (propertize (format linum-format-fmt line) 'face 'linum)
      (propertize "\u2502 " 'face 'default)
      ))

  ;; indention highlight
  (defun indent-guide-ruler-enabler()
    (indent-guide-mode 1)
    (setq indent-guide-char "⎸")
    (set-face-foreground 'indent-guide-face "#ccc"))

  (defun indent-guide-block-enabler()
    (indent-guide-mode 1)
    (setq indent-guide-char " ")
    (set-face-background 'indent-guide-face "#ccc")
    ))

(defun dotspacemacs/user-config ()
  ;; ----- Hooks ----- ;;

  ;; line number
  (add-hook
   'linum-before-numbering-hook
   (lambda ()
     (setq-local
      linum-format-fmt
      (let
          ((w (length
               (number-to-string
                (count-lines (point-min) (point-max))
                )
               )
              )
           )
        (concat "%" (number-to-string w) "d")
        )
      )
     ))

  ;; aggressively indent codes
  ;; (add-hook 'emacs-lisp-mode-hook #'aggressive-indent-mode)
  ;; (add-hook 'yaml-mode-hook #'aggressive-indent-mode)

  ;; indention highlight
  (add-hook 'lisp-mode-hook 'indent-guide-ruler-enabler)
  (add-hook 'yaml-mode-hook 'indent-guide-block-enabler)

  ;; indent-tools
  (add-hook 'python-mode-hook 'indent-tools-minor-mode)
  (add-hook 'yaml-mode-hook 'indent-tools-minor-mode)

  ;; color
  (add-hook 'scss-mode-hook 'rainbow-mode)

  ;; -------------------------------------------------- ;;

  ;; ----- Plugin Settings ----- ;;
  ;; magit
  (setq magit-repository-directories 
        '( "~/Repositories"
           "~/.dotfiles"
           user-emacs-directory))

  ;; typescript
  (add-to-list 'auto-mode-alist '("\\.tsx\\'" . typescript-mode))
  (flycheck-add-mode 'typescript-tslint 'typescript-mode)

  ;; indention
  (global-smart-shift-mode 1)

  ;; selection
  (delete-selection-mode 1)

  ;; osx-clipboard
  (osx-clipboard-mode 1)
  (diminish osx-clipboard-mode)

  ;; set ivy to use an arrow to highlight seted item
  (setq ivy-format-function 'ivy-format-function-arrow)

  ;; yasnippet
  (setq yas-snippet-dirs '(
                           "~/.dotfiles/snippets"
                           ))
  (yas-global-mode 1)

  ;; prettier
  (setq prettier-js-args '(
                        "--single-quote"
                        "--tab-width" "2"
                        "--trailing-comma" "none"
                        ))
  (add-hook 'web-mode-hook 'prettier-js-mode)
  (add-hook 'tide-mode-hook 'prettier-js-mode)
  (add-hook 'typescript-mode-hook 'prettier-js-mode)
  (diminish 'prettier-js-mode)

  ;; -------------------------------------------------- ;;

  ;; ----- Styles ----- ;;

  ;; rename minor mode
  (defmacro rename-modeline (package-name mode new-name)
    `(eval-after-load ,package-name
       '(defadvice ,mode (after rename-modeline activate)
          (setq mode-name ,new-name))))

  (rename-modeline "js2-mode" js2-mode "JS2")

  ;; spacing for number line
  (setq linum-format 'linum-format-func)

  ;; colors
  (set-face-attribute 'region nil :background "#666")
  (set-face-attribute 'border nil :background "#999")
  (set-face-attribute 'powerline-active2 nil :background "#444")
  (set-face-attribute 'spacemacs-emacs-face nil :background "yellow")

  ;; transparent backgound
  (set-face-background 'default "unspecified-bg" (selected-frame))

  ;; trailing whitespace
  (require 'whitespace)
  (setq-default whitespace-style '(face trailing))
  (setq-default whitespace-line-column 80)
  (global-whitespace-mode 1)

  ;; syntax checking
  (require 'flycheck)
  (set-face-attribute 'flycheck-error nil :foreground "#000" :background "#c66")
  (set-face-attribute 'flycheck-warning nil :foreground "#000" :background "#f0c674")

  ;; mode line
  (sml/setup)
  (spaceline-toggle-minor-modes-off)

  ;; -------------------------------------------------- ;;

  ;; ----- Key Bindings ----- ;;

  ;; code folding
  (global-set-key (kbd "\C-[[;`") 'evil-toggle-fold)
  (global-set-key (kbd "\C-[[;{") 'evil-open-folds)
  (global-set-key (kbd "\C-[[;}") 'evil-close-folds)

  ;; closing minibuffers
  (define-key evil-normal-state-map (kbd "<escape>") 'keyboard-quit)
  (define-key evil-visual-state-map (kbd "<escape>") 'keyboard-quit)
  (define-key minibuffer-local-map (kbd "<escape>") 'minibuffer-keyboard-quit)
  (define-key minibuffer-local-ns-map (kbd "<escape>") 'minibuffer-keyboard-quit)
  (define-key minibuffer-local-completion-map (kbd "<escape>") 'minibuffer-keyboard-quit)
  (define-key minibuffer-local-must-match-map (kbd "<escape>") 'minibuffer-keyboard-quit)
  (define-key minibuffer-local-isearch-map (kbd "<escape>") 'minibuffer-keyboard-quit)
  (define-key ivy-minibuffer-map (kbd "<escape>") 'minibuffer-keyboard-quit)
  (define-key swiper-map (kbd "<escape>") 'minibuffer-keyboard-quit)

  ;; file operations
  (global-set-key (kbd "C-f") nil)
  (global-set-key (kbd "C-f C-r") 'rename-current-buffer-file)
  (global-set-key (kbd "C-f C-k") 'delete-current-buffer-file)

  ;; magit
  (with-eval-after-load 'magit (define-key magit-status-mode-map (kbd "q") 'magit-quit-session))

  ;; nano
  (global-set-key (kbd "C-k") 'kill-whole-line)

  ;; git rebase
  (global-set-key (kbd "M-<down>") 'git-rebase-move-line-down)
  (global-set-key (kbd "M-<up>") 'git-rebase-move-line-up)

  ;; unindent
  (global-set-key (kbd "<backtab>") 'clean-aindent--bsunindent)

  ;; key binding in terminal
  (unless window-system
    ;; OSX
    (global-set-key (kbd "\C-[[;c") 'evil-yank)
    (global-set-key (kbd "\C-[[;q") 'save-buffers-kill-terminal)
    (global-set-key (kbd "\C-[[;s") 'save-buffer)
    (global-set-key (kbd "\C-[[;v") 'yank)
    (global-set-key (kbd "\C-[[;w") 'delete-window)
    (global-set-key (kbd "\C-[[;W") 'delete-frame)
    (global-set-key (kbd "\C-[[;x") 'kill-region)
    (global-set-key (kbd "\C-[[;z") 'undo-tree-undo)
    (global-set-key (kbd "\C-[[;Z") 'undo-tree-redo)
    (global-set-key (kbd "\C-[[;/") 'comment-line)

    ;; Section
    (global-set-key (kbd "\C-[[.L") 'windmove-left)
    (global-set-key (kbd "\C-[[.R") 'windmove-right)
    (global-set-key (kbd "\C-[[.U") 'windmove-up)
    (global-set-key (kbd "\C-[[.D") 'windmove-down)

    ;; scrolling
    (global-set-key (kbd "<mouse-4>") 'scroll-down-line)
    (global-set-key (kbd "<mouse-5>") 'scroll-up-line))
  ;; -------------------------------------------------- ;;
  )

;; Do not write anything past this comment. This is where Emacs will
;; auto-generate custom variable definitions.
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" default)))
 '(evil-want-Y-yank-to-eol nil)
 '(package-selected-packages
   (quote
    (flycheck-flow flow-minor-mode xpm evil-vimish-fold vimish-fold let-alist helm helm-core ghub evil goto-chg diminish projectile pkg-info epl counsel swiper bind-key packed popup undo-tree ivy hydra avy color-theme-sanityinc-tomorrow org-mime toml-mode racer flycheck-rust seq cargo rust-mode yaml-mode flycheck-color-mode-line ws-butler winum volatile-highlights vi-tilde-fringe uuidgen spaceline powerline restart-emacs rainbow-delimiters popwin persp-mode paradox spinner open-junk-file neotree move-text lorem-ipsum linum-relative link-hint info+ indent-guide hungry-delete hl-todo highlight-parentheses highlight-numbers parent-mode highlight-indentation hide-comnt google-translate golden-ratio flx-ido fill-column-indicator fancy-battery eyebrowse expand-region evil-visual-mark-mode evil-unimpaired evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-lisp-state smartparens evil-indent-plus evil-iedit-state iedit evil-exchange evil-ediff evil-args evil-anzu anzu eval-sexp-fu highlight dumb-jump define-word column-enforce-mode clean-aindent-mode auto-highlight-symbol aggressive-indent adaptive-wrap ace-link toc-org orgit org-projectile org-category-capture org-present org-bullets yapfify web-mode web-beautify tagedit stickyfunc-enhance srefactor smeargle smart-shift smart-mode-line rich-minority slim-mode scss-mode sass-mode ranger rainbow-mode rainbow-identifiers pyvenv pytest pyenv-mode py-isort pug-mode prettier-js pip-requirements osx-clipboard org-plus-contrib org-pomodoro alert log4e gntp org-download mmm-mode markdown-toc markdown-mode magit-gitflow livid-mode live-py-mode less-css-mode js2-refactor multiple-cursors js-doc indent-tools yafolding ibuffer-projectile hy-mode htmlize haml-mode gnuplot gitignore-mode gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link git-gutter-fringe+ git-gutter-fringe fringe-helper git-gutter+ git-gutter gh-md fuzzy flycheck-pos-tip pos-tip evil-magit magit git-commit with-editor emmet-mode ein skewer-mode request-deferred websocket request deferred js2-mode simple-httpd dockerfile-mode docker json-mode tablist magit-popup docker-tramp dash async json-snatcher json-reformat diff-hl cython-mode company-web web-completion-data company-tern dash-functional tern company-statistics company-anaconda company color-identifiers-mode coffee-mode auto-yasnippet yasnippet anaconda-mode pythonic f ac-ispell auto-complete tide typescript-mode flycheck s which-key wgrep use-package smex pcre2el macrostep ivy-hydra help-fns+ helm-make flx exec-path-from-shell evil-visualstar evil-escape elisp-slime-nav counsel-projectile bind-map auto-compile ace-window))))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(defun dotspacemacs/emacs-custom-settings ()
  "Emacs custom settings.
This is an auto-generated function, do not modify its content directly, use
Emacs customize menu instead.
This function is called at the very end of Spacemacs initialization."
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" default)))
 '(evil-want-Y-yank-to-eol nil)
 '(package-selected-packages
   (quote
    (yasnippet-snippets symon string-inflection spaceline-all-the-icons all-the-icons memoize pippel password-generator overseer org-brain ob-ipython nameless ivy-purpose window-purpose imenu-list importmagic epc ctable concurrent impatient-mode helm helm-core evil-org ghub let-alist evil-lion evil-cleverparens paredit editorconfig projectile pkg-info epl counsel-css counsel swiper ivy color-theme-sanityinc-tomorrow browse-at-remote packed avy popup hydra font-lock+ evil goto-chg undo-tree diminish bind-key org-mime toml-mode racer flycheck-rust seq cargo rust-mode yaml-mode flycheck-color-mode-line ws-butler winum volatile-highlights vi-tilde-fringe uuidgen spaceline powerline restart-emacs rainbow-delimiters popwin persp-mode paradox spinner open-junk-file neotree move-text lorem-ipsum linum-relative link-hint info+ indent-guide hungry-delete hl-todo highlight-parentheses highlight-numbers parent-mode highlight-indentation hide-comnt google-translate golden-ratio flx-ido fill-column-indicator fancy-battery eyebrowse expand-region evil-visual-mark-mode evil-unimpaired evil-tutor evil-surround evil-search-highlight-persist evil-numbers evil-nerd-commenter evil-mc evil-matchit evil-lisp-state smartparens evil-indent-plus evil-iedit-state iedit evil-exchange evil-ediff evil-args evil-anzu anzu eval-sexp-fu highlight dumb-jump define-word column-enforce-mode clean-aindent-mode auto-highlight-symbol aggressive-indent adaptive-wrap ace-link toc-org orgit org-projectile org-category-capture org-present org-bullets yapfify web-mode web-beautify tagedit stickyfunc-enhance srefactor smeargle smart-shift smart-mode-line rich-minority slim-mode scss-mode sass-mode ranger rainbow-mode rainbow-identifiers pyvenv pytest pyenv-mode py-isort pug-mode prettier-js pip-requirements osx-clipboard org-plus-contrib org-pomodoro alert log4e gntp org-download mmm-mode markdown-toc markdown-mode magit-gitflow livid-mode live-py-mode less-css-mode js2-refactor multiple-cursors js-doc indent-tools yafolding ibuffer-projectile hy-mode htmlize haml-mode gnuplot gitignore-mode gitconfig-mode gitattributes-mode git-timemachine git-messenger git-link git-gutter-fringe+ git-gutter-fringe fringe-helper git-gutter+ git-gutter gh-md fuzzy flycheck-pos-tip pos-tip evil-magit magit git-commit with-editor emmet-mode ein skewer-mode request-deferred websocket request deferred js2-mode simple-httpd dockerfile-mode docker json-mode tablist magit-popup docker-tramp dash async json-snatcher json-reformat diff-hl cython-mode company-web web-completion-data company-tern dash-functional tern company-statistics company-anaconda company color-identifiers-mode coffee-mode auto-yasnippet yasnippet anaconda-mode pythonic f ac-ispell auto-complete tide typescript-mode flycheck s which-key wgrep use-package smex pcre2el macrostep ivy-hydra help-fns+ helm-make flx exec-path-from-shell evil-visualstar evil-escape elisp-slime-nav counsel-projectile bind-map auto-compile ace-window))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
)
