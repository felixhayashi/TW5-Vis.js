#!/bin/bash
# this script will compile the vis library into a tw-plugin

#####################################################################
# Script Configuration
#####################################################################

pluginPrefix="$:/plugins/felixhayashi/vis"  # prefix for all tiddlers of this plugin
distPath="dist/felixhayashi/vis/"           # output path
srcPath="src/"                              # plugin's src path
visSrcPath="${srcPath}/vis/dist/"           # vis module's dist path
imgSrcPath="${srcPath}/img/"                # customised vis-images path
images=($(cd "$imgSrcPath"; echo */*;))     # array of customised vis-images
compress=1                                  # set this to 0 to disable compression of css and js

#####################################################################
# Program
#####################################################################

#====================================================================
#~ printf "Fetch upstream resources...\n"
#====================================================================

#~ git submodule update --init --recursive

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
  
  twImgPrefix="img/${images[i]}"
  
  # replace shash with underscore
  imgName="${twImgPrefix//\//_}.tid";

  # inject meta and content and place it into dist folder
  {
    printf "title: %s\ntype:%s\n\n" "${pluginPrefix}/${twImgPrefix}" "image/png"
    base64 -w 0 "$imgSrcPath/${images[i]}"
  } >> "${distPath}/tiddlers/${imgName}"

done

#====================================================================
printf "replace urls...\n"
#====================================================================

{
  perl fixurls.pl "$visSrcPath/vis.css" "$pluginPrefix"
} > "$distPath/tiddlers/vis.css.tid"

#====================================================================
printf "minify and copy styles...\n"
#====================================================================
    
# header with macro
header=\
'title: '${pluginPrefix}/vis.css'
type: text/vnd.tiddlywiki
tags: $:/tags/Stylesheet

\rules except list'

macro=\
'\define datauri(title)
<$macrocall $name="makedatauri" type={{$title$!!type}} text={{$title$}}/>
\end'

# uglifyied content; redirect stdin so its not closed by npm command
body=$(uglifycss $distPath/tiddlers/vis.css.tid < /dev/null)

if [ $compress == 1 ]; then
  # uglifyied content; redirect stdin so its not closed by npm command
  body=$(uglifycss $distPath/tiddlers/vis.css.tid < /dev/null)
else
  # just use as is
  body=$(cat $distPath/tiddlers/vis.css.tid)
fi

printf "%s\n\n%s\n\n%s" "$header" "$macro" "$body" > "$distPath/tiddlers/vis.css.tid"

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

header="$header"$'\n'$'\n'"$(cat $srcPath/extra.js)"

if [ $compress == 1 ]; then
  # uglifyied content; redirect stdin so its not closed by npm command
  body=$(uglifyjs $visSrcPath/vis.js --comments < /dev/null)
else
  # just use as is
  body=$(cat $visSrcPath/vis.js)
fi

printf "%s\n\n%s\n" "$header" "$body" > $distPath/vis.js

#====================================================================
printf "copy other stuff...\n"
#====================================================================

cp src/plugin.info $distPath/plugin.info
cp src/tiddlers/* $distPath/tiddlers/

exit
