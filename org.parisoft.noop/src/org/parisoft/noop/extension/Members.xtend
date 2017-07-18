package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.HashSet
import java.util.List
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.MetaData
import org.parisoft.noop.noop.Member
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelection
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.Variable

import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.noop.NoopFactory

public class Members {

	public static val CONSTANT_SUFFIX = '#'

	@Inject extension Classes
	@Inject extension Expressions
	@Inject extension Statements
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

	val running = new HashSet<Member>
	val allocating = new HashSet<Member>

	def isAccessibleFrom(Member member, EObject context) {
		val contextClass = if (context instanceof MemberSelection) context.receiver.typeOf else context.containingClass
		val memberClass = member.containingClass

		contextClass == memberClass || contextClass.isSubclassOf(memberClass)
	}

	def isParameter(Variable variable) {
		variable.eContainer instanceof Method
	}

	def isNonParameter(Variable variable) {
		!variable.isParameter
	}

	def isConstant(Variable variable) {
		variable.name.startsWith(CONSTANT_SUFFIX)
	}

	def isNonConstant(Variable variable) {
		!variable.isConstant
	}

	def isROM(Variable variable) {
		variable.storage !== null
	}

	def isNonROM(Variable variable) {
		!variable.isROM
	}

	def isMain(Method method) {
		method.containingClass.isGame && method.name == 'main' && method.params.isEmpty
	}

	def isNmi(Method method) {
		method.containingClass.isGame && method.name == 'nmi' && method.params.isEmpty
	}

	def typeOf(Member member) {
		switch (member) {
			Variable: member.typeOf
			Method: member.typeOf
		}
	}

	def typeOf(Variable variable) {
		if (running.add(variable)) {
			try {
				if (variable.type !== null) {
					variable.type
				} else if (variable.value instanceof MemberRef && (variable.value as MemberRef).member === variable) {
					TypeSystem::TYPE_VOID
				} else {
					variable.value.typeOf
				}
			} finally {
				running.remove(variable)
			}
		}
	}

	def typeOf(Method method) {
		if (running.add(method)) {
			try {
				method.body.getAllContentsOfType(ReturnStatement).map[value.typeOf].filterNull.toSet.merge
			} finally {
				running.remove(method)
			}
		}
	}

	def valueOf(Member member) {
		switch (member) {
			Variable: member.valueOf
			Method: member.valueOf
		}
	}

	def valueOf(Variable variable) {
		if (running.add(variable)) {
			try {
				return variable.value.valueOf
			} finally {
				running.remove(variable)
			}
		}
	}

	def valueOf(Method method) {
		throw new NonConstantMemberException
	}

	def List<Integer> dimensionOf(Member member) {
		switch (member) {
			Variable:
				if (member.isParameter) {
					member.dimension.map[1]
				} else {
					member.value.dimensionOf
				}
			Method:
				<Integer>emptyList // methods cannot return arrays?
		}
	}

	def sizeOf(Member member) {
		member.typeOf.sizeOf * (member.dimensionOf.reduce [ d1, d2 |
			d1 * d2
		] ?: 1)
	}

	def asmName(Variable variable, String containerName) {
		if (variable.getContainerOfType(Method) !== null) {
			containerName + variable.fullyQualifiedName.toString.substring(containerName.indexOf('@')) + '@' + Integer.toHexString(variable.hashCode)
		} else {
			containerName + '.' + variable.name + '@' + Integer.toHexString(variable.hashCode)
		}
	}

	def asmName(Method method) {
		method.fullyQualifiedName.toString + '@' + Integer.toHexString(method.hashCode)
	}

	def alloc(Method method, MetaData data) {
		if (allocating.add(method)) {
			try {
				val snapshot = data.snapshot
				val methodName = method.asmName

				data.container = methodName

				val receiver = if (method.containingClass.isNonSingleton) {
						data.pointers.computeIfAbsent(methodName + '.receiver', [newArrayList(data.chunkForPointer(it))])
					} else {
						emptyList
					}

				val chunks = (receiver + method.params.map[alloc(data)].flatten).toList

				if (method.isMain) {
					val constructor = NoopFactory::eINSTANCE.createNewInstance => [
						type = method.containingClass
					]
					
					chunks += constructor.alloc(data)
				}

				chunks += method.body.statements.map[alloc(data)].flatten.toList
				chunks.disoverlap(methodName)

				data.restoreTo(snapshot)

				return chunks
			} finally {
				allocating.remove(method)
			}
		} else {
			newArrayList
		}
	}
	
}
