package org.parisoft.noop.generator

import com.google.inject.Inject
import java.util.NoSuchElementException
import org.parisoft.noop.^extension.Classes
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopFactory
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.^extension.Members

class MethodCompiler {

	@Inject extension Classes
	@Inject extension Members
	@Inject extension StatementCompiler
	@Inject extension IQualifiedNameProvider

	val running = <Method>newHashSet

	def boolean alloc(Method method, MetaData data) {
		if (running.add(method)) {
			try {
				val prevPtrCounter = data.ptrCounter.get
				val prevVarCounter = data.varCounter.get
				val ptr = method.lowPointer(data)
				val ^var = method.lowVariable(data)

				if (ptr !== null) {
					return true
				}

				if (^var !== null) {
					return true
				}

				val implementingClass = method.containingClass

				if (method.isMain) {
					implementingClass.inheritedFields.filter[nonConstant].forEach[alloc(data)]
				} else {
					method.params.forEach[alloc(data)]
				}

				try {
					method.body.statements.forEach[alloc(data)]
				} catch (PtrMemOverlapException e) {
					return method.rollback(data).alloc(data => [ptrCounter.set(e.chunk.high + 1)])
				} catch (VarMemOverlapException e) {
					return method.rollback(data).alloc(data => [varCounter.set(e.chunk.high + 1)])
				}

				if (implementingClass.isSingleton) {
					data.singletons.add(implementingClass)
				} else {
					data.pointers.get(method).put(NoopFactory::eINSTANCE.createVariable => [
						name = method.fullyQualifiedName.toString + ".receiver"
					], data.chunkForPointer)
				}

				data.classes.add(implementingClass)

				data.ptrCounter.set(prevPtrCounter)
				data.varCounter.set(prevVarCounter)
				
				true
			} finally {
				running.remove(method)
			}
		} else {
			false
		}
	}

	private def lowPointer(Method method, MetaData data) {
		try {
			val ptr = data.pointers.computeIfAbsent(method, [newHashMap]).values.minBy[low]

			if (ptr.low < data.ptrCounter.get) {
				throw new PtrMemOverlapException(data.pointers.get(method).values.maxBy[high])
			}

			return ptr
		} catch (NoSuchElementException e) {
			return null
		}
	}

	private def lowVariable(Method method, MetaData data) {
		try {
			val ^var = data.variables.computeIfAbsent(method, [newHashMap]).values.minBy[low]

			if (^var.low < data.varCounter.get) {
				throw new VarMemOverlapException(data.variables.get(method).values.maxBy[high])
			}

			return ^var
		} catch (NoSuchElementException e) {
			return null
		}
	}

	private def rollback(Method method, MetaData data) {
		data.pointers.remove(method)
		data.variables.remove(method)
		return method
	}

}
