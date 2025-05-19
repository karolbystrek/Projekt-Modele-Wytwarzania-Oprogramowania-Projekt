#!/bin/bash

# Sprawdzenie czy plantuml.jar istnieje
if [ ! -f "./plantuml.jar" ]; then
    echo "Brakuje pliku plantuml.jar w bieżącym folderze."
    exit 1
fi

# Sprawdzenie czy podano argument (folder źródłowy)
if [ -z "$1" ]; then
    echo "Użycie: $0 <folder_źródłowy>"
    exit 1
fi

# Definiujemy folder źródłowy na podstawie argumentu
src_dir="$1"

# Sprawdzenie czy folder źródłowy istnieje
if [ ! -d "$src_dir" ]; then
    echo "Folder '$src_dir' nie istnieje."
    exit 1
fi

# Definiujemy główny folder wyjściowy wewnątrz folderu źródłowego jako ścieżkę bezwzględną
# Używamy cd && pwd dla lepszej kompatybilności niż realpath
abs_src_dir=$(cd "$src_dir" && pwd)
if [ -z "$abs_src_dir" ]; then
    echo "Nie można uzyskać bezwzględnej ścieżki dla '$src_dir'."
    exit 1
fi
base_output_dir="$abs_src_dir/images"

# Tworzymy główny folder na obrazy, jeśli nie istnieje
mkdir -p "$base_output_dir"

# Licznik znalezionych plików
file_count=0

# Przetwarzamy pliki .txt znalezione przez find
# Używamy pętli while read zamiast mapfile dla większej kompatybilności
# Używamy -print0 i read -d $'\0' dla bezpiecznego przetwarzania nazw plików ze spacjami/znakami specjalnymi
find "$src_dir" -type f -name '*.txt' -print0 | while IFS= read -d $'\0' -r txt_file; do
    # Pomijamy pliki w folderze Images, aby uniknąć pętli
    # Porównujemy ze ścieżką bezwzględną folderu wyjściowego
    if [[ "$(dirname "$txt_file")" == "$base_output_dir"* ]]; then
        continue
    fi

    # Zwiększamy licznik plików przy każdym znalezionym pliku
    ((file_count++))

    # Jeśli to pierwszy znaleziony plik, wyświetl nagłówek
    if [ "$file_count" -eq 1 ]; then
        echo "Znaleziono pliki .txt w '$src_dir'. Generowanie diagramów..."
    fi

    echo "Przetwarzanie pliku: $txt_file"

    # Uzyskaj ścieżkę względną pliku bez nazwy folderu źródłowego
    # relative_path="${txt_file#$src_dir/}" # Niepotrzebne, PlantUML sam obsłuży nazwę pliku
    # Uzyskaj ścieżkę do katalogu względnego
    # relative_dir=$(dirname "$relative_path") # Niepotrzebne

    # Utwórz docelowy katalog wyjściowy wewnątrz głównego folderu wyjściowego
    # target_dir="$base_output_dir/" # Niepotrzebne, PlantUML tworzy pliki bezpośrednio w -output
    # mkdir -p "$target_dir" # Niepotrzebne, mkdir -p dla base_output_dir wystarczy

    # Generuj obrazki do docelowego katalogu wyjściowego (ścieżka bezwzględna)
    # PlantUML użyje nazwy pliku źródłowego dla pliku wyjściowego
    java -jar ./plantuml.jar -config "/Users/karol/Programming/LaTeX/MWO Projekt/aws-orange-theme.puml" "$txt_file" -output "$base_output_dir"

    # Sprawdź kod wyjścia polecenia java
    if [ $? -ne 0 ]; then
        echo "Błąd podczas przetwarzania pliku: $txt_file"
    fi
done

# Sprawdzamy, czy znaleziono jakiekolwiek pliki po zakończeniu pętli
if [ "$file_count" -gt 0 ]; then
    echo "Generowanie diagramów zakończone dla $file_count plików. Obrazy zapisano w '$base_output_dir'."
else
    echo "Nie znaleziono plików .txt w folderze '$src_dir' ani jego podfolderach (poza '$base_output_dir')."
fi
