package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.noop.NoopClass

class Datas {

	public static val int PTR_PAGE = 0
	public static val int SND_PAGE = 3
	public static val int VAR_PAGE = 4

	@Inject extension Values
	@Inject extension Classes
	@Inject extension Operations

	val loopThreshold = 9
	val labelCounter = new AtomicInteger

	def sizeOf(CompileContext ctx) {
		ctx.type.sizeOf
	}

	def sizeOfOp(CompileContext ctx) {
		ctx.opType.sizeOf
	}

	def resolveTo(CompileContext src, CompileContext dst) {
		switch (dst.mode) {
			case COPY: src.copyTo(dst)
			case POINT: dst.pointTo(src)
			case OPERATE: dst.operateOn(src)
			case REFERENCE: src.referenceInto(dst)
		}
	}

	def copyTo(CompileContext src, CompileContext dst) '''
		«IF src.immediate !== null»
			«IF dst.absolute !== null»
				«src.copyImmediateToAbsolute(dst)»
			«ELSEIF dst.indirect !== null»
				«src.copyImmediateToIndirect(dst)»
			«ELSEIF dst.register !== null»
				«src.copyImmediateToRegister(dst)»
			«ELSEIF dst.relative !== null»
				«src.branchImmediateToRelative(dst)»
			«ENDIF»
		«ELSEIF src.absolute !== null»
			«IF dst.absolute !== null»
				«src.copyAbsoluteToAbsolute(dst)»
			«ELSEIF dst.indirect !== null»
				«src.copyAbsoluteToIndirect(dst)»
			«ELSEIF dst.register !== null»
				«src.copyAbsoluteToRegister(dst)»
			«ELSEIF dst.relative !== null»
				«src.branchAbsoluteToRelative(dst)»
			«ENDIF»
		«ELSEIF src.indirect !== null»
			«IF dst.absolute !== null»
				«src.copyIndirectToAbsolute(dst)»
			«ELSEIF dst.indirect !== null»
				«src.copyIndirectToIndirect(dst)»
			«ELSEIF dst.register !== null»
				«src.copyIndirectToRegister(dst)»
			«ELSEIF dst.relative !== null»
				«src.branchIndirectToRelative(dst)»
			«ENDIF»
		«ELSEIF src.register !== null»
			«IF dst.absolute !== null»
				«src.copyRegisterToAbsolute(dst)»
			«ELSEIF dst.indirect !== null»
				«src.copyRegisterToIndirect(dst)»
			«ELSEIF dst.relative !== null»
				«src.branchRegisterToRelative(dst)»
			«ENDIF»
		«ENDIF»
	'''

	private def copyImmediateToAbsolute(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			«IF dst.isIndexed»
				LDX «dst.index»
			«ENDIF»
			LDA #<(«src.immediate»)
			STA «dst.absolute»«IF dst.isIndexed», X«ENDIF»
			«IF dst.sizeOf > 1»
				LDA #>(«src.immediate»)
				STA «dst.absolute» + 1«IF dst.isIndexed», X«ENDIF»
			«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyImmediateToIndirect(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			LDY «IF dst.isIndexed»«dst.index»«ELSE»#$00«ENDIF»
			LDA #<(«src.immediate»)
			STA («dst.indirect»), Y
			«IF dst.sizeOf > 1»
				LDA #>(«src.immediate»)
				INY
				STA («dst.indirect»), Y
			«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyImmediateToRegister(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«IF dst.sizeOf > 1»
			«noop»
				LDA #>(«src.immediate»)
				PHA
				LDA #<(«src.immediate»)
		«ELSE»
			«noop»
				LDA #(«src.immediate»)
		«ENDIF»
	'''

	private def copyAbsoluteToAbsolute(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«IF dst.sizeOf < loopThreshold»
			«noop»
				«IF src.isIndexed»
					LDY «src.index»
				«ENDIF»
				«IF dst.isIndexed»
					LDX «dst.index»
				«ENDIF»
			«FOR i : 0 ..< Math::min(src.sizeOf, dst.sizeOf)»
				«noop»
					LDA «src.absolute»«IF i > 0» + «i»«ENDIF»«IF src.isIndexed», Y«ENDIF»
					STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
			«ENDFOR»
			«IF src.type.isNumeric»
				«IF src.sizeOf < dst.sizeOf»
					«src.loadMSBFromAcc»
				«ENDIF»
				«FOR i : src.sizeOf ..< dst.sizeOf»
					«noop»
						STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
				«ENDFOR»
			«ENDIF»
		«ELSE»
			«val minSize = '''#«Math::min(src.sizeOf, dst.sizeOf).toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «minSize»
					TAY
					CLC
					LDA «dst.index»
					ADC «minSize»
					TAX
				-«copyLoop»:
					DEY
					DEX
					LDA «src.absolute», Y
					STA «dst.absolute», X
					CPY «src.index»
					BNE -«copyLoop»
			«ELSEIF src.isIndexed || dst.isIndexed»
				«noop»
					LDY «IF src.isIndexed»«src.index»«ELSE»«dst.index»«ENDIF»
					LDX #$00
				-«copyLoop»:
					LDA «src.absolute»«IF src.isIndexed», Y«ELSE», X«ENDIF»
					STA «dst.absolute»«IF dst.isIndexed», Y«ELSE», X«ENDIF»
					INY
					INX
					CPX «minSize»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDX #$00
				-«copyLoop»:
					LDA «src.absolute», X
					STA «dst.absolute», X
					INX
					CPX «minSize»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyAbsoluteToIndirect(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«IF dst.sizeOf < loopThreshold»
			«val minSize = Math::min(src.sizeOf, dst.sizeOf)»
				«IF src.isIndexed»
					LDX «src.index»
				«ENDIF»
				«IF dst.isIndexed»
					LDY «dst.index»
				«ELSE»
					LDY #$00
				«ENDIF»
			«FOR i : 0 ..< minSize»
				«noop»
					LDA «src.absolute»«IF i > 0» + «i»«ENDIF»«IF src.isIndexed», X«ENDIF»
					STA («dst.indirect»), Y
					«IF i < minSize - 1»
						INY
					«ENDIF»
			«ENDFOR»
			«IF src.type.isNumeric»
				«IF src.sizeOf < dst.sizeOf»
					«src.loadMSBFromAcc»
						INY
				«ENDIF»
				«FOR i : src.sizeOf ..< dst.sizeOf»
					«noop»
						STA («dst.indirect»), Y
						«IF i < dst.sizeOf - 1»
							INY
						«ENDIF»
				«ENDFOR»
			«ENDIF»
		«ELSE»
			«val minSize = '''#«Math::min(src.sizeOf, dst.sizeOf).toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «minSize»
					TAX
					CLC
					LDA «dst.index»
					ADC «minSize»
					TAY
				-«copyLoop»:
					DEY
					DEX
					LDA «src.absolute», X
					STA («dst.indirect»), Y
					CPX «src.index»
					BNE -«copyLoop»
			«ELSEIF src.isIndexed || dst.isIndexed»
				«noop»
					LDX «IF src.isIndexed»«src.index»«ELSE»«dst.index»«ENDIF»
					LDY #$00
				-«copyLoop»:
					LDA «src.absolute»«IF src.isIndexed», X«ELSE», Y«ENDIF»
					STA («dst.indirect»«IF dst.isIndexed», X)«ELSE»), Y«ENDIF»
					INX
					INY
					CPX «minSize»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDY #$00
				-«copyLoop»
					LDA «src.absolute», Y
					STA («dst.indirect»), Y
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyAbsoluteToRegister(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«IF src.isIndexed»
			«noop»
				LDX «src.index»
		«ENDIF»
		«IF dst.sizeOf > 1»
			«IF src.sizeOf > 1»
				«noop»
					LDA «src.absolute» + 1«IF src.isIndexed», X«ENDIF»
			«ELSE»
				«src.loadMSB»
			«ENDIF»
			«noop»
				PHA
		«ENDIF»
		«noop»
			LDA «src.absolute»«IF src.isIndexed», X«ENDIF»
	'''

	private def copyIndirectToAbsolute(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«IF dst.sizeOf < loopThreshold»
			«val minSize = Math::min(src.sizeOf, dst.sizeOf)»
				«IF src.isIndexed»
					LDY «src.index»
				«ELSE»
					LDY #$00
				«ENDIF»
				«IF dst.isIndexed»
					LDX «dst.index»
				«ENDIF»
			«FOR i : 0 ..< minSize»
				«noop»
					LDA («src.indirect»), Y
					STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
					«IF i < minSize - 1»
						INY
					«ENDIF»
			«ENDFOR»
			«IF src.type.isNumeric»
				«IF src.sizeOf < dst.sizeOf»
					«src.loadMSBFromAcc»
				«ENDIF»
				«FOR i : src.sizeOf ..< dst.sizeOf»
					«noop»
						STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
				«ENDFOR»
			«ENDIF»
		«ELSE»
			«val minSize = '''#«Math::min(src.sizeOf, dst.sizeOf).toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «minSize»
					TAY
					CLC
					LDA «dst.index»
					ADC «minSize»
					TAX
				-«copyLoop»:
					DEY
					DEX
					LDA («src.indirect»), Y
					STA «dst.absolute», X
					CPY «src.index»
					BNE -«copyLoop»
			«ELSEIF src.isIndexed || dst.isIndexed»
				«noop»
					LDX «IF src.isIndexed»«src.index»«ELSE»«dst.index»«ENDIF»
					LDY #$00
				-«copyLoop»:
					LDA («src.indirect»«IF src.isIndexed», X)«ELSE»), Y«ENDIF»
					STA «dst.absolute»«IF dst.isIndexed», X«ELSE», Y«ENDIF»
					INX
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDY #$00
				-«copyLoop»:
					LDA («src.indirect»), Y
					STA «dst.absolute», Y
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyIndirectToIndirect(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«IF dst.sizeOf < loopThreshold»
			«val minSize = Math::min(src.sizeOf, dst.sizeOf)»
				LDX «IF src.isIndexed»«src.index»«ELSE»#$00«ENDIF»
				LDY «IF dst.isIndexed»«dst.index»«ELSE»#$00«ENDIF»
			«FOR i : 0 ..< minSize»
				«noop»
					LDA («src.indirect», X)
					STA («dst.indirect»), Y
					«IF i < minSize - 1»
						INX
						INY
					«ENDIF»
			«ENDFOR»
			«IF src.type.isNumeric»
				«IF src.sizeOf < dst.sizeOf»
					«src.loadMSBFromAcc»
						INY
				«ENDIF»
				«FOR i : src.sizeOf ..< dst.sizeOf»
					«noop»
						STA («dst.indirect»), Y
						«IF i < dst.sizeOf - 1»
							INY
						«ENDIF»
				«ENDFOR»
			«ENDIF»
		«ELSE»
			«val minSize = '''#«Math::min(src.sizeOf, dst.sizeOf).toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «minSize»
					TAX
					CLC
					LDA «dst.index»
					ADC «minSize»
					TAY
				-«copyLoop»:
					DEY
					DEX
					LDA («src.indirect», X)
					STA («dst.indirect»), Y
					CPX «src.index»
					BNE -«copyLoop»
			«ELSEIF src.isIndexed || dst.isIndexed»
				«noop»
					LDX «IF src.isIndexed»«src.index»«ELSE»«dst.index»«ENDIF»
					LDY #$00
				-«copyLoop»:
					LDA («src.indirect»«IF src.isIndexed», X)«ELSE»), Y«ENDIF»
					STA («dst.indirect»«IF dst.isIndexed», X)«ELSE»), Y«ENDIF»
					INX
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDY #$00
				-«copyLoop»:
					LDA («src.indirect»), Y
					STA («dst.indirect»), Y
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyIndirectToRegister(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«IF dst.sizeOf > 1»
			«IF src.sizeOf > 1»
				«noop»
					«IF src.isIndexed»
						LDY «src.index»
						INY
					«ELSE»
						LDY #$01
					«ENDIF»
					LDA («src.indirect»), Y
					PHA
					DEY
			«ELSE»
				«noop»
					LDY «IF src.isIndexed»«src.index»«ELSE»#$00«ENDIF»
				«src.loadMSB»
					PHA
			«ENDIF»
		«ELSE»
			«noop»
				LDY «IF src.isIndexed»«src.index»«ELSE»#$00«ENDIF»
		«ENDIF»
		«noop»
			LDA («src.indirect»), Y
	'''

	private def copyRegisterToAbsolute(CompileContext src, CompileContext dst) '''
		«noop»
			«IF dst.isIndexed»
				LDX «dst.index»
			«ENDIF»
			STA «dst.absolute»«IF dst.isIndexed», X«ENDIF»
		«IF dst.sizeOf > 1»
			«IF src.sizeOf > 1»
				«noop»
					PLA
			«ELSE»
				«src.loadMSBFromAcc»
			«ENDIF»
			«noop»
				STA «dst.absolute» + 1«IF dst.isIndexed», X«ENDIF»
		«ELSEIF src.sizeOf > 1»
			«noop»
				PLA
		«ENDIF»
	'''

	private def copyRegisterToIndirect(CompileContext src, CompileContext dst) '''
		«noop»
			LDY «IF dst.isIndexed»«dst.index»«ELSE»#$00«ENDIF»
			STA («dst.indirect»), Y
		«IF dst.sizeOf > 1»
			«IF src.sizeOf > 1»
				«noop»
					PLA
			«ELSE»
				«src.loadMSBFromAcc»
			«ENDIF»
			«noop»
				INY
				STA («dst.indirect»), Y
		«ELSEIF src.sizeOf > 1»
			«noop»
				PLA
		«ENDIF»
	'''

	private def branchImmediateToRelative(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			LDA #(«src.immediate»)
			BNE +«dst.relative»
		«dst.pullAccIfOperating»
	'''

	private def branchAbsoluteToRelative(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			«IF src.isIndexed»
				LDX «src.index»
			«ENDIF»
			LDA «src.absolute»«IF src.isIndexed», X«ENDIF»
			BNE +«dst.relative»
		«dst.pullAccIfOperating»
	'''

	private def branchIndirectToRelative(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			LDY «IF src.isIndexed»«src.index»«ELSE»#$00«ENDIF»
			LDA («src.indirect»), Y
			BNE +«dst.relative»
		«dst.pullAccIfOperating»
	'''

	private def branchRegisterToRelative(CompileContext src, CompileContext dst) '''
		«noop»
			BNE +«dst.relative»
	'''

	def copyArrayTo(CompileContext src, CompileContext dst, int len) '''
		«IF src.absolute !== null && dst.absolute !== null»
			«src.copyArrayAbsoluteToAbsoulte(dst, len)»
		«ELSEIF src.absolute !== null && dst.indirect !== null»
			«src.copyArrayAbsoluteToIndirect(dst, len)»
		«ELSEIF src.indirect !== null && dst.absolute !== null»
			«src.copyArrayIndirectToAbsolute(dst, len)»
		«ELSEIF src.indirect !== null && dst.indirect !== null»
			«src.copyArrayIndirectToIndirect(dst, len)»
		«ENDIF»
	'''

	private def copyArrayAbsoluteToAbsoulte(CompileContext src, CompileContext dst, int len) '''
		«dst.pushAccIfOperating»
		«val bytes = len * dst.sizeOf»
		«IF bytes < loopThreshold»
			«noop»
				«IF src.isIndexed»
					LDY «src.index»
				«ENDIF»
				«IF dst.isIndexed»
					LDX «dst.index»
				«ENDIF»
			«FOR i : 0 ..< bytes»
				«noop»
					LDA «src.absolute»«IF i > 0» + «i»«ENDIF»«IF src.isIndexed», Y«ENDIF»
					STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
			«ENDFOR»
		«ELSE»
			«(new CompileContext => [indirect = Members::TEMP_VAR_NAME1]).pointIndirectToAbsolute(src)»
			«(new CompileContext => [indirect = Members::TEMP_VAR_NAME3]).pointIndirectToAbsolute(dst)»
			«bytes.copyArrayIndirectToIndirect»
		«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyArrayAbsoluteToIndirect(CompileContext src, CompileContext dst, int len) '''
		«dst.pushAccIfOperating»
		«(new CompileContext => [indirect = Members::TEMP_VAR_NAME1]).pointIndirectToAbsolute(src)»
		«(new CompileContext => [indirect = Members::TEMP_VAR_NAME3]).pointIndirectToIndirect(dst)»
		«val bytes = len * dst.sizeOf»
		«bytes.copyArrayIndirectToIndirect»
		«dst.pullAccIfOperating»
	'''

	private def copyArrayIndirectToAbsolute(CompileContext src, CompileContext dst, int len) '''
		«dst.pushAccIfOperating»
		«(new CompileContext => [indirect = Members::TEMP_VAR_NAME1]).pointIndirectToIndirect(src)»
		«(new CompileContext => [indirect = Members::TEMP_VAR_NAME3]).pointIndirectToAbsolute(dst)»
		«val bytes = len * dst.sizeOf»
		«bytes.copyArrayIndirectToIndirect»
		«dst.pullAccIfOperating»
	'''

	private def copyArrayIndirectToIndirect(CompileContext src, CompileContext dst, int len) '''
		«dst.pushAccIfOperating»
		«(new CompileContext => [indirect = Members::TEMP_VAR_NAME1]).pointIndirectToIndirect(src)»
		«(new CompileContext => [indirect = Members::TEMP_VAR_NAME3]).pointIndirectToIndirect(dst)»
		«val bytes = len * dst.sizeOf»
		«bytes.copyArrayIndirectToIndirect»
		«dst.pullAccIfOperating»
	'''
	
	private def copyArrayIndirectToIndirect(int bytes) '''
		«val pages = bytes / 0xFF»
		«val frags = bytes % 0xFF»
		«val copyLoop = labelForCopyLoop»
			LDY #0
		«IF pages > 0»
			«noop»
				LDX #«pages»
			--«copyLoop»:
				LDA («Members::TEMP_VAR_NAME1»), Y
				STA («Members::TEMP_VAR_NAME3»), Y
				INY
				BNE -«copyLoop»
				INC «Members::TEMP_VAR_NAME1»
				INC «Members::TEMP_VAR_NAME3»
				DEX
				BNE --«copyLoop»
		«ENDIF»
		«IF frags > 0»
			-«copyLoop»:
				LDA («Members::TEMP_VAR_NAME1»), Y
				STA («Members::TEMP_VAR_NAME3»), Y
				INY
				CPY #«frags»
				BNE -«copyLoop»
		«ENDIF»
	'''

	def fillArrayWith(CompileContext array, CompileContext identity, int len) '''
	'''

	private def fillArrayAbsoluteWithAbsolute(CompileContext array, CompileContext identity, int len) '''
	'''
	
	private def fillArrayIndirect(NoopClass type, int len)'''
		«val copyLoop = labelForCopyLoop»
		«val loops = len - 1»
			LDA #<«loops»
			STA «Members::TEMP_VAR_NAME2»
			«IF loops > 0xFF»
				LDA #>«loops»
				STA «Members::TEMP_VAR_NAME2» + 1
			«ENDIF»
			LDX #<«type.sizeOf»
			LDY #0
		--«copyLoop»:
			LDA («Members::TEMP_VAR_NAME1»), Y
			STA («Members::TEMP_VAR_NAME3»), Y
			DEX
			BEQ +«copyLoop»
		-«copyLoop»:
			INY
			BNE --
			INC «Members::TEMP_VAR_NAME1» + 1
			INC «Members::TEMP_VAR_NAME3» + 1
		+«copyLoop»:
			«IF loops > 0xFF»
				SEC
				LDA «Members::TEMP_VAR_NAME2»
				SBC #1
				SDA «Members::TEMP_VAR_NAME2»
				LDA «Members::TEMP_VAR_NAME2» + 1
				SBC #0
				STA «Members::TEMP_VAR_NAME2» + 1
				CMP #>«loops»
				BNE --«copyLoop»
				LDA «Members::TEMP_VAR_NAME2»
			«ELSE»
				DEC «Members::TEMP_VAR_NAME2»
			«ENDIF»
			CMP #<«loops»
			BNE --«copyLoop»
	'''

	def pointTo(CompileContext ptr, CompileContext src) '''
		«IF src.absolute !== null && ptr.indirect !== null»
			«ptr.pushAccIfOperating»
			«ptr.pointIndirectToAbsolute(src)»
			«ptr.pullAccIfOperating»
		«ELSEIF src.indirect !== null && ptr.indirect !== null»
			«ptr.pushAccIfOperating»
			«ptr.pointIndirectToIndirect(src)»
			«ptr.pullAccIfOperating»
		«ENDIF»
	'''

	private def pointIndirectToAbsolute(CompileContext ptr, CompileContext src) '''
		«noop»
			LDA #<(«src.absolute»)
			«IF src.isIndexed»
				CLC
				ADC «src.index»
			«ENDIF»
			STA «ptr.indirect»
			LDA #>(«src.absolute»)
			«IF src.isIndexed»
				ADC #$00
			«ENDIF»
			STA «ptr.indirect» + 1
	'''

	private def pointIndirectToIndirect(CompileContext ptr, CompileContext src) '''
		«noop»
			LDA «src.indirect»
			«IF src.isIndexed»
				CLC
				ADC «src.index»
			«ENDIF»
			STA «ptr.indirect»
			LDA «src.indirect» + 1
			«IF src.isIndexed»
				ADC #$00
			«ENDIF»
			STA «ptr.indirect» + 1
	'''

	def referenceInto(CompileContext src, CompileContext dst) {
		dst.absolute = src.absolute
		dst.indirect = src.indirect
		dst.index = src.index
	}

	def pushAccIfOperating(CompileContext ctx) '''
		«IF ctx.operation !== null && ctx.isAccLoaded»
			«ctx.accLoaded = false»
				PHA
		«ENDIF»
	'''

	def pullAccIfOperating(CompileContext ctx) '''
		«IF ctx.operation !== null && !ctx.isAccLoaded»
			«ctx.accLoaded = true»
				PLA
		«ENDIF»
	'''

	private def labelForCopyLoop() '''copyLoop«labelCounter.andIncrement»'''

	private def void noop() {
	}

	def computePtr(AllocContext ctx, String varName) {
		computeVar(ctx, varName, PTR_PAGE, 2)
	}

	def computeVar(AllocContext ctx, String varName, int size) {
		computeVar(ctx, varName, VAR_PAGE, size)
	}

	def computeVar(AllocContext ctx, String varName, int page, int size) {
		val chunksByVarName = if(page === PTR_PAGE) ctx.pointers else ctx.variables

		chunksByVarName.compute(varName, [ name, value |
			var chunks = value

			if (chunks === null) {
				chunks = newArrayList(ctx.chunkFor(page, name, size))
			} else if (ctx.counters.get(page).get < chunks.last.hi) {
				ctx.counters.get(page).set(chunks.last.hi + 1)
			}

			return chunks
		])
	}

	def computeTmp(AllocContext ctx, String varName, int size) {
		if (size > 2) {
			ctx.computeVar(varName, VAR_PAGE, size)
		} else {
			ctx.computeVar(varName, PTR_PAGE, size)
		}
	}

	def void disoverlap(Iterable<MemChunk> chunks, String methodName) {
		methodName.debug('--------------------------------')
		methodName.debug('''disoverlaping «methodName»''')
		methodName.debug('''«chunks»:''')

		chunks.forEach [ chunk, index |
			if (chunk.variable.startsWith(methodName)) {
				val outers = chunks.drop(index).reject[variable.startsWith(methodName)]
				var overlapped = true

				while (overlapped) {
					overlapped = false

					for (outer : outers) {
						if (chunk.overlap(outer)) {
							methodName.debug('''«chunk» overlaps «outer»''')
							overlapped = true

							val delta = chunk.deltaFrom(outer)

							chunks.drop(index).filter [
								it.variable.startsWith(methodName)
							].filter [
								it.ZP == chunk.ZP
							].forEach [ inner |
								methodName.debug('''«inner» shift to «delta»''')
								inner.shiftTo(delta)
							]
						}
					}
				}
			}
		]

//		println('''disoverlapped «methodName» to «chunks»''')
//		println('--------------------------------')
	}

	private def debug(String methodName, CharSequence message) {
		val enabled = message === null

		if (enabled && methodName?.contains('$reset')) {
			println(message)
		}
	}
}
