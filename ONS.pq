// Based on https://docs.microsoft.com/en-us/power-query/samples/trippin/1-odata/readme 

section ONS;

[DataSource.Kind="ONS", Publish="ONS.Publish"]
shared ONS.Contents = () => QueryTypeLevNavTable() as table;  



// Data Source Kind description
ONS = [
    TestConnection = (dataSourcePath) => { "ONS.Contents" },
    Authentication = [
        Anonymous = []
    ],
    Label = "ONS"
];

// Data Source UI publishing description
ONS.Publish = [
    Beta = true,
    Category = "Other",
    ButtonText = { "ONS Data Source Path", "ONS Data Source Paths" }
];

//
// Implementation
// 

DefaultRequestHeaders = [
    #"Accept" = "application/json;odata.metadata=minimal",  // column name and values only
    #"OData-MaxVersion" = "4.0"                             // we only support v4
];




shared querytype = () as table =>
let

    // The line below can be uncommented and it will work.  I found everything I need in the one dataset so left the other out to aid performance
    //Source = {"weekly-deaths-age-sex"	,"weekly-deaths-local-authority"},
    Source = {"weekly-deaths-age-sex"},
    
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "querytype"}})
    in
    #"Renamed Columns";

shared WeekTbl = () as table =>
let

    Source = Table.FromList({1..52},Splitter.SplitByNothing()),      
    #"Added Custom" = Table.AddColumn(Source, "Custom", each "week-"),
    #"Reordered Columns" = Table.ReorderColumns(#"Added Custom",{"Custom", "Column1"}),
    #"Merged Columns" = Table.CombineColumns(Table.TransformColumnTypes(#"Reordered Columns", {{"Column1", type text}}, "en-GB"),{ "Custom","Column1"},Combiner.CombineTextByDelimiter("", QuoteStyle.None),"week")
in
    #"Merged Columns";


shared placeofdeathTbl = () as table =>
let
    Source = {"hospital","hospice","care-home","elsewhere","home","other-communal-establishment"},
    #"Converted to Table" = #table(1, {{Source}}),
    Column1 = #"Converted to Table"{0}[Column1],
    #"Converted to Table1" = Table.FromList(Column1, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table1",{{"Column1", "placeofdeath"}})
in
    #"Renamed Columns";


shared causeofdeathTbl = () as table =>
let
    Source = {"all-causes"},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "causeofdeath"}})
in
    #"Renamed Columns";


shared regoroccTbl = () as table =>
let
    //Source = {"registrations","occurrences"},
    Source = {"registrations"},  // only run for registrations as this matches the spreadsheets available on the ONS site
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "RegOrOcc"}})
in
    #"Renamed Columns";




shared agegroups = () as table =>
let
    Source = {"0-1"
	,"1-4"
	,"10-14"
	,"15-19"
	,"20-24"
	,"25-29"
	,"30-34"
	,"35-39"
	,"40-44"
	,"45-49"
	,"5-9"
	,"50-54"
	,"55-59"
	,"60-64"
	,"65-69"
	,"70-74"
	,"75-79"
	,"80-84"
	,"85-89"
	,"90%2b" 
    },
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "agegroup"}})
    in
    #"Renamed Columns";

shared sex = () as table =>
let
    Source = {"male","female"},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "sex"}})
    in
    #"Renamed Columns";

shared deaths = () as table =>
let
    Source = {"total-registered-deaths"},  // Maybe later add deaths=deaths-involving-covid-19-registrations
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "deaths"}})
in
    #"Renamed Columns";



shared yearsTbl = () as table =>
let
    Source = {2020..2020},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "year"}})
in
    #"Renamed Columns";


shared geoTbl = () as table =>
let
    Source = {"*"},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Geography"}})
in
    #"Renamed Columns";


 // For "weekly-deaths-local-authority" 
shared GetURL1 = (vYear as text, vWeek as text, vGeo as text, vplaceofdeath as text, vcauseofdeath as text, vregorocc as text) as text =>
let

        DSVerNum = GetDSVersion("weekly-deaths-local-authority"),
        BaseURL  = "https://api.beta.ons.gov.uk/v1/datasets/weekly-deaths-local-authority/editions/time-series/versions/" & DSVerNum & "/observations?",
        AddYear         = BaseURL           & "time="                       & vYear,               
        AddWeek         = AddYear           & "&week="                      & vWeek,
        AddGeo          = AddWeek           & "&geography="                 & vGeo,
        Addplaceofdeath = AddGeo            & "&placeofdeath="              & vplaceofdeath,
        Addcauseofdeath = Addplaceofdeath   & "&causeofdeath="              & vcauseofdeath,
        Addregorocc    = Addcauseofdeath    & "&registrationoroccurrence="  & vregorocc  
in
    Addregorocc;


// For "weekly-deaths-age-sex" 
shared GetURL2 = (vYear as text, vWeek as text, vGeo as text, vdeaths as text, vagegroups as text, vsex as text) as text =>
let
        
        DSVerNum = GetDSVersion("weekly-deaths-age-sex"),
        BaseURL  = "https://api.beta.ons.gov.uk/v1/datasets/weekly-deaths-age-sex/editions/covid-19/versions/" & DSVerNum & "/observations?",
        AddYear         = BaseURL           & "time="                       & vYear,               
        AddWeek         = AddYear           & "&week="                      & vWeek,
        AddGeo          = AddWeek           & "&geography="                 & vGeo,
        Adddeaths       = AddGeo            & "&deaths="                    & vdeaths,
        Addagegroups    = Adddeaths         & "&agegroups="               & vagegroups,
        AddSex    = Addagegroups             & "&sex="  & vsex  
in
    AddSex;


// For "weekly-deaths-local-authority" 
shared GetAllURLsList1 = (vyear as text, vweek as text) as list=>
    
    let
    Source = {"X"},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Dummy"}}),
    #"Add Week" =                       Table.AddColumn(#"Renamed Columns","week", each vweek  ),
     #"Add placeofdeath" =               Table.AddColumn(#"Add Week","placeofdeath", each placeofdeathTbl() ),
    #"Add years" =                      Table.AddColumn(#"Add placeofdeath","years", each vyear),           
    #"Add causeofdeath" =               Table.AddColumn(#"Add years","causeofdeath", each causeofdeathTbl()),
    #"Add Registration_Or_Occurrence" = Table.AddColumn(#"Add causeofdeath","RegOrOcc", each regoroccTbl()),  
    #"Add Geography" =                  Table.AddColumn(#"Add Registration_Or_Occurrence","Geography", each geoTbl()),
    #"Expanded placeofdeath" = Table.ExpandTableColumn(#"Add Geography", "placeofdeath", {"placeofdeath"}, {"placeofdeath"}),
    #"Expanded causeofdeath" = Table.ExpandTableColumn(#"Expanded placeofdeath", "causeofdeath", {"causeofdeath"}, {"causeofdeath"}),
    #"Expanded Registration_Or_Occurrence" = Table.ExpandTableColumn(#"Expanded causeofdeath", "RegOrOcc", {"RegOrOcc"}, {"RegOrOcc"}),
    #"Expanded Geography" = Table.ExpandTableColumn(#"Expanded Registration_Or_Occurrence", "Geography", {"Geography"}, {"Geography"}),
    #"Removed Columns" = Table.RemoveColumns(#"Expanded Geography",{"Dummy"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"week", type text}, {"years", type text}})   ,
    #"Invoked Custom Function" = Table.AddColumn(#"Changed Type", "GetURL", each GetURL1([years],[week],[Geography],[placeofdeath],[causeofdeath],[RegOrOcc])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoked Custom Function",{{"GetURL", "URL"}}),
    aURL = #"Renamed Columns1"[URL]      
         in  aURL
        ;


// For "weekly-deaths-age-sex" 
shared GetAllURLsList2 = (vyear as text, vweek as text) as list=>
    
    let
    Source = {"X"},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Dummy"}}),
    #"Add Week" =                       Table.AddColumn(#"Renamed Columns","week", each vweek  ), 
    #"Add years" =                      Table.AddColumn(#"Add Week","years", each vyear),           
    #"Add Geography" =                  Table.AddColumn(#"Add years","Geography", each geoTbl()),

    #"Add Deaths" =                  Table.AddColumn(#"Add Geography","deaths", each deaths()),
    #"Add Sex" =                  Table.AddColumn(#"Add Deaths","sex", each sex()),
    #"Add agegroups" =                  Table.AddColumn(#"Add Sex","agegroup", each agegroups()),

    #"Expanded Sex" = Table.ExpandTableColumn(#"Add agegroups", "sex", {"sex"}, {"sex"}),
    #"Expanded agegroups" = Table.ExpandTableColumn(#"Expanded Sex", "agegroup", {"agegroup"}, {"agegroup"}),    
    #"Expanded deaths" = Table.ExpandTableColumn(#"Expanded agegroups", "deaths", {"deaths"}, {"deaths"}),
    #"Expanded Geography" = Table.ExpandTableColumn(#"Expanded deaths", "Geography", {"Geography"}, {"Geography"}),


    #"Removed Columns" = Table.RemoveColumns(#"Expanded Geography",{"Dummy"}),
    #"Changed Type" = Table.TransformColumnTypes(#"Removed Columns",{{"week", type text}, {"years", type text}})   ,
    #"Invoked Custom Function" = Table.AddColumn(#"Changed Type", "GetURL", each GetURL2([years],[week],[Geography],[deaths],[agegroup],[sex])),
    #"Renamed Columns1" = Table.RenameColumns(#"Invoked Custom Function",{{"GetURL", "URL"}}),
    aURL = #"Renamed Columns1"[URL]      

         in  aURL
        ;



// get latest version number for dataset 
shared GetDSVersion = (querytype as text) as text =>

let 
        
        url = "https://api.beta.ons.gov.uk/v1/datasets/" & querytype,
        WebContents = Web.Contents(url, [ Headers = DefaultRequestHeaders ]), 
        Source = Json.Document(WebContents)  ,
        links = Source[links],
        latest_version = links[latest_version],
        #"Converted to Table" = Record.ToTable(latest_version),
        #"Filtered Rows" = Table.SelectRows(#"Converted to Table", each ([Name] = "id")),
        result =  #"Filtered Rows"[Value]{0}
        in

         result   ;


 

shared GetMaxWeek = (vyear as text, querytype as text) as text=>
let

    // Need to run one generic query to determine the maxium week of the year data is available.
    

        DSVerNum = GetDSVersion(querytype),
       url = if querytype =  "weekly-deaths-local-authority"        // geography=E09000001 (London)
                then "https://api.beta.ons.gov.uk/v1/datasets/weekly-deaths-local-authority/editions/time-series/versions/"& DSVerNum &"/observations?time=" & vyear & "&week=*&geography=E09000001&placeofdeath=home&causeofdeath=all-causes&registrationoroccurrence=registrations"

                     //"weekly-deaths-local-authority"    geography=K04000001 (England and Wales)
                else "https://api.beta.ons.gov.uk/v1/datasets/weekly-deaths-age-sex/editions/covid-19/versions/"& DSVerNum &"/observations?time=" & vyear & "&week=*&geography=K04000001&deaths=total-registered-deaths&sex=male&agegroups=all",
       
       
       source = Web.Contents(url, [ Headers = DefaultRequestHeaders ]), 
        json = Json.Document(source)  ,
        result =  "week-" & Number.ToText(json[total_observations])
             
    
in
    result;
    


shared GetYearAndWeek = (year as text, maxMonth as text) as table=>
        let


   maxMonthNm =  Number.FromText( Text.AfterDelimiter(maxMonth,"-")),
    Source = {"X"},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Renamed Columns" = Table.RenameColumns(#"Converted to Table",{{"Column1", "Dummy"}}),

    #"Add Week" =                       Table.AddColumn(#"Renamed Columns","week", each WeekTbl()),
    #"Add years" = Table.AddColumn(#"Add Week","years", each yearsTbl()),
    #"Removed Columns" = Table.RemoveColumns(#"Add years",{"Dummy"}),
    #"Expanded week" = Table.ExpandTableColumn(#"Removed Columns", "week", {"week"}, {"week"}),
    #"Expanded years" = Table.ExpandTableColumn(#"Expanded week", "years", {"year"}, {"year"}),
    #"Selected years" = Table.SelectRows(#"Expanded years", each (Number.ToText([year]) = year)),
    #"Add week as Num" = Table.AddColumn( #"Selected years","week num", each Number.FromText( Text.AfterDelimiter([week],"-") )  ),
    #"Selected years & Months" = Table.SelectRows(#"Add week as Num", each (([week num]) <= maxMonthNm))         /// << this is not working
in
    #"Selected years & Months" ;






QueryTypeLevNavTable = () as table => 
					let




    querytypetable = querytype(),
    withData = Table.AddColumn(querytypetable            ,"Data", each  YearLevelNavTable([querytype]) ),            
        YearsTbl =   Table.RenameColumns(withData     ,{"querytype","Name"}),      
        withItemKind = Table.AddColumn(YearsTbl         , "ItemKind", each "Table", type text),
        withItemName = Table.AddColumn(withItemKind     , "ItemName", each "Table", type text),
        withIsLeaf = Table.AddColumn(withItemName       , "IsLeaf", each false, type logical),
        navTable = Table.ToNavigationTable(withIsLeaf, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
        
in 
   
  //result;
   navTable;




YearLevelNavTable = (querytype as text) as table => 
					let

    yearstable = yearsTbl(),
    withData = Table.AddColumn(yearstable            ,"Data", each  WeekLevelNavTable(              querytype
                                                                                                    ,Number.ToText([year])        
                                                                                                    
                                                                                                    ) ),            

        YearsTbl =   Table.RenameColumns(withData     ,{"year","Name"}),      
        withItemKind = Table.AddColumn(YearsTbl         , "ItemKind", each "Table", type text),
        withItemName = Table.AddColumn(withItemKind     , "ItemName", each "Table", type text),
        withIsLeaf = Table.AddColumn(withItemName       , "IsLeaf", each false, type logical),
        navTable = Table.ToNavigationTable(withIsLeaf, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")
in 
   
  
   navTable;

		

WeekLevelNavTable = (querytype as text, year as text) as table => 

					let


        MaxWeek = GetMaxWeek(year,querytype),
        WeeksTable = GetYearAndWeek (year
                                    ,MaxWeek
                                    ), 
   
     withData = Table.AddColumn( WeeksTable
                                            , "Data"
                                            , each  if querytype = "weekly-deaths-local-authority" 
                                                    then
                                                        GetandCombinebyWeek(   GetAllURLsList1(year,[week] ) ,[week],year       )
                                                    
                                                    else // weekly-deaths-age-sex
                                                        GetandCombinebyWeek(   GetAllURLsList2(year,[week] ) ,[week],year       )
                                                    
                                             ),

        
                               
    renamed = Table.RenameColumns(withData,{{"week", "Name"}}), // Name needs to be Unique, so use week number for now.
    
    withItemKind = Table.AddColumn(renamed         , "ItemKind", each "Table", type text),
    withItemName = Table.AddColumn(withItemKind     , "ItemName", each "Table", type text),
    withIsLeaf = Table.AddColumn(withItemName       , "IsLeaf", each true, type logical),      
    navTable = Table.ToNavigationTable(withIsLeaf, {"Name"}, "Name", "Data", "ItemKind", "ItemName", "IsLeaf")                        

    in     

    navTable   ;






 GetandCombinebyWeek = (url as list, week as text, year as text) as any =>
     let
     asTableTest = Table.FromList(url, Splitter.SplitByNothing()),        // turns the list into a Table (note the column is called 'Column1')
     rename = Table.RenameColumns(asTableTest,{"Column1","URL"}),
   
      withData = Table.AddColumn( rename, "Data"
                                            //, each ONS.Feed(   [URL] )     
                                            
                                            , each  if querytype = "weekly-deaths-local-authority" 
                                                    then
                                                        ONS.Feed1(    [URL]      )
                                                    
                                                    else // weekly-deaths-age-sex
                                                        ONS.Feed2(   [URL]     )


                                            ),
    combined = Table.Combine(withData[Data]) ,            // combined for 1 week
    AddWeek = Table.AddColumn( combined,"week", each week),
    AddYear = Table.AddColumn( AddWeek,"year", each year)

     in 
         AddYear;


ONS.Feed1 = (url as text) as table =>
    let

 
         asTableTest = Table.FromList(url, Splitter.SplitByNothing()),        // turns the list into a Table (note the column is called 'Column1')
        source = Web.Contents(url, [ Headers = DefaultRequestHeaders ]), 



        json = Json.Document(source),
        observations = json[observations],  

         asTable = Table.FromList(observations, Splitter.SplitByNothing()),        // turns the list into a Table (note the column is called 'Column1')
         // expand all columns from the record
         fields = Record.FieldNames( Table.FirstValue( asTable, [Empty = null])),
         expandAll = Table.ExpandRecordColumn(asTable, "Column1", fields),

         fields2 = Record.FieldNames( Table.FirstValue( expandAll, [Empty = null])),
         expandAll2 = Table.ExpandRecordColumn(expandAll, "dimensions", fields2),

         fields3 = Record.FieldNames( Table.FirstValue( expandAll2, [Empty = null])),
         expandAll3 = Table.ExpandRecordColumn(expandAll2, "geography", fields3)
    in
      expandAll3;


// weekly-deaths-age-sex      
ONS.Feed2 = (url as text) as table =>
    let

 
         asTableTest = Table.FromList(url, Splitter.SplitByNothing()),        // turns the list into a Table (note the column is called 'Column1')
        source = Web.Contents(url, [ Headers = DefaultRequestHeaders ]), 



        json = Json.Document(source),
        observations = json[observations],  

         asTable = Table.FromList(observations, Splitter.SplitByNothing()),        // turns the list into a Table (note the column is called 'Column1')
         // expand all columns from the record
         fields = Record.FieldNames( Table.FirstValue( asTable, [Empty = null])),
         expandAll = Table.ExpandRecordColumn(asTable, "Column1", fields),

         fields2 = Record.FieldNames( Table.FirstValue( expandAll, [Empty = null])),
         expandAll2 = Table.ExpandRecordColumn(expandAll, "dimensions", fields2),

         fields3 = Record.FieldNames( Table.FirstValue( expandAll2, [Empty = null])),
         expandAll3 = Table.ExpandRecordColumn(expandAll2, "geography", fields3),


             dimensions = json[dimensions],  
            #"Converted to Table" = Record.ToTable(dimensions),
            #"Expanded Value" = Table.ExpandRecordColumn(#"Converted to Table", "Value", {"option"}, {"option"}),
            #"Dimensions Table" = Table.ExpandRecordColumn(#"Expanded Value", "option", {"id"}, {"id"}),
            #"Filtered agegroup" = Table.SelectRows( #"Dimensions Table", each ([Name] = "agegroups")),
            #"Filtered sex" = Table.SelectRows( #"Dimensions Table", each ([Name] = "sex")),


         Add_agegroup = Table.AddColumn( expandAll3,"agegroup",each  #"Filtered agegroup"[id]{0}   ),
         Add_sex = Table.AddColumn( Add_agegroup,"sex",each  #"Filtered sex"[id]{0}   )


    
    in
        Add_sex;


//
// Common functions
//
Table.ToNavigationTable = (
    table as table,
    keyColumns as list,
    nameColumn as text,
    dataColumn as text,
    itemKindColumn as text,
    itemNameColumn as text,
    isLeafColumn as text
) as table =>
    let
        tableType = Value.Type(table),
        newTableType = Type.AddTableKey(tableType, keyColumns, true) meta 
        [
            NavigationTable.NameColumn = nameColumn, 
            NavigationTable.DataColumn = dataColumn,
            NavigationTable.ItemKindColumn = itemKindColumn, 
            Preview.DelayColumn = itemNameColumn, 
            NavigationTable.IsLeafColumn = isLeafColumn
        ],
        navigationTable = Value.ReplaceType(table, newTableType)
    in
        navigationTable;


// TEMPORARY WORKAROUND until we're able to reference other M modules
Extension.LoadFunction = (name as text) =>
    let
        binary = Extension.Contents(name),
        asText = Text.FromBinary(binary)
    in
        Expression.Evaluate(asText, #shared);


// Diagnostics module contains multiple functions. We can take the ones we need.
Diagnostics = Extension.LoadFunction("Diagnostics.pqm");
Diagnostics.LogValue = Diagnostics[LogValue];
Diagnostics.LogFailure = Diagnostics[LogFailure];