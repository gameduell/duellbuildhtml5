## Description
 
Use this plugin to build for the HTML5 platform.
## Usage:
`$ duell build html5 -browser -debug`
## Arguments:
* `-browser` &ndash; fixes wrong brew commands, for example `brew docto/brew doctor`
* `-slimerjs` &ndash; Use this argument to make the app run on slimerjs which is a standalone tiny firefox. This has the benefit of not opening a new tab on your browser.
* `-debug` &ndash; Use this argument if you want to build in debug.

## Project Configuration Documentation:
* `<style>` &ndash; Use this to add custom style to the application. E.g.: `<style bgColor="#badda55" />`.
* `<head-section>` &ndash; Use this to add custom data to the application html header. E.g.: 
`<header-sectionrt; <meta charset="UTF-8">`. It supports multiple tags.
* `<body-section>` &ndash; Use this to add custom data to the application html header. E.g.: 
`<body-section> <p>lorem ipsum</p> </body-sectionrt>`. It supports multiple tags.
* `<js-source>` &ndash; Use this to include external javascript code.E.g.:
`<js-source path="libs/mylib.js" applyTemplate="true|false" renamePackage="oldPackageName-newPackageName"/>`. It supports multiple tags. The applyTemplate and renamePackages attributes are optional.
* `<win-size>` &ndash; Use this to specifie the canvas dimension(width x height) in the application html page. E.g.:
`<win-size width="1024" height="768"/>`. It supports multiple tags. The applyTemplate and renamePackages attributes are optional.
* `<prehead-section>` &ndash; 	Use this to add custom data before the head tag in the application html page. E.g.:
`<preheader-section> <doctype html> </preheader-section>`. It supports multiple tags. The applyTemplate and renamePackages attributes are optional. It supports multiple tags.
