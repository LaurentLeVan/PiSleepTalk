#!/bin/bash

# 
# This file is part of PiSleepTalk.
# Learn more at: https://github.com/blaues0cke/PiSleepTalk
# 
# Author:  Thomas Kekeisen <pisleeptalk@tk.ca.kekeisen.it>
# License: This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License.
#          To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/4.0/.
#

. /usr/sleeptalk/config/config.cfg

. /usr/sleeptalk/bash/tool/create-record-to-render.sh

echo "Processing records to crop"
echo ""

script_name=`basename "$0"`
lock_file_name="/var/lock/.${script_name}.${lock_file_format}"

if [ ! -d "${lock_file_name}" ]; then
	mkdir "$lock_file_name"

	file_count=0

	dir_list=$(ls ${audio_file_path_crop}/*.${default_audio_format} 2>/dev/null)
	for audio_file_path in $dir_list
	do
		if [ -f $audio_file_path ]; then
			audio_file_name=$(basename $audio_file_path)

		 	echo "... cropping file: ${audio_file_path}"

			seconds_start=$(echo $audio_file_name | sed -r -n 's#^start-([0-9.]+)-stop-([0-9.]+).*?\.'"${default_audio_format}"'$#\1#p')
		 	seconds_stop=$(echo $audio_file_name | sed -r -n 's#^start-([0-9.]+)-stop-([0-9.]+).*?\.'"${default_audio_format}"'$#\2#p')
		 	# Thanks to
		 	# * http://unix.stackexchange.com/questions/184360/how-can-subtract-2-floats-which-have-been-extracted-from-2-other-files-with-bash
		 	duration=$(echo "${seconds_stop} ${seconds_start}" | awk '{print $1-$2}')
		 	
			echo "... seconds start: ${seconds_start}"
			echo "... seconds stop: ${seconds_stop}"
			echo "... duration: ${duration}"

		 	audio_file_name=$(basename $audio_file_path)
		 	final_audio_path="${temp_file_path}/CR-${audio_file_name}"

		 	# Thanks to
		 	# * http://stackoverflow.com/questions/12562023/trim-audio-files-with-sox-in-milliseconds
		 	# * http://stackoverflow.com/questions/9667081/how-do-you-trim-the-audio-files-end-using-sox
		 	sox $audio_file_path $final_audio_path trim "$seconds_start" "=${seconds_stop}" >>"${error_log_path}" 2>&1

			if [ -f $final_audio_path ]; then
		 		rm $audio_file_path

		 		create_record_to_render $final_audio_path
			else
				echo "... error while trimming audio, aborting"
			fi

		 	file_count=$((file_count + 1))

		 	echo ""
		fi
	done

	if [ -n "$file_count" ]; then
	    echo "Done cropping audio, processed files:"
	    echo "... processed files: ${file_count}"
	else
		echo "Done cropping audio, no files found";
	fi
  	
  	if [ -d "${lock_file_name}" ]; then
  		rmdir "${lock_file_name}"
	fi
else
	echo "... done - existing lock file found"
fi