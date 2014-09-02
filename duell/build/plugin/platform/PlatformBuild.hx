/**
 * @autor kgar
 * @date 01.09.2014.
 * @company Gameduell GmbH
 */
  package duell.build.plugin.platform;

 import duell.build.objects.Configuration;
 import duell.build.objects.DuellProjectXML;
 import duell.helpers.PathHelper;
 import duell.helpers.LogHelper;
 import duell.helpers.FileHelper;
 import duell.helpers.ProcessHelper;
 import duell.objects.DuellLib;
 import duell.objects.Haxelib;
 import duell.helpers.TemplateHelper;

 class PlatformBuild
 {
 	public var requiredSetups = [];

 	private static var isDebug : Bool = false;

 	public var targetDirectory : String;
 	public var duellBuildHtml5Path : String;
 	public var projectDirectory : String;
 	
 	public function new()
 	{
 		checkArguments();
 	}
	public static function checkArguments():Void
 	{
		for (arg in Sys.args())
		{
			if (arg == "-debug")
			{
				isDebug = true;
			}		
		}

 	}

 	public function parse() : Void
 	{
 	    parseProject();
 	}
 	public function parseProject() : Void
 	{
 	    var projectXML = DuellProjectXML.getConfig();
		projectXML.parse();
 	}
 	public function prepareBuild() : Void
 	{
 	    targetDirectory = Configuration.getData().OUTPUT+"/" ;
 	    projectDirectory = targetDirectory+"/" ;
 	    duellBuildHtml5Path = DuellLib.getDuellLib("duellbuildhtml5").getPath();
		
		convertDuellAndHaxelibsIntoHaxeCompilationFlags();
 	    prepareHtml5Build();
 	    convertParsingDefinesToCompilationDefines();
 	}
 	private function convertDuellAndHaxelibsIntoHaxeCompilationFlags()
	{
		for (haxelib in Configuration.getData().DEPENDENCIES.HAXELIBS)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp");
			Configuration.getData().HAXE_COMPILE_ARGS.push(Haxelib.getHaxelib(haxelib.name, haxelib.version).getPath());
		}

		for (duelllib in Configuration.getData().DEPENDENCIES.DUELLLIBS)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp");
			Configuration.getData().HAXE_COMPILE_ARGS.push(DuellLib.getDuellLib(duelllib.name, duelllib.version).getPath());
		}

		for (path in Configuration.getData().SOURCES)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp");
			Configuration.getData().HAXE_COMPILE_ARGS.push(path);
		}
	}
 	public function build() : Void
 	{
		LogHelper.info("", "" + Configuration.getData());
		LogHelper.info("", "" + Configuration.getData().LIBRARY.GRAPHICS);
		ProcessHelper.runCommand(targetDirectory+"html5/hxml/","haxe",["Build.hxml"]);
 	}

 	public function run() : Void
 	{
 	    runApp();/// run app in the browser
 	}
 	public function runApp() : Void
 	{
 		//python "$HTML5_DIR"/slimerjs-0.9.1/slimerjs.py "$HTML5_DIR"/test.js --debug=true
 	    ProcessHelper.openURL("http://localhost:8080");
 	    //var result : Int = ProcessHelper.openURL(targetDirectory+"html5/web/index.html");
		var result : Int = ProcessHelper.runCommand(targetDirectory+"html5/web","python",["-m","SimpleHTTPServer","8080"]);
 	    if(result == 0)/// if the server is running successfully
 	    {
 	    	ProcessHelper.openURL("http://127.0.0.1:8080");
 	    	//LogHelper.error ("could not launch the application");
 	    }
 	    else
 	    {
 	    	LogHelper.info ("could not launch the application via server make sure python is installed");
 	    	ProcessHelper.openURL(targetDirectory+"html5/web/index.html");
 	    }
 	}
 	public function prepareHtml5Build() : Void
 	{
 		trace(Configuration.getData());
 	    createDirectoryAndCopyTemplate();
 	}
 	public function createDirectoryAndCopyTemplate() : Void
 	{
 		/// Create directories
 		PathHelper.mkdir(targetDirectory);

 	    ///copying template files 
 	    /// index.html, expressInstall.swf and swiftObject.js
 	    TemplateHelper.recursiveCopyTemplatedFiles(duellBuildHtml5Path + "template", projectDirectory, Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
 	}
	private function convertParsingDefinesToCompilationDefines()
	{	

		for (define in DuellProjectXML.getConfig().parsingConditions)
		{
			if (define == "debug" )
			{
				/// not allowed
				Configuration.getData().HAXE_COMPILE_ARGS.push("-debug");
				continue;
			} 

			Configuration.getData().HAXE_COMPILE_ARGS.push("-D");
			Configuration.getData().HAXE_COMPILE_ARGS.push(define);
		}
	} 	

 }