package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.List
import java.util.concurrent.ConcurrentHashMap
import org.parisoft.noop.exception.NonConstantMemberException
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.CompileContext.Mode
import org.parisoft.noop.noop.Expression
import org.parisoft.noop.noop.Index
import org.parisoft.noop.noop.MemberRef
import org.parisoft.noop.noop.Method
import org.parisoft.noop.noop.NoopClass
import org.parisoft.noop.noop.StorageType
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.Variable

import static extension java.lang.Character.*
import static extension java.lang.Integer.*

class Variables {

	@Inject extension Tags
	@Inject extension Datas
	@Inject extension Classes
	@Inject extension Members
	@Inject extension Operations
	@Inject extension Statements
	@Inject extension Expressions
	@Inject extension Collections

	static val running = ConcurrentHashMap::<Variable>newKeySet

	def getOverriders(Variable variable) {
		variable.containerClass.subClasses.map[declaredFields.filter[it.isOverrideOf(variable)]].filterNull.flatten
	}

	def getOverriderClasses(Variable variable) {
		newArrayList(variable.containerClass) + variable.containerClass.subClasses.filter [
			declaredFields.forall[!it.isOverrideOf(variable)]
		]
	}

	def isPointer(Variable v) {
		v.typeOf.isNonNumeric || v.dimensionOf.isNotEmpty
	}

	def isParameter(Variable variable) {
		variable.eContainer instanceof Method
	}

	def isField(Variable variable) {
		variable.eContainer instanceof NoopClass
	}

	def isNonField(Variable variable) {
		!variable.isField
	}

	def isNonParameter(Variable variable) {
		!variable.isParameter
	}

	def isConstant(Variable variable) {
		variable.isStatic && variable.name.chars.skip(1).allMatch [
			val c = it as char
			c.isUpperCase || c.isDigit || c === Members::PRIVATE_PREFIX.charAt(0) ||
				c === Members::STATIC_PREFIX.charAt(0)
		]
	}

	def isNonConstant(Variable variable) {
		!variable.isConstant
	}

	def isDMC(Variable variable) {
		val expr = variable.value

		if (expr instanceof StringLiteral) {
			expr.isDmcFile
		} else {
			false
		}
	}

	def isNonDMC(Variable variable) {
		!variable.isDMC
	}

	def isOverride(Variable v) {
		v.containerClass.superClass.allFieldsTopDown.exists[v.isOverrideOf(it)]
	}

	def isOverrideOf(Variable v1, Variable v2) {
		return v1 != v2 && v1.name == v2.name && v1.containerClass.isSubclassOf(v2.containerClass)
	}

	def isINesHeader(Variable variable) {
		variable.isINesPrg || variable.isINesChr || variable.isINesMapper || variable.isINesMir
	}

	def isNonINesHeader(Variable variable) {
		!variable.isINesHeader
	}

	def isINesPrg(Variable variable) {
		variable.storage?.type == StorageType::INESPRG
	}

	def isINesChr(Variable variable) {
		variable.storage?.type == StorageType::INESCHR
	}

	def isINesMapper(Variable variable) {
		variable.storage?.type == StorageType::INESMAPPER
	}

	def isINesMir(Variable variable) {
		variable.storage?.type == StorageType::INESMIR
	}

	def isMapperConfig(Variable variable) {
		variable.storage?.isMapperConfig
	}

	def isNonMapperConfig(Variable variable) {
		!variable.isMapperConfig
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

	def valueOf(Variable variable) {
		if (variable.isNonConstant || (variable.isROM && variable.dimensionOf.isNotEmpty)) {
			throw new NonConstantMemberException
		}

		if (running.add(variable)) {
			try {
				return variable.value.valueOf
			} finally {
				running.remove(variable)
			}
		}
	}

	def nameOfOffset(Variable variable) {
		variable.nameOf
	}

	def nameOfLen(Variable variable, int i) {
		'''«variable.nameOf».len«i»'''.toString
	}

	def nameOfTmpParam(Variable param, Expression arg, String container) {
		'''«container».tmp«param.name.toFirstUpper»@«arg.hashCode.toHexString»'''.toString
	}

	def push(Variable variable) '''
		«IF variable.isParameter && (variable.type.isNonPrimitive || variable.dimension.isNotEmpty)»
			«val pointer = variable.nameOf»
				LDA «pointer» + 1
				PHA
				LDA «pointer» + 0
				PHA
			«FOR i : 0 ..< variable.dimension.size»
				«val len = variable.nameOfLen(i)»
					LDA «len» + 1
					PHA
					LDA «len» + 0
					PHA
			«ENDFOR»
		«ELSE»
			«val local = variable.nameOf»
			«val size = variable.sizeOf»
			«IF size instanceof Integer && (size as Integer) < Datas::loopThreshold»
				«FOR i : size as Integer >.. 0»
					«noop»
						LDA «local»«IF i > 0» + «i»«ENDIF»
						PHA
				«ENDFOR»
			«ELSE»
				«val loop = 'pushLoop'»
					LDX #(«size» - 1)
				-«loop»:
					LDA «local», X
					PHA
					DEX
					BNE -«loop»
			«ENDIF»
		«ENDIF»
	'''

	def pull(Variable variable) '''
		«IF variable.isParameter && (variable.type.isNonPrimitive || variable.dimension.isNotEmpty)»
			«val pointer = variable.nameOf»
				PLA
				STA «pointer» + 0
				PLA
				STA «pointer» + 1
			«FOR i : 0 ..< variable.dimension.size»
				«val len = variable.nameOfLen(i)»
					PLA
					STA «len» + 0
					PLA
					STA «len» + 1
			«ENDFOR»
		«ELSE»
			«val local = variable.nameOf»
			«val size = variable.sizeOf»
			«IF size instanceof Integer && (size as Integer) < Datas::loopThreshold»
				«FOR i : 0 ..< size as Integer»
					«noop»
						PLA
						STA «local»«IF i > 0» + «i»«ENDIF»
				«ENDFOR»
			«ELSE»
				«val loop = 'pushLoop'»
					LDX #0
				-«loop»:
					PLA
					STA «local», X
					INX
					CMP #«size»
					BNE -«loop»
			«ENDIF»
		«ENDIF»
	'''

	def prepareReference(Variable variable, Expression receiver, List<Index> indexes, AllocContext ctx) {
		receiver.prepare(ctx)
		variable.prepare(ctx)
		variable.prepareIndexes(indexes, ctx)
	}
	
	def prepareReference(Variable variable, List<Index> indexes, AllocContext ctx) {
		variable.prepare(ctx)
		variable.prepareIndexes(indexes, ctx)
	}
	

	def allocReference(Variable variable, Expression receiver, List<Index> indexes, AllocContext ctx) {
		val chunks = receiver.alloc(ctx)

		if (variable.overriders.isNotEmpty && receiver.isNonThisNorSuper &&
			!(receiver instanceof MemberRef && (receiver as MemberRef).member instanceof Variable)) {
			chunks += ctx.computePtr(receiver.nameOfTmpVar(ctx.container))
		}

		val rcv = new CompileContext => [
			container = ctx.container
			type = receiver.typeOf
			mode = Mode::REFERENCE
		]

		receiver.compile(rcv)

		val ref = rcv => [
			if (absolute !== null) {
				absolute = '''«rcv.absolute» + #«variable.nameOfOffset»'''
			} else if (indirect !== null) {
				index = '''«IF rcv.index !== null»«rcv.index» + «ENDIF»#«variable.nameOfOffset»'''
			}
		]

		chunks += variable.allocIndexes(indexes, ref, ctx)

		return chunks
	}

	def allocRomReference(Variable variable, List<Index> indexes, AllocContext ctx) {
		val ref = new CompileContext => [absolute = variable.nameOf]
		variable.allocIndexes(indexes, ref, ctx) + variable.alloc(ctx)
	}

	def allocConstantReference(Variable variable, AllocContext ctx) {
		variable.alloc(ctx)
	}

	def allocStaticReference(Variable variable, List<Index> indexes, AllocContext ctx) {
		val ref = new CompileContext => [absolute = variable.nameOf]
		variable.allocIndexes(indexes, ref, ctx) + variable.alloc(ctx)
	}

	def allocPointerReference(Variable variable, String receiver, List<Index> indexes, AllocContext ctx) {
		val ref = new CompileContext => [
			indirect = receiver
			index = if (variable.isNonParameter) '''#«variable.nameOfOffset»'''
		]
		variable.allocIndexes(indexes, ref, ctx)
	}

	def allocLocalReference(Variable variable, List<Index> indexes, AllocContext ctx) {
		val ref = new CompileContext => [absolute = variable.nameOf]
		variable.allocIndexes(indexes, ref, ctx)
	}

	def compileConstant(Variable variable) {
		if (variable.isNonConstant || variable.isROM) {
			throw new NonConstantMemberException
		}

		if (running.add(variable)) {
			try {
				return variable.nameOf
			} finally {
				running.remove(variable)
			}
		}
	}

	def compileReference(Variable variable, Expression receiver, List<Index> indexes, CompileContext ctx) '''
		«val rcv = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.isAccLoaded
			type = receiver.typeOf
			mode = null
		]»
		«val overriders = if (receiver.isNonThisNorSuper) variable.overriders else emptyList»
		«IF overriders.isEmpty»
			«receiver.compile(rcv => [mode = Mode::REFERENCE])»
			«IF rcv.absolute !== null»
				«variable.compileAbsoluteReference(rcv, indexes, ctx)»
			«ELSEIF rcv.indirect !== null»
				«variable.compileIndirectReference(rcv, indexes, ctx)»
			«ENDIF»
		«ELSE»
			«receiver.compile(rcv => [
				if (receiver instanceof MemberRef && (receiver as MemberRef).member instanceof Variable) {
					mode = Mode::REFERENCE
				} else {
					indirect = receiver.nameOfTmpVar(ctx.container)
					mode = Mode::POINT
				}
			])»
			«IF rcv.absolute !== null»
				«ctx.pushAccIfOperating»
					LDA «rcv.absolute»
			«ELSE»
				«ctx.pushAccIfOperating»
					LDY #$00
					LDA («rcv.indirect»), Y
			«ENDIF»
			«val finish = '''reference.end'''»
			«val pullAcc = ctx.pullAccIfOperating»
			«val relative = ctx.relative»
			«val bypass = if (relative !== null) '''«relative».bypass'''»
			«FOR overrider : overriders»
				«FOR container : overrider.overriderClasses»
					«noop»
					+	CMP #«container.nameOf»
						BEQ ++
				«ENDFOR»
				«noop»
					JMP +
				«IF pullAcc.length > 0»
					++«pullAcc»
					«IF rcv.absolute !== null»
						«overrider.compileAbsoluteReference(rcv, indexes, ctx => [it.relative = bypass])»
					«ELSE»
						«overrider.compileIndirectReference(rcv, indexes, ctx => [it.relative = bypass])»
					«ENDIF»
				«ELSE»
					«IF rcv.absolute !== null»
						++«overrider.compileAbsoluteReference(rcv, indexes, ctx => [it.relative = bypass])»
					«ELSE»
						++«overrider.compileIndirectReference(rcv, indexes, ctx => [it.relative = bypass])»
					«ENDIF»
				«ENDIF»
				«noop»
					JMP +«finish»
				«IF relative !== null»
					+«bypass»:
						JMP +«relative»
					«ctx.relative = relative»
				«ENDIF»
			«ENDFOR»
			«IF pullAcc.length > 0»
				+«pullAcc»
				«IF rcv.absolute !== null»
					«variable.compileAbsoluteReference(rcv, indexes, ctx)»
				«ELSE»
					«variable.compileIndirectReference(rcv, indexes, ctx)»
				«ENDIF»
			«ELSE»
				«IF rcv.absolute !== null»
					+«variable.compileAbsoluteReference(rcv, indexes, ctx)»
				«ELSE»
					+«variable.compileIndirectReference(rcv, indexes, ctx)»
				«ENDIF»
			«ENDIF»
			+«finish»:
		«ENDIF»
	'''

	private def compileAbsoluteReference(Variable variable, CompileContext receiver, List<Index> indexes,
		CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = receiver.container
			operation = receiver.operation
			accLoaded = receiver.accLoaded
			absolute = '''«receiver.absolute» + #«variable.nameOfOffset»'''
			index = receiver.index
			type = variable.typeOf
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.lengthExpression = variable.getLengthExpression(indexes)»
			«ref.copyArrayTo(ctx)»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	private def compileIndirectReference(Variable variable, CompileContext receiver, List<Index> indexes,
		CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = receiver.container
			operation = receiver.operation
			accLoaded = receiver.accLoaded
			indirect = receiver.indirect
			type = variable.typeOf
		]»
		«IF receiver.index.isAbsolute»
			«ref.index = receiver.index»
			«ctx.pushAccIfOperating»
				CLC
				LDA «ref.index»
				ADC #«variable.nameOfOffset»
				STA «ref.index»
			«ctx.pullAccIfOperating»
		«ELSEIF receiver.index !== null»
			«ref.index = '''«receiver.index» + #«variable.nameOfOffset»'''»
		«ELSE»
			«ref.index = '''#«variable.nameOfOffset»'''»
		«ENDIF»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.lengthExpression = variable.getLengthExpression(indexes)»
			«ref.copyArrayTo(ctx)»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	def compilePointerReference(Variable variable, String receiver, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.accLoaded
			type = variable.typeOf
			indirect = receiver
			index = if (variable.isNonParameter) '''#«variable.nameOfOffset»'''
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.lengthExpression = variable.getLengthExpression(indexes)»
			«ref.copyArrayTo(ctx)»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	def compileRomReference(Variable variable, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.accLoaded
			type = variable.typeOf
			absolute = variable.nameOf
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.lengthExpression = variable.getLengthExpression(indexes)»
			«ref.copyArrayTo(ctx)»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	def compileConstantReference(Variable variable, CompileContext ctx) '''
		«val const = new CompileContext => [
			container = ctx.container
			type = variable.typeOf
			immediate = variable.nameOf
		]»
		«IF ctx.mode === Mode::OPERATE»
			«ctx.operateOn(const)»
		«ELSEIF ctx.mode === Mode::COPY»
			«const.copyTo(ctx)»
		«ENDIF»
	'''

	def compileStaticReference(Variable variable, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.accLoaded
			type = variable.typeOf
			absolute = variable.nameOf
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.lengthExpression = variable.getLengthExpression(indexes)»
			«ref.copyArrayTo(ctx)»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	def compileLocalReference(Variable variable, List<Index> indexes, CompileContext ctx) '''
		«val ref = new CompileContext => [
			container = ctx.container
			operation = ctx.operation
			accLoaded = ctx.accLoaded
			type = variable.typeOf
			absolute = variable.nameOf
		]»
		«variable.compileIndexes(indexes, ref)»
		«IF ctx.mode === Mode::COPY && variable.isArrayReference(indexes)»
			«ref.lengthExpression = variable.getLengthExpression(indexes)»
			«ref.copyArrayTo(ctx)»
		«ELSE»
			«ref.resolveTo(ctx)»
		«ENDIF»
	'''

	private def isAbsolute(String index) {
		index !== null && index.split('\\+').exists[!trim.startsWith('#')]
	}

	private def void noop() {
	}

}
