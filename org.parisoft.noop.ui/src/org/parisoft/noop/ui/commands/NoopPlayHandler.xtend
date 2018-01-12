package org.parisoft.noop.ui.commands

import java.nio.file.Paths
import org.eclipse.core.commands.ExecutionEvent
import org.eclipse.core.commands.ExecutionException
import org.eclipse.core.resources.IMarker
import org.eclipse.core.resources.IProject
import org.eclipse.core.resources.IResource
import org.eclipse.core.resources.IncrementalProjectBuilder
import org.eclipse.jface.dialogs.MessageDialog
import org.eclipse.jface.preference.PreferenceDialog
import org.eclipse.jface.preference.PreferenceManager
import org.eclipse.jface.preference.PreferenceNode
import org.parisoft.noop.generator.NoopOutputConfigurationProvider
import org.parisoft.noop.preferences.NoopPreferences
import org.parisoft.noop.ui.preferences.NoopPlayPreferencePage

import static extension org.eclipse.ui.handlers.HandlerUtil.*
import java.util.concurrent.CompletableFuture
import java.io.BufferedReader
import java.io.InputStreamReader

class NoopPlayHandler extends NoopAbstractHandler {

	override execute(ExecutionEvent event) throws ExecutionException {
		var emu = ''
		val opts = NoopPreferences::emulatorOptions

		while ((emu = NoopPreferences::emulatorPath).isNullOrEmpty) {
			val setup = MessageDialog::openQuestion(event.activeWorkbenchWindow.shell, 'Emulator not found   :(', '''
				An external emulator is required to play the compiled game.
				You can configure it through "Windows > Preferences > NOOP > Play".
				
				Do you want to setup one now?
			''')

			if (setup) {
				event.openPreferences
			} else {
				return null
			}
		}

		val resource = event.IResource
		val project = resource?.project

		if (resource === null || project === null) {
			MessageDialog::openError(event.activeWorkbenchWindow.shell, 'Project not found   :(', '''
			No game projects where found for play.
			Please, select a project or open a NOOP file and try again.''')
			return null
		}

		if (!project.build(IncrementalProjectBuilder::INCREMENTAL_BUILD, event)) {
			return null
		}

		var bin = project.binFile ?: project.refresh(event).binFile

		if (bin === null) {
			if (project.build(IncrementalProjectBuilder::FULL_BUILD, event)) {
				bin = project.binFile ?: project.refresh(event).binFile
			} else {
				return null
			}
		}

		if (bin === null) {
			return null
		}

		val command = '''«emu»«IF !opts.nullOrEmpty» «opts»«ENDIF» «Paths::get(bin.locationURI).toAbsolutePath.toString»'''

		event.activeWorkbenchWindow.run(true, true) [ monitor |
			monitor.beginTask('Launching game', 2)

			val proc = Runtime::runtime.exec(command)
			
			monitor.worked(1)
			
			val err = CompletableFuture::runAsync [
				new BufferedReader(new InputStreamReader(proc.inputStream)).lines.forEach[System::out.println(it)]
			]
			val out = CompletableFuture::runAsync [
				new BufferedReader(new InputStreamReader(proc.errorStream)).lines.forEach[System::err.println(it)]
			]

			while (proc.alive && !monitor.isCanceled) {
				Thread::sleep(100)
			}

			if (monitor.isCanceled) {
				out.cancel(true)
				err.cancel(true)
				proc.destroyForcibly.waitFor
			} else {
				monitor.worked(1)
			}
		]

		null
	}

	private def openPreferences(ExecutionEvent event) {
		val page = new NoopPlayPreferencePage
		val node = new PreferenceNode('org.parisoft.noop.ui.preferences.NoopPreferencePage', page)
		val manager = new PreferenceManager => [addToRoot(node)]

		new PreferenceDialog(event.activeWorkbenchWindow.shell, manager) => [
			create
			message = page.title
			open
		]

	}

	private def build(IProject project, int kind, ExecutionEvent event) {
		event.activeWorkbenchWindow.run(true, true) [ monitor |
			project.build(kind, monitor);
		]

		val failed = project.members.exists [
			findMaxProblemSeverity(null, true, IResource::DEPTH_INFINITE) >= IMarker::SEVERITY_ERROR
		]

		if (failed) {
			MessageDialog::openError(event.activeWorkbenchWindow.shell, 'Build failed   :(', '''
			Project «project.name» contains errors.
			Please, fix all those errors and try again.''')
		}

		failed == false
	}

	private def refresh(IProject project, ExecutionEvent event) {
		event.activeWorkbenchWindow.run(true, true) [ monitor |
			project.refreshLocal(IResource::DEPTH_INFINITE, monitor)
		]

		project
	}

	private def getBinFile(IProject project) {
		project.getFolder(NoopOutputConfigurationProvider::OUTPUT_DIR)?.members?.findFirst [
			fileExtension == 'nes'
		]
	}

}
