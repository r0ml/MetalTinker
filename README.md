
Introduction
=========

The motivation for this project was to build something like [Shadertoy](http://www.shadertoy.com) while adding additional features that I wanted to experiment with.   These features are:

1. Metal shaders instead of GLSL shaders — since I own a Mac, and Apple is deprecating OpenGL going forward.  
2. Using XCode and github as the development environment, rather than support uploading and editing shaders as Shadertoy does.  The expectation is that one can distribute an app with the compiled Metal shaders for browsing — and if one wanted to write new shaders (or modify existing ones), the workflow would start with cloning the git repository.
3. Support for kernel shaders and vertex shaders.   Many of the geometry calculations done by hand in a fragment shader could be handled by modern GPUs using vertex shaders and instances.  This would also allow writing shaders that generate points and lines, as well as triangle meshes.
4. The ability to compose shaders.  Instead of just having the ability to have a multipass shader, where the passes are built in to the shader, support a way of building a kernel or fragment shader — and then refer to that shader by name in a subsequent shader which uses that shader as one pass of a multi-pass rendering.
5. The abiity to integrate with the macOS Photo and Music libraries, to be able to use textures, photos, videos, and music stored in their native macOS applications.  One should be abe to drag a photo or track from Photos or iMusic into a shader, and have that picture or audio track processed by the shader.
6. The ability to capture still frames or video sequences from a running shader directly into one's Photo library.
7. Better font handling.  Rather than requiring a pre-built texture which is a series of sprites representing fixed width characters, implement some mechanism for the GPU and CPU to co-operate on text rendering and utilize the  fonts installed on the machine.
8. The ability to modify parameters.  XScreenSaver would generate a preferences pane from the available parameters.  In this way, rather than have multiple different shaders as variants of a single shader, or #ifdefs which would modify the shader at compile time, a shader could specify parameters which woulld automatically generate a preferences pane which would allow dynamically modifying these parameters while the shader was running.

# Building a shader

To be written….

