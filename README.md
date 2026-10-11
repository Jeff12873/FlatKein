# FlatKein

Dépôt Flatpak personnel : un seul dépôt à ajouter dans Warehouse pour recevoir toutes mes applications
et leurs mises à jour.

Adresse : https://jeff12873.github.io/FlatKein/

## Ajouter le dépôt

Dans Warehouse : **Remotes › +**, nom `FlatKein`, adresse
`https://jeff12873.github.io/FlatKein/FlatKein.flatpakrepo`, installation **User**.

Ou en une commande :

    flatpak remote-add --user --if-not-exists FlatKein https://jeff12873.github.io/FlatKein/FlatKein.flatpakrepo

## Fonctionnement

```
dépôt de chaque application ── fabrique son .flatpak ──► Release GitHub
                                                              │
FlatKein (ce dépôt) ── récupère la dernière Release de chaque application,
                       assemble, signe ──► GitHub Pages ──► Warehouse
```

| Fichier | Rôle |
|---|---|
| `applications.txt` | La liste des applications publiées |
| `outils/assembler.sh` | Télécharge les `.flatpak`, construit le dépôt signé et le site |
| `.github/workflows/publier.yml` | Lance l'assemblage et publie sur GitHub Pages |
| `icone.svg` | Icône du dépôt |

La publication se lance quand une application prévient d'une nouvelle version, quand
`applications.txt` change, à la main (`gh workflow run publier -R Jeff12873/FlatKein`),
et toutes les 6 heures par sécurité (sans rien republier si rien n'a changé).

## Ajouter une application

Modèle complet : le dépôt [enveloppes](https://github.com/Jeff12873/enveloppes)
(`outils/flatpak.sh`, `bureau/flatpak/`, `.github/workflows/flatpak.yml`).

1. **Identifiant Flatpak** au format `domaine.inverse.NomApp` (ex. `fr.enveloppes.Enveloppes`) :
   la dernière partie est le nom affiché par défaut.
2. **Fichiers Flatpak** dans le dépôt de l'application :
   - un `.desktop` (lanceur du menu) et un `.metainfo.xml` (fiche : nom, résumé, description, catégories) ;
   - des icônes PNG 64 et 128 px, plus une grande (512 px) ;
   - **la fiche AppStream** dans `files/share/app-info/xmls/<id>.xml.gz` et les icônes dans
     `files/share/app-info/icons/flatpak/<taille>/<id>.png`. **Sans elle, l'application est invisible
     dans Warehouse et Discover**, même si elle est bien dans le dépôt.
3. **Workflow GitHub** qui fabrique le `.flatpak` à chaque `git push` et le publie en **Release**
   (permission `contents: write`), puis prévient FlatKein avec le secret `FLATKEIN_JETON` :
   `gh secret set FLATKEIN_JETON -R Jeff12873/<application>` (même jeton pour toutes les applications).
4. Ajouter une ligne dans `applications.txt` : `Jeff12873/<depot>  <identifiant>  <Nom>`, puis `git push`.
5. Vérifier : https://jeff12873.github.io/FlatKein/versions.txt liste la nouvelle application,
   puis elle apparaît dans Warehouse (rouvrir Warehouse pour qu'il relise le catalogue).

Pour une application **qui n'est pas en Electron**, la base `org.electronjs.Electron2.BaseApp` et le
lanceur `zypak-wrapper` ne servent pas : seuls la fiche, le workflow et la Release restent identiques.

## Signature

Le dépôt est signé avec une clé GPG dédiée : secret `CLE_GPG_PRIVEE`, variable `CLE_GPG_ID`.
Une copie de la clé privée est gardée hors de GitHub (dossier `prive/` du projet Enveloppes).
Sans elle, il faudrait créer une nouvelle clé et ré-ajouter le dépôt sur chaque PC.

## Mises à jour immédiates (facultatif)

Sans réglage, une nouvelle version d'une application arrive dans FlatKein en 6 heures au plus.
Pour qu'elle arrive en quelques minutes, chaque application peut prévenir FlatKein :

1. Créer un jeton sur https://github.com/settings/personal-access-tokens/new :
   accès au **seul dépôt FlatKein**, permission **Contents : Read and write**.
2. L'enregistrer comme secret `FLATKEIN_JETON` dans le dépôt de l'application :
   `gh secret set FLATKEIN_JETON -R Jeff12873/<application>`.

GitHub met en pause les tâches planifiées d'un dépôt public sans activité pendant 60 jours :
avec ce jeton, ce n'est plus un problème, puisque chaque nouvelle version déclenche la publication.
