
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

var functionMaps = [ // "Shaders" : Function("Shaders"),
                    "Generators" : Function("Generators"),
                    "Filters" : Function("Filters"),
                    "Feedback" : Function("Feedback"),
                    "Vertex" : Function("Vertex"),
                    "Parameterized" : Function("Parameterized"),
                    "Multipass" : Function("Multipass"),
                    "PointCloud" : Function("PointClouds"),
                    "SceneShaders" : Function("Scenes"),
]

struct SidebarView : View {
  @AppStorage("selectedGroup") var selectedItem : String?

  //  @State var selectedItem : String?
//  var initialSelection : String?
  init() {
 //   initialSelection = fl[2].id
//    selectedItem = initialSelection
    
/*    if let sl = UserDefaults.standard.string(forKey: "selectedLibrary"), self.state.libName != sl {
      self.state.lib = fl.first(where: { $0.id == sl })
      if let ss = UserDefaults.standard.string(forKey: "selectedShader"), self.state.delegate.shader?.id != ss {
        self.state.delegate.shader = self.state.lib?.items.first(where: { $0.id == ss} )?.rm
      }
    }
 */
  }

  var body: some View {
    NavigationView {
      List(selection: $selectedItem) {

        FoldersListView("Generators", folders: ShaderLib<GenericShader>.getList("Generators"))
        FoldersListView("Parameterized", folders: ShaderLib<ParameterizedShader>.getList("Parameterized"))
        FoldersListView("Filters", folders: ShaderLib<ShaderFilter>.getList("Filters"))
        FoldersListView("Feedback", folders: ShaderLib<ShaderFeedback>.getList("Feedback"))
//        FoldersListView("Shaders", folders : ShaderLib<ShaderTwo>.getList("Shaders")) // selectedItem: $selectedItem)
        FoldersListView("Vertex", folders : ShaderLib<ShaderVertex>.getList("Vertex")) // selectedItem: $selectedItem)
        FoldersListView("PointCloud", folders : ShaderLib<ShaderPointCloud>.getList("PointCloud")) // selectedItem: $selectedItem)
        FoldersListView("Multipass", folders: ShaderLib<ShaderMultipass>.getList("Multipass"))

        // FIXME: put me back
        SceneSidebarView(folderList: SceneShaderLib.folderList)
        

//        SpriteListView(folderList: SpriteShaderLib.folderList) // see SpriteLibraryView
      }
      
      #if os(iOS) || targetEnvironment(macCatalyst)
      .navigationBarTitle("" , displayMode: .inline)
      #endif
      .onAppear {
        //        print("set selection \(initialSelection)")
        //        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
        //          selectedItem = initialSelection
        //        }
      }

      NothingSelectedView()
      Text("No Shader Selection")
    }


#if os(macOS) && !targetEnvironment(macCatalyst)
    .toolbar {
      ToolbarItem(placement: .navigation) {
      Button(action: toggleSidebar) {
        Image(systemName: "sidebar.left")
          .help("Toggle Sidebar")
      }
    }
    }
  #endif

  }

  #if os(macOS)
  private func toggleSidebar() {
    NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
  }
  #endif
  
}
