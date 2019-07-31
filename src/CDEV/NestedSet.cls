/// Nested set model implementation.
/// How to use this class:
/// 1) Create persistent class for hierarchical data (e.g. MyApp.Category), and specify CDEV.NestedSet as a superclass
/// 2) In your class (MyApp.Category) override parameters: LEVEL, RIGHT, LEFT, ROOT
/// 3) Add indices 
///        Index RootIndex On Root;
///        Index RootLftIndex On (Root, Lft);
/// 4) To add new Node Use one of the Methods: AddLast, AddFirst, 
/// or create new node (%New()), set Parent Property and Save with %Save()
/// or use SQL INSERT statement
/// 5) To Delete Node - call %DeleteId, or use SQL DELETE Statement
/// 6) To order siblings use MoveUp and MoveDown methods
Class CDEV.NestedSet [ Abstract, DependsOn = CDEV.NestedSetUtils ]
{

/// Override this parameter!
/// Specify level property (should be %Integer property)
Parameter LEVEL;

/// Override this parameter!
/// Specify Left property (should be %Integer property)
Parameter LEFT;

/// Override this parameter!
/// Specify Right property (should be %Integer property)
Parameter RIGHT;

/// Override this parameter!
/// Specify Root property (should be %Integer property)
Parameter ROOT;

/// Override this parameter!
/// Specify Parent property (should be the same type as your class)
/// e.g. 
///     Property Parent as MyApp.Category, 
/// or 
///     Relationship Parent As MyApp.Category [ Cardinality = one, Inverse = ChildrenNodes ];
Parameter PARENT;

/// Returns list ($LB) of root ID or empty string ("") 
ClassMethod GetRoots() As %List [ CodeMode = objectgenerator ]
{
	set tablename = %compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName
	if (##class(CDEV.NestedSetUtils).IsParamsValid(%compiledclass, .params, .x)) {
		do %code.WriteLine(" set list = """"")
		do %code.WriteLine(" &sql(SELECT %DLIST("""_x("ROOT")_""") INTO :list  FROM  "_tablename_" WHERE """_x("PARENT")_""" IS NULL)")
		do %code.WriteLine(" return list")
	}
}

/// Adds new node as the last sibling under current node
Method AddLastChild(newNode As CDEV.NestedSet) As %Status [ CodeMode = objectgenerator ]
{
	set tablename = %compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName
	if (##class(CDEV.NestedSetUtils).IsParamsValid(%compiledclass, .params, .x)) {
		do %code.WriteLine(" set newNode."_x("PARENT")_" = $this")
		do %code.WriteLine(" return newNode.%Save()")
	}
}

/// Adds new node as the first sibling under current node
Method AddFirstChild(newNode As CDEV.NestedSet) As %Status [ CodeMode = objectgenerator ]
{
	set tablename = %compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName
	if (##class(CDEV.NestedSetUtils).IsParamsValid(%compiledclass, .params, .x)) {
		do %code.WriteLine(" try {")
		do %code.WriteLine("	 &sql(START TRANSACTION)")
		do %code.WriteLine("	 set newNode."_x("PARENT")_" = $this")
		do %code.WriteLine("     $$$ThrowOnError(newNode.%Save())")
		do %code.WriteLine("     $$$ThrowOnError(newNode.%Reload())")
		do %code.WriteLine("     set parentLeft=.."_x("LEFT"))
		do %code.WriteLine("     set root=newNode."_x("ROOT")_", left=newNode."_x("LEFT")_", right=newNode."_x("RIGHT")_", id = newNode.%Id()")
		do %code.WriteLine("     &sql(SELECT TOP 1 """_x("LEFT")_""" INTO :firstLeft FROM "_tablename_" WHERE """_x("ROOT")_"""=:root AND """_x("LEFT")_""">:parentLeft ORDER BY """_x("LEFT")_""")")
		do %code.WriteLine("     if (firstLeft '= newNode."_x("LEFT")_") {")
		do %code.WriteLine("         &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_"""="""_x("LEFT")_"""+2, """_x("RIGHT")_"""="""_x("RIGHT")_"""+2 WHERE """_x("ROOT")_"""=:root AND """_x("LEFT")_""">=:firstLeft AND """_x("LEFT")_"""<:left)")
		do %code.WriteLine("         if (SQLCODE<0) { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg) }")
		do %code.WriteLine("         &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_"""=:firstLeft, """_x("RIGHT")_"""=(:firstLeft+1) WHERE ID = :id)")
		do %code.WriteLine("         if (SQLCODE<0) { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg) }")
		do %code.WriteLine("     }")
		do %code.WriteLine("     &sql(COMMIT)")
		do %code.WriteLine(" } catch ex {")
		do %code.WriteLine("     &sql(ROLLBACK)")
		do %code.WriteLine("     return ex.AsStatus()")
		do %code.WriteLine(" }")
		do %code.WriteLine(" return $$$OK")
	} else {
		do %code.WriteLine(" return $$$ERROR(5001,""Please, specify all PARAMETERS "_$LTS(params)_" and recompile class"")")
	}
}

Method MoveUp() As %Status [ CodeMode = objectgenerator ]
{
	set tablename = %compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName
	if (##class(CDEV.NestedSetUtils).IsParamsValid(%compiledclass, .params, .x)) {
		do %code.WriteLine(" do ..%Reload()")
		do %code.WriteLine(" set left = .."_x("LEFT")_", right = .."_x("RIGHT")_", root=.."_x("ROOT")_"")
		do %code.WriteLine(" set prevLevel = 0")
		do %code.WriteLine(" &sql(SELECT TOP 1 """_x("LEVEL")_""", """_x("LEFT")_""", """_x("RIGHT")_""" INTO :prevLevel, :prevLeft, :prevRight FROM "_tablename_" WHERE """_x("ROOT")_"""=:root AND """_x("RIGHT")_"""<:left ORDER BY """_x("RIGHT")_""" DESC)")
		do %code.WriteLine(" if (SQLCODE<0) { return ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg).AsStatus() }")
		do %code.WriteLine(" if (prevLevel'=.."_x("LEVEL")_") { return $$$ERROR(5001,""This node is already the first one"") }")
		do %code.WriteLine(" try {")		
		do %code.WriteLine("     set plus = right - prevRight")
		do %code.WriteLine("     set minus = left - prevLeft")
		do %code.WriteLine("     &sql(START TRANSACTION)")
		do %code.WriteLine("     &sql(SELECT %DLIST(ID) INTO :minuslist  FROM  "_tablename_" WHERE """_x("ROOT")_"""=:root AND """_x("LEFT")_""">=:left AND """_x("RIGHT")_"""<=:right)")
		do %code.WriteLine("     &sql(SELECT %DLIST(ID) INTO :pluslist  FROM  "_tablename_" WHERE """_x("ROOT")_"""=:root AND """_x("LEFT")_""">=:prevLeft AND """_x("RIGHT")_"""<=:prevRight)")
		do %code.WriteLine("     &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_"""="""_x("LEFT")_"""-:minus, """_x("RIGHT")_"""="""_x("RIGHT")_"""-:minus WHERE ID %INLIST :minuslist)")
		do %code.WriteLine("     if (SQLCODE<0) { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg) }")
		do %code.WriteLine("     &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_"""="""_x("LEFT")_"""+:plus, """_x("RIGHT")_"""="""_x("RIGHT")_"""+:plus WHERE ID %INLIST :pluslist)")
		do %code.WriteLine("     if (SQLCODE<0) { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg) }")
		do %code.WriteLine("     &sql(COMMIT)")
		do %code.WriteLine(" } catch ex {")
		do %code.WriteLine("     &sql(ROLLBACK)")
		do %code.WriteLine("     return ex.AsStatus()")
		do %code.WriteLine(" }")
		do %code.WriteLine(" return $$$OK")
	}
}

Method MoveDown() As %Status [ CodeMode = objectgenerator ]
{
	set tablename = %compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName
	if (##class(CDEV.NestedSetUtils).IsParamsValid(%compiledclass, .params, .x)) {
		do %code.WriteLine(" do ..%Reload()")
		do %code.WriteLine(" set left = .."_x("LEFT")_", right = .."_x("RIGHT")_", root=.."_x("ROOT")_"")
		do %code.WriteLine(" set nextLevel = 0")
		do %code.WriteLine(" &sql(SELECT TOP 1 """_x("LEVEL")_""", """_x("LEFT")_""", """_x("RIGHT")_""" INTO :nextLevel, :nextLeft, :nextRight FROM "_tablename_" WHERE """_x("ROOT")_"""=:root AND """_x("LEFT")_""">:right ORDER BY """_x("LEFT")_""" ASC)")
		do %code.WriteLine(" if (SQLCODE<0) { return ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg).AsStatus() }")
		do %code.WriteLine(" if ((nextLevel=0)||(nextLevel'=.."_x("LEVEL")_")) { return $$$ERROR(5001,""This node is already the last one"") }")
		do %code.WriteLine(" try {")		
		do %code.WriteLine("     set minus = nextLeft - left")
		do %code.WriteLine("     set plus = nextRight - right")
		do %code.WriteLine("     &sql(START TRANSACTION)")
		do %code.WriteLine("     &sql(SELECT %DLIST(ID) INTO :minuslist  FROM  "_tablename_" WHERE """_x("ROOT")_"""=:root AND """_x("LEFT")_""">=:nextLeft AND """_x("RIGHT")_"""<=:nextRight)")
		do %code.WriteLine("     &sql(SELECT %DLIST(ID) INTO :pluslist  FROM  "_tablename_" WHERE """_x("ROOT")_"""=:root AND """_x("LEFT")_""">=:left AND """_x("RIGHT")_"""<=:right)")
		do %code.WriteLine("     &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_"""="""_x("LEFT")_"""-:minus, """_x("RIGHT")_"""="""_x("RIGHT")_"""-:minus WHERE ID %INLIST :minuslist)")
		do %code.WriteLine("     if (SQLCODE<0) { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg) }")
		do %code.WriteLine("     &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_"""="""_x("LEFT")_"""+:plus, """_x("RIGHT")_"""="""_x("RIGHT")_"""+:plus WHERE ID %INLIST :pluslist)")
		do %code.WriteLine("     if (SQLCODE<0) { throw ##class(%Exception.SQL).CreateFromSQLCODE(SQLCODE, %msg) }")
		do %code.WriteLine("     &sql(COMMIT)")
		do %code.WriteLine(" } catch ex {")
		do %code.WriteLine("     &sql(ROLLBACK)")
		do %code.WriteLine("     return ex.AsStatus()")
		do %code.WriteLine(" }")
		do %code.WriteLine(" return $$$OK")
	}
}

Trigger AfterAddNode [ CodeMode = objectgenerator, Event = INSERT, Foreach = row/object, Time = AFTER ]
{
	set tablename = %compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName
	if (##class(CDEV.NestedSetUtils).IsParamsValid(%compiledclass, .params, .x)) {
		do %code.WriteLine(" new parent, parentRight, parentLevel, id, root, parentID")
		do %code.WriteLine(" set id = {ID}")
        do %code.WriteLine(" set parentID = {"_x("PARENT")_"}")
        do %code.WriteLine(" if (parentID = id) { set %ok=0 set %msg=""a node cannot be a parent for itself"" return  }")
		do %code.WriteLine(" if (parentID'="""") { ")
		do %code.WriteLine("     set parent = ##class("_%compiledclass.Name_").%OpenId(parentID)")
        do %code.WriteLine("     do parent.%Reload()")
		do %code.WriteLine("     set parentRight = parent."_x("RIGHT"))
		do %code.WriteLine("     set parentLevel = parent."_x("LEVEL"))
		do %code.WriteLine("     set root = parent.Root")
		do %code.WriteLine("     &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_""" = """_x("LEFT")_"""+2, """_x("RIGHT")_"""="""_x("RIGHT")_"""+2 WHERE ("""_x("LEFT")_""">:parentRight) AND ("""_x("ROOT")_"""=:root) )")
		do %code.WriteLine("     &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("RIGHT")_""" = """_x("RIGHT")_"""+2 WHERE ("""_x("RIGHT")_""">=:parentRight) AND ("""_x("LEFT")_"""<:parentRight) AND ("""_x("ROOT")_"""=:root) )")
		do %code.WriteLine(" } else { ")
		do %code.WriteLine("     set parentRight = 1 ")
		do %code.WriteLine("     set parentLevel = 0 ")
		do %code.WriteLine("     set root = id ")
		do %code.WriteLine(" } ")
		do %code.WriteLine(" &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_"""=(:parentRight), """_x("RIGHT")_"""=(:parentRight+1), """_x("LEVEL")_"""=(:parentLevel+1), """_x("ROOT")_"""=:root WHERE ID = :id)")
	} else {
		do %code.WriteLine(" set %ok=0 set %msg=""Specify all PARAMETERS "_$LTS(params)_" and recompile class""")
	}
}

/// Prevent changing helper properties
Trigger UpdateNode [ CodeMode = objectgenerator, Event = UPDATE, Foreach = row/object ]
{
	if (##class(CDEV.NestedSetUtils).IsParamsValid(%compiledclass, .params, .x)) {
		do %code.WriteLine(" if (({"_x("LEVEL")_"*C}) || ({"_x("LEFT")_"*C}) || ({"_x("RIGHT")_"*C}) || ({"_x("ROOT")_"*C}) || ({"_x("PARENT")_"*C})) {")
		do %code.WriteLine("     set %ok = 0")
		do %code.WriteLine("     set %msg = ""Special fields (LEFT, RIGHT, ROOT, LEVEL, PARENT) cannot be changed""")
		do %code.WriteLine(" }")
	} else {
		do %code.WriteLine(" set %ok=0 set %msg=""Specify all PARAMETERS "_$LTS(params)_" and recompile class""")
	}
}

Trigger DeleteNode [ CodeMode = objectgenerator, Event = DELETE, Foreach = row/object, Time = AFTER ]
{
	set tablename = %compiledclass.SqlSchemaName_"."_%compiledclass.SqlTableName
	if (##class(CDEV.NestedSetUtils).IsParamsValid(%compiledclass, .params, .x)) {
		do %code.WriteLine(" new left, right, root")
		do %code.WriteLine(" set left = {"_x("LEFT")_"}")
		do %code.WriteLine(" set right = {"_x("RIGHT")_"}")
		do %code.WriteLine(" set root = {"_x("ROOT")_"}")
		do %code.WriteLine(" &sql(DELETE %NOTRIGGER FROM "_tablename_" WHERE """_x("LEFT")_""">:left AND """_x("RIGHT")_"""<:right)")
		do %code.WriteLine(" &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("RIGHT")_"""=("""_x("RIGHT")_"""-(:right-:left+1)) WHERE ("""_x("RIGHT")_""">:right) AND ("""_x("LEFT")_"""<:left) AND ("""_x("ROOT")_"""=:root))")
		do %code.WriteLine(" &sql(UPDATE %NOTRIGGER "_tablename_" SET """_x("LEFT")_"""=("""_x("LEFT")_"""-(:right-:left+1)), """_x("RIGHT")_"""=("""_x("RIGHT")_"""-(:right-:left+1)) WHERE ("""_x("LEFT")_""">:right) AND ("""_x("ROOT")_"""=:root))")
	} else {
		do %code.WriteLine(" set %ok=0 set %msg=""Specify all PARAMETERS "_$LTS(params)_" and recompile class""")
	}
}

}
