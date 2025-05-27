# Configuration des clés API

## Méthode 1 : Fichier APIKeys.plist (Recommandée pour la production)

1. **Copiez le fichier template :**
   ```bash
   cp APIKeys.plist.template APIKeys.plist
   ```

2. **Éditez le fichier `APIKeys.plist` :**
   - Ouvrez le fichier `APIKeys.plist` dans Xcode
   - Remplacez `YOUR_OPENAI_API_KEY_HERE` par votre vraie clé API OpenAI

3. **Ajoutez le fichier au projet :**
   - Glissez-déposez `APIKeys.plist` dans votre projet Xcode
   - Assurez-vous qu'il est ajouté au target principal

4. **Ajoutez à .gitignore :**
   ```
   APIKeys.plist
   ```

## Méthode 2 : Variables d'environnement Xcode (Pour le développement)

1. **Dans Xcode :**
   - Product → Scheme → Edit Scheme...
   - Onglet "Run" → "Arguments"
   - Section "Environment Variables"
   - Ajoutez : `OPENAI_API_KEY` = `votre_clé_api`

## Méthode 3 : Info.plist (Alternative)

1. **Ajoutez dans Info.plist :**
   ```xml
   <key>OPENAI_API_KEY</key>
   <string>votre_clé_api</string>
   ```

## Obtenir une clé API OpenAI

1. Allez sur [platform.openai.com](https://platform.openai.com)
2. Créez un compte ou connectez-vous
3. Allez dans "API Keys"
4. Créez une nouvelle clé API
5. Copiez la clé (elle ne sera affichée qu'une fois)

## Sécurité

⚠️ **Important :**
- Ne commitez jamais vos vraies clés API dans Git
- Ajoutez `APIKeys.plist` à votre `.gitignore`
- Utilisez des clés API avec des limites appropriées
- Régénérez vos clés si elles sont compromises

## Ordre de priorité

L'app cherche les clés API dans cet ordre :
1. Variables d'environnement (développement avec Xcode)
2. Fichier `APIKeys.plist` (production)
3. `Info.plist` (alternative) 