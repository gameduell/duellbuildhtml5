/**
 * @autor kgar
 * @date 01.09.2014.
 * @company Gameduell GmbH
 */
package duell.build.plugin.platform;

typedef PlatformConfigurationData = {
PLATFORM_NAME : String,
WIDTH : String,
HEIGHT : String,
BGCOLOR : String
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
	public static function addParsingDefines(str : String):Void
	{
	    _parsingDefines.push(str);
	}
	public static function initConfig() : Void
	{
	    _configuration = 
	    {
			PLATFORM_NAME : "html5",
			WIDTH : "800",
			HEIGHT : "600",
			BGCOLOR : "#FFF"//same as #FFFFFF
	    };
	}

}