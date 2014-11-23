#!/bin/bash
# this script will compile the vis library into a tw-plugin

modulePath="$:/plugins/felixhayashi/vis"  # module path
cssSrc="vis/vis.css"                      # path to the css within the source dir
distPath="../dist/felixhayashi/vis/"      # Path to dist-files
cssOut="$distPath/files/vis.css"          # outpath of the css in the dist dir
cd vis; images=(img/*/*); cd ..           # array of images used by vis relative to css dir

buildTWFilesFile() {
  
# print tiddlywiki.files preamble
printf '{
  "tiddlers": [' > "$distPath/files/tiddlywiki.files"

imagesLength=${#images[*]}
for((i = 0; i < $imagesLength; i++)); do

  # update tiddlywiki.files
  printf '
      {
        "file": "%s", "fields": {
          "title": "%s/%s",
          "type": "image/png"
      }},' "${images[i]}" "$modulePath" "${images[i]}" >> "$distPath/files/tiddlywiki.files"
      
done;

# finish file
printf '
    {
      "file": "vis.css", "fields": {
        "title": "%s/vis.css",
        "type": "text/vnd.tiddlywiki",
        "tags": [ "$:/tags/Stylesheet" ]
    }},
    {
      "file": "vis.js", "fields": {
        "title": "%s/vis.js",
        "type": "application/javascript",
        "module-type": "library"
      }}
  ]
}' "$modulePath" "$modulePath" >> "$distPath/files/tiddlywiki.files" # can't access arguments by index in gnu's printf

}

buildStyles() {
  
  # replace urls
  gawk -v mpath="$modulePath" '
    {
      pos = match($0, /(.*)[\"'\''](.*)[\"'\''](.*)/, arr);
      if(pos != 0) print arr[1] "<<datauri \"" mpath "/" arr[2] "\" >>" arr[3]
      else print
    }' $cssSrc > $cssOut
    
  # uglify; redirect stdin so its not closed by npm command
  body=$(uglifycss $cssOut < /dev/null)
  
  # insert the macro function at the top
  echo \
'\define datauri(title)
<$macrocall $name="makedatauri" type={{$title$!!type}} text={{$title$}}/>
\end'$'\n'$'\n'$body > $cssOut
    
}

copyMedia() {
  # copy images
  cp -r ./vis/img/ "$distPath/files/img"
}

buildScripts() {
  cp ./vis/vis.min.js "$distPath/files/vis.js"
  # append empty line
  # fix for https://github.com/felixhayashi/tw-vis/issues/2
  echo "" >> "$distPath/files/vis.js"
}

createStructure() {
  [ -d "$distPath" ] && rm -rf "$distPath"
  mkdir -p "$distPath/files"
  cp ./plugin.info "$distPath"
}

#execute

createStructure
copyMedia
buildStyles
buildScripts
buildTWFilesFile

