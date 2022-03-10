
Introduction
=========

This application implements a variety of scenes which replicate various GLSL shaders by using SceneKit, SpriteKit, and Metal in various combinations.  In addtion to browsing and viewing these scenes, the feature that are (or will be) implemented are:

1. Support for kernel shaders and vertex shaders in addition to fragment shaders.
2. Scenes that use points or lines instead of triangles.
3. The abiity to integrate with the macOS Photo and Music libraries, to be able to use textures, photos, videos, and music stored in their native macOS applications.  One should be abe to drag a photo or track from Photos or iMusic into a scene, and have that picture or audio track processed by the scene.
6. The ability to capture still frames or video sequences from a running scene directly into one's Photo library.
7. Better font handling.
8. The ability to modify parameters.  XScreenSaver would generate a preferences pane from the available parameters.  In this way, rather than have multiple different scenes as variants of a single scene, or #ifdefs which would modify the scene at compile time, a scene could specify parameters which woulld automatically generate a preferences pane which would allow dynamically modifying these parameters while the scene was running.

# Building a scene

To be written….

