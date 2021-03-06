/*
 * generated by Xtext 2.10.0
 */
package org.parisoft.noop

import com.google.inject.Binder
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.scoping.impl.AbstractDeclarativeScopeProvider
import org.parisoft.noop.scoping.NoopImportedNamespaceAwareLocalScopeProvider
import com.google.inject.name.Names
import org.eclipse.xtext.resource.IDefaultResourceDescriptionStrategy
import org.parisoft.noop.scoping.NoopResourceDescriptionStrategy
import org.parisoft.noop.convertion.NoopValueConverter
import org.parisoft.noop.generator.NoopOutputConfigurationProvider
import org.eclipse.xtext.generator.IOutputConfigurationProvider
import org.parisoft.noop.^extension.NoopQualifiedNameProvider

/**
 * Use this class to register components to be used at runtime / without the Equinox extension registry.
 */
class NoopRuntimeModule extends AbstractNoopRuntimeModule {

	override configureIScopeProviderDelegate(Binder binder) {
		binder.bind(IScopeProvider).annotatedWith(Names.named(AbstractDeclarativeScopeProvider.NAMED_DELEGATE)).to(
			NoopImportedNamespaceAwareLocalScopeProvider)
		binder.bind(IDefaultResourceDescriptionStrategy).to(NoopResourceDescriptionStrategy)
		binder.bind(IOutputConfigurationProvider).to(NoopOutputConfigurationProvider)
	}

	override bindIValueConverterService() {
		NoopValueConverter
	}

	override bindIQualifiedNameProvider() {
		NoopQualifiedNameProvider
	}
	
}
