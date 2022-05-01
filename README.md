
Introduction
============

I'm working on this project to help me learn about rendering graphics on Apple platforms.  It started out as a way to learn about programming Metal shaders, and has expanded to include SceneKit and other graphics rendering technologies.

The project name (AppRender) is the Portuguese word for "to learn" -- and coincidentally (in English) looks like "an app for rendering".  So, combining the two, ...

The project is structured in sucah a way as to isolate the successive refinements, so that one can explore the code from "basic foundational stuff" through "adding particular feature or technology enhancements."  This description will provide a roadmap to approaching the code in roughly the order in which the learning happens.

The project compiles and runs on desktop macOS, macOS Catalyst, and also iPadOS.

The structure of the app is a standard three pane display.  The first (sidebar) pane has a list of the various types of rendering (e.g. fragment shaders, vertex shaders, SceneKit scenes, etc.).

The second pane will have a list of examples demonstrating the type of rendering selected in the first pane.

The final pane will contain the running instance of the shader or scene selected in the second pane.

The app will allow recording and saving the running shader to a video file.  Other features of the app will be discussed in the *Rendering Controls* section below.

The existence of this app was inspired by sites like http://shadertoy.com and https://www.vertexshaderart.com .  However, these sites provide a platform for people to upload and share separately installable shaders which follow a particular calling convention.  Although AppRender began with the same intent, it soon became clear that a more thorough exploration was going to require different kinds of calling conventions for different kinds of rendering techniques.  It is relatively easy to provide hosting for separately loadable OpenGL shaders.  However, not only am I planning to implement lots of different rendering techniques, some of them require implementation as Swift (or Objective-C) code.  if one is implementing a Swift class which generates a SceneKit scene, the engineering required to provide safe dynamic loading of a collection of separately submitted such classes requires more effort and skill than I am prepared to provide.  It may be possible at some point in the future.  In the interim, the expectation is that anybody who wants to share additional examples will submit a pull request.

Views
=====

The overall app framework code is in the Group *AppRender*.  The classes related to displaying the results of the rendering are in the Group *ShaderView*.

There are two ways to get the rendered pixels to light up behind the glass: 
  1) using MTKView directly and updating the view using a Metal shader render pipeline. (*ShaderMetalView*.
  2) using a SceneView (in SwiftUI) and setting the background contents to a Metal texture.  The shader pipeline renders to this texture, and the SceneView renders the texture into the background.  (*ShaderSceneView*)
  
There is a setting available in the app settings ( *SettingsView* ) which is a toggle labeled "MetalKit".  When set, the MTKView is used, otherwise the SceneView.  The SceneView implementation is 100% SwiftUI; the MTKView implementation obviously uses NSHostingView to wrap the MTKView, as the rest of the application uses SwiftUI.

*FIXME:*  Currently, the MTKView implements multi-sampling anti-aliasing properly, but I have not yet figured out how to do this for the SceneView -- so when toggling the setting while a shader is running one can see the difference between the anti-aliased MTKView version vs the non-anti-aliased SceneView version.  

Shaders
=======

Rendering done exclusively via Metal are implemented using various kinds of shaders.  The implementation code is in the Group *ShaderClasses*.  

The implementation strategy begins with the simplest interface (*GenericShader*).  This implements a fragment shader which renders to the view.  For each subsequent enhancement, a new shader subclass is implemented which refines the behavior of its superclass.  I chose to have each new subclass inherit from the previous one so that the features are additive rather than have a flatter hierarchy which only implements one additional feature over the generic shader case.

The hierarchy is: 

  - GenericShader
  - ParameterizedShader
  - ShaderFilter
  - ShaderFeedback
  - ShaderVertex
  
ShaderFilter adds the ability to take texture inputs.  (Hence the name -- the most frequent example involves applying some kind of filter to the input).  Texture inputs can come from images, videos, or webcams.  The framework provides an enhanced preferences view which includes the ability to set the input texture source (via drag'n'drop, a file dialog, or loaded from Photos).

ShaderFeedback adds the ability to take the previously rendered frame and feed it back in as an input texture.  Additionally, it permits adding additional render targets (colorAttachments) so that the shader can be generating multiple planes of output, and have all the planes fed back in as input to the next frame.  This enables shaders which maintain pixel "memory" for multipass algorithms.

ShaderVertex adds the ability to implement vertex shaders.  

Each one of these shader types will be discussed in greater detail below.

Scenes
======
