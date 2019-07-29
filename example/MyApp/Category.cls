Class MyApp.Category Extends (%Persistent, CDEV.NestedSet)
{

Index TreeIndex On (Root, Lft, Rgt);

Parameter LEVEL = "Lvl";

Parameter LEFT = "Lft";

Parameter RIGHT = "Rgt";

Parameter ROOT = "Root";

Parameter PARENT = "Parent";

Property Title As %String;

Property Lft As %Integer;

Property Rgt As %Integer;

Property Lvl As %Integer;

Property Root As %Integer;

Property Parent As MyApp.Category;

ClassMethod PrintTree(nodeId As %Integer) As %Status
{
    try {
        set category = ##class(MyApp.Category).%OpenId(nodeId,,.sc)
        $$$ThrowOnError(sc)
        do category.%Reload()
        set sql = "SELECT ID, Title, Lvl, Lft, Rgt FROM MyApp.Category WHERE Lft >= ? AND Rgt <=? AND Root = ? ORDER BY Lft"
        set stmt = ##class(%SQL.Statement).%New()
        $$$ThrowOnError(stmt.%Prepare(sql))
        set res = stmt.%Execute(category.Lft, category.Rgt, category.Root)
        set rootlevel = 0
        while (res.%Next()) {
            write !
            if (rootlevel=0) { set rootlevel = res.%GetData(3) }
            for i=1:1:(res.%GetData(3)-rootlevel) {
                write " *"
            }
            write " "_res.%GetData(1)_" "_res.%GetData(2)_"(left="_res.%GetData(4)_", right="_res.%GetData(5)_")"
        }
        write !
    } catch ex {
        return ex.AsStatus()
    }
    return $$$OK
}

ClassMethod PrintPath(nodeId As %Integer) As %Status
{
    try {
        set category = ##class(MyApp.Category).%OpenId(nodeId,,.sc)
        $$$ThrowOnError(sc)
        do category.%Reload()
        set sql = "SELECT ID, Title, Lvl, Lft, Rgt FROM MyApp.Category WHERE Lft <= ? AND Rgt >=? AND Root = ? ORDER BY Lft"
        set stmt = ##class(%SQL.Statement).%New()
        $$$ThrowOnError(stmt.%Prepare(sql))
        set res = stmt.%Execute(category.Lft, category.Rgt, category.Root)

        while (res.%Next()) { 
            if (res.%ROWCOUNT=1) { write !} else { write " > " }
            write res.%GetData(2)
        }
        write !
    } catch ex {
        return ex.AsStatus()
    }
    return $$$OK
}

ClassMethod Add(title As %String, parentId As %Integer) As %Status
{
    try {
        set parent = ##class(MyApp.Category).%OpenId(parentId,,.sc)
        $$$ThrowOnError(sc)
        set category = ##class(MyApp.Category).%New()
        set category.Title = title
        $$$ThrowOnError(parent.AddFirstChild(category))       
    } catch ex {
        return ex.AsStatus()
    }
    return $$$OK
}

ClassMethod Populate() As %Status
{
    kill ^MyApp.CategoryD
    kill ^MyApp.CategoryI

    set data(1) = $LB("Books")
    set data(2) = $LB("Business",1)
    set data(3) = $LB("Cookbooks",1)
    set data(4) = $LB("Accounting",2)
    set data(5) = $LB("Economics",2)
    set data(6) = $LB("Investing",2)
    set data(7) = $LB("Dessetrs",3)
    set data(8) = $LB("Special Diet",3)
    set data(9) = $LB("Commodities",6)
    set data(10) = $LB("Real Estate",6)      

    try {
        set id = ""
        for {
            set id = $ORDER(data(id))
            quit:(id="")
            if ($LISTLENGTH(data(id)) = 1 ) {
                // root node
                set category = ##class(MyApp.Category).%New()
                set category.Title = $LI(data(id),1)
                $$$ThrowOnError(category.%Save())
            } else {
                set parent = ##class(MyApp.Category).%OpenId($LI(data(id),2),,.sc)
                $$$ThrowOnError(sc)
                set category = ##class(MyApp.Category).%New()
                set category.Title = $LI(data(id),1)
                set category.Parent = parent
                $$$ThrowOnError(category.%Save())                
            }
            write $LI(data(id),1),!
        }
    } catch ex {
        return ex.AsStatus()
    }
    return $$$OK
}

Storage Default
{
<Data name="CategoryDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Title</Value>
</Value>
<Value name="3">
<Value>Lft</Value>
</Value>
<Value name="4">
<Value>Rgt</Value>
</Value>
<Value name="5">
<Value>Lvl</Value>
</Value>
<Value name="6">
<Value>Parent</Value>
</Value>
<Value name="7">
<Value>Root</Value>
</Value>
</Data>
<DataLocation>^MyApp.CategoryD</DataLocation>
<DefaultData>CategoryDefaultData</DefaultData>
<IdLocation>^MyApp.CategoryD</IdLocation>
<IndexLocation>^MyApp.CategoryI</IndexLocation>
<StreamLocation>^MyApp.CategoryS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
