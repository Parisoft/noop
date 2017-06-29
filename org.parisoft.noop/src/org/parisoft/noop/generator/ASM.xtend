package org.parisoft.noop.generator

class ASM {
	
	private val String filename;
	private val String content;
	
	new(String filename, String content) {
		this.filename = filename
		this.content = content
	}
	
	def getFilename() {
		filename
	}
	
	def getContent() {
		content
	}
}