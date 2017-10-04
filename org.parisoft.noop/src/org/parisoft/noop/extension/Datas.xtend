package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.AllocData
import org.parisoft.noop.generator.CompileData
import org.parisoft.noop.generator.MemChunk

class Datas {

	@Inject extension Values
	@Inject extension Classes
	@Inject extension Operations

	val loopThreshold = 9
	val labelCounter = new AtomicInteger

	def int sizeOf(CompileData data) {
		data.type.sizeOf
	}

	def isPointer(CompileData data) {
		data.indirect !== null && !data.isCopy
	}

	def transferTo(CompileData src, CompileData dst) {
		if (dst.operation !== null) {
			dst.operateOn(src)
		} else if (dst.isCopy) {
			src.copyTo(dst)
		} else {
			dst.pointTo(src)
		}
	}

	def copyTo(CompileData src, CompileData dst) '''
		«IF src.immediate !== null»
			«IF dst.absolute !== null»
				«src.copyImmediateToAbsolute(dst)»
			«ELSEIF dst.indirect !== null»
				«src.copyImmediateToIndirect(dst)»
			«ELSEIF dst.register !== null»
				«src.copyImmediateToRegister(dst)»
			«ENDIF»
		«ELSEIF src.absolute !== null»
			«IF dst.absolute !== null»
				«src.copyAbsoluteToAbsolute(dst)»
			«ELSEIF dst.indirect !== null»
				«src.copyAbsoluteToIndirect(dst)»
			«ELSEIF dst.register !== null»
				«src.copyAbsoluteToRegister(dst)»
			«ENDIF»
		«ELSEIF src.indirect !== null»
			«IF dst.absolute !== null»
				«src.copyIndirectToAbsolute(dst)»
			«ELSEIF dst.indirect !== null»
				«src.copyIndirectToIndirect(dst)»
			«ELSEIF dst.register !== null»
				«src.copyIndirectToRegister(dst)»
			«ENDIF»
		«ELSEIF src.register !== null»
			«IF dst.absolute !== null»
				«src.copyRegisterToAbsolute(dst)»
			«ELSEIF dst.indirect !== null»
				«src.copyRegisterToIndirect(dst)»
			«ENDIF»
		«ENDIF»
	'''

	private def copyImmediateToAbsolute(CompileData src, CompileData dst) '''
		«IF dst.isIndexed»
			«noop»
				LDX «dst.index»
		«ENDIF»
		«noop»
			LDA #<(«src.immediate»)
			STA «dst.absolute»«IF dst.isIndexed», X«ENDIF»
		«IF dst.sizeOf > 1»
			«IF src.sizeOf > 1»
				«noop»
					LDA #>(«src.immediate»)
			«ELSE»
				«src.loadMSBFromAcc»
			«ENDIF»
			«noop»
				STA «dst.absolute» + 1«IF dst.isIndexed», X«ENDIF»
		«ENDIF»
	'''

	private def copyImmediateToIndirect(CompileData src, CompileData dst) '''
		«noop»
			LDY «IF dst.isIndexed»«dst.index»«ELSE»#$00«ENDIF»
			LDA #<(«src.immediate»)
			STA («dst.indirect»), Y
		«IF dst.sizeOf > 1»
			«IF src.sizeOf > 1»
				«noop»
					LDA #>(«src.immediate»)
			«ELSE»
				«src.loadMSBFromAcc»
			«ENDIF»
			«noop»
				INY
				STA («dst.indirect»), Y
		«ENDIF»
	'''

	private def copyImmediateToRegister(CompileData src, CompileData dst) '''
		«IF dst.sizeOf > 1»
			«IF src.sizeOf > 1»
				«noop»
					LDA #>(«src.immediate»)
			«ELSE»
				«src.loadMSB»
			«ENDIF»
			«noop»
				PHA
				LDA #<(«src.immediate»)
		«ELSE»
			«noop»
				LDA #«src.immediate»
		«ENDIF»
	'''

	private def copyAbsoluteToAbsolute(CompileData src, CompileData dst) '''
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
			«IF src.sizeOf < dst.sizeOf»
				«src.loadMSBFromAcc»
			«ENDIF»
			«FOR i : src.sizeOf ..< dst.sizeOf»
				«noop»
					STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
			«ENDFOR»
		«ELSE»
			«val minSize = '''#«Math::min(src.sizeOf, dst.sizeOf).byteValue.toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «minSize»
					TAY «src.index»
					CLC
					LDA «dst.index»
					ADC «minSize»
					TAX «dst.index»
				-«copyLoop»
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
				-«copyLoop»
					LDA «src.absolute»«IF src.isIndexed», Y«ELSE», X«ENDIF»
					STA «dst.absolute»«IF dst.isIndexed», Y«ELSE», X«ENDIF»
					INY
					INX
					CPX «minSize»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDX #$00
				-«copyLoop»
					LDA «src.absolute», X
					STA «dst.absolute», X
					INX
					CPX «minSize»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyAbsoluteToIndirect(CompileData src, CompileData dst) '''
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
		«ELSE»
			«val minSize = '''#«Math::min(src.sizeOf, dst.sizeOf).byteValue.toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «minSize»
					TAX «src.index»
					CLC
					LDA «dst.index»
					ADC «minSize»
					TAY «dst.index»
				-«copyLoop»
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
				-«copyLoop»
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
	'''

	private def copyAbsoluteToRegister(CompileData src, CompileData dst) '''
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

	private def copyIndirectToAbsolute(CompileData src, CompileData dst) '''
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
			«IF src.sizeOf < dst.sizeOf»
				«src.loadMSBFromAcc»
			«ENDIF»
			«FOR i : src.sizeOf ..< dst.sizeOf»
				«noop»
					STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
			«ENDFOR»
		«ELSE»
			«val minSize = '''#«Math::min(src.sizeOf, dst.sizeOf).byteValue.toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «minSize»
					TAY «src.index»
					CLC
					LDA «dst.index»
					ADC «minSize»
					TAX «dst.index»
				-«copyLoop»
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
				-«copyLoop»
					LDA («src.indirect»«IF src.isIndexed», X)«ELSE»), Y«ENDIF»
					STA «dst.absolute»«IF dst.isIndexed», X«ELSE», Y«ENDIF»
					INX
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDY «minSize» - 1
				-«copyLoop»
					LDA («src.indirect»), Y
					STA «dst.absolute», Y
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyIndirectToIndirect(CompileData src, CompileData dst) '''
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
		«ELSE»
			«val minSize = '''#«Math::min(src.sizeOf, dst.sizeOf).byteValue.toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «minSize»
					TAX «src.index»
					CLC
					LDA «dst.index»
					ADC «minSize»
					TAY «dst.index»
				-«copyLoop»
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
				-«copyLoop»
					LDA («src.indirect»«IF src.isIndexed», X)«ELSE»), Y«ENDIF»
					STA («dst.indirect»«IF dst.isIndexed», X)«ELSE»), Y«ENDIF»
					INX
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDY #$00
				-«copyLoop»
					LDA («src.indirect»), Y
					STA («dst.indirect»), Y
					INY
					CPY «minSize»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyIndirectToRegister(CompileData src, CompileData dst) '''
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

	private def copyRegisterToAbsolute(CompileData src, CompileData dst) '''
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

	private def copyRegisterToIndirect(CompileData src, CompileData dst) '''
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

	def copyArrayTo(CompileData src, CompileData dst, int len) '''
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

	private def copyArrayAbsoluteToAbsoulte(CompileData src, CompileData dst, int len) '''
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
			«val limit = '''#«bytes.byteValue.toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «limit»
					TAY «src.index»
					CLC
					LDA «dst.index»
					ADC «limit»
					TAX «dst.index»
				-«copyLoop»
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
				-«copyLoop»
					LDA «src.absolute»«IF src.isIndexed», Y«ELSE», X«ENDIF»
					STA «dst.absolute»«IF dst.isIndexed», Y«ELSE», X«ENDIF»
					INY
					INX
					CPX «limit»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDX #$00
				-«copyLoop»
					LDA «src.absolute», X
					STA «dst.absolute», X
					INX
					CPX «limit»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyArrayAbsoluteToIndirect(CompileData src, CompileData dst, int len) '''
		«val bytes = len * dst.sizeOf»
		«IF bytes < loopThreshold»
			«noop»
				«IF src.isIndexed»
					LDX «src.index»
				«ENDIF»
				«IF dst.isIndexed»
					LDY «dst.index»
				«ELSE»
					LDY #$00
				«ENDIF»
			«FOR i : 0 ..< bytes»
				«noop»
					LDA «src.absolute»«IF i > 0» + «i»«ENDIF»«IF src.isIndexed», X«ENDIF»
					STA («dst.indirect»), Y
					«IF i < bytes - 1»
						INY
					«ENDIF»
			«ENDFOR»
		«ELSE»
			«val limit = '''#«bytes.byteValue.toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «limit»
					TAX «src.index»
					CLC
					LDA «dst.index»
					ADC «limit»
					TAY «dst.index»
				-«copyLoop»
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
				-«copyLoop»
					LDA «src.absolute»«IF src.isIndexed», X«ELSE», Y«ENDIF»
					STA («dst.indirect»«IF dst.isIndexed», X)«ELSE»), Y«ENDIF»
					INX
					INY
					CPX «limit»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDY #$00
				-«copyLoop»
					LDA «src.absolute», Y
					STA («dst.indirect»), Y
					INY
					CPY «limit»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyArrayIndirectToAbsolute(CompileData src, CompileData dst, int len) '''
		«val bytes = len * dst.sizeOf»
		«IF bytes < loopThreshold»
			«noop»
				«IF src.isIndexed»
					LDY «src.index»
				«ELSE»
					LDY #$00
				«ENDIF»
				«IF dst.isIndexed»
					LDX «dst.index»
				«ENDIF»
			«FOR i : 0 ..< bytes»
				«noop»
					LDA («src.indirect»), Y
					STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
					«IF i < bytes - 1»
						INY
					«ENDIF»
			«ENDFOR»
		«ELSE»
			«val limit = '''#«bytes.byteValue.toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «limit»
					TAY «src.index»
					CLC
					LDA «dst.index»
					ADC «limit»
					TAX «dst.index»
				-«copyLoop»
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
				-«copyLoop»
					LDA («src.indirect»«IF src.isIndexed», X)«ELSE»), Y«ENDIF»
					STA «dst.absolute»«IF dst.isIndexed», X«ELSE», Y«ENDIF»
					INX
					INY
					CPY «limit»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDY «limit» - 1
				-«copyLoop»
					LDA («src.indirect»), Y
					STA «dst.absolute», Y
					INY
					CPY «limit»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyArrayIndirectToIndirect(CompileData src, CompileData dst, int len) '''
		«val bytes = len * dst.sizeOf»
		«IF bytes < loopThreshold»
			«noop»
				LDX «IF src.isIndexed»«src.index»«ELSE»#$00«ENDIF»
				LDY «IF dst.isIndexed»«dst.index»«ELSE»#$00«ENDIF»
			«FOR i : 0 ..< bytes»
				«noop»
					LDA («src.indirect», X)
					STA («dst.indirect»), Y
					«IF i < bytes - 1»
						INX
						INY
					«ENDIF»
			«ENDFOR»
		«ELSE»
			«val limit = '''#«bytes.byteValue.toHex»'''»
			«val copyLoop = labelForCopyLoop»
			«IF src.isIndexed && dst.isIndexed»
				«noop»
					CLC
					LDA «src.index»
					ADC «limit»
					TAX «src.index»
					CLC
					LDA «dst.index»
					ADC «limit»
					TAY «dst.index»
				-«copyLoop»
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
				-«copyLoop»
					LDA («src.indirect»«IF src.isIndexed», X)«ELSE»), Y«ENDIF»
					STA («dst.indirect»«IF dst.isIndexed», X)«ELSE»), Y«ENDIF»
					INX
					INY
					CPY «limit»
					BNE -«copyLoop»
			«ELSE»
				«noop»
					LDY #$00
				-«copyLoop»
					LDA («src.indirect»), Y
					STA («dst.indirect»), Y
					INY
					CPY «limit»
					BNE -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	def fillArrayWith(CompileData array, CompileData identity, int len) '''
	'''

	private def fillArrayAbsoluteWithAbsolute(CompileData array, CompileData identity, int len) '''
	'''

	def pointTo(CompileData ptr, CompileData src) '''
		«IF src.absolute !== null && ptr.indirect !== null»
			«ptr.pointIndirectToAbsolute(src)»
		«ELSEIF src.indirect !== null && ptr.indirect !== null»
			«ptr.pointIndirectToIndirect(src)»
		«ENDIF»
	'''

	private def pointIndirectToAbsolute(CompileData ptr, CompileData src) '''
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

	private def pointIndirectToIndirect(CompileData ptr, CompileData src) '''
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

	private def labelForCopyLoop() '''copyLoop«labelCounter.andIncrement»:'''

	private def noop() {
	}

	def computePtr(AllocData data, String varName) {
		data.pointers.compute(varName, [ name, value |
			var chunks = value

			if (chunks === null) {
				chunks = newArrayList(data.chunkForPtr(name))
			} else if (data.ptrCounter.get < chunks.last.hi) {
				data.ptrCounter.set(chunks.last.hi + 1)
			}

			return chunks
		])
	}

	def computeVar(AllocData data, String varName, int size) {
		data.variables.compute(varName, [ name, value |
			var chunks = value

			if (chunks === null) {
				chunks = newArrayList(data.chunkForVar(name, size))
			} else if (data.varCounter.get < chunks.last.hi) {
				data.varCounter.set(chunks.last.hi + 1)
			}

			return chunks
		])
	}

	def computeTmp(AllocData data, String varName, int size) {
		if (size > 2) {
			data.variables.compute(varName, [ name, value |
				var chunks = value

				if (chunks === null) {
					chunks = newArrayList(data.chunkForVar(name, size) => [tmp = true])
				} else if (data.varCounter.get < chunks.last.hi) {
					data.varCounter.set(chunks.last.hi + 1)
				}

				return chunks
			])
		} else {
			data.pointers.compute(varName, [ name, value |
				var chunks = value

				if (chunks === null) {
					chunks = newArrayList(data.chunkForZP(name, size) => [tmp = true])
				} else if (data.ptrCounter.get < chunks.last.hi) {
					data.ptrCounter.set(chunks.last.hi + 1)
				}

				return chunks
			])
		}
	}

	def void disoverlap(Iterable<MemChunk> chunks, String methodName) {
//		println('--------------------------------')
//		println('''disoverlaping «methodName» chunks «chunks»''')
		chunks.forEach [ chunk, index |
			if (chunk.variable.startsWith(methodName) && chunk.isNonDisposed) {
				chunks.drop(index).reject [
					it.variable.startsWith(methodName)
				].forEach [ outer |
					if (chunk.overlap(outer)) {
//						println('''«chunk» overlaps «outer»''')
						val delta = chunk.deltaFrom(outer)

						chunks.drop(index).filter [
							it.variable.startsWith(methodName)
						].filter [
							it.ZP == chunk.ZP
						].forEach [ inner |
//							println('''«inner» shift to «delta»''')
							inner.shiftTo(delta)
						]
					}
				]
			}
		]

		chunks.filter[tmp].filter[variable.startsWith(methodName)].forEach[disposed = true]

//		println('''disoverlapped «methodName» to «chunks»''')
//		println('--------------------------------')
	}
}
