package com.github.parisoft.noop.typing

import com.github.parisoft.noop.NOOPLib
import com.github.parisoft.noop.nOOP.Expression
import com.github.parisoft.noop.nOOP.NOOPFactory
import com.github.parisoft.noop.nOOP.NOOPPackage
import com.github.parisoft.noop.nOOP.SJAssignment
import com.github.parisoft.noop.nOOP.SJBoolConstant
import com.github.parisoft.noop.nOOP.SJClass
import com.github.parisoft.noop.nOOP.SJIntConstant
import com.github.parisoft.noop.nOOP.SJMemberSelection
import com.github.parisoft.noop.nOOP.SJMethod
import com.github.parisoft.noop.nOOP.SJNew
import com.github.parisoft.noop.nOOP.SJNull
import com.github.parisoft.noop.nOOP.SJReturn
import com.github.parisoft.noop.nOOP.SJStringConstant
import com.github.parisoft.noop.nOOP.SJSuper
import com.github.parisoft.noop.nOOP.SJSymbolRef
import com.github.parisoft.noop.nOOP.SJThis
import com.github.parisoft.noop.nOOP.SJVariableDeclaration
import com.google.inject.Inject

import static extension org.eclipse.xtext.EcoreUtil2.*

class NOOPTypeComputer {
private static val factory = NOOPFactory.eINSTANCE
	public static val STRING_TYPE = factory.createSJClass => [name = 'stringType']
	public static val INT_TYPE = factory.createSJClass => [name = 'intType']
	public static val BOOLEAN_TYPE = factory.createSJClass => [name = 'booleanType']
	public static val NULL_TYPE = factory.createSJClass => [name = 'nullType']

	static val ep = NOOPPackage.eINSTANCE

	@Inject extension NOOPLib

	def SJClass typeFor(Expression e) {
		switch (e) {
			SJNew:
				e.type
			SJSymbolRef:
				e.symbol.type
			SJMemberSelection:
				e.member.type
			SJAssignment:
				e.left.typeFor
			SJThis:
				e.getContainerOfType(SJClass)
			SJSuper:
				e.getContainerOfType(SJClass).getSuperclassOrObject
			SJNull:
				NULL_TYPE
			SJStringConstant:
				STRING_TYPE
			SJIntConstant:
				INT_TYPE
			SJBoolConstant:
				BOOLEAN_TYPE
		}
	}

	def getSuperclassOrObject(SJClass c) {
		c.superclass ?: getNoopObjectClass(c)
	}

	def isPrimitive(SJClass c) {
		c.eResource === null
	}

	def expectedType(Expression e) {
		val c = e.eContainer
		val f = e.eContainingFeature
		switch (c) {
			SJVariableDeclaration:
				c.type
			SJAssignment case f == ep.getSJAssignment_Right:
				typeFor(c.left)
			SJReturn:
				c.getContainerOfType(SJMethod).type
			case f == ep.getSJIfStatement_Expression:
				BOOLEAN_TYPE
			SJMemberSelection case f == ep.getSJMemberSelection_Args: {
				// assume that it refers to a method and that there
				// is a parameter corresponding to the argument
				try {
					(c.member as SJMethod).params.get(c.args.indexOf(e)).type
				} catch (Throwable t) {
					null // otherwise there is no specific expected type
				}
			}
		}
	}
}
