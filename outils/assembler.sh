#!/bin/sh
# Assemble toutes les applications de applications.txt en un seul dépôt Flatpak signé,
# et prépare le site GitHub Pages dans site/ :
#   repo/                   le dépôt Flatpak
#   FlatKein.flatpakrepo    pour ajouter le dépôt (Warehouse › Remotes)
#   <identifiant>.flatpakref  pour installer une application en une commande
#   versions.txt            version publiée de chaque application (sert à éviter les publications inutiles)
#   index.html              page d'accueil
#
# Usage : CLE_GPG=<identifiant de la clé> ADRESSE=https://jeff12873.github.io/FlatKein sh outils/assembler.sh
# Prérequis : flatpak, ostree, gh (connecté), gpg avec la clé privée importée.

set -e

SITE=site
CLE=$(gpg --export "$CLE_GPG" | base64 -w0)

rm -rf paquets "$SITE"
mkdir -p paquets "$SITE"
ostree init --mode=archive-z2 --repo="$SITE/repo"
: > "$SITE/versions.txt"
: > liste.html

grep -v -e '^#' -e '^[[:space:]]*$' applications.txt | while read -r DEPOT ID NOM; do
  VERSION=$(gh release view --repo "$DEPOT" --json tagName --jq .tagName)
  echo "• $NOM : $DEPOT $VERSION"

  gh release download "$VERSION" --repo "$DEPOT" --pattern '*.flatpak' --dir "paquets/$ID"
  flatpak build-import-bundle --gpg-sign="$CLE_GPG" "$SITE/repo" paquets/"$ID"/*.flatpak > /dev/null
  echo "$DEPOT $VERSION" >> "$SITE/versions.txt"

  cat > "$SITE/$ID.flatpakref" <<FIN
[Flatpak Ref]
Name=$ID
Branch=master
Title=$NOM
Url=$ADRESSE/repo/
SuggestRemoteName=FlatKein
RuntimeRepo=https://dl.flathub.org/repo/flathub.flatpakrepo
IsRuntime=false
GPGKey=$CLE
FIN

  echo "<li><strong>$NOM</strong> ($VERSION) — <code>flatpak install --user $ADRESSE/$ID.flatpakref</code></li>" >> liste.html
done

flatpak build-update-repo --gpg-sign="$CLE_GPG" --title="FlatKein" \
  --generate-static-deltas --prune "$SITE/repo" > /dev/null

cp icone.svg "$SITE/icone.svg"
cat > "$SITE/FlatKein.flatpakrepo" <<FIN
[Flatpak Repo]
Title=FlatKein
Url=$ADRESSE/repo/
Homepage=$ADRESSE/
Comment=Les applications de Jeff12873
Icon=$ADRESSE/icone.svg
GPGKey=$CLE
FIN

cat > "$SITE/index.html" <<FIN
<!doctype html>
<html lang="fr"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>FlatKein</title>
<link rel="icon" href="icone.svg">
<style>body{font-family:system-ui,sans-serif;max-width:760px;margin:40px auto;padding:0 16px;line-height:1.55;color:#1f1640}
h1{display:flex;gap:12px;align-items:center}code,pre{background:#f1edff;border-radius:8px;padding:2px 6px;word-break:break-all}pre{padding:12px}</style>
<h1><img src="icone.svg" alt="" width="44" height="44">FlatKein</h1>
<p>Dépôt Flatpak personnel.</p>
<h2>Ajouter le dépôt</h2>
<p>Dans Warehouse › Remotes › +, ou en une commande :</p>
<pre>flatpak remote-add --user --if-not-exists FlatKein $ADRESSE/FlatKein.flatpakrepo</pre>
<h2>Applications</h2>
<ul>
$(cat liste.html)
</ul>
</html>
FIN
rm liste.html

echo "Dépôt prêt dans $SITE/"
