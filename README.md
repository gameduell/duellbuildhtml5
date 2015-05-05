## Description
 
Use this plugin to build for the HTML5 platform.
 
## Arguments:
 
  #### -browser
  Use this argument to make the app run on browser. The default is slimerjs.
  #### slimerjs
  Use this argument to make the app run on slimerjs which is a standalone tiny firefox. This has the benefit of not opening a new tab on your browser.
  #### -debug
  >*Use this argument if you want to build in debug.

## Project Configuration Documentation:
 #### <style>
 Use this to add custom style to the application. E.g.: <style bgColor="#badda55" />.
 #### <head-section>
 Use this to add custom data to the application html header. E.g.: <header-section> <meta charset="UTF-8"> </header-section>. It supports multiple tags.
 #### <body-section>
 
 Use this to add custom data inside the body tag in the application html page. E.g.: <body-section> <p>lorem ipsum</p> </body-section>. It supports multiple tags.
 #### <js-source>
 Use this to include external javascript code.E.g.: <js-source path="libs/mylib.js" applyTemplate="true|false" renamePackage="oldPackageName->newPackageName"/>. the applyTemplate and renamePackages attributes are optional.
 #### <win-size>
 Use this to specifie the canvas dimension(width x height) in the application html page. E.g.: <win-size width="1024" height="768" />.

#### <prehead-section>
Use this to add custom data before the head tag in the application html page. E.g.: <preheader-section> <doctype html> </preheader-section>. It supports multiple tags.