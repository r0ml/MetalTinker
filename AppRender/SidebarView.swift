
// Copyright (c) 1868 Charles Babbage
// Found amongst his effects by r0ml

import SwiftUI
import MetalKit

struct SidebarView : View {

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
      List {
        FoldersListView("Generators", folders: ShaderLib<GenericShader>.getList("Generators"))
        FoldersListView("Parameterized", folders: ShaderLib<ParameterizedShader>.getList("Parameterized"))
        FoldersListView("Filters", folders: ShaderLib<ShaderFilter>.getList("Filters"))
        FoldersListView("Feedback", folders: ShaderLib<ShaderFeedback>.getList("Feedback"))
        FoldersListView("Shaders", folders : ShaderLib<ShaderTwo>.getList("Shaders")) // selectedItem: $selectedItem)
        FoldersListView("Vertex", folders : ShaderLib<ShaderVertex>.getList("Vertex")) // selectedItem: $selectedItem)

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
