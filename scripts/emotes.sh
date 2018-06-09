#!/bin/bash
set -o errexit
set -o nounset

#fonctions
mysort() {
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
	count_words="${*:3}"
	if [ "${1}" = "numeric" ]
	then
		emotes_while=$(sort ${sortArgs} <<< "${count_words}" | awk '{ print $2 ":" $1 }')
	else
		emotes_while=$(awk '{ print $2 ":" $1 }' <<< "${count_words}" | sort ${sortArgs})
	fi
	echo "${emotes_while}"
}

file_users_separate_with_rafter() {
	sed -E 's/[[:space:]]/\n/gm; s/^/</gm; s/$/>/gm' < "${1}" > "${LIST_USER_FILE}"
}

filterlist() {
	whitelist="${1}"		#$1= true pour whitelist, false pour blacklist
	file_users_separate_with_rafter "${2}"
	grep_args="--word-regexp --file=${LIST_USER_FILE}"
	if [ "${whitelist}" = "false" ]
	then
		grep_args="--invert-match ${grep_args}"
	fi
	list_greped=$(grep $grep_args <<< "${@:3}")
	echo "${list_greped}"
}

DIR_LOGS="/var/lib/znc/users/trobiun/networks/twitch/moddata/log/#mygowd"			#le répertoire des fichiers de log
EMOTES_FILE="emotes.list"									#le fichier contenant les emotes à compter
LIST_USER_FILE="users_list.txt"									#le fichier pour whitelist et blacklist les  utilisateurs

#grep en premier les utilisateurs puis calculer  les emotes_greped ?
#ou enlever le -o dans emotes_greped puis grep les utilisateurs puis
#regrep les emotes ?
#à tester la rapidité, la 1ère est peut-être mieux
#declare -a blacklist_users=()
#declare -a whitelist_users=()

#blacklist_users_file="blacklist_users.txt"
#whitelist_users_file="whitelist_users.txt"

#arguments provenant de l'appel du script
sortby="${1}"
order="${2}"
blacklist_users_file="${3}"
whitelist_users_file="${4}"

count_days=$(find "${DIR_LOGS}" -type f | wc --lines)
lines_conv=$(find "${DIR_LOGS}" -type f -exec cat  '{}' ';' | grep --invert-match "\*\*\*")
count_lines_conv=$(wc --lines <<< "${lines_conv}")

lines_with_emotes=$(grep --no-filename --word-regexp --ignore-case --recursive --file="${EMOTES_FILE}" "${DIR_LOGS}")

lines="${lines_with_emotes}"
if [ -s "${blacklist_users_file}" ]
then
	lines=$(filterlist "false" "${blacklist_users_file}" "${lines}")
fi
if [ -s "${whitelist_users_file}" ]
then
	lines=$(filterlist "true" "${whitelist_users_file}" "${lines}")
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

percent_lines_with_emotes=$(bc --mathlib <<< "scale=7; (${count_lines_with_emotes} * 100) / ${count_lines_conv}")
emotes_greped=$(echo "${lines}" | grep --only-matching --no-filename --word-regexp --ignore-case  --file="${EMOTES_FILE}")

count_total_emotes=$(echo "${emotes_greped}" | wc --lines)							#compte le nombre total d'emotes utilisées
use_per_emote=$(sort --ignore-case <<< "${emotes_greped}" | uniq --count --ignore-case | sed --expression='s/^[[:space:]]*//')
average_emotes_per_line=$(bc --mathlib <<< "scale=7; ${count_total_emotes} / ${count_lines_with_emotes}")

#count_words=$(sort -f <<< "${emotes_greped}" | uniq --count --ignore-case | sed --expression='s/^[[:space:]]*//')	#compte le nombre d'utilisation pour toutes les emotes
#total_lines=$(grep --word-regexp --ignore-case --recursive --file="${EMOTES_FILE}" "${DIR_LOGS}" | wc --lines)				#compte le nombre total de lignes contenant une emote

echo "Statistiques faites sur ${count_days} jours et ${count_lines_conv} lignes :"
echo "Tri par ${sort_message} :"
echo "Nombre de lignes contenant au moins une emote : ${count_lines_with_emotes}"
echo "Pourcentage de lignes contenant au moins une emote : ${percent_lines_with_emotes}"
echo "Moyenne d'emotes par ligne contenant au moins une emote : ${average_emotes_per_line}"

emotes_while=$(mysort "${sortby}" "${order}" "${use_per_emote[@]}")  #cat "${EMOTES_FILE}")								#définit les emotes qui seront parcourues par les emotes dans le fichier qui liste les emotes

while read -r emote;										#parcourt le fichier EMOTES_FILE
do
	words_for_emote=0; count_lines_for_emote=0; emotes_per_total=0; emote_per_line=0;
	emote=$(cut --delimiter=":" --fields=1 <<< "${emote}")
	words_for_emote=$(grep --ignore-case --word-regexp "${emote}" <<< "${use_per_emote}" | cut --delimiter=" " --fields=1)			#récupère le nombre d'utilisation (en mots) de l'emote actuelle
	count_lines_for_emote=$(echo "${lines}" | grep --word-regexp --count --ignore-case "$emote")				#compte le nombre de lignes dans lesquelles l'emote apparaît
	echo "${emote} :"										#affiche l'emote
	echo "	emotes		= ${words_for_emote}	/ ${count_total_emotes}"					#affiche le nombre d'utilisation (en mots) de l'emote et le total
	if [ "${words_for_emote}"  ]
	then
		emotes_per_total=$(bc --mathlib <<< "scale=7; (${words_for_emote} * 100) / ${count_total_emotes}")			#calcule le poucentage d'utilisation (en mots) de l'emote
	fi
	echo "	emote/total	= ${emotes_per_total} %"						#affiche le pourcentage d'utilisation (en mots) de l'emote
	echo "	lignes		= ${count_lines_for_emote}	/ ${count_lines_with_emotes}"					#affiche le nombre de lignes contenant l'emote actuelle et le total de lignes contenant une emote
	if [ "${words_for_emote}" ]
	then
		emote_per_line=$(bc --mathlib <<< "scale=7; ${words_for_emote} / ${count_lines_for_emote}")				#calcule le nombre d'emote utilisée par ligne
	fi
	echo "	emotes/ligne	= ${emote_per_line}"						#affiche le nombre d'emote utilisée par ligne
done <<< "${emotes_while}"
if [ -f "${LIST_USER_FILE}" ]
then
	rm -f "${LIST_USER_FILE}"
fi
