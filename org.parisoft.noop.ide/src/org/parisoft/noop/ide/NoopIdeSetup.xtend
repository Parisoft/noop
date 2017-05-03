/*
 * generated by Xtext 2.11.0
 */
package org.parisoft.noop.ide

import com.google.inject.Guice
import org.eclipse.xtext.util.Modules2
import org.parisoft.noop.NoopRuntimeModule
import org.parisoft.noop.NoopStandaloneSetup

/**
 * Initialization support for running Xtext languages as language servers.
 */
class NoopIdeSetup extends NoopStandaloneSetup {

	override createInjector() {
		Guice.createInjector(Modules2.mixin(new NoopRuntimeModule, new NoopIdeModule))
	}
	
}