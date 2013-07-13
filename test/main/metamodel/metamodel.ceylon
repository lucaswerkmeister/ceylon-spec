
void test<T>() {
    @type:"Class<NoParams,Empty>" 
    value noParamsType = `NoParams`;
    @type:"Class<Params,Tuple<Integer|String,Integer,Tuple<String,String,Empty>>>" 
    value paramsType = `Params`;
    @type:"Class<ParameterisedClass<Integer>,Empty>" 
    value parameterisedType = `ParameterisedClass<Integer>`;
    @type:"Interface<Interface1>" 
    value interfaceType = `Interface1`;
    @type:"UnionType" 
    value unionType = `Interface1|Interface2`;
    @type:"IntersectionType" 
    value intersectionType = `Interface1&Interface2`;
    @type:"Type" 
    value parameterType = `T`;
    // couldn't find a way to assert that its type is really nothingType since it's an anonymous type
    @type:"Basic&Type" 
    value nothingType = `String&Integer`;
    @type:"Class<NoParams,Empty>" 
    value aliasType = `Alias`;
    
    // members
    @type:"Member<Container,Class<Container.InnerClass,Empty>>"
    value memberClassType = `Container.InnerClass`;
    @type:"Member<Container,Interface<Container.InnerInterface>>"
    value memberInterfaceType = `Container.InnerInterface`;
    @type:"Member<ParameterisedContainer<String>,Class<ParameterisedContainer<String>.InnerClass<Integer>,Empty>>"
    value memberParameterisedClassType = `ParameterisedContainer<String>.InnerClass<Integer>`;
    @type:"Member<ParameterisedContainer<String>,Interface<ParameterisedContainer<String>.InnerInterface<Integer>>>"
    value memberParameterisedInterfaceType = `ParameterisedContainer<String>.InnerInterface<Integer>`;

    // toplevel methods
    @type:"Function<Integer,Tuple<String,String,Empty>>"
    value toplevelMethod = `method`;
    @error:"does not accept type arguments: method"
    value toplevelMethodErr = `method<String>`;
    @error:"function or value does not exist: method"
    value toplevelMethodErr2 = `missingMethod`;
    @type:"Function<Integer,Tuple<String,String,Empty>>"
    value toplevelParameterisedMethod = `parameterisedMethod<Integer,String>`;
    @error:"missing type arguments to: parameterisedMethod"
    value toplevelParameterisedMethodErr = `parameterisedMethod`;
    @type:"Function<Callable<Integer,Tuple<Boolean,Boolean,Empty>>,Tuple<String,String,Empty>>"
    value toplevelMPLMethod = `mplMethod`;

    // qualified methods
    @type:"Member<Container,Function<Anything,Empty>>"
    value containerMethod = `Container.method`;
    @error:"member method or attribute is ambiguous: missing"
    value containerMethodErr = `Container.missing`;
    @type:"Member<ParameterisedContainer<String>,Function<Anything,Tuple<Integer,Integer,Empty>>>"
    value parameterisedContainerMethod = `ParameterisedContainer<String>.method<Integer>`;
    
    // toplevel attributes
    @type:"Attribute<Integer>"
    value toplevelAttribute = `attribute`;
    @error:"does not accept type arguments: attribute"
    value toplevelAttributeErr = `attribute<String>`;
    @type:"Variable<Integer>"
    value toplevelVariableAttribute = `variableAttribute`;

    // qualified attributes
    @type:"Member<Container,Attribute<Integer>>"
    value containerAttribute = `Container.attribute`;
    @type:"Member<Container,Variable<Integer>>"
    value containerVariableAttribute = `Container.variableAttribute`;
    @type:"Member<ParameterisedContainer<String>,Attribute<String>>"
    value parameterisedContainerAttribute = `ParameterisedContainer<String>.attribute`;
    @type:"Member<ParameterisedContainer<String>,Variable<String>>"
    value parameterisedContainerVariableAttribute = `ParameterisedContainer<String>.variableAttribute`;
}


// put them after usage to make sure their types are available when we deal with literals

class NoParams(){}
class Params(Integer i, String s){}
class ParameterisedClass<T>(){}
interface Interface1{}
interface Interface2{}
alias Alias => NoParams;

Integer attribute = 2;
variable Integer variableAttribute = 2;

Integer method(String p){ return 1; }
Integer mplMethod(String p)(Boolean b){ return 1; }
Ret parameterisedMethod<Ret, Arg>(Arg a){ return nothing; }

class Container(){
    shared interface InnerInterface{}
    shared class InnerClass(){}
    shared void method(){}
    shared Integer attribute = 2;
    shared variable Integer variableAttribute = 2;
}

class ParameterisedContainer<Outer>(Outer a){
    shared interface InnerInterface<Inner>{}
    shared class InnerClass<Inner>(){}
    shared void method<Inner>(Inner p){}
    shared Outer attribute = a;
    shared variable Outer variableAttribute = a;
}