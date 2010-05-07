package org.as3commons.emit.bytecode {
import flash.utils.Dictionary;

import org.as3commons.emit.reflect.EmitAccessor;
import org.as3commons.emit.reflect.EmitConstant;
import org.as3commons.emit.reflect.EmitMemberVisibility;
import org.as3commons.emit.reflect.EmitMethod;
import org.as3commons.emit.reflect.EmitType;
import org.as3commons.emit.reflect.EmitTypeUtils;
import org.as3commons.emit.reflect.EmitVariable;
import org.as3commons.emit.reflect.IEmitMember;

public class DynamicClass extends EmitType {
	
	//--------------------------------------------------------------------------
	//
	//  Variables
	//
	//--------------------------------------------------------------------------
	
	private var methodBodies:Dictionary = new Dictionary();
	
	//--------------------------------------------------------------------------
	//
	//  Constructor
	//
	//--------------------------------------------------------------------------
	
	/**
	 * Constructor.
	 */
	public function DynamicClass(qname:QualifiedName, superClassType:EmitType, interfaces:Array, autoGenerateInitializers:Boolean=false) {
		
		super(superClassType.applicationDomain, qname);
		
		this.superClassType = superClassType;
		this.interfaces.concat(interfaces);
		if(autoGenerateInitializers) {
			generateInitializerMethods();
		}
	}
	
	//--------------------------------------------------------------------------
	//
	//  Methods
	//
	//--------------------------------------------------------------------------
	
	public function addField(field:IEmitMember):DynamicClass {
		if(field is EmitConstant) {
			if(field.isStatic) {
				staticConstants.push(field);
			} else {
				constants.push(field);
			}
		} else if(field is EmitVariable) {
			if(field.isStatic) {
				staticVariables.push(field);
			} else {
				variables.push(field);
			}
		}
		return this;
	}
	
	public function addMethod(method:EmitMethod):DynamicClass {
		methods.push(method);
		return this;
	}
	
	public function addMethodBody(methodBody:DynamicMethod):DynamicClass {
		methodBodies[methodBody.method] = methodBody;
		return this;
	}
	
	public function addProperty(property:EmitAccessor):DynamicClass {
		accessors.push(property);
		return this;
	}
	
	public function getMethodBodies():Dictionary {
		return methodBodies;
	}
	
	/**
	 * @private
	 */
	private function generateConstructor():EmitMethod {
		return new EmitMethod(this, "ctor", null, EmitMemberVisibility.PUBLIC, false, false, superClassType.constructorMethod.parameters, EmitTypeUtils.UNTYPED);
	}
	
	public function generateInitializerMethods():void {
		generateConstructor();
		addMethodBody(generateScriptInitializer());
		addMethodBody(generateStaticInitializer());
		addMethodBody(generateInitializer());
	}
	
	/**
	 * @private
	 * Corresponds to the constructor method ClassName()
	 */
	private function generateInitializer():DynamicMethod {
		var argCount:uint = superClassType.constructorMethod.parameters.length;
		var instructions:Array = [
			[Instructions.GetLocal_0],
			[Instructions.PushScope],
			[Instructions.GetLocal_0],
			[Instructions.ConstructSuper, argCount]
		];
			
		/*var fields:Array = getFields(false, true);
		var length:int = fields.length;
		
		for(var a:int = 0; a < length; a++) {
			var field:IEmitMember = fields[a];
			instructions.push([Instructions.GetProperty, field.qname]);
			instructions.push([Instructions.PushString, ""]);
			instructions.push([Instructions.SetProperty, field.qname]);
		}*/
		
		instructions.push([Instructions.ReturnVoid]);
				
		return new DynamicMethod(constructorMethod, 6 + argCount, 3 + argCount, 4, 5, instructions);
	}
	
	/**
	 * @private
	 * Corresponds to the script method init()
	 */
	private function generateScriptInitializer():DynamicMethod {
		var instructions:Array = [
			[Instructions.GetLocal_0],
			[Instructions.PushScope],
			[Instructions.FindPropertyStrict, multiNamespaceName], 
			[Instructions.GetLex, superClassType.qname],
			[Instructions.PushScope],
			[Instructions.GetLex, superClassType.qname],
			[Instructions.NewClass, this],
			[Instructions.PopScope],
			[Instructions.InitProperty, qname],
			[Instructions.ReturnVoid]
		];
		return new DynamicMethod(scriptInitializer, 3, 2, 1, 3, instructions);
	}
	
	/**
	 * @private
	 * Corresponds to the static method cinit()
	 */
	private function generateStaticInitializer():DynamicMethod {
		var instructions:Array = [
			[Instructions.GetLocal_0],
			[Instructions.PushScope]
		];
		
		var fields:Array = getFields(true, false);
		var length:int = fields.length;
		
		for(var a:int = 0; a < length; a++) {
			var field:IEmitMember = fields[a];
			instructions.push([Instructions.FindProperty, field.qname]);
			instructions.push([Instructions.PushString, ""]);
			instructions.push([Instructions.InitProperty, field.qname]);
		}		
		
		instructions.push([Instructions.ReturnVoid]);
		
		return new DynamicMethod(staticInitializer, 1 + length, 2, 1, 2, instructions);
	}	
}
}