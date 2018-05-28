package org.parisoft.noop.generator

class ASM {
	
	private val String asmFilename;
	private val String binFilename;
	private val String lstFilename;
	private val String content;
	
	new(String name, String content) {
		this.asmFilename = '''«name».asm'''
		this.binFilename = '''«name».nes'''
		this.lstFilename = '''«name».lst'''
		this.content = content
	}
	
	def getAsmFileName() {
		asmFilename
	}
	
	def getBinFileName() {
		binFilename
	}
	
	def getLstFileName() {
		lstFilename
	}
	
	def getContent() {
		content
	}
}