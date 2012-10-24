package utils
{
	import flash.errors.*;
	import flash.events.*;
	import flash.external.*;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.system.Capabilities;
	
	import mx.collections.ArrayCollection;
	import mx.controls.AdvancedDataGrid;
	import mx.controls.DataGrid;
	import mx.controls.advancedDataGridClasses.AdvancedDataGridColumn;
	import mx.controls.advancedDataGridClasses.AdvancedDataGridListData;
	import mx.core.ClassFactory;
	
	/* This class is a slightly improved version of the following solution http://www.saskovic.com/blog/?p=3 */

	public class DataGridUtils
	{
		public static const TYPE_CSV:String = "typeCsv";
		public static const TYPE_TSV:String = "typeTsv";
		
		public static const EXPORT_ALL:String 		= "exportAll";
		public static const EXPORT_VISIBLE:String	= "exportVisible";
		public static const EXPORT_SELECTED:String 	= "exportSelected";		
		
		/**
		 * This will convert the data shown in the DataGrid to a CSV/TSV file
		 */
		public static function copyData( dataGrid:AdvancedDataGrid, fileType:String, exportType:String ):String
		{
			var str:String 	 		= "";
			var value:String 		= "";
			var skipColumns:Array	= [];
			
			
			
			//var data:Array = new Array();
			
			//for each (var obj:Object in dataGrid.dataProvider) {
	/*			var arr:Array=new Array();
				//for each (var hd:AdvancedDataGridColumn in dataGrid.columns) {
					if (hd.itemRenderer != null) {
						var classFactory:ClassFactory=hd.itemRenderer as ClassFactory;
						var itemRenderer:Object = classFactory.newInstance();
						var listData:AdvancedDataGridListData = new AdvancedDataGridListData(hd.editorDataField,hd.dataField,arr.length+1,"id",dataGrid,1);
						itemRenderer.listData = listData;
						if (itemRenderer.hasOwnProperty(hd.editorDataField)) {
							itemRenderer[hd.editorDataField] = obj[hd.dataField];
							itemRenderer.data = obj; // must be last apply for complex itemRenderer
							arr.push(itemRenderer[hd.editorDataField]);
						} else {
							arr.push(itemRenderer.toString());
						}
					} else if (hd.labelFunction != null) {
						arr.push(hd.labelFunction(obj,null));
					} else {
						arr.push(obj[hd.dataField]);
					}*/
				
			
		

			
			
			
			for (var i:int = 0;i<dataGrid.columns.length;i++) 
			{
				if (dataGrid.columns[i].headerText != undefined) 
				{
					value = dataGrid.columns[i].headerText;					
				} 
				else 
				{
					value = dataGrid.columns[i].dataField;
				}
				
				// we won't include columns which don't have titles
				if (value.length == 0)
				{
					skipColumns.push( i );
					continue;
				}
				else
				{
					if (fileType == TYPE_CSV)
					{
						str += '"' + value + '"';
					}
					else
					{
						str += value;
					}
				}
				
				if (i < dataGrid.columns.length-1)
				{
					str += fileType == TYPE_CSV ? "," : "\t";
				}
			}
			
			str += lineEnding; 

			//Loop through the records in the dataprovider and 
			//insert the column information into the table			
			var data:Array;
			
			if (exportType == EXPORT_ALL)
			{
				data = ArrayCollection( dataGrid.dataProvider ).source;
			}
			else
			{
				data = dataGrid.selectedItems;
			}
			
			for each (var item:Object in data)
			{					
				for(var k:int=0; k < dataGrid.columns.length; k++) 
				{
					// check if we're skipping this column
					if (skipColumns.indexOf( k ) >= 0)
					{
						continue;
					}
					
    				//Check to see if the profile specified a labelfunction which we must
					//use instead of the dataField
					if (dataGrid.columns[k].labelFunction != undefined) 
					{
						value = dataGrid.columns[k].labelFunction(item, dataGrid.columns[k]);			        					
					} 
					else 
					{
						//Our dataprovider contains the real data
						//We need the column information (dataField)
						//to specify which key to use.
						var dataField:String = dataGrid.columns[k].dataField;
						
						value = item[ dataField ];
					}
				
					if (value)
					{
						var pattern:RegExp = /["]/g;
						value = value.replace( pattern, "" );
						
						if (fileType == TYPE_CSV)
						{
							value = '"' + value + '"';
						}
					}
					else
					{
						if (fileType == TYPE_CSV)
						{
							value = '""';
						}
					}
					
					str += value;
					
					if (k < dataGrid.columns.length - 1)
					{
						str += fileType == TYPE_CSV ? "," : "\t";
					}
				}
				
				str += lineEnding;
			}
			
			return str;
		}
        
		public static function getItemsFromText( text:String ):Array
		{
			var rows:Array = text.split( lineEnding );
			
			// check for a blank row
			if (rows.length > 0 && !rows[rows.length - 1])
			{
				rows.pop();
			}
			
			var itemsFromText:Array = [];

			for each (var row:String in rows)
			{
				var fields:Array = row.split("\t");
				var item:Object = {};
				
				for (var i:int = 0; i < fields.length; i++)
				{
					item["col" + (i+1)] = fields[i];
				}
				
				itemsFromText.push(item);
			}
			
			return itemsFromText;
		}

		private static function get lineEnding():String
		{
			if (Capabilities.os.indexOf( "Mac" ) >= 0)
			{
				return "\r";
			}
			else
			{
				return "\r\n";
			}
		}

      	public static function loadDataGridInExcel( dataGrid:AdvancedDataGrid ):void 
		{
			//Pass the htmltable in a variable so that it can be delivered
			//to the backend script
			var variables:URLVariables = new URLVariables(); 
			variables.htmlTable	= copyData( dataGrid, TYPE_TSV, EXPORT_ALL );
			
			//Setup a new request and make sure that we are 
			//sending the data through a post
			var url:String = Consts.SERVER_URL + Consts.CSV_EXPORT_SCRIPT;
			var u:URLRequest = new URLRequest( url );
			u.data = variables; //Pass the variables
			u.method = URLRequestMethod.POST; //Don't forget that we need to send as POST
			
			//Navigate to the script
			//We can use _self here, since the script will through a filedownload header
			//which results in offering a download to the profile (and still remaining in you Flex app.)
			navigateToURL( u, "_self" );			
		}	
	}       
}