/// helper class
Class CDEV.NestedSetUtils
{

ClassMethod IsParamsValid(%compiledclass As %Dictionary.CompiledClass, Output params As %List, Output nestedSetParamsWithValues)
{
    set params = ..GetParams()
    set paramsNumber = ..GetParamValues(%compiledclass, .params, .nestedSetParamsWithValues)
    if (paramsNumber '= $LL(params)) {
        set nestedSetParamsWithValues = ""
        return 0
    }
    return 1
}

ClassMethod GetParams() As %List
{
    set classDef = ##class(%Dictionary.ClassDefinition).%OpenId("CDEV.NestedSet")
    set params = ""
    set key = ""
    for {
        set param = classDef.Parameters.GetNext(.key)
        quit:(key="")
        set params = params_$LB(param.Name)	
    }
    return params
}

/// returns number of notnull params
ClassMethod GetParamValues(%compiledclass As %Dictionary.CompiledClass, params As %List, Output values) As %Integer
{
        set key = ""
        set i = 0
        for {
            set param = %compiledclass.Parameters.GetNext(.key)
            quit:(key="")
            if ($LF(params, param.Name)) {
                if (param.Default'="") {
                    set i=i+1
                    set values(param.Name)=param.Default
                }
            }
            quit:($LL(params)=i) // all params found
        }
        return i
}

}
