package org.parisoft.noop.generator.process

import org.eclipse.xtend.lib.annotations.Accessors
import java.util.LinkedHashSet
import org.parisoft.noop.generator.alloc.AllocContext
import org.parisoft.noop.^extension.TypeSystem
import org.parisoft.noop.generator.compile.MetaClass
import java.util.Map
import java.util.HashMap
import java.util.List
import java.util.LinkedHashMap
import java.util.ArrayList
import java.util.HashSet

class ProcessContext {

	@Accessors val classes = new LinkedHashSet<String> => [TypeSystem::LIB_PRIMITIVES.forEach[t|add(t)]]
	@Accessors val statics = new LinkedHashSet<String>
	@Accessors val constants = new LinkedHashSet<String>
	@Accessors val methods = new LinkedHashSet<String>
	@Accessors val constructors = new LinkedHashSet<String>
	@Accessors val alloc = new AllocContext
	@Accessors val sizeOfClasses = new HashMap<String, Integer>
	@Accessors val superClasses = new HashMap<String, List<String>>
	@Accessors val subClasses = new HashMap<String, List<String>>
	@Accessors val recursionDirectives = new HashSet<String>
	@Accessors val callDirectives = new HashMap<String, CharSequence>

	@Accessors var AST ast
	@Accessors var Map<String, MetaClass> metaClasses

	def start(String vector) {
		val entry = ast.vectors.get(vector)
		ast.get(entry)?.forEach[process(this)]
	}

	def finish() {
		for (clazz : classes) {
			sizeOfClasses.put(clazz, clazz.size)
		}

		for (clazz : classes) {
			for (other : classes.filter[it != clazz]) {
				if (other.superClasses.contains(clazz)) {
					subClasses.computeIfAbsent(clazz, [new ArrayList]).add(other)
				}
			}
		}

		for (method : methods) {
			for (call : method.calls) {
				if (method.isCalledBy(call)) {
					recursionDirectives.add('''recursive_«method»_to_«call.methodName» = 1''')
				} else {
					recursionDirectives.add('''recursive_«method»_to_«call.methodName» = 0''')
				}
			}
		}

		for (method : methods) {
			val dot = method.lastIndexOf('.')
			val containerClass = method.substring(0, dot)
			val methodName = method.substring(dot + 1)

			if (!methodName.startsWith('_$') && !methodName.startsWith('$')) {
				val overriders = containerClass.subClasses.filter [ sub |
					val overrideName = '''«sub».«methodName»'''
					sub.metadata?.methods.values.exists[containsKey(overrideName)]
				].toList

				if (overriders.size > 0) {
					val params = ast.get(method)?.filter(NodeVar).filter[param].toList ?: emptyList
					val ret = ast.get(method)?.filter(NodeVar).findFirst[varName.endsWith('.ret')]
					val call = containerClass.getPolymorphicCall(methodName, overriders, params, ret)
					callDirectives.put('''call_«method»''', call)
				} else {
					callDirectives.put('''call_«method»''', '''	JSR «method»''')
				}
			}
		}
	}

	private def int getSize(String clazz) {
		switch (clazz) {
			case TypeSystem::LIB_VOID:
				0
			case TypeSystem::LIB_BYTE:
				1
			case TypeSystem::LIB_SBYTE:
				1
			case TypeSystem::LIB_BOOL:
				1
			case TypeSystem::LIB_INT:
				2
			case TypeSystem::LIB_UINT:
				2
			case TypeSystem::LIB_PRIMITIVE:
				2
			default: {
				val fields = new LinkedHashMap(clazz.metadata?.fields ?: emptyMap)
				clazz.superClasses.map[metadata?.fields ?: emptyMap].forEach[fields.putAll(it)]
				val size = 1 + (fields.values.map[qty * type.size].reduce[a, b|a + b] ?: 0)
				clazz.superClasses.forEach [
					sizeOfClasses.compute(it, [ k, v |
						if (v === null || v < size) {
							size
						} else {
							v
						}
					])
				]

				size
			}
		}
	}

	private def getSubClasses(String clazz) {
		subClasses.get(clazz) ?: emptyList
	}

	private def getSuperClasses(String clazz) {
		superClasses.get(clazz) ?: emptyList
	}

	private def getMetadata(String clazz) {
		metaClasses.get(clazz)
	}

	private def Iterable<NodeCall> getCalls(String entry) {
		ast.get(entry)?.map [
			switch (it) {
				NodeCall: newArrayList(it)
				NodeBeginStmt: statementName.calls
				default: emptyList
			}
		].flatten
	}

	private def boolean isCalledBy(String method, NodeCall node) {
		node.methodName == method || node.methodName.calls.exists[method.isCalledBy(it)]
	}

	private def getPolymorphicCall(String clazz, String method, List<String> overriders, List<NodeVar> params,
		NodeVar ret) '''
		«noop»
			LDY #0
			LDA («clazz».«method».rcv), Y
		«FOR overrider : overriders»
			+	CMP #«overrider».CLASS
				BEQ ++
				JMP +
			++	LDA «clazz».«method».rcv + 0
				STA «overrider».«method».rcv + 0
				LDA «clazz».«method».rcv + 1
				STA «overrider».«method».rcv + 1
			«FOR param : params»
				«val overrideParam = param.varName.replaceFirst(clazz, overrider)»
				«IF param.ptr»
					«noop»
					LDA «param.varName» + 0
					STA «overrideParam» + 0
					LDA «param.varName» + 1
					STA «overrideParam» + 1
				«ELSE»
					i = 0
						.rept «param.type».SIZE
						LDA «param.varName» + i
						STA «overrideParam» + i
					i = i + 1
						.endr
				«ENDIF»
			«ENDFOR»
			«noop»
				JSR «overrider».«method»
			«IF ret !== null»
				«val overrideRet = ret.varName.replaceFirst(clazz, overrider)»
				«IF ret.ptr»
					«noop»
					LDA «overrideRet» + 0
					STA «ret.varName» + 0
					LDA «overrideRet» + 1
					STA «ret.varName» + 1
				«ELSE»
					i = 0
						.rept «ret.type».SIZE
						LDA «overrideRet» + i
						STA «ret.varName» + i
					i = i + 1
						.endr
				«ENDIF»
			«ENDIF»
			«noop»
				JMP +invocation.end
		«ENDFOR»
		+	JSR «clazz».«method»
		+invocation.end:
	'''

	private def void noop() {
	}
}
