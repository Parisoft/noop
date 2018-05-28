package org.parisoft.noop.generator

import org.eclipse.xtext.generator.OutputConfigurationProvider

class NoopOutputConfigurationProvider extends OutputConfigurationProvider {
	
	public static val OUTPUT_DIR = './out'
	
	override getOutputConfigurations() {
		super.getOutputConfigurations() => [
			head.outputDirectory = OUTPUT_DIR
		]
	}
	
}