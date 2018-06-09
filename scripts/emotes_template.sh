#!/bin/bash
set -o errexit
set -o nounset

#fonctions
mysort () {
	sortArgs="--ignore-case"
	if [ "${1}" = "numeric" ]
	then
		sortArgs="--numeric-sort"
	else
		sortArgs="--dictionary-order ${sortArgs}"
	fi
	if [ "$order" = "dsc" ]
	then
		sortArgs="--reverse ${sortArgs}"
	fi
	count_words="${@:3}"
	if [ "${1}" = "numeric" ]
	then
		emotes_while=$(sort ${sortArgs} <<< "${count_words}" | awk '{ print $2 ":" $1 }')
	else
		emotes_while=$(awk '{ print $2 ":" $1 }' <<< "${count_words}" | sort ${sortArgs})
	fi
	echo "${emotes_while}"
}

users_array_to_file() {
	sed -E 's/[[:space:]]/\n/gm; s/^/</gm; s/$/>/gm' <<< "$@" > "${LIST_USER_FILE}";
}

filterlist() {
	whitelist="$1"
	grep_args="--word-regexp --file=${LIST_USER_FILE}"
	if [ "${whitelist}" = "false" ]
	then
		grep_args="--invert-match ${grep_args}"
	fi
	list_greped=$(grep $grep_args <<< "${@:2}")
	echo "${list_greped}"
}

DIR_LOGS="/var/lib/znc/users/trobiun/networks/twitch/moddata/log/#mygowd"			#le répertoire des fichiers de log
EMOTES_FILE="emotes.list"									#le fichier contenant les emotes à compter
#LIST_USER_FILE="users_list.txt"
#arguments provenant de l'appel du script php
sortby="${@:3:1}"
order="${@:4:1}"
blacklist_users_file="${@:5:1}"
whitelist_users_file="${@:6:1}"
LIST_USER_FILE="${@:7:1}"

count_days=$(find "${DIR_LOGS}" -type f | wc --lines)
lines_conv=$(find "${DIR_LOGS}" -type f -exec cat '{}' ';' | grep --invert-match "\*\*\*")
count_lines_conv=$(wc --lines <<< "${lines_conv}")

lines_with_emotes=$(grep --no-filename --word-regexp --ignore-case --recursive --file="${EMOTES_FILE}" "${DIR_LOGS}")

lines="${lines_with_emotes}"
if [ -s "${blacklist_users_file}" ]
then
	LIST_USER_FILE="${blacklist_users_file}"
	lines=$(filterlist "false" "${lines}")
fi
if [ -s "${whitelist_users_file}" ]
then
	LIST_USER_FILE="${whitelist_users_file}"
	lines=$(filterlist "true" "${lines}")
fi
if [ "${order}" = "asc" ]
then
	orderMessage="croissant"
else
	orderMessage="décroissant"
fi
if [ "${sortby}" = "numeric" ]
then
	sort_message="utilisation ${orderMessage}"
else
	sort_message="ordre alphabétique ${orderMessage}"
fi
count_lines_with_emotes=$(echo "${lines}" | wc --lines)

percent_lines_with_emotes=$(bc --mathlib <<< "scale=7;(${count_lines_with_emotes} / ${count_lines_conv}) * 100")
emotes_greped=$(echo "${lines}" | grep --only-matching --no-filename --word-regexp --ignore-case --file="${EMOTES_FILE}")

count_total_emotes=$(echo "${emotes_greped}" | wc --lines)
use_per_emote=$(sort --ignore-case <<< "${emotes_greped}" | uniq --count --ignore-case | sed --expression='s/^[[:space:]]*//')	#compte le nombre d'utilisation pour toutes les emotes
average_emotes_per_line=$(bc --mathlib <<< "scale=7; ${count_total_emotes} / ${count_lines_with_emotes}")

#percent_lines_with_emotes=$(bc --mathlib <<< "scale=7; (${count_lines_with_emotes} * 100) / ${count_lines_conv}")

#emotes_greped=$(grep --only-matching --no-filename --word-regexp --ignore-case --file="${EMOTES_FILE}" <<< "${lines_with_emotes}")



emotes_while=$(mysort "${sortby}" "${order}" "${use_per_emote[@]}")

#emotes_lines1=$(wc --lines <<< "${emotes_greped}")				#compte le nombre total de lignes contenant une emote
#emotes_lines=$(grep --word-regexp --ignore-case --recursive --file="${EMOTES_FILE}" "${DIR_LOGS}" | wc --lines)				#compte le nombre total de lignes contenant une emote
#plus compliqué et à peine plus lent
#emotes_lines3=$(grep --word-regexp --no-filename --ignore-case --recursive --file="${EMOTES_FILE}" "${DIR_LOGS}" --count)				#compte le nombre total de lignes contenant une emote
#emotes_lines_plus=$(tr '\n' '+' <<< "${emotes_lines3}")
#emotes_lines_sum=$(time bc --mathlib <<< "${emotes_lines_plus}0")  #$(sed --expression='s/[[:space:]]/\+/g'  <<< \"${emotes_lines3}\"))
#if [ "${order}" = "asc" ]
#then
#	orderMessage="croissant"
#else
#	orderMessage="décroissant"
#fi
#if [ "${sortby}" = "numeric" ]
#then
#	sort_message="utilisation ${orderMessage}"
#else
#	sort_message="ordre alphabétique ${orderMessage}"
#fi
i=1
while read -r emote;										#parcourt le fichier emotes_file
do
	words_for_emote[$i]=0; count_lines_for_emote[$i]=0; emotes_per_total[$i]=0; emotes_per_line[$i]=0;
	emotes[$i]=$(cut --delimiter=":" --fields=1 <<< "${emote}")
	words_for_emote[$i]=$(grep --ignore-case --word-regexp "${emotes[$i]}" <<< "${use_per_emote}" | cut --delimiter=" " --fields=1)			#récupère le nombre d'utilisation (en mots) de l'emote actuelle
	#count_lines_for_emote[$i]=$(grep --word-regexp --ignore-case --recursive "${emotes[$i]}" "${DIR_LOGS}" | wc --lines)				#compte le nombre de lignes dans lesquelles l'emote apparaît
	if [ "${words_for_emote[$i]}" ]
	then
		count_lines_for_emote[$i]=$(echo "${lines}" | grep --word-regexp --count --ignore-case "${emotes[$i]}")
	fi
	if [ "${words_for_emote[$i]}" ]
	then
		emotes_per_total[$i]=$(bc --mathlib <<< "scale=7; (${words_for_emote[$i]} * 100) / ${count_total_emotes}")	#calcule le poucentage d'utilisation (en mots) de l'emote
	fi
	words_per_line[$i]=$(bc --mathlib <<< "scale=7; ${words_for_emote[$i]} / ${count_lines_for_emote[$i]}")		#calcule le nombre d'emote utilisée par ligne
	((i++))
done <<< "${emotes_while}"
#if [ -f "${LIST_USER_FILE}" ]
#then
#	rm -f "${LIST_USER_FILE}"
#fi
