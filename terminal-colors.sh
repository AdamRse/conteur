#!/bin/bash
# Script pour afficher toutes les couleurs 256 avec leur code

echo "=== PALETTE 256 COULEURS ==="
echo "Format: \\e[38;5;XXXm  où XXX = code couleur"
echo ""

# Fonction pour afficher une couleur
show_color() {
    local code=$1
    printf "\e[48;5;%sm  %3d  \e[0m" $code $code
}

# 1. COULEURS SYSTÈME (0-15)
echo "══╣ 0-15 : Couleurs système ╠══"
for i in {0..15}; do
    show_color $i
    if [ $(((i+1)%8)) -eq 0 ]; then
        echo ""
    fi
done
echo ""

# 2. CUBE RGB 6×6×6 (16-231)
echo "══╣ 16-231 : Cube RGB 6×6×6 ╠══"
echo "Organisation : 16 + (R×36) + (G×6) + B (R,G,B de 0 à 5)"
echo ""

# Afficher le cube par plans R (Rouge)
for r in {0..5}; do
    echo "╔═══ Plan R=$r (rouge) ═══╗"
    for g in {0..5}; do
        for b in {0..5}; do
            code=$((16 + r*36 + g*6 + b))
            show_color $code
        done
        echo ""
    done
    echo ""
done

# 3. NIVEAUX DE GRIS (232-255)
echo "══╣ 232-255 : Niveaux de gris ╠══"
for i in {232..255}; do
    show_color $i
    if [ $(((i-231)%12)) -eq 0 ] || [ $i -eq 255 ]; then
        echo ""
    fi
done

# 4. AFFICHAGE COMPACT ALTERNATIF
echo ""
echo "══╣ Vue compacte (0-255) ╠══"
for i in {0..255}; do
    printf "\e[38;5;%sm%3d\e[0m " $i $i
    if [ $(((i+1)%16)) -eq 0 ]; then
        echo ""
    fi
done

# 5. EXEMPLES D'UTILISATION
echo ""
echo "══╣ Exemples d'utilisation ╠══"
echo -e "Texte rouge vif:     \e[38;5;196mCODE 196\e[0m"
echo -e "Texte vert vif:      \e[38;5;46mCODE 46\e[0m"
echo -e "Texte jaune vif:     \e[38;5;226mCODE 226\e[0m"
echo -e "Texte bleu vif:      \e[38;5;21mCODE 21\e[0m"
echo -e "Texte magenta:       \e[38;5;201mCODE 201\e[0m"
echo -e "Texte cyan:          \e[38;5;51mCODE 51\e[0m"
echo -e "Texte orange:        \e[38;5;214mCODE 214\e[0m"
echo -e "Texte violet:        \e[38;5;93mCODE 93\e[0m"

# 6. COMMENT CALCULER UNE COULEUR RGB
echo ""
echo "══╣ Calculer une couleur RGB ╠══"
echo "Pour R=3, G=2, B=1 (chaque de 0 à 5):"
echo "Code = 16 + (R×36) + (G×6) + B"
echo "      = 16 + (3×36) + (2×6) + 1"
echo "      = 16 + 108 + 12 + 1"
echo "      = 137"
echo -e "Résultat: \e[38;5;137mCODE 137\e[0m"

# 7. TESTER UN CODE SPÉCIFIQUE
echo ""
echo "══╣ Tester un code spécifique ╠══"
read -p "Entrez un code (0-255) ou ENTER pour quitter: " code

if [[ -n "$code" && "$code" =~ ^[0-9]+$ && "$code" -ge 0 && "$code" -le 255 ]]; then
    echo ""
    echo -e "Code $code: \e[48;5;${code}m   ARRIÈRE-PLAN   \e[0m"
    echo -e "Code $code: \e[38;5;${code}m   PREMIER PLAN   \e[0m"
    echo ""
    
    # Calcul RGB si dans la plage 16-231
    if [[ "$code" -ge 16 && "$code" -le 231 ]]; then
        temp=$((code - 16))
        r=$((temp / 36))
        temp=$((temp % 36))
        g=$((temp / 6))
        b=$((temp % 6))
        echo "Composition RGB (0-5):"
        echo "  Rouge: $r (0=min, 5=max)"
        echo "  Vert:  $g (0=min, 5=max)"
        echo "  Bleu:  $b (0=min, 5=max)"
        echo "  RVB réel: ~$((r*51)), $((g*51)), $((b*51))"
    elif [[ "$code" -ge 232 && "$code" -le 255 ]]; then
        niveau=$((code - 232))
        gris=$((niveau * 10 + 8))
        echo "Niveau de gris: $niveau/23"
        echo "Valeur RGB: ~$gris,$gris,$gris"
    fi
fi

echo ""
echo "=== FIN DE LA PALETTE ==="