package org.parisoft.noop.^extension

import com.google.inject.Inject
import org.parisoft.noop.generator.AllocContext
import org.parisoft.noop.generator.CompileContext
import org.parisoft.noop.generator.MemChunk
import org.parisoft.noop.noop.ByteLiteral
import org.parisoft.noop.noop.StringLiteral
import org.parisoft.noop.noop.Expression

class Datas {

	public static val int PTR_PAGE = 0
	public static val int SND_PAGE = 3
	public static val int VAR_PAGE = 4
	public static val loopThreshold = 9

	@Inject extension Classes
	@Inject extension Variables
	@Inject extension Operations
	@Inject extension Expressions

	def sizeOf(CompileContext ctx) {
		ctx.type.sizeOf
	}

	def sizeOfAsInt(CompileContext ctx) {
		ctx.type.sizeOf as Integer
	}

	def sizeOfOp(CompileContext ctx) {
		ctx.opType.sizeOf as Integer
	}

	def CharSequence resolveTo(CompileContext src, CompileContext dst) {
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
			«ELSEIF dst.db !== null»
				«src.copyImmediateToDb(dst)»
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
			.if «dst.sizeOf» > 1
			LDA #>(«src.immediate»)
			STA «dst.absolute» + 1«IF dst.isIndexed», X«ENDIF»
			.endif
		«dst.pullAccIfOperating»
	'''

	private def copyImmediateToIndirect(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			LDY «IF dst.isIndexed»«dst.index»«ELSE»#$00«ENDIF»
			LDA #<(«src.immediate»)
			STA («dst.indirect»), Y
			.if «dst.sizeOf» > 1
			LDA #>(«src.immediate»)
			INY
			STA («dst.indirect»), Y
			.endif
		«dst.pullAccIfOperating»
	'''

	private def copyImmediateToRegister(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			.if «dst.sizeOf» > 1
			LDA #>(«src.immediate»)
			PHA
			LDA #<(«src.immediate»)
			.else
			LDA #(«src.immediate»)
			.endif
	'''

	private def copyImmediateToDb(CompileContext src, CompileContext dst) '''
		«dst.db»:
			«IF dst.sizeOfAsInt > 1»
				.dw «src.immediate»
			«ELSE»
				.db «src.immediate»
			«ENDIF»
	'''

	private def copyAbsoluteToAbsolute(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			.if «dst.sizeOf» < «loopThreshold»
			«IF src.isIndexed»
				LDY «src.index»
			«ENDIF»
			«IF dst.isIndexed»
				LDX «dst.index»
			«ENDIF»
		a = «src.sizeOf»
		b = «dst.sizeOf»
		i = 0
			.rept min
			LDA «src.absolute» + i«IF src.isIndexed», Y«ENDIF»
			STA «dst.absolute» + i«IF dst.isIndexed», X«ENDIF»
		i = i + 1	
			.endr
		«IF src.type.isNumeric»
			«noop»
				.if «src.sizeOf» < «dst.sizeOf»
			«src.loadMSBFromAcc»
				.endif
			i = «src.sizeOf»
				.rept «dst.sizeOf» - «src.sizeOf»
				STA «dst.absolute» + i«IF dst.isIndexed», X«ENDIF»
			i = i + 1
				.endr
		«ENDIF»
			.else
		a = «src.sizeOf»
		b = «dst.sizeOf»
		«val minSize = '#(min)'»
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
			.endif
		«dst.pullAccIfOperating»
	'''

	private def copyAbsoluteToIndirect(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			.if «dst.sizeOf» < «loopThreshold»
			«IF src.isIndexed»
				LDX «src.index»
			«ENDIF»
			«IF dst.isIndexed»
				LDY «dst.index»
			«ELSE»
				LDY #$00
			«ENDIF»
		a = «src.sizeOf»
		b = «dst.sizeOf»
		i = 0
			.rept min
			LDA «src.absolute» + i«IF src.isIndexed», X«ENDIF»
			STA («dst.indirect»), Y
			.if i < (min) - 1
			INY
			.endif
		i = i + 1
			.endr
		«IF src.type.isNumeric»
			«noop»
				.if «src.sizeOf» < «dst.sizeOf»
			«src.loadMSBFromAcc»
				INY
				.endif
			i = «src.sizeOf»
				.rept «dst.sizeOf» - «src.sizeOf»
				STA («dst.indirect»), Y
				.if i < «dst.sizeOf» - 1
				INY
				.endif
			i = i + 1
				.endr
		«ENDIF»
			.else
		a = «src.sizeOf»
		b = «dst.sizeOf»
		«val minSize = '#(min)'»
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
		«ELSEIF src.isIndexed»
			«noop»
				LDX «src.index»
				LDY #$00
			-«copyLoop»:
				LDA «src.absolute», X
				STA («dst.indirect»), Y
				INX
				INY
				CPY «minSize»
				BNE -«copyLoop»
		«ELSEIF dst.isIndexed»
			«noop»
				LDX #$00
				LDY «dst.index»
			-«copyLoop»:
				LDA «src.absolute», X
				STA («dst.indirect»), Y
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
			.endif
		«dst.pullAccIfOperating»
	'''

	private def copyAbsoluteToRegister(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«IF src.isIndexed»
			«noop»
				LDX «src.index»
		«ENDIF»
			.if «dst.sizeOf» > 1
			.if «src.sizeOf» > 1
			LDA «src.absolute» + 1«IF src.isIndexed», X«ENDIF»
			.else
		«src.loadMSB»
			.endif
			PHA
			.endif
			LDA «src.absolute»«IF src.isIndexed», X«ENDIF»
	'''

	private def copyIndirectToAbsolute(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			.if «dst.sizeOf» < «loopThreshold»
			«IF src.isIndexed»
				LDY «src.index»
			«ELSE»
				LDY #$00
			«ENDIF»
			«IF dst.isIndexed»
				LDX «dst.index»
			«ENDIF»
		a = «src.sizeOf»
		b = «dst.sizeOf»
		i = 0
			.rept min
			LDA («src.indirect»), Y
			STA «dst.absolute» + i«IF dst.isIndexed», X«ENDIF»
			.if i < (min) - 1
			INY
			.endif
		i = i + 1
			.endr
		«IF src.type.isNumeric»
			«noop»
				.if «src.sizeOf» < «dst.sizeOf»
			«src.loadMSBFromAcc»
				.endif
			i = «src.sizeOf»
				.rept «dst.sizeOf» - «src.sizeOf»
				STA «dst.absolute» + i«IF dst.isIndexed», X«ENDIF»
			i = i + 1
				.endr
		«ENDIF»
			.else
		a = «src.sizeOf»
		b = «dst.sizeOf»
		«val minSize = '#(min)'»
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
		«ELSEIF src.isIndexed»
			«noop»
				LDX #$00
				LDY «src.index»
			-«copyLoop»:
				LDA («src.indirect»), Y
				STA «dst.absolute», X
				INX
				INY
				CPX «minSize»
				BNE -«copyLoop»
		«ELSEIF dst.isIndexed»
			«noop»
				LDX «dst.index»
				LDY #$00
			-«copyLoop»:
				LDA («src.indirect»), Y
				STA «dst.absolute», X
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
			.endif
		«dst.pullAccIfOperating»
	'''

	private def copyIndirectToIndirect(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			.if «dst.sizeOf» < «loopThreshold»
			LDA «IF src.isIndexed»«src.index»«ELSE»#$00«ENDIF»
			STA «Members::TEMP_VAR_NAME1»
			LDA «IF dst.isIndexed»«dst.index»«ELSE»#$00«ENDIF»
			STA «Members::TEMP_VAR_NAME3»
		a = «src.sizeOf»
		b = «dst.sizeOf»
		i = 0
			.rept min
			LDY «Members::TEMP_VAR_NAME1»
			LDA («src.indirect»), Y
			LDY «Members::TEMP_VAR_NAME3»
			STA («dst.indirect»), Y
			.if i < (min) - 1
			INC «Members::TEMP_VAR_NAME1»
			INC «Members::TEMP_VAR_NAME3»
			.endif
		i = i + 1
			.endr
		«IF src.type.isNumeric»
			«noop»
				.if «src.sizeOf» < «dst.sizeOf»
			«src.loadMSBFromAcc»
				LDY «Members::TEMP_VAR_NAME3»
				INY
				.endif
			i = «src.sizeOf»
				.rept «dst.sizeOf» - «src.sizeOf»
				STA («dst.indirect»), Y
				.if i < «dst.sizeOf» - 1
				INY
				.endif
			i = i + 1
				.endr
		«ENDIF»
			.else
		a = «src.sizeOf»
		b = «dst.sizeOf»	
		«val minSize = '#(min)'»
		«val copyLoop = labelForCopyLoop»
		«IF src.isIndexed && dst.isIndexed»
			«noop»
				CLC
				LDA «src.index»
				ADC «minSize»
				STA «Members::TEMP_VAR_NAME1»
				CLC
				LDA «dst.index»
				ADC «minSize»
				STA «Members::TEMP_VAR_NAME3»
			-«copyLoop»:
				DEC «Members::TEMP_VAR_NAME1»
				DEC «Members::TEMP_VAR_NAME3»
				LDY «Members::TEMP_VAR_NAME1»
				LDA («src.indirect»), Y
				LDY «Members::TEMP_VAR_NAME3»
				STA («dst.indirect»), Y
				CPY «dst.index»
				BNE -«copyLoop»
		«ELSEIF src.isIndexed»
			«noop»
				LDA «src.index»
				STA «Members::TEMP_VAR_NAME1»
				LDA #$00
				STA «Members::TEMP_VAR_NAME3»
			-«copyLoop»:
				LDY «Members::TEMP_VAR_NAME1»
				LDA («src.indirect»), Y
				INY
				STY «Members::TEMP_VAR_NAME1»
				LDY «Members::TEMP_VAR_NAME3»
				STA («dst.indirect»), Y
				INY
				STY «Members::TEMP_VAR_NAME3»
				CPY «minSize»
				BNE -«copyLoop»
		«ELSEIF dst.isIndexed»
			«noop»
				LDA #$00
				STA «Members::TEMP_VAR_NAME1»
				LDA «dst.index»
				STA «Members::TEMP_VAR_NAME3»
			-«copyLoop»:
				LDY «Members::TEMP_VAR_NAME1»
				LDA («src.indirect»), Y
				LDY «Members::TEMP_VAR_NAME3»
				STA («dst.indirect»), Y
				INY
				STY «Members::TEMP_VAR_NAME3»
				LDY «Members::TEMP_VAR_NAME1»
				INY
				STY «Members::TEMP_VAR_NAME1»
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
			.endif
		«dst.pullAccIfOperating»
	'''

	private def copyIndirectToRegister(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
			.if «dst.sizeOf» > 1
			.if «src.sizeOf» > 1
			«IF src.isIndexed»
				LDY «src.index»
				INY
			«ELSE»
				LDY #$01
			«ENDIF»
			LDA («src.indirect»), Y
			PHA
			DEY
			.else
			LDY «IF src.isIndexed»«src.index»«ELSE»#$00«ENDIF»
		«src.loadMSB»
			PHA
			.endif
			.else
			LDY «IF src.isIndexed»«src.index»«ELSE»#$00«ENDIF»
			.endif
			LDA («src.indirect»), Y
	'''

	private def copyRegisterToAbsolute(CompileContext src, CompileContext dst) '''
		«noop»
			«IF dst.isIndexed»
				LDX «dst.index»
			«ENDIF»
			STA «dst.absolute»«IF dst.isIndexed», X«ENDIF»
			.if «dst.sizeOf» > 1
			.if «src.sizeOf» > 1
			PLA
			.else
		«src.loadMSBFromAcc»
			.endif
			STA «dst.absolute» + 1«IF dst.isIndexed», X«ENDIF»
			.elseif «src.sizeOf» > 1
			PLA
			.endif
	'''

	private def copyRegisterToIndirect(CompileContext src, CompileContext dst) '''
		«noop»
			LDY «IF dst.isIndexed»«dst.index»«ELSE»#$00«ENDIF»
			STA («dst.indirect»), Y
			.if «dst.sizeOf» > 1
			.if «src.sizeOf» > 1
			PLA
			.else
		«src.loadMSBFromAcc»
			.endif
			INY
			STA («dst.indirect»), Y
			.elseif «src.sizeOf» > 1
			PLA
			.endif
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

	def copyArrayTo(CompileContext src, CompileContext dst) '''
		«IF src.absolute !== null && dst.absolute !== null»
			«src.copyArrayAbsoluteToAbsoulte(dst)»
		«ELSEIF src.absolute !== null && dst.indirect !== null»
			«src.copyArrayAbsoluteToIndirect(dst)»
		«ELSEIF src.indirect !== null && dst.absolute !== null»
			«src.copyArrayIndirectToAbsolute(dst)»
		«ELSEIF src.indirect !== null && dst.indirect !== null»
			«src.copyArrayIndirectToIndirect(dst)»
		«ENDIF»
	'''

	private def copyArrayAbsoluteToAbsoulte(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«assignToAandB(src.lengthExpression, dst.lengthExpression)»
		«val bytes = '''((min) * «dst.sizeOf»)'''»
			.if «bytes» < «loopThreshold»
			«IF src.isIndexed»
				LDY «src.index»
			«ENDIF»
			«IF dst.isIndexed»
				LDX «dst.index»
			«ENDIF»
		i = 0
			.rept «bytes»
			LDA «src.absolute» + i«IF src.isIndexed», Y«ENDIF»
			STA «dst.absolute» + i«IF dst.isIndexed», X«ENDIF»
		i = i + 1
			.endr
			.else
		«(new CompileContext => [indirect = Members::TEMP_VAR_NAME1]).pointIndirectToAbsolute(src)»
		«(new CompileContext => [indirect = Members::TEMP_VAR_NAME3]).pointIndirectToAbsolute(dst)»
		«bytes.copyArrayIndirectToIndirect»
			.endif
		«dst.pullAccIfOperating»
	'''

	private def copyArrayAbsoluteToIndirect(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«val tmp1 = new CompileContext => [indirect = Members::TEMP_VAR_NAME1]»
		«val tmp3 = new CompileContext => [indirect = Members::TEMP_VAR_NAME3]»
		«IF (src.lengthExpression instanceof ByteLiteral || src.lengthExpression instanceof StringLiteral) 
		&& (dst.lengthExpression === null || dst.lengthExpression instanceof ByteLiteral || dst.lengthExpression instanceof StringLiteral)»
			«tmp1.pointIndirectToAbsolute(src)»
			«tmp3.pointIndirectToIndirect(dst)»
			«assignToAandB(src.lengthExpression, dst.lengthExpression)»
			«val bytes = '''((min) * «dst.sizeOf»)'''»
			«bytes.copyArrayIndirectToIndirect»
		«ELSE»
			«src.lengthExpression.compile(tmp1 => [
				absolute = indirect
				indirect = null
				type = src.lengthExpression.typeOf
			])»
			«IF dst.lengthExpression !== null»
				«dst.lengthExpression.compile(tmp3 => [
					absolute = indirect
					indirect = null
					type = dst.lengthExpression.typeOf
				])»
				«val reg = new CompileContext => [
					register = 'A'
					type = tmp1.type
				]»
				«tmp1.copyTo(reg)»
				«reg.relative = 'set'»
				«reg.lessThan(tmp3)»
					LDA «tmp3.absolute» + 0
					PHA
					.if «tmp3.sizeOf» > 1
					LDX «tmp3.absolute» + 1
					.else
					LDX #0
					.endif
					JMP +point
			«ENDIF»
			+set:
				LDA «tmp1.absolute» + 0
				PHA
				.if «tmp1.sizeOf» > 1
				LDX «tmp1.absolute» + 1
				.else
				LDX #0
				.endif
			+point:
			«(tmp1 => [indirect = absolute]).pointIndirectToAbsolute(src)»
			«(tmp3 => [indirect = absolute]).pointIndirectToIndirect(dst)»
			«copyArrayIndirectToIndirectByXY»
		«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyArrayIndirectToAbsolute(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«val tmp1 = new CompileContext => [indirect = Members::TEMP_VAR_NAME1]»
		«val tmp3 = new CompileContext => [indirect = Members::TEMP_VAR_NAME3]»
		«IF (src.lengthExpression instanceof ByteLiteral || src.lengthExpression instanceof StringLiteral) 
		&& (dst.lengthExpression === null || dst.lengthExpression instanceof ByteLiteral || dst.lengthExpression instanceof StringLiteral)»
			«tmp1.pointIndirectToIndirect(src)»
			«tmp3.pointIndirectToAbsolute(dst)»
			«assignToAandB(src.lengthExpression, dst.lengthExpression)»
			«val bytes = '''((min) * «dst.sizeOf»)'''»
			«bytes.copyArrayIndirectToIndirect»
		«ELSE»
			«src.lengthExpression.compile(tmp1 => [
				absolute = indirect
				indirect = null
				type = src.lengthExpression.typeOf
			])»
			«IF dst.lengthExpression !== null»
				«dst.lengthExpression.compile(tmp3 => [
					absolute = indirect
					indirect = null
					type = dst.lengthExpression.typeOf
				])»
				«val reg = new CompileContext => [
					register = 'A'
					type = tmp1.type
				]»
				«tmp1.copyTo(reg)»
				«reg.relative = 'set'»
				«reg.lessThan(tmp3)»
					LDA «tmp3.absolute» + 0
					PHA
					.if «tmp3.sizeOf» > 1
					LDX «tmp3.absolute» + 1
					.else
					LDX #0
					.endif
					JMP +point
			«ENDIF»
			+set:
				LDA «tmp1.absolute» + 0
				PHA
				.if «tmp1.sizeOf» > 1
				LDX «tmp1.absolute» + 1
				.else
				LDX #0
				.endif
			+point:
			«(tmp1 => [indirect = absolute]).pointIndirectToIndirect(src)»
			«(tmp3 => [indirect = absolute]).pointIndirectToAbsolute(dst)»
			«copyArrayIndirectToIndirectByXY»
		«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyArrayIndirectToIndirect(CompileContext src, CompileContext dst) '''
		«dst.pushAccIfOperating»
		«val tmp1 = new CompileContext => [indirect = Members::TEMP_VAR_NAME1]»
		«val tmp3 = new CompileContext => [indirect = Members::TEMP_VAR_NAME3]»
		«IF (src.lengthExpression instanceof ByteLiteral || src.lengthExpression instanceof StringLiteral) 
		&& (dst.lengthExpression === null || dst.lengthExpression instanceof ByteLiteral || dst.lengthExpression instanceof StringLiteral)»
			«tmp1.pointIndirectToIndirect(src)»
			«tmp3.pointIndirectToIndirect(dst)»
			«assignToAandB(src.lengthExpression, dst.lengthExpression)»
			«val bytes = '''((min) * «dst.sizeOf»)'''»
			«bytes.copyArrayIndirectToIndirect»
		«ELSE»
			«src.lengthExpression.compile(tmp1 => [
				absolute = indirect
				indirect = null
				type = src.lengthExpression.typeOf
			])»
			«IF dst.lengthExpression !== null»
				«dst.lengthExpression.compile(tmp3 => [
					absolute = indirect
					indirect = null
					type = dst.lengthExpression.typeOf
				])»
				«val reg = new CompileContext => [
					register = 'A'
					type = tmp1.type
				]»
				«tmp1.copyTo(reg)»
				«reg.relative = 'set'»
				«reg.lessThan(tmp3)»
					LDA «tmp3.absolute» + 0
					PHA
					.if «tmp3.sizeOf» > 1
					LDX «tmp3.absolute» + 1
					.else
					LDX #0
					.endif
					JMP +point
			«ENDIF»
			+set:
				LDA «tmp1.absolute» + 0
				PHA
				.if «tmp1.sizeOf» > 1
				LDX «tmp1.absolute» + 1
				.else
				LDX #0
				.endif
			+point:
			«(tmp1 => [indirect = absolute]).pointIndirectToIndirect(src)»
			«(tmp3 => [indirect = absolute]).pointIndirectToIndirect(dst)»
			«copyArrayIndirectToIndirectByXY»
		«ENDIF»
		«dst.pullAccIfOperating»
	'''

	private def copyArrayIndirectToIndirect(String bytes) '''
		«val pages = '''(«bytes» / $FF)'''»
		«val frags = '''(«bytes» % $FF)'''»
		«val copyLoop = labelForCopyLoop»
			LDY #0
			.if «pages» > 0 ; pages
			LDX #«pages»
		--«copyLoop»:
			LDA («Members::TEMP_VAR_NAME1»), Y
			STA («Members::TEMP_VAR_NAME3»), Y
			INY
			BNE --«copyLoop»
			INC «Members::TEMP_VAR_NAME1» + 1
			INC «Members::TEMP_VAR_NAME3» + 1
			DEX
			BNE --«copyLoop»
			.endif
			.if «frags» > 0 ; fragments
		-«copyLoop»:
			LDA («Members::TEMP_VAR_NAME1»), Y
			STA («Members::TEMP_VAR_NAME3»), Y
			INY
			CPY #«frags»
			BNE -«copyLoop»
			.endif
	'''

	private def copyArrayIndirectToIndirectByXY() '''
		«val copyLoop = labelForCopyLoop»
			CPX #0
			BEQ +«copyLoop»
			LDY #0
		--«copyLoop»:
			LDA («Members::TEMP_VAR_NAME1»), Y
			STA («Members::TEMP_VAR_NAME3»), Y
			INY
			BNE --«copyLoop»
			INC «Members::TEMP_VAR_NAME1» + 1
			INC «Members::TEMP_VAR_NAME3» + 1
			DEX
			BNE --«copyLoop»
		+«copyLoop»:
			PLA
			TAY
			BEQ +done
		-«copyLoop»:
			DEY
			LDA («Members::TEMP_VAR_NAME1»), Y
			STA («Members::TEMP_VAR_NAME3»), Y
			CPY #0
			BNE -«copyLoop»
		+done:
	'''

	def fillArray(CompileContext array, int len) '''
		«array.pushAccIfOperating»
		«IF array.absolute !== null»
			«(new CompileContext => [indirect = Members::TEMP_VAR_NAME1]).pointIndirectToAbsolute(array)»
		«ELSEIF array.indirect !== null»
			«(new CompileContext => [indirect = Members::TEMP_VAR_NAME1]).pointIndirectToIndirect(array)»
		«ENDIF»
		«val elementSize = array.type.sizeOf»
			CLC	
			LDA «Members::TEMP_VAR_NAME1» + 0
			ADC #«elementSize»
			STA «Members::TEMP_VAR_NAME3» + 0
			LDA «Members::TEMP_VAR_NAME1» + 1
			ADC #0
			STA «Members::TEMP_VAR_NAME3» + 1
		«copyArrayIndirectToIndirect('''(«elementSize» * «len - 1»)''')»
		«array.pullAccIfOperating»
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
		dst.immediate = src.immediate
		dst.absolute = src.absolute
		dst.indirect = src.indirect
		dst.index = src.index
		''''''
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

	def pushRecusiveVars(CompileContext ctx) '''
		«FOR variable : ctx.recursiveVars»
			«variable.push»
		«ENDFOR»
	'''

	def pullRecursiveVars(CompileContext ctx) '''
		«FOR variable : ctx.recursiveVars»
			«variable.pull»
		«ENDFOR»
		«ctx.recursiveVars.clear»
	'''

	private def labelForCopyLoop() '''copyLoop'''

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
		ctx.computeVar(varName, VAR_PAGE, size).map[it => [tmp = true]]
	}

	def void disoverlap(Iterable<MemChunk> chunks, String methodName) {
		methodName.debug('--------------------------------')
		methodName.debug('''disoverlaping «methodName»''')
		methodName.debug('''«chunks»:''')

		chunks.forEach [ chunk, index |
			if (chunk.variable.startsWith(methodName) && chunk.isNonDisposed) {
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

		chunks.dispose(methodName)
	}

	def void dispose(Iterable<MemChunk> chunks, String methodName) {
		chunks.filter[tmp].filter[variable.startsWith(methodName)].forEach[disposed = true]
	}

	private def debug(String methodName, CharSequence message) {
		val enabled = message === null

		if (enabled && methodName?.contains('$reset')) {
			println(message)
		}
	}

	private def assignToAandB(Expression e1, Expression e2) {
		try {
			'''
				a = «(e1 as ByteLiteral)?.value ?: Integer::MAX_VALUE»
				b = «(e2 as ByteLiteral)?.value ?: Integer::MAX_VALUE»
			'''
		} catch (ClassCastException e) {
			'''
				a = «(e1 as StringLiteral)?.value ?: Integer::MAX_VALUE»
				b = «(e2 as StringLiteral)?.value ?: Integer::MAX_VALUE»
			'''
		}
	}
}
