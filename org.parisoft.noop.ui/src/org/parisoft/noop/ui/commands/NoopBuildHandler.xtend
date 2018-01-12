package org.parisoft.noop.ui.commands

import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.commands.ExecutionException
import org.eclipse.core.resources.IncrementalProjectBuilder
import org.eclipse.jface.dialogs.MessageDialog

import static extension org.eclipse.ui.handlers.HandlerUtil.*
import org.eclipse.core.resources.IResource
import org.eclipse.core.resources.IMarker

class NoopBuildHandler extends NoopAbstractHandler {

	override execute(ExecutionEvent event) throws ExecutionException {
		val resource = event.IResource
		val project = resource?.project

		if (resource === null || project === null) {
			MessageDialog::openError(event.activeWorkbenchWindow.shell, 'Project not found   :(', '''
			No projects where found for build.
			Please, select a project or open a NOOP file and try again.''')
			return null
		}

		event.activeWorkbenchWindow.run(true, true) [ monitor |
			project.build(IncrementalProjectBuilder::FULL_BUILD, monitor);
		]

		val failed = project.members.exists [
			findMaxProblemSeverity(null, true, IResource::DEPTH_INFINITE) >= IMarker::SEVERITY_ERROR
		]

		if (failed) {
			MessageDialog::openError(event.activeWorkbenchWindow.shell, 'Build failed   :(', '''
			Project «project.name» contains errors.
			Please, fix all those errors and try again.''')
		} else {
			MessageDialog::openInformation(event.activeWorkbenchWindow.shell,
				'Build successful   =)', '''Build of project «project.name» completed''')
		}

		null
	}

}
