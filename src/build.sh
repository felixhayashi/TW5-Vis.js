#!/bin/bash
# this script will compile the vis library into a tw-plugin

distPath="../dist/felixhayashi/vis/"    # Path to dist-files
modulePath="$:/plugins/felixhayashi/vis"  # module path
cssSrc="vis/vis.css"                    # path to the css
cssOut="$distPath/files/vis.css"        # outpath of the css
cd vis; images=(img/*/*); cd ..         # array of images used by vis relative to css dir

createTWFilesFile() {
  
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
          "type": "text/css"
      }},' "${images[i]}" "$modulePath" "${images[i]}" >> "$distPath/files/tiddlywiki.files"
      
done;

# finish file
printf '
    {
      "file": "vis.css", "fields": {
        "title": "%s/vis.css",
        "type": "text/vnd.tiddlywiki",
        "tags": [ "$:/tags/stylesheet" ]
    }},
    {
      "file": "vis.js", "fields": {
        "title": "%s/vis.js",
        "type": "application/javascript",
        "module-type": "library"
      }}
  ]
}' "$modulePath" "$modulePath" >> "$distPath/files/tiddlywiki.files"

}

integrateCSS() {

  # insert macro at top
  echo \
'\define datauri(title)
<$macrocall $name="makedatauri" type={{$title$!!type}} text={{$title$}}/>
\end' $'\n' > $cssOut
  
  # replace urls
  gawk -v mpath="$modulePath" '
    {
      pos = match($0, /(.*)[\"'\''](.*)[\"'\''](.*)/, arr);
      if(pos != 0) print arr[1] "<<datauri \"" mpath arr[2] "\" >>" arr[3]
      else print
    }' $cssSrc >> $cssOut
    
}

createStructure() {
  mkdir -p "$distPath"
  cp ./plugin.info "$distPath"
  mkdir "$distPath/files/"
  cp -r ./vis/* "$distPath/files/"
}

#execute

rm -rf "$distPath"
createStructure
integrateCSS
createTWFilesFile