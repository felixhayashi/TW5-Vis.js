#!/bin/bash
# this script will compile the vis library into a tw-plugin

#####################################################################
# Script Configuration
#####################################################################

pluginPrefix="$:/plugins/felixhayashi/vis"  # prefix for all tiddlers of this plugin
distPath="dist/felixhayashi/vis/"           # output path
visSrcPath="src/vis/dist/"                  # input path
imgSrcPath="src/"                           # customised vis-images path
images=($(cd "$imgSrcPath"; echo img/*/*;)) # array of customised vis-images

#####################################################################
# Program
#####################################################################

#====================================================================
printf "Fetch upstream resources...\n"
#====================================================================

git submodule update --init --recursive

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
    base64 -w 0 $imgSrcPath/${images[i]}
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
\*/

/*** TO AVOID STRANGE LIB ERRORS FROM BUBBLING UP *****************/

if($tw.boot.tasks.trapErrors) {

  var defaultHandler = window.onerror;
  window.onerror = function(errorMsg, url, lineNumber) {
    if(errorMsg.indexOf("NS_ERROR_NOT_AVAILABLE") !== -1
       && url == "$:/plugins/felixhayashi/vis/vis.js") {
      console.error("Strange firefox related vis.js error (see #125)",
                    arguments);
    } else if(errorMsg.indexOf("Permission denied to access property") !== -1) {
      console.error("Strange firefox related vis.js error (see #163)",
                    arguments);
    } else if(defaultHandler) {
      defaultHandler.apply(this, arguments);
    }
  }
}

/******************************************************************/
'

# uglifyied content; redirect stdin so its not closed by npm command
body=$(uglifyjs $visSrcPath/vis.js --comments < /dev/null)
#body=$(cat $visSrcPath/vis.js) # uncomment for no compression

printf "%s\n\n%s\n" "$header" "$body" > $distPath/vis.js

#====================================================================
printf "copy other stuff...\n"
#====================================================================

cp src/plugin.info $distPath/plugin.info
cp src/tiddlers/* $distPath/tiddlers/

exit
