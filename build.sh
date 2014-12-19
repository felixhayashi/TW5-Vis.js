#!/bin/bash
# this script will compile the vis library into a tw-plugin

#####################################################################
# Script Configuration
#####################################################################

pluginPrefix="$:/plugins/felixhayashi/vis" # prefix for all tiddlers of this plugin
distPath="dist/felixhayashi/vis/"          # output path
visSrcPath="src/vis/"                      # input path
images=($(cd $visSrcPath; echo img/*/*;))  # array of vis-images relative to css dir

#####################################################################
# Program
#####################################################################

#====================================================================
printf "Perform cleanup...\n"
#====================================================================

# clean up
[ -d $distPath ] && rm -rf $distPath

# create paths
mkdir -p $distPath
mkdir $distPath/tiddlers

#====================================================================
printf "compile and copy images...\n"
#====================================================================

imagesLength=${#images[*]}
for((i = 0; i < $imagesLength; i++)); do
  
  # replace shash with underscore
  imgName="${images[i]//\//_}.tid";

  # inject meta and content and place it into dist folder
  {
    printf "title: %s\ntype:%s\n\n" "${pluginPrefix}/${images[i]}" "image/png"
    base64 -w 0 $visSrcPath/${images[i]}
  } >> $distPath/tiddlers/$imgName

done

#====================================================================
printf "minify and copy styles...\n"
#====================================================================

# replace urls and move file to dist
gawk -v mpath="$pluginPrefix" '
  {
    pos = match($0, /(.*)[\"'\''](.*)[\"'\''](.*)/, arr);
    if(pos != 0) print arr[1] "<<datauri \"" mpath "/" arr[2] "\" >>" arr[3]
    else print
  }' $visSrcPath/vis.css > $distPath/tiddlers/vis.css.tid
    
# header with macro
header=\
'title: '${pluginPrefix}/vis.css'
type: text/vnd.tiddlywiki
tags: $:/tags/Stylesheet'

macro=\
'\define datauri(title)
<$macrocall $name="makedatauri" type={{$title$!!type}} text={{$title$}}/>
\end'

# uglifyied content; redirect stdin so its not closed by npm command
body=$(uglifycss $distPath/tiddlers/vis.css.tid < /dev/null)

printf "%s\n\n%s\n\n%s" "$header" "$macro" "$body" > $distPath/tiddlers/vis.css.tid

#====================================================================
printf "uglify and copy scripts...\n"
#====================================================================

# header with macro
header=\
'/*\
title: '${pluginPrefix}/vis.js'
type: application/javascript
module-type: library

@preserve
\*/'

# uglifyied content; redirect stdin so its not closed by npm command
body=$(uglifyjs $visSrcPath/vis.js < /dev/null)
body=$(cat $visSrcPath/vis.js)

printf "%s\n\n%s\n" "$header" "$body" > $distPath/vis.js

#====================================================================
printf "copy other stuff...\n"
#====================================================================

cp src/plugin.info $distPath/plugin.info
cp src/tiddlers/* $distPath/tiddlers/

exit
