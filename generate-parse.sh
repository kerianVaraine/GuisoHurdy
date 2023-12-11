#!/bin/bash

set -euo pipefail
TMP_FILE=$(mktemp)
OUT_FILE=parse-input-events.h
INPUT_EVENT_CODES=/usr/include/linux/input-event-codes.h
# inspired from https://stackoverflow.com/a/2554421/2958741
echo generating parse.h
> $OUT_FILE
echo -en "// DO NOT EDIT: File generated automatically by $(basename $0) from $INPUT_EVENT_CODES\n" >> $OUT_FILE
echo -en "struct parse_key {\n\tunsigned int code;\n\tchar ascii;\n};\n" >> $OUT_FILE
echo -en "struct parse_key keynames[] = {\n" >> $OUT_FILE

# only letters and numbers and the values listed below are actually parsed. Add
# more pairs of values here while looking at key names in $INPUT_EVENT_CODES
pairs=( \
	COMMA , \
	DOT . \
	SLASH / \
	SPACE " " \
	ENTER "\\\\n" \
	SEMICOLON ";" \
	APOSTROPHE "\\\\'" \
	EQUAL "=" \
	MINUS "-" \
	PLUS "+" \
	ASTERISK "*" \
	TAB "\\\\t" \
	BACKSPACE "\\\\b" \
	ESC "\\\\e" \
)

> $TMP_FILE
grep "#define KEY_*[A-Z0-9]\s\|#define KEY_*KP[0-9]\s"  $INPUT_EVENT_CODES|\
	sed "s@#define KEY_\(KP\)*\([^\s\t]\+\)\s\+\([0-9]\+\)@\3, '\2' }, // KEY_\1\2@" \
	>> $TMP_FILE

for (( n=0; n < ${#pairs[@]}; n=$((n+2)) )); do
	name=${pairs[$n]}
	ascii=${pairs[$((n+1))]}
	grep "#define KEY_KP$name\s\|#define KEY_$name\s" $INPUT_EVENT_CODES |\
		sed "s@#define KEY_\(KP\)*$name\s\+\([0-9]\+\)@\2, '$ascii' }, // KEY_\1$name@" \
		>> $TMP_FILE
done

cat $TMP_FILE |\
	sort -n |\
	sed "s/\(^.*$\)/{\1/" \
	>> $OUT_FILE
echo -en "};\n" \
       >> $OUT_FILE
echo -en "#define keynames_size (sizeof(keynames)/sizeof(struct parse_key))\n" \
       >> $OUT_FILE
rm $TMP_FILE
