/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop.scoping

import com.google.inject.Inject
import java.util.List
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.EReference
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.Scopes
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.^extension.Expressions
import org.parisoft.noop.^extension.Members
import org.parisoft.noop.noop.AsmStatement
import org.parisoft.noop.noop.Block
import org.parisoft.noop.noop.Constructor
import org.parisoft.noop.noop.ConstructorField
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.ForStatement
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NewInstance
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.NoopPackage
import org.parisoft.noop.noop.Variable
import org.eclipse.xtext.scoping.impl.SimpleScope

/**
 * This class contains custom scoping description.
 * 
 * See https://www.eclipse.org/Xtext/documentation/303_runtime_concepts.html#scoping
 * on how and when to use it.
 */
class NoopScopeProvider extends AbstractNoopScopeProvider {

	@Inject extension Expressions
	@Inject extension Classes
	@Inject extension Members
	@Inject extension IQualifiedNameProvider

	override getScope(EObject context, EReference eRef) {
		try {
			switch (context) {
				Block:
					if (eRef == NoopPackage::eINSTANCE.memberRef_Member) {
						return scopeForVariableRef(context, eRef)
					}
				AsmStatement:
					if (eRef == NoopPackage::eINSTANCE.asmStatement_Vars) {
						return scopeForVariableRef(context, eRef)
					}
				Constructor:
					if (eRef == NoopPackage::eINSTANCE.constructorField_Variable) {
						return scopeForNewInstance(context.eContainer as NewInstance, eRef)
					}
				ConstructorField:
					if (eRef == NoopPackage::eINSTANCE.constructorField_Variable) {
						return scopeForNewInstance(context.eContainer.eContainer as NewInstance, eRef)
					} else {
						return scopeForVariableRef(context, eRef)
					}
				MemberRef:
					if (eRef == NoopPackage::eINSTANCE.memberRef_Member) {
						return scopeForMemberRef(context, eRef)
					}
				MemberSelect:
					if (eRef == NoopPackage::eINSTANCE.memberSelect_Member) {
						return scopeForMemberSelect(context)
					}
				Variable:
					if (eRef == NoopPackage::eINSTANCE.newInstance_Type) {
						return scopeForVariableRef(context, eRef)
					}
			}

			return super.getScope(context, eRef)
		} catch (Exception e) {
			System::err.println('''Got a «e». Is eclipse cleaning?''')
			e.printStackTrace(System::err)

			return IScope.NULLSCOPE
		}
	}

	protected def scopeForMemberRef(MemberRef memberRef, EReference eRef) {
		if (memberRef.hasArgs) {
			scopeForMethodInvocation(memberRef, memberRef.args)
		} else {
			scopeForVariableRef(memberRef, eRef)
		}
	}

	protected def IScope scopeForVariableRef(EObject context, EReference ref) {
		val container = context.eContainer

		if (container === null) {
			return IScope.NULLSCOPE
		}

		return switch (container) {
			NoopClass: {
				val thisMembers = container.declaredVariables.takeWhile[it != context] +
					container.declaredMethods.filterOverload(emptyList)
				val superMembers = container.allFieldsTopDown.takeWhile[it != context].toList.reverse +
					container.allMethodsBottomUp.filterOverload(emptyList)
				val classes = super.getScope(container, ref).allElements.filter [
					EClass.name == NoopClass.simpleName
				].toList
				Scopes.scopeFor(thisMembers, Scopes.scopeFor(superMembers, new SimpleScope(classes)))
			}
			NewInstance: {
				val members = container.type.allFieldsBottomUp +
					container.type.allMethodsBottomUp.filterOverload(emptyList)
				Scopes.scopeFor(members, scopeForVariableRef(container, ref))
			}
			Method:
				Scopes.scopeFor(container.params, scopeForVariableRef(container, ref))
			Block: {
				val localVars = container.statements.takeWhile[it != context].filter(Variable)
				Scopes.scopeFor(localVars, scopeForVariableRef(container, ref))
			}
			ForStatement: {
				val localVars = container.variables.takeWhile[it != context]
				Scopes.scopeFor(localVars, scopeForVariableRef(container, ref))
			}
			default:
				scopeForVariableRef(container, ref)
		}
	}

	protected def IScope scopeForMethodInvocation(EObject context, EList<Expression> args) {
		val container = context.eContainer

		if (container === null) {
			return IScope.NULLSCOPE
		}

		return switch (container) {
			NoopClass: {
				val thisMembers = container.members.takeWhile[it != context].filter(Variable) +
					container.declaredMethods.filterOverload(args)
				val superMembers = container.allFieldsBottomUp + container.allMethodsBottomUp.filterOverload(args)
				Scopes.scopeFor(thisMembers, Scopes.scopeFor(superMembers))
			}
			Method:
				Scopes.scopeFor(container.params, scopeForMethodInvocation(container, args))
			Block: {
				val localVars = container.statements.takeWhile[it != context].filter(Variable)
				Scopes.scopeFor(localVars, scopeForMethodInvocation(container, args))
			}
			default:
				scopeForMethodInvocation(container, args)
		}
	}

	protected def scopeForMemberSelect(MemberSelect selection) {
		val receiver = selection.receiver
		val type = receiver.typeOf
		val isArrayReceiver = receiver.dimensionOf.size > selection.indices.size

		if (type === null) {
			IScope.NULLSCOPE
		} else if (isArrayReceiver) {
			Scopes.scopeFor(type.allMethodsBottomUp.filter[nativeArray])
		} else if (receiver instanceof NewInstance && (receiver as NewInstance).constructor === null) {
			val args = selection.args
			val declaredMembers = type.declaredMethods.filter[static].filterOverload(args) + type.declaredVariables.filter [
				static
			]
			val allMembers = type.allMethodsBottomUp.filter[static].filterOverload(args) + type.allFieldsBottomUp.filter [
				static
			]
			Scopes.scopeFor(declaredMembers, Scopes.scopeFor(allMembers))
		} else {
			val args = selection.args
			val declaredMembers = type.declaredMethods.filter[nonStatic].filterOverload(args) +
				type.declaredVariables.filter[nonStatic]
			val allMembers = type.allMethodsBottomUp.filter[nonStatic].filterOverload(args).filter[nonNativeArray] +
				type.allFieldsBottomUp.filter[nonStatic]
			Scopes.scopeFor(declaredMembers, Scopes.scopeFor(allMembers))
		}
	}

	protected def scopeForNewInstance(NewInstance newInstance, EReference ref) {
		val container = newInstance.type
		val fields = container.allFieldsBottomUp.filter[nonStatic]

		return Scopes.scopeFor(fields, scopeForVariableRef(container, ref))
	}

	private def filterOverload(Iterable<Method> methods, List<Expression> args) {
		methods.filter [ method |
			method.params.size == args.size && args.forall [ arg |
				try {
					val index = args.indexOf(arg)
					val param = method.params.get(index)
					val argType = arg.typeOf
					val paramType = param.typeOf

					argType.fullyQualifiedName.toString == paramType.fullyQualifiedName.toString &&
						argType.sizeOf == paramType.sizeOf && arg.dimensionOf.size == param.dimensionOf.size
				} catch (Exception exception) {
					false
				}
			]
		] + methods.filter [ method |
			method.params.size == args.size && args.forall [ arg |
				try {
					val index = args.indexOf(arg)
					val param = method.params.get(index)

					arg.typeOf.isInstanceOf(param.typeOf) && arg.dimensionOf.size == param.dimensionOf.size
				} catch (Exception exception) {
					false
				}
			]
		]
	}

}
