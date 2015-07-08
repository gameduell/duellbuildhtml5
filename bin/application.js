var page = require('webpage').create();
var width = parseInt(phantom.args[0]);
var height = parseInt(phantom.args[1]);

width = isNaN(width) ? 1024 : width;
height = isNaN(height) ? 768 : height;

page.open('http://localhost:3000', function()
{
});
page.viewportSize = { width:width, height:height };

page.onConsoleMessage = function(message, line, file){
    console.log(file+":"+line+": "+message);
}
