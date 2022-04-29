
import SwiftUI

struct SettingsView : View {
  @AppStorage("useMetalKit") var useMetalKit = false
  
  var body: some View {
    Form {
      Toggle(isOn: $useMetalKit) {
        Text("Use MetalKit")
      }
    }.padding()
    }
}