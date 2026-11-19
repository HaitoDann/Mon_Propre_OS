# vinx-i18n.sh : langue des messages des scripts VinX (notifications, noms de dossiers).
# À inclure (« . /usr/lib/vinx/vinx-i18n.sh ») ; même règle que les applications (common/vinxi18n.h) :
# préférence interface/language de ~/.config/vinx/shell.ini, sinon langue du système ;
# français par défaut, anglais pour toute autre langue.
#   T "texte français" "English text"   → affiche le texte dans la langue de l'utilisateur
vinx_lang() {
	pref=$(awk -F= '/^\[/{g=$0} g=="[interface]" && $1=="language" {sub(/^[^=]*=/,""); gsub(/^"|"$/,""); print; exit}' \
		"${XDG_CONFIG_HOME:-$HOME/.config}/vinx/shell.ini" 2>/dev/null)
	if [ -z "$pref" ]; then
		pref=${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}
		pref=${pref%%_*}; pref=${pref%%.*}
	fi
	case "$pref" in fr|C|"") echo fr ;; *) echo en ;; esac
}
VINX_LANG=${VINX_LANG:-$(vinx_lang)}
T() { if [ "$VINX_LANG" = en ]; then printf '%s' "$2"; else printf '%s' "$1"; fi; }
