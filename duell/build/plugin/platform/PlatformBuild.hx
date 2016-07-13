/*
 * Copyright (c) 2003-2015, GameDuell GmbH
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
 * IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
import duell.helpers.ThreadHelper;
import duell.objects.DuellProcess;
import duell.objects.Arguments;
import duell.objects.Server;

import haxe.io.Path;

import sys.FileSystem;
import sys.io.File;

using StringTools;

class PlatformBuild
{
 	public var requiredSetups = [];
	public var supportedHostPlatforms = [WINDOWS, MAC, LINUX];

	private static inline var TEST_RESULT_FILENAME = "test_result_html5.xml";
	private static inline var DEFAULT_SERVER_URL = "http://localhost:3001/";
	private static inline var DELAY_BETWEEN_PYTHON_LISTENER_AND_RUNNING_THE_APP = 2;

 	private var isDebug : Bool = false;
 	private var isTest : Bool = false;
	private var applicationWillRunAfterBuild : Bool = false;
	private var runInSlimerJS : Bool = false;
	private var runInBrowser : Bool = false;
	private var server : Server;
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
		if (isDebug)
		{
			Configuration.getData().PLATFORM.DEBUG = true;
		}

 		prepareVariables();

		convertDuellAndHaxelibsIntoHaxeCompilationFlags();
 	    convertParsingDefinesToCompilationDefines();
        forceSourceMaps();
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
                version = "dev";
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

    private function forceSourceMaps(): Void
    {
        Configuration.getData().HAXE_COMPILE_ARGS.push("-D source-map-content");
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
				server.shutdown();
			}

			throw "Haxe Compilation Failed";
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
	}

	public function fast()
	{
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

            var appPath = Path.join([duellBuildHtml5Path, "bin", slimerFolder, "application.ini"]);
            var scriptPath = Path.join([duellBuildHtml5Path, "bin", "application.js"]);

 			if (PlatformHelper.hostPlatform != WINDOWS)
 			{
	 			CommandHelper.runCommand(xulrunnerFolder,
	 									 "chmod",
	 									 ["+x", "xulrunner"],
	 									 {systemCommand: true,
	 									  errorMessage: "Setting permissions for slimerjs"});
 			}
            else
            {
                xulrunnerFolder = xulrunnerFolder.split("/").join("\\");
                xulrunnerCommand = xulrunnerCommand.split("/").join("\\");
                appPath = appPath.split("/").join("\\");
                scriptPath = scriptPath.split("/").join("\\");
            }

			slimerProcess = new DuellProcess(
												xulrunnerFolder,
												xulrunnerCommand,
												["-app",
												 appPath,
												 "-no-remote",
												 scriptPath, PlatformConfiguration.getData().WIDTH, PlatformConfiguration.getData().HEIGHT],
												{
													logOnlyIfVerbose : true,
													systemCommand : false,
													errorMessage: "Running the slimer js browser"
												});
			slimerProcess.blockUntilFinished();
			server.shutdown();
 		}
 		else if(runInBrowser)
 		{
            server.waitUntilFinished();
 		}
 	}
 	public function prepareAndRunHTTPServer() : Void
 	{
 		var serverTargetDirectory : String  = Path.join([targetDirectory,"html5","web"]);

 		server = new Server(serverTargetDirectory, -1, 3001);
        server.start();
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
				destinationFileOutput.close();
				File.copy(scriptItem.originalPath, copyDestinationPath);
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
		ThreadHelper.runInAThread(function()
		{
			Sys.sleep(DELAY_BETWEEN_PYTHON_LISTENER_AND_RUNNING_THE_APP);

			runApp();
		});

		/// RUN THE LISTENER
		try
		{
			/**
            * TODO: Find a better/central place for the hardcoded fallback port 8181
            *       which is intended fall back on if the duell-tool's configuration
            *       does not provide the TEST_PORT property (backward-compatibility).
            *       Remove eventually...
            **/
			var testPort:Int = untyped Configuration.getData().TEST_PORT == null ?
				8181 : Configuration.getData().TEST_PORT;

			TestHelper.runListenerServer(300, testPort, fullTestResultPath);
		}
		catch (e:Dynamic)
		{
			if (server != null)
				server.shutdown();

			if (runInSlimerJS)
			{
				if (slimerProcess != null)
					slimerProcess.kill();
			}
			throw e;
		}
		if (server != null)
		{
			server.shutdown();
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

    public function handleError()
    {
        if (server != null)
            server.shutdown();

        if (slimerProcess != null)
            slimerProcess.kill();
    }
}
