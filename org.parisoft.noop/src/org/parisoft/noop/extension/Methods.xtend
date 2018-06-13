package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.concurrent.ConcurrentHashMap
import org.eclipse.xtext.naming.IQualifiedNameProvider
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.CompileContext.Mode
import org.parisoft.noop.noop.AssignmentExpression
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.MemberSelect
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.ReturnStatement
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.Variable

import static org.parisoft.noop.^extension.Cache.*

import static extension org.eclipse.xtext.EcoreUtil2.*
import org.parisoft.noop.generator.process.AST
import org.parisoft.noop.generator.process.NodeVar

class Methods {
	
	@Inject extension Datas
	@Inject extension Values
	@Inject extension Classes
	@Inject extension Members 
	@Inject extension Variables
	@Inject extension Statements
	@Inject extension TypeSystem
	@Inject extension Expressions
	@Inject extension Collections
	@Inject extension IQualifiedNameProvider

	static val running = ConcurrentHashMap::<Method>newKeySet
	static val allocating = ConcurrentHashMap::<Method>newKeySet
	
	def getOverriders(Method method) {
		method.containerClass.subClasses.map[declaredMethods.filter[it.isOverrideOf(method)]].filterNull.flatten
	}
	
	def getOverriderClasses(Method method) {
		newArrayList(method.containerClass) + method.containerClass.subClasses.filter[declaredMethods.forall[!it.isOverrideOf(method)]]
	}
	
	def getOverriddenVariablesOnRecursion(Method method, Expression expression) {
		val statement = method.body.statements.findFirst[
			it == expression || eAllContentsAsList.contains(expression)
		]
		
		val localVars = method.params + method.body.statements.takeWhile[it != statement].map[
			newArrayList(it) + eAllContentsAsList
		].flatten.filter(Variable)
		
		return method.body.statements.dropWhile[it != statement].drop(1).map[
			newArrayList(it) + eAllContentsAsList
		].flatten.filter(MemberRef).map[member].filter(Variable).filter[variable|
			localVars.exists[it == variable]
		].toSet
	}
	
	def isOverride(Method m) {
		m.containerClass.superClass.allMethodsTopDown.exists[m.isOverrideOf(it)]
	}
	
	def isNonOverride(Method m) {
		!m.isOverride
	}
	
	def isOverrideOf(Method m1, Method m2) {
		if (m1 != m2
			&& m1.name == m2.name 
			&& m1.params.size == m2.params.size 
			&& m1.containerClass.isSubclassOf(m2.containerClass)) {
			for (i : 0 ..< m1.params.size) {
				val p1 = m1.params.get(i)
				val p2 = m2.params.get(i)
				
				if (p1.type.isNotEquals(p2.type)) {
					return false
				}
				
				if (p1.dimensionOf.size != p2.dimensionOf.size) {
					return false
				}
			}

			return true
		}
		
		return false
	}

	def isVector(Method m) {
		m.isIrq || m.isNmi || m.isReset
	}
	
	def isNonVector(Method m) {
		!m.isVector
	}
		
	def isObjectSize(Method method) {
		method.containerClass.isObject && method.name == 'size' && method.params.isEmpty
	}
	
	def isInline(Method method) {
		method.storage?.type == StorageType::INLINE
	}
	
	def isNonInline(Method method) {
		!method.isInline
	}
	
	def isNative(Method method) {
		val methodContainer = method.containerClass.fullyQualifiedName.toString
		return (methodContainer == TypeSystem.LIB_OBJECT || methodContainer == TypeSystem.LIB_PRIMITIVE) 
		&& (method.name == Members::METHOD_ARRAY_LENGTH /*put other native methods here separated by || */)
	}
	
	def isNonNative(Method method) {
		!method.isNative
	}
	
	def isNativeArray(Method method) {
		method.isNative && (method.name == Members::METHOD_ARRAY_LENGTH /*put other array methods here separated by || */)
	}
	
	def isNonNativeArray(Method method) {
		!method.isNativeArray
	}
	
	def isArrayLength(Method method) {
		method.isNativeArray && method.name == Members::METHOD_ARRAY_LENGTH
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
	
	def List<Integer> dimensionOf(Method method) {
		if (running.add(method)) {
			try {
				method.body.getAllContentsOfType(ReturnStatement).head?.dimensionOf ?: emptyList
			} finally {
				running.remove(method)
			}
		} else {
			emptyList
		}
	}
	
	def nameOfReceiver(Method method) {
		'''«method.nameOf».rcv'''.toString
	}
	
	def nameOfReturn(Method method) {
		'''«method.nameOf».ret'''.toString
	}
	
	def void preProcess(Method method, AST ast) {
		val container = ast.container
		ast.container = method.nameOf
		
		if (method.isNonStatic) {
			ast.append(new NodeVar => [
				varName = method.nameOfReceiver
				ptr = true
			])
		}
		
		method.params.forEach[preProcess(ast)]
		method.body.statements.forEach[preProcess(ast)]
		
		ast.container = container
	}
	
	def void prepare(Method method, AllocContext ctx) {
		if (prepared.add(method)) {
			val ini = System::currentTimeMillis
			method.body.statements.forEach[prepare(ctx)]
			println('''prepared «method.containerClass.name».«method.name» = «System::currentTimeMillis - ini»ms''')
		}
	}
	
	def void prepareInvocation(Method method, Expression receiver, List<Expression> args, List<Index> indexes, AllocContext ctx) {
		if (method.isNative) {
			return
		}

		if (receiver !== null) {
			receiver.prepare(ctx)
		}
		
		args.forEach [ arg, i |
			if (arg.containsMulDivMod) {
				try {
					arg.prepare(ctx => [types.put(method.params.get(i).type)])
				} finally {
					ctx.types.pop
				}
			} else {
				arg.prepare(ctx)
			}
		]
		
		method.prepare(ctx)
		
		if (receiver !== null && receiver.isNonSuper) {
			method.overriders.forEach[prepare(ctx)]
		}

		method.prepareIndexes(indexes, ctx)
	}
	
	def prepareInvocation(Method method, List<Expression> args, List<Index> indexes, AllocContext ctx) {
		method.prepareInvocation(null, args, indexes, ctx)
	}
	
	def alloc(Method method, AllocContext ctx) {
		if (allocating.add(method)) {
			try {
				allocated.get(method, [
					val snapshot = ctx.snapshot
					val methodName = method.nameOf
	
					ctx.container = methodName
	
					val receiver = if (method.isNonStatic) {
							ctx.computePtr(method.nameOfReceiver)
						} else {
							emptyList
						}
	
					val chunks = (receiver + method.params.map[alloc(ctx)].flatten).toList
					chunks += method.body.statements.map[alloc(ctx)].flatten.toList
					chunks.disoverlap(methodName)
	
					ctx.restoreTo(snapshot)
					ctx.methods.put(method.nameOf, method)
	
					return chunks
				])
			} finally {
				allocating.remove(method)
			}
		} else {
			newArrayList
		}
	}
	
	def allocInvocation(Method method, Expression receiver, List<Expression> args, List<Index> indexes, AllocContext ctx) {
		val chunks = newArrayList
		
		if (method.isNative) {
			return chunks
		}
		
		val methodChunks = method.alloc(ctx)
		
		if (method.overriders.isNotEmpty && receiver.isNonSuper) {
			methodChunks += method.overriders.map[alloc(ctx)].flatten.toList
		}
		
		if (receiver !== null) {
			chunks += receiver.alloc(ctx)
		}

		args.forEach [ arg, i |
			if (arg.containsMulDivMod) {
				try {
					chunks += arg.alloc(ctx => [types.put(method.params.get(i).type)])
				} finally {
					ctx.types.pop
				}
			} else {
				chunks += arg.alloc(ctx)
			}
			
			if (arg.containsMethodInvocation && !arg.isComplexMemberArrayReference) {
				chunks += ctx.computeTmp(method.params.get(i).nameOfTmpParam(arg, ctx.container), arg.fullSizeOf as Integer)
			}
		]

		chunks += method.allocIndexes(indexes, new CompileContext => [indirect = method.nameOfReturn], ctx)
		chunks += methodChunks

		return chunks
	}
	
	def allocInvocation(Method method, List<Expression> args, List<Index> indexes, AllocContext ctx) {
		method.allocInvocation(null, args, indexes, ctx)
	}
	
	def compile(Method method, CompileContext ctx) '''
		«IF method.isNonNative && method.isNonInline»
			«method.nameOf»:
			«IF method.isReset»
				;;;;;;;;;; Initial setup begin
				«IF ctx.allocation.constants.values.findFirst[INesMapper]?.valueOf ?: 0 as Integer == 4»
					CLI          ; enable IRQs
				«ELSE»
					SEI          ; disable IRQs
				«ENDIF»
				CLD          ; disable decimal mode
				LDX #$40
				STX $4017    ; disable APU frame IRQ
				LDX #$FF
				TXS          ; Set up stack
				INX          
				STX $2000    ; disable NMI
				STX $2001    ; disable rendering
				STX $4010    ; disable DMC IRQs
			
			-waitVBlank1:
				BIT $2002
				BPL -waitVBlank1
			
			-clrMem:
				LDA #$00
				STA $0000, X
				STA $0100, X
				STA $0300, X
				STA $0400, X
				STA $0500, X
				STA $0600, X
				STA $0700, X
				LDA #$FE
				STA $0200, X
				INX
				BNE -clrMem:

				; Instantiate all static variables
			«val resetMethod = method.nameOf»
			«FOR staticVar : ctx.allocation.statics.values»
				«staticVar.compile(new CompileContext => [container = resetMethod])»
			«ENDFOR»
			
			-waitVBlank2:
				BIT $2002
				BPL -waitVBlank2
				;;;;;;;;;; Initial setup end
			
			«FOR statement : method.body.statements»
				«statement.compile(new CompileContext => [container = method.nameOf])»
			«ENDFOR»
				RTS
			«ELSEIF method.isNmi || method.isIrq»
				PHA
				TXA
				PHA
				TYA
				PHA
			«FOR statement : method.body.statements»
				«statement.compile(new CompileContext => [container = method.nameOf])»
			«ENDFOR»
				PLA
				TAY
				PLA
				TAX
				PLA
				RTI
			«ELSE»
				«FOR statement : method.body.statements»
					«statement.compile(new CompileContext => [container = method.nameOf])»
				«ENDFOR»
					RTS
			«ENDIF»
		«ENDIF»
	'''
	
	def compileInvocation(Method method, List<Expression> args, List<Index> indexes, CompileContext ctx) '''
		«IF method.isNonNative»
			«ctx.pushAccIfOperating»
			«ctx.pushRecusiveVars»
			«val tmps = newArrayList»
			«tmps.add(0, null)»
			«FOR i : 0 ..< args.size»
				«val param = method.params.get(i)»
				«val arg = args.get(i)»
				«IF arg.containsMethodInvocation»
					«val tmp = new CompileContext => [
						container = ctx.container
						type = param.type
						
						if (arg.isComplexMemberArrayReference) {
							mode = Mode::REFERENCE							
						} else {
							absolute = param.nameOfTmpParam(arg, ctx.container)
							mode = Mode::COPY
						}
					]»
					«tmps.add(i, tmp)»
					«arg.compile(tmp)»
				«ELSE»
					«tmps.add(i, null)»
				«ENDIF»
			«ENDFOR»
			«FOR i : 0 ..< args.size»
				«val param = method.params.get(i)»
				«val arg = args.get(i)»
				«val tmpCtx = tmps.get(i)»
				«val paramCtx = new CompileContext => [
					container = ctx.container
					type = param.type
					
					if (param.type.isPrimitive && param.dimensionOf.isEmpty) {
						absolute = param.nameOf
						mode = Mode::COPY
					} else {
						indirect = param.nameOf
						mode = Mode::POINT
					}
				]»
				«IF tmpCtx !== null»
					«tmpCtx.resolveTo(paramCtx)»
				«ELSE»
					«arg.compile(paramCtx)»
				«ENDIF»
				«IF param.isUnbounded»
					«IF arg.isUnbounded»
						«val member = if (arg instanceof MemberRef) {
							arg.member as Variable
						} else if (arg instanceof MemberSelect) {
							arg.member as Variable
						} else if (arg instanceof AssignmentExpression) {
							arg.member as Variable
						}»
						«val initIndex = if (arg instanceof MemberRef) {
							arg.indexes.size
						} else if (arg instanceof MemberSelect) {
							arg.indexes.size
						} else {
							0
						}»
						«IF member !== null»
							«FOR src : initIndex ..< member.dimensionOf.size»
								«val dst = src - initIndex»
									LDA «member.nameOfLen(src)» + 0
									STA «param.nameOfLen(dst)» + 0
									LDA «member.nameOfLen(src)» + 1
									STA «param.nameOfLen(dst)» + 1
							«ENDFOR»
						«ENDIF»
					«ELSE»
						«val dimension = arg.dimensionOf»
						«FOR dim : 0..< dimension.size»
							«val len = dimension.get(dim).toHex»
								LDA #<«len»
								STA «param.nameOfLen(dim)» + 0
								LDA #>«len»
								STA «param.nameOfLen(dim)» + 1
						«ENDFOR»
					«ENDIF»
				«ENDIF»
			«ENDFOR»
			«IF method.isInline»
				«FOR statement : method.body.statements»
					«statement.compile(new CompileContext => [container = method.nameOf])»
				«ENDFOR»
			«ELSE»
				«noop»
					JSR «method.nameOf»
			«ENDIF»
			«ctx.pullRecursiveVars»
			«ctx.pullAccIfOperating»
			«IF method.typeOf.isNonVoid»
				«val ret = new CompileContext => [
					container = ctx.container
					type = method.typeOf
					
					if (method.typeOf.isPrimitive && method.dimensionOf.isEmpty) {
						absolute = method.nameOfReturn
					} else {
						indirect = method.nameOfReturn
					}
				]»
				«method.compileIndexes(indexes, ret)»
«««				;TODO if ctx is indirect (mode POINT) then copy ret to a aux var then point to ctx
				«IF ctx.mode === Mode::COPY && method.isArrayReference(indexes)»
					«ret.lengthExpression = method.getLengthExpression(indexes)»
					«ret.copyArrayTo(ctx)»
				«ELSE»
					«ret.resolveTo(ctx)»
				«ENDIF»
			«ENDIF»
		«ENDIF»
	'''
	
	def compileNativeInvocation(Method method, Expression receiver, List<Expression> args, CompileContext ctx) '''
«««		;TODO compile receiver by copying it, removing indexes, and call receiver.compile with a new context moded as null
		«IF method.name == Members::METHOD_ARRAY_LENGTH»
			«val member = if (receiver instanceof MemberRef) {
				receiver.member
			} else if (receiver instanceof MemberSelect) {
				receiver.member
			} else if (receiver instanceof AssignmentExpression) {
				receiver.member
			}»
			«IF member !== null && member instanceof Variable && (member as Variable).isUnbounded»
				«val idx = if (receiver instanceof MemberRef) {
					receiver.indexes.size
				 } else if (receiver instanceof MemberSelect) {
				 	receiver.indexes.size
				 } else {
				 	0
				 }»
				«val len = new CompileContext => [
					container = ctx.container
					type = ctx.type.toUIntClass
					absolute = (member as Variable).nameOfLen(idx)
				]»
				«len.resolveTo(ctx)»
			«ELSE»
				«val len = new CompileContext => [
					container = ctx.container
					type = ctx.type.toUIntClass
					immediate = receiver.dimensionOf.head.toString
				]»
				«len.resolveTo(ctx)»
			«ENDIF»
		«ENDIF»
	'''
	
	private def void noop() {
	}
}