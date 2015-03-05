/**
 * @autor kgar
 * @date 01.09.2014.
 * @company Gameduell GmbH
 */
package duell.build.plugin.platform;
typedef ScriptItem = {
	originalPath : String,
	destination : String, 
	applyTemplate : Bool,
	oldPackage: String,
	newPackage: String
}

typedef PlatformConfigurationData = {
PLATFORM_NAME : String,
WIDTH : String,
HEIGHT : String,
BGCOLOR : String,
HEAD_SECTIONS : Array<String>,
BODY_SECTIONS : Array<String>,
JS_SOURCES : Array<ScriptItem>,
PREHEAD_SECTIONS : Array<String>
}

class PlatformConfiguration
{
	public static var _configuration : PlatformConfigurationData = null;
	public static var _parsingDefines : Array<String> = ["html5"];
	public function new()
	{}

	public static function getData() : PlatformConfigurationData
	{
	    if(_configuration == null)
	    	initConfig();

	    return _configuration;
	}
	public static function getConfigParsingDefines() : Array<String>
	{
	    return _parsingDefines;
	}
	public static function initConfig() : Void
	{
	    _configuration = 
	    {
			PLATFORM_NAME : "html5",
			WIDTH : "800",
			HEIGHT : "600",
			BGCOLOR : "#FFF",//same as #FFFFFF
			HEAD_SECTIONS:[],
			BODY_SECTIONS:[],
			JS_SOURCES : [],
			PREHEAD_SECTIONS : []
	    };
	}
	
}