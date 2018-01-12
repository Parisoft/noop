package org.parisoft.noop.ui.commands;

import java.lang.reflect.InvocationTargetException;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.eclipse.core.commands.AbstractHandler;
import org.eclipse.core.commands.ExecutionEvent;
import org.eclipse.core.commands.ExecutionException;
import org.eclipse.core.commands.IHandler;
import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IMarker;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.resources.IncrementalProjectBuilder;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.util.EcoreUtil;
import org.eclipse.jface.dialogs.MessageDialog;
import org.eclipse.ui.IEditorPart;
import org.eclipse.ui.handlers.HandlerUtil;
import org.eclipse.xtext.EcoreUtil2;
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2;
import org.eclipse.xtext.diagnostics.Severity;
import org.eclipse.xtext.generator.IGenerator2;
import org.eclipse.xtext.ui.resource.IResourceSetProvider;
import org.eclipse.xtext.util.CancelIndicator;
import org.eclipse.xtext.validation.CheckMode;
import org.eclipse.xtext.validation.IResourceValidator;
import org.eclipse.xtext.validation.Issue;
import org.parisoft.noop.noop.MemberSelect;
import org.parisoft.noop.noop.NewInstance;
import org.parisoft.noop.ui.editor.NoopEditor;
import org.parisoft.noop.validation.NoopValidator;

import com.google.inject.Inject;
import com.google.inject.Provider;

public class NoopRunHandler extends AbstractHandler implements IHandler {

	@Inject
	IResourceValidator validator;
	@Inject
	IGenerator2 generator;
	@Inject
	IResourceSetProvider resourceSetProvider;
	@Inject
	Provider<EclipseResourceFileSystemAccess2> fileAccessProvider;

	@Override
	public Object execute(ExecutionEvent event) throws ExecutionException {
		IEditorPart editor = HandlerUtil.getActiveEditor(event);

		if (editor instanceof NoopEditor) {
			try {
				HandlerUtil.getActiveWorkbenchWindow(event).run(true, true, monitor -> {
					IFile file = ((NoopEditor) editor).getFile();
					IProject project = file.getProject();
					ResourceSet resourceSet = resourceSetProvider.get(project);
					Resource resource = resourceSet.getResource(URI.createURI(file.getLocationURI().toString(), true),
							true);
					
					try {
						project.build(IncrementalProjectBuilder.FULL_BUILD, monitor);
					} catch (CoreException e) {
						e.printStackTrace();
					}
					
					try {
						if (monitor.isCanceled()) {
							for (IResource m : project.members()) {
								if (m.findMaxProblemSeverity(null, true, IResource.DEPTH_INFINITE) >= IMarker.SEVERITY_ERROR) {
									throw new IllegalStateException("Project contains errors");
								}
							}
						}
					} catch (CoreException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}

//					List<Issue> issues = validator.validate(resource, CheckMode.ALL, CancelIndicator.NullImpl);
//
//					for (Issue issue : issues) {
//						if (issue.getSeverity() == Severity.ERROR
//								&& issue.getCode().startsWith(NoopValidator.ISSUE_PREFIX)) {
//							throw new RuntimeException("Project contains errors");
//						}
//					}
//
//					EclipseResourceFileSystemAccess2 fsa = fileAccessProvider.get();
//					fsa.setOutputPath("/out");
//					fsa.setMonitor(monitor);
//					fsa.setProject(project);
//
//					generator.doGenerate(resource, fsa, null);
				});
			} catch (InvocationTargetException e) {
				MessageDialog.openError(HandlerUtil.getActiveWorkbenchWindow(event).getShell(), "Error",
						e.getTargetException().getMessage());
			} catch (InterruptedException e) {
				return null;
			}
		}
		// try {
		// HandlerUtil.getActiveWorkbenchWindow(event).run(true, true, (monitor) -> {
		// monitor.beginTask("open", 1);
		// String nes = "
		// /home/andre/git/runtime-EclipseApplication/compile-test/out/Oba.nes";
		// try {
		// Runtime.getRuntime().exec(NoopPreferences.getPathToEmulator() + nes);
		// } catch (IOException e) {
		// monitor.setCanceled(true);
		// }
		// monitor.internalWorked(1);
		// });
		// } catch (InvocationTargetException | InterruptedException e) {
		// MessageDialog.openError(HandlerUtil.getActiveShell(event), "Error",
		// e.getMessage());
		// }
		//
		// MessageDialog.openInformation(HandlerUtil.getActiveWorkbenchWindow(event).getShell(),
		// "Info", outPath);
		return null;
	}

	private static void resolveAll(EObject o, Set<EObject> resolved) {
		EcoreUtil2.resolveAll(o);
		System.out.println("resolved? " + !o.eIsProxy() + " " + o);
		
		if (resolved.add(o)) {
			if (o instanceof NewInstance) {
				resolveAll(((NewInstance) o).getType(), resolved);
				for (EObject member : resolved) {
					resolveAll(member, resolved);
				}
			}
			
			if (o instanceof MemberSelect) {
				MemberSelect s = (MemberSelect) o;
				System.out.println("let's go " + s.getMember());
				resolveAll(s.getMember(), resolved);
			}

			o.eAllContents().forEachRemaining(c -> resolveAll(o, resolved));
		}
	}
}
