/*** TO AVOID STRANGE LIB ERRORS FROM BUBBLING UP *****************/

if($tw.boot.tasks.trapErrors) {

  var defaultHandler = window.onerror;
  window.onerror = function(errorMsg, url, lineNumber) {
    
    if(errorMsg.indexOf("NS_ERROR_NOT_AVAILABLE") !== -1
       && url == "$:/plugins/felixhayashi/vis/vis.js") {
         
      var text = "Strange firefox related vis.js error (see #125)";
      console.error(text, arguments);
      
    } else if(errorMsg.indexOf("Permission denied to access property") !== -1) {
      
      var text = "Strange firefox related vis.js error (see #163)";
      console.error(text, arguments);
      
    } else if(defaultHandler) {
      
      defaultHandler.apply(this, arguments);
      
    }
    
  }
  
}

/******************************************************************/