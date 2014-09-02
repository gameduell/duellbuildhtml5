var page = require('webpage').create();
page.open('http://localhost:3000', function() 
{
});

page.onConsoleMessage = function(message, line, file){
    console.log("[DEBUG] "+file+" : "+line+" : "+message);
}