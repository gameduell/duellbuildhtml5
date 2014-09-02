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

 import sys.io.Process;

 class PlatformBuild
 {
 	public var requiredSetups = [];

 	private  var isDebug : Bool = false;
	private  var applicationWillRunAfterBuild : Bool = false;
	private var serverProcess : Process; 
 	public var targetDirectory : String;
 	public var duellBuildHtml5Path : String;
 	public var projectDirectory : String;
 	
 	public function new()
 	{
 		checkArguments();
 	}
	public function checkArguments():Void
 	{
		for (arg in Sys.args())
		{
			if (arg == "-debug")
			{
				isDebug = true;
			}
			if(arg == "-run")
			{
				applicationWillRunAfterBuild = true;
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

 	    // if(applicationWillRunAfterBuild == true)
 	    // {
 	    // 	prepareAndRunHTTPServer();
 	    // }
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
		var result : Int = prepareAndRunHTTPServer();
		Sys.putEnv("SLIMERJSLAUNCHER", duellBuildHtml5Path+"bin/slimerjs-0.9.1/xulrunner/xulrunner");
		ProcessHelper.runCommand(duellBuildHtml5Path+"bin/slimerjs-0.9.1","python",["slimerjs.py","../test.js"]);

 	}
 	public function prepareAndRunHTTPServer() : Int
 	{
 		var args:Array<String> = [duellBuildHtml5Path+"bin/node/http-server/http-server",targetDirectory+"html5/web","-p", "3000", "-c-1"];
 	    serverProcess = new Process(duellBuildHtml5Path+"/bin/node/node-mac",args);
 	    //var result : Int = serverProcess.exitCode();
 	    //return result;
 	    return 0;
 	}
 	public function prepareHtml5Build() : Void
 	{
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
				Configuration.getData().HAXE_COMPILE_ARGS.push("-debug");
				continue;
			} 

			Configuration.getData().HAXE_COMPILE_ARGS.push("-D");
			Configuration.getData().HAXE_COMPILE_ARGS.push(define);
		}
	} 	

 }