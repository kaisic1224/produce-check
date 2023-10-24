#!/bin/sh
LANG=C; LC_ALL=C

function get_changes {
        declare -a args
        args=(-type f -mmin -10 -not -path '*/.venv/*' -not -path '*/.git/*' -not -path '*/*data/*' -not -path "*.png" -not -path '*.lock' -not -path '*.gitignore' -not -path "*/lib/*" -not -path "*/target/*", -not -path "*/*.qgz" -not -path "*/*.pdf" -not -path "*/*.aux" -not -path "*/*.fdb_latexmk" -not -path "*/*.synctex.gz" -not -path "*/*.log" -not -path "*/*.fls" -not -path "*/*.log" -not -path "*/*.rkt~")
        sum=0
        while IFS= read -r line; do
                extension=${line##*.}
                new_filename="$line"
                dirn=$(dirname "$line")
                if [[ $extension == "docx" ]]; then
                        libreoffice --headless --convert-to "txt:Text (encoded):UTF8" "$line" --outdir "$dirn"
                        new_filename="${line%.*}.txt"
                fi
                word_count=$(<"$new_filename" wc -w)
                diffs=$(./searchcmd "$new_filename" "$word_count")
                sum=$((diffs + sum))
        done < <(find ~/Documents "${args[@]}")
        echo $sum
}

function create_row {
        productivity=$(get_changes)
        read -p "Please list your current mood (1-10 (best-worst)): " mood
        read -p "Please list your current fatigue (1-10 (least-most)): " fatigue
        read -p "Please list your current heartrate (bpm): " bpm
        printf '%s,%s,%s,%s,%s,%s,%s\n' "$1" "$2" "$3" "$productivity" "$fatigue" "$mood" "$bpm" >> "../logs/log.csv"
}

start_time=0
while read -u3 line; do
        echo $line
        date=$(date +"%s")
        if [[ $line == "Playing" ]]; then
                start_time=$date
        elif [[ $line == "Paused" ]] && [[ $start_time != 0 ]]; then
                difference="$(($date-$start_time))"
                create_row $start_time $date $difference
        fi
done 3< <(playerctl --follow status -p spotify)
