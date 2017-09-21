package org.parisoft.noop.^extension

import com.google.inject.Inject
import java.util.concurrent.atomic.AtomicInteger
import org.parisoft.noop.generator.CompileData

class Datas {

	@Inject extension Classes
	@Inject extension Values

	val loopThreshold = 8
	val labelCounter = new AtomicInteger

	def int sizeOf(CompileData data) {
		data.type.sizeOf
	}

	def isPointer(CompileData data) {
		data.indirect !== null && !data.isCopy
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
			«ELSEIF src.type.isSigned»
				«val signLabel = labelForSignedComplementEnd»
					ORA #$7F
					BMI +«signLabel»
					LDA #$00
				+«signLabel»
			«ELSE»
				«noop»
					LDA #$00
			«ENDIF»
			«noop»
				STA «dst.absolute» + 1«IF dst.isIndexed», X«ENDIF»
		«ENDIF»
	'''

	private def copyImmediateToIndirect(CompileData src, CompileData dst) '''
		«IF dst.isIndexed»
			«noop»
				LDY «dst.index»
		«ENDIF»
		«noop»
			LDA #<(«src.immediate»)
			STA («dst.indirect»)«IF dst.isIndexed», Y«ENDIF»
		«IF dst.sizeOf > 1»
			«IF src.sizeOf > 1»
				«noop»
					LDA #>(«src.immediate»)
			«ELSEIF src.type.isSigned»
				«val signLabel = labelForSignedComplementEnd»
					ORA #$7F
					BMI +«signLabel»
					LDA #$00
				+«signLabel»
			«ELSE»
				«noop»
					LDA #$00
			«ENDIF»
			«IF dst.isIndexed»
				INY
			«ELSE»
				LDY #$01
			«ENDIF»
			«noop»
				STA «dst.indirect», Y
		«ENDIF»
	'''

	private def copyImmediateToRegister(CompileData src, CompileData dst) '''
		«noop»
			LD«dst.register» #<(«src.immediate»)
	'''

	private def copyAbsoluteToAbsolute(CompileData src, CompileData dst) '''
		«IF dst.sizeOf < loopThreshold»
			«FOR i : 0 ..< Math::min(src.sizeOf, dst.sizeOf)»
				«noop»
					«IF src.isIndexed»
						LDY «src.index»
					«ENDIF»
					«IF dst.isIndexed»
						LDX «dst.index»
					«ENDIF»
					LDA «src.absolute»«IF i > 0» + «i»«ENDIF»«IF src.isIndexed», Y«ENDIF»
					STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
			«ENDFOR»
			«IF src.sizeOf < dst.sizeOf»
				«IF src.type.isSigned»
					«val signLabel = labelForSignedComplementEnd»
						ORA #$7F
						BMI +«signLabel»
						LDA #$00
					+«signLabel»
				«ELSE»
					«noop»
						LDA #$00
				«ENDIF»
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
					CLC
					LDA «IF src.isIndexed»«src.index»«ELSE»«dst.index»«ENDIF»
					ADC «minSize» - 1
					TAY
					LDX «minSize» - 1
				-«copyLoop»
					LDA «src.absolute»«IF src.isIndexed», Y«ELSE», X«ENDIF»
					STA «dst.absolute»«IF dst.isIndexed», Y«ELSE», X«ENDIF»
					DEY
					DEX
					BPL -«copyLoop»
			«ELSE»
				«noop»
					LDX «minSize» - 1
				-«copyLoop»
					LDA «src.absolute», X
					STA «dst.absolute», X
					DEX
					BPL -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyAbsoluteToIndirect(CompileData src, CompileData dst) '''
		«IF dst.sizeOf < loopThreshold»
			«val minSize = Math::min(src.sizeOf, dst.sizeOf)»
			«FOR i : 0 ..< minSize»
				«noop»
					«IF src.isIndexed»
						LDX «src.index»
					«ENDIF»
					«IF dst.isIndexed»
						LDY «dst.index»
					«ENDIF»
					LDA «src.absolute»«IF i > 0» + «i»«ENDIF»«IF src.isIndexed», X«ENDIF»
					STA («dst.indirect»)«IF dst.isIndexed», Y«ENDIF»
					«IF dst.isIndexed && i < minSize - 1»
						INY
					«ENDIF»
			«ENDFOR»
			«IF src.sizeOf < dst.sizeOf»
				«IF src.type.isSigned»
					«val signLabel = labelForSignedComplementEnd»
						ORA #$7F
						BMI +«signLabel»
						LDA #$00
					+«signLabel»
				«ELSE»
					«noop»
						LDA #$00
				«ENDIF»
				«IF dst.isIndexed»
					«noop»
						INY
				«ENDIF»
			«ENDIF»
			«FOR i : src.sizeOf ..< dst.sizeOf»
				«noop»
					STA («dst.indirect»)«IF dst.isIndexed», Y«ENDIF»
					«IF dst.isIndexed && i < dst.sizeOf - 1»
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
					CLC
					LDA «IF src.isIndexed»«src.index»«ELSE»«dst.index»«ENDIF»
					ADC «minSize» - 1
					TAX
					LDY «minSize» - 1
				-«copyLoop»
					LDA «src.absolute»«IF src.isIndexed», X«ELSE», Y«ENDIF»
					STA («dst.indirect»«IF dst.isIndexed», X)«ELSE»), Y«ENDIF»
					DEX
					DEY
					BPL -«copyLoop»
			«ELSE»
				«noop»
					LDY «minSize» - 1
				-«copyLoop»
					LDA «src.absolute», Y
					STA («dst.indirect»), Y
					DEY
					BPL -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyAbsoluteToRegister(CompileData src, CompileData dst) '''
		«noop»
			«IF src.isIndexed»
				LDX «src.index»
				LDA «src.absolute», X
				«IF dst.register != 'A'»
					TA«dst.register»
				«ENDIF»
			«ELSE»
				LD«dst.register» «src.absolute»
			«ENDIF»
	'''

	private def copyIndirectToAbsolute(CompileData src, CompileData dst) '''
		«IF dst.sizeOf < loopThreshold»
			«val minSize = Math::min(src.sizeOf, dst.sizeOf)»
			«FOR i : 0 ..< minSize»
				«noop»
					«IF src.isIndexed»
						LDY «src.index»
					«ENDIF»
					«IF dst.isIndexed»
						LDX «dst.index»
					«ENDIF»
					LDA («src.indirect»)«IF src.isIndexed», Y«ENDIF»
					STA «dst.absolute»«IF i > 0» + «i»«ENDIF»«IF dst.isIndexed», X«ENDIF»
					«IF src.isIndexed && i < minSize - 1»
						INY
					«ENDIF»
			«ENDFOR»
			«IF src.sizeOf < dst.sizeOf»
				«IF src.type.isSigned»
					«val signLabel = labelForSignedComplementEnd»
						ORA #$7F
						BMI +«signLabel»
						LDA #$00
					+«signLabel»
				«ELSE»
					«noop»
						LDA #$00
				«ENDIF»
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
					CLC
					LDA «IF src.isIndexed»«src.index»«ELSE»«dst.index»«ENDIF»
					ADC «minSize» - 1
					TAX
					LDY «minSize» - 1
				-«copyLoop»
					LDA («src.indirect»«IF src.isIndexed», X)«ELSE»), Y«ENDIF»
					STA «dst.absolute»«IF dst.isIndexed», X«ELSE», Y«ENDIF»
					DEX
					DEY
					BPL -«copyLoop»
			«ELSE»
				«noop»
					LDY «minSize» - 1
				-«copyLoop»
					LDA («src.indirect»), Y
					STA «dst.absolute», Y
					DEY
					BPL -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyIndirectToIndirect(CompileData src, CompileData dst) '''
		«IF dst.sizeOf < loopThreshold»
			«val minSize = Math::min(src.sizeOf, dst.sizeOf)»
			«FOR i : 0 ..< minSize»
				«noop»
					«IF src.isIndexed»
						LDX «src.index»
					«ENDIF»
					«IF dst.isIndexed»
						LDY «dst.index»
					«ENDIF»
					LDA («src.indirect»«IF src.isIndexed», X«ENDIF»)
					STA («dst.indirect»)«IF dst.isIndexed», Y«ENDIF»
					«IF src.isIndexed && i < minSize - 1»
						INX
					«ENDIF»
					«IF dst.isIndexed && i < minSize - 1»
						INY
					«ENDIF»
			«ENDFOR»
			«IF src.sizeOf < dst.sizeOf»
				«IF src.type.isSigned»
					«val signLabel = labelForSignedComplementEnd»
						ORA #$7F
						BMI +«signLabel»
						LDA #$00
					+«signLabel»
				«ELSE»
					«noop»
						LDA #$00
				«ENDIF»
				«IF dst.isIndexed»
					«noop»
						INY
				«ENDIF»
			«ENDIF»
			«FOR i : src.sizeOf ..< dst.sizeOf»
				«noop»
					STA («dst.indirect»)«IF dst.isIndexed», Y«ENDIF»
					«IF dst.isIndexed && i < dst.sizeOf - 1»
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
					CLC
					LDA «IF src.isIndexed»«src.index»«ELSE»«dst.index»«ENDIF»
					ADC «minSize» - 1
					TAX
					LDY «minSize» - 1
				-«copyLoop»
					LDA («src.indirect»«IF src.isIndexed», X)«ELSE»), Y«ENDIF»
					STA («dst.indirect»«IF dst.isIndexed», X)«ELSE»), Y«ENDIF»
					DEX
					DEY
					BPL -«copyLoop»
			«ELSE»
				«noop»
					LDY «minSize» - 1
				-«copyLoop»
					LDA («src.indirect»), Y
					STA («dst.indirect»), Y
					DEY
					BPL -«copyLoop»
			«ENDIF»
		«ENDIF»
	'''

	private def copyIndirectToRegister(CompileData src, CompileData dst) '''
		«noop»
			«IF src.isIndexed»
				LDY «src.index»
			«ENDIF»
			LDA («src.indirect»)«IF src.isIndexed», Y«ENDIF»
			«IF dst.register != 'A'»
				TA«dst.register»
			«ENDIF»
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

	private def labelForSignedComplementEnd() {
		'''signedComplementEnd«labelCounter.andIncrement»:'''
	}

	private def labelForCopyLoop() {
		'''copyLoop«labelCounter.andIncrement»:'''
	}

	private def noop() {
	}
}
