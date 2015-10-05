#!/bin/bash
# Written by Alexander Löhner
# The Linux Counter Project

if [ "${1}" = "" ]; then
echo "Argument 1 has to be the start position (linenumber) to begin the cut"
echo "This line will be included in your resulting file as the first line"
echo "You may use \"grep -n\" to get the linenumber"
exit 1
fi

if [ "${2}" = "" ]; then
echo "Argument 2 has to be the end position (linenumber) to end the cut"
echo "This line will be included in your resulting file as the last line"
echo "You may use \"grep -n\" to get the linenumber"
exit 1
fi

if [ "${3}" = "" ]; then
echo "Argument 3 has to be the filename of the original file to cut from"
exit 1
fi

if [ "${4}" = "" ]; then
echo "Argument 4 has to be the filename of the new, resulting file"
exit 1
fi

begin=$(( ${1} - 1 ))
head -n ${2} ${3} > ${3}.tmp
lines=$(( ${2} - ${begin} ))
tail -n ${lines} ${3}.tmp > ${4}
rm -f ${3}.tmp
echo "Done."
exit 0
