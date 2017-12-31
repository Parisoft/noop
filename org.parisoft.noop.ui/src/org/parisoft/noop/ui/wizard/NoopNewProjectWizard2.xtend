package org.parisoft.noop.ui.wizard

import org.eclipse.xtext.ui.wizard.IProjectCreator
import org.eclipse.core.runtime.IExecutableExtension
import org.eclipse.core.runtime.IConfigurationElement
import org.eclipse.core.runtime.CoreException
import org.eclipse.ui.wizards.newresource.BasicNewProjectResourceWizard
import com.google.inject.Inject

class NoopNewProjectWizard2 extends NoopNewProjectWizard implements IExecutableExtension {

	var IConfigurationElement config

	@Inject
	new(IProjectCreator projectCreator) {
		super(projectCreator)
		windowTitle = 'New NOOP project'
	}

	override addPages() {
		super.addPages()
		mainPage.title = "NOOP Project"
		mainPage.description = "Create a new NOOP project."
	}

	override setInitializationData(IConfigurationElement config, String propertyName,
		Object data) throws CoreException {
		this.config = config
	}

	override performFinish() {
		BasicNewProjectResourceWizard::updatePerspective(config)
		super.performFinish
	}

}
