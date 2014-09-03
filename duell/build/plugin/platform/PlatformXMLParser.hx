/**
 * @autor kgar
 * @date 01.09.2014.
 * @company Gameduell GmbH
 */
package duell.build.plugin.platform;

import haxe.xml.Fast;

import duell.build.objects.DuellProjectXML;
import duell.build.objects.Configuration;
import duell.helpers.XMLHelper;
import duell.helpers.LogHelper;

 class PlatformXMLParser
 {
 	public function new()
 	{}

 	public static function parse(xml : Fast) : Void
	{
		for (element in xml.elements) 
		{
			switch(element.name)
			{
				case 'html5':
					parsePlatform(element);
			}
		}
	}
	public static function parsePlatform(xml : Fast) : Void
	{
	    for (element in xml.elements) 
		{
			if (!XMLHelper.isValidElement(element, DuellProjectXML.getConfig().parsingConditions))
				continue;
			switch (element.name) 
			{
				case "win-size":
					parseWinSize(element);
				case "style":
					parseStyle(element);
				case "head-section":
					parseHeadSection(element);
				case "js-includes":
					parseJSInclude(element);
			}
		}
	}
	public static function parseJSInclude(element : Fast) : Void
	{
		var path:haxe.io.Path;
		for (script in element.nodes.script) 
		{
			if(script.has.path)
			{
				path = new haxe.io.Path(resolvePath(script.att.path));
				PlatformConfiguration.getData().JS_INCLUDES.push({originalPath : resolvePath(script.att.path), destination : "libs/"+path.file+"."+path.ext, applyTemplate : script.has.applyTemplate ? cast script.att.applyTemplate : false});
			}
		}
	}
	public static function parseStyle(element : Fast) : Void
	{
	    if(element.has.bgColor)
	    {
	    	PlatformConfiguration.getData().BGCOLOR = element.att.bgColor;      
	    }
	}
	public static function parseWinSize(element : Fast) : Void
	{
	    if(element.has.width)
	    {
	    	PlatformConfiguration.getData().WIDTH = element.att.width;
	    }
	    if(element.has.height)
	    {
	    	PlatformConfiguration.getData().HEIGHT = element.att.height;
	    }
	}
	
	private static function resolvePath(string : String) : String /// convenience method
	{
		return DuellProjectXML.getConfig().resolvePath(string);
	}

	private static function parseHeadSection(element : Fast)
	{
		PlatformConfiguration.getData().HEAD_SECTIONS.push(element.innerHTML);
	}
 }