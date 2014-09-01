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
			}
		}
	}
	
	
	private static function resolvePath(string : String) : String /// convenience method
	{
		return DuellProjectXML.getConfig().resolvePath(string);
	}

 }