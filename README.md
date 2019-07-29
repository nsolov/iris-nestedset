# Nested set model for InterSystems IRIS

Objectscript class that implements basic functionality of the nested set model.

This implementation:
* automatically sets the values of the additional fields Level, Right, Left when: 
    * adding new data (no matter how you add data via SQL or saving an object using the  %Save method)
    * deleting a node (deleting a node deletes all its sub-nodes)
* reorder nodes at one level of the tree
* supports work with several trees (with several roots). Even if you are working with only one tree, you must define the Root property, which will contain the numeric identifier of the root node.

Restrictions:
* only numeric identifiers are supported 
* it is not allowed to specify SqlFieldName for special fields (Parent, Rgt, Lvl, Lft, Root).

### How to Install
1. Import the CDEV.NestedSet class from the repository.
2. Create a persistent class (for example, MyApp.Category) and add CDEV.NestedSet as a superclass to your class.
3. In your class (MyApp.Category) add properties: Parent, Rgt, Lvl, Lft, Root.
4. Override parameters PARENT, LEVEL, ROOT, LEFT, RIGHT. In the values of these parameters, you must specify the names of the corresponding properties in your class.
5. Add an index on Root, Lft, Rgt

```
Index TreeIndex On (Root, Lft, Rgt);
```

6. Compile your class

### How to use
* Use %New(), %Save(), %DeleteId() or SQL queries as usual. To add new node specify Parent property, if you leave Parent property blank - new root will be created
* To add new node you can also use AddFirstChild() or AddLastChild() 
* Use MoveUp() or MoveDown() to reorder siblings

### ObjectScript Example

```
NS > set c = ##class(MyApp.Category).%New()
NS > set c.Title = "root"
NS > write c.%Save()
1
NS > set c1 = ##class(MyApp.Category).%New()
NS > set c1.Title = "node 1"
NS > set c1.Parent = c
NS > write c1.%Save()
1
NS > set c2 = ##class(MyApp.Category).%New()
NS > set c2.Title = "node 2"
NS > do c.AddLastChild(c2)
NS > set c3 = ##class(MyApp.Category).%New()
NS > set c3.Title = "node 1-1"
NS > do c1.AddLastChild(c3)
NS > do ##class(MyApp.Category).PrintTree(c.%Id())

21 root(left=1, right=8)
* 22 node 1(left=2, right=5)
* * 24 node 1-1(left=3, right=4)
* 23 node 2(left=6, right=7)

NS > write c2.MoveUp()
1
NS > do ##class(MyApp.Category).PrintTree(c.%Id())

21 root(left=1, right=8)
* 23 node 2(left=2, right=3)
* 22 node 1(left=4, right=7)
* * 24 node 1-1(left=5, right=6)

NS > do ##class(MyApp.Category).%DeleteId(23)
NS > do ##class(MyApp.Category).PrintTree(c.%Id())

21 root(left=1, right=6)
* 22 node 1(left=2, right=5)
* * 24 node 1-1(left=3, right=4)
```
