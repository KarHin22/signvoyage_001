//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

<<<<<<< HEAD
<<<<<<< Updated upstream

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
=======
import speech_to_text
import sqflite_darwin
import video_player_avfoundation

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  SpeechToTextPlugin.register(with: registry.registrar(forPlugin: "SpeechToTextPlugin"))
  SqflitePlugin.register(with: registry.registrar(forPlugin: "SqflitePlugin"))
  FVPVideoPlayerPlugin.register(with: registry.registrar(forPlugin: "FVPVideoPlayerPlugin"))
>>>>>>> Stashed changes
=======
import speech_to_text

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  SpeechToTextPlugin.register(with: registry.registrar(forPlugin: "SpeechToTextPlugin"))
>>>>>>> ba3c115af09a3135c3a92d99339dc3ed4ca2ea48
}
