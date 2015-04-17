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
import duell.helpers.TestHelper;
import duell.helpers.CommandHelper;
import duell.objects.DuellLib;
import duell.objects.Haxelib;
import duell.helpers.TemplateHelper;
import duell.helpers.PlatformHelper;
import duell.helpers.ServerHelper;
import duell.objects.DuellProcess;
import duell.objects.Arguments;

import haxe.io.Path;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class PlatformBuild
{
 	public var requiredSetups = [];
	public var supportedHostPlatforms = [WINDOWS, MAC, LINUX];

	private static inline var TEST_RESULT_FILENAME = "test_result_html5.xml";
	private static inline var DEFAULT_SERVER_URL = "http://localhost:3000/";
	private static inline var DELAY_BETWEEN_PYTHON_LISTENER_AND_RUNNING_THE_APP = 2;

 	private var isDebug : Bool = false;
 	private var isTest : Bool = false;
	private var applicationWillRunAfterBuild : Bool = false;
	private var runInSlimerJS : Bool = false;
	private var runInBrowser : Bool = false;
	private var serverProcess : DuellProcess; 
	private var slimerProcess : DuellProcess; 
	private var fullTestResultPath : String;
 	private var targetDirectory : String;
 	private var duellBuildHtml5Path : String;
 	private var projectDirectory : String;
 	
 	public function new()
 	{
 		checkArguments();
 	}
	public function checkArguments():Void
 	{
		if (Arguments.isSet("-debug"))
		{
			isDebug = true;
		}
		
		if(!Arguments.isSet("-norun"))
		{
			applicationWillRunAfterBuild = true;
		}	
		
		if(Arguments.isSet("-slimerjs"))
		{
			runInSlimerJS = true;
		}	
		
		if(Arguments.isSet("-browser"))
		{
			runInBrowser = true;
		}	
		
		if (Arguments.isSet("-test"))
		{
			isTest = true;
			applicationWillRunAfterBuild = true;
			Configuration.addParsingDefine("test");
		}

		/// if nothing passed slimerjs is the default
 		if(!runInBrowser && !runInSlimerJS)
 			runInSlimerJS = true;

		if (isDebug)
		{
			Configuration.addParsingDefine("debug");
		}
		else
		{
			Configuration.addParsingDefine("release");
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
 		prepareVariables();
		
		convertDuellAndHaxelibsIntoHaxeCompilationFlags();
 	    convertParsingDefinesToCompilationDefines();
        forceHaxeJson();
		forceDeprecationWarnings();
 	    prepareHtml5Build();
 	    copyJSIncludesToLibFolder();

 	    if(applicationWillRunAfterBuild) 
 	    {
 	    	prepareAndRunHTTPServer();
 	    }
 	}

 	private function prepareVariables() : Void
 	{
 	    targetDirectory = Configuration.getData().OUTPUT;
 	    projectDirectory = Path.join([targetDirectory, "html5"]);
		fullTestResultPath = Path.join([Configuration.getData().OUTPUT, "test", TEST_RESULT_FILENAME]);
 	    duellBuildHtml5Path = DuellLib.getDuellLib("duellbuildhtml5").getPath();
 	}

 	private function convertDuellAndHaxelibsIntoHaxeCompilationFlags()
	{
		for (haxelib in Configuration.getData().DEPENDENCIES.HAXELIBS)
		{
            var version = haxelib.version;
            if (version.startsWith("ssh") || version.startsWith("http"))
                version = "git";
            Configuration.getData().HAXE_COMPILE_ARGS.push("-lib " + haxelib.name + (version != "" ? ":" + version : ""));
        }

		for (duelllib in Configuration.getData().DEPENDENCIES.DUELLLIBS)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + DuellLib.getDuellLib(duelllib.name, duelllib.version).getPath());
		}

		for (path in Configuration.getData().SOURCES)
		{
			Configuration.getData().HAXE_COMPILE_ARGS.push("-cp " + path);
		}
	}

	private function forceHaxeJson(): Void
	{
		Configuration.getData().HAXE_COMPILE_ARGS.push("-D haxeJSON");
	}

	private function forceDeprecationWarnings(): Void
	{
		Configuration.getData().HAXE_COMPILE_ARGS.push("-D deprecation-warnings");
	}

 	public function build() : Void
 	{
		var buildPath : String  = Path.join([targetDirectory,"html5","hxml"]);


		var result = CommandHelper.runHaxe( buildPath,
											["Build.hxml"], 
											{
												logOnlyIfVerbose : false, 
												systemCommand : true,
												errorMessage: "compiling the haxe code",
												exitOnError: false
											});

		if (result != 0)
		{
			if (applicationWillRunAfterBuild)
			{
				serverProcess.kill();
			}

			LogHelper.error("Haxe Compilation Failed");
		}
 	}

 	public function run() : Void
 	{
 	    runApp();/// run app in the browser
 	}

	public function test()
	{
		testApp();
	}

	public function publish()
	{
		throw "Publishing is not yet implemented for this platform";
	}

	public function fast()
	{
		parseProject();

		prepareVariables();
 	    prepareAndRunHTTPServer();
		build();
		
		if (Arguments.isSet("-test"))
			testApp();
		else
			runApp();
	}

 	public function runApp() : Void
 	{
 		/// order here matters cause opening slimerjs is a blocker process	
 		if(runInBrowser)
 		{
 			CommandHelper.openURL(DEFAULT_SERVER_URL);
 		}

 		if(runInSlimerJS)
 		{

 			var slimerFolder: String;
 			var xulrunnerFolder: String;
 			var xulrunnerCommand: String;

 			if (PlatformHelper.hostPlatform == LINUX)
 			{
 				slimerFolder = "slimerjs_linux";
 				xulrunnerCommand = "xulrunner";
 			}
 			else if (PlatformHelper.hostPlatform == MAC)
 			{
				slimerFolder = "slimerjs_mac";
 				xulrunnerCommand = "xulrunner";
 			}
 			else
 			{
				slimerFolder = "slimerjs_win";
 				xulrunnerCommand = "xulrunner.exe";
 			}

			xulrunnerFolder = Path.join([duellBuildHtml5Path,"bin",slimerFolder,"xulrunner"]);

 			if (PlatformHelper.hostPlatform != WINDOWS)
 			{
	 			CommandHelper.runCommand(xulrunnerFolder,
	 									 "chmod",
	 									 ["+x", "xulrunner"], 
	 									 {systemCommand: true,
	 									  errorMessage: "Setting permissions for slimerjs"});
 			}

			slimerProcess = new DuellProcess(
												xulrunnerFolder, 
												xulrunnerCommand, 
												["-app", 
												 Path.join([duellBuildHtml5Path, "bin", slimerFolder, "application.ini"]), 
												 "-no-remote", 
												 Path.join([duellBuildHtml5Path, "bin", "test.js"])], 
												{
													logOnlyIfVerbose : true, 
													systemCommand : false,
													errorMessage: "Running the slimer js browser"
												});
			slimerProcess.blockUntilFinished();
			serverProcess.kill();
 		} 
 		else if(runInBrowser)
 		{
			serverProcess.blockUntilFinished();
 		}
 	}
 	public function prepareAndRunHTTPServer() : Void
 	{
 		var serverTargetDirectory : String  = Path.join([targetDirectory,"html5","web"]);
 		
 		serverProcess = ServerHelper.runServer(serverTargetDirectory, duellBuildHtml5Path);
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
 	    TemplateHelper.recursiveCopyTemplatedFiles(Path.join([duellBuildHtml5Path, "template", "html5"]), projectDirectory, Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
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

			Configuration.getData().HAXE_COMPILE_ARGS.push("-D " + define);
		}
	} 
	private function copyJSIncludesToLibFolder() : Void
	{
		var jsIncludesPaths : Array<String> = [];
		var copyDestinationPath : String = "";

        var libsDir: String = Path.join([projectDirectory,"web","libs"]);

        if (!FileSystem.exists(libsDir))
        {
            FileSystem.createDirectory(libsDir);
        }

	    for ( scriptItem in PlatformConfiguration.getData().JS_SOURCES )
	    {
	    	copyDestinationPath = Path.join([projectDirectory,"web",scriptItem.destination]);

	    	if (FileSystem.exists(copyDestinationPath))
	    	{
	    		FileSystem.deleteFile(copyDestinationPath);
	    	}

	    	var destinationFileOutput = File.write(copyDestinationPath);

	    	if (scriptItem.oldPackage != null && scriptItem.newPackage != null)
	    	{
	    		var prepend = File.getContent(Path.join([duellBuildHtml5Path, "template", "jsimport", "preimport.js"]));
	    		destinationFileOutput.writeString(prepend);
	    	}

	    	if(scriptItem.applyTemplate == true)
	    	{
				var fileContents:String = File.getContent(scriptItem.originalPath);
				var template:Template = new Template(fileContents);
				var result:String = template.execute(Configuration.getData(), Configuration.getData().TEMPLATE_FUNCTIONS);
				destinationFileOutput.writeString(result);
	    	}
	    	else
	    	{
				var fileContents:String = File.getContent(scriptItem.originalPath);
				destinationFileOutput.writeString(fileContents);
	    	}

	    	if (scriptItem.oldPackage != null && scriptItem.newPackage != null)
	    	{
	    		var prepend = File.getContent(Path.join([duellBuildHtml5Path, "template", "jsimport", "postimport.js"]));
				var template:Template = new Template(prepend);
				var result:String = template.execute({NEW_PACKAGE: scriptItem.newPackage, OLD_PACKAGE: scriptItem.oldPackage}, Configuration.getData().TEMPLATE_FUNCTIONS);
	    		destinationFileOutput.writeString(result);
	    	}

	    	destinationFileOutput.close();
	    }
	}	

	private function testApp()
	{
		/// DELETE PREVIOUS TEST
		if (sys.FileSystem.exists(fullTestResultPath))
		{
			sys.FileSystem.deleteFile(fullTestResultPath);
		}

		/// CREATE TARGET FOLDER
		PathHelper.mkdir(Path.directory(fullTestResultPath));

		/// RUN THE APP IN A THREAD
		var targetTime = haxe.Timer.stamp() + DELAY_BETWEEN_PYTHON_LISTENER_AND_RUNNING_THE_APP;
		neko.vm.Thread.create(function()
		{
			Sys.sleep(DELAY_BETWEEN_PYTHON_LISTENER_AND_RUNNING_THE_APP);

			runApp();
		});

		/// RUN THE LISTENER
		try
		{
			TestHelper.runListenerServer(300, 8181, fullTestResultPath);
		}
		catch (e:Dynamic)
		{
			if (serverProcess != null)
				serverProcess.kill();

			if (runInSlimerJS)
			{
				if (slimerProcess != null)
					slimerProcess.kill();
			}
			neko.Lib.rethrow(e);
		}
		if (serverProcess != null)
		{
			serverProcess.kill();
		}
		if (runInSlimerJS)
		{
			if (slimerProcess != null)
			{
				slimerProcess.kill();
			}
		}
	}

	public function clean()
	{
		prepareVariables();

		LogHelper.info('Cleaning html5 part of export folder...');

		if (FileSystem.exists(projectDirectory))
		{
			PathHelper.removeDirectory(projectDirectory);
		}
	}

}
