import Orion
import UIKit

var statefulPlayer: StatefulPlayerImplementation?
var backgroundViewModel: SPTNowPlayingBackgroundViewModel?
var scrollDataSource: NowPlayingScrollDataSourceImplementation?

var nowPlayingScrollViewController: NowPlayingScrollViewController?
var npvScrollViewController: NPVScrollViewController?

// iOS 14: usa TriggerGroup para que o detector rode independente de patching.
class LegacyNowPlayingPlatformSwiftServiceImplementationHook: ClassHook<NSObject> {
    typealias Group = TriggerGroup
    static let targetName = "NowPlaying_PlatformImpl.NowPlayingPlatformSwiftServiceImplementation"
    
    func provideStatefulPlayer() -> StatefulPlayerImplementation {
        statefulPlayer = orig.provideStatefulPlayer()
        if let statefulPlayer {
            TriggerTrackDetector.shared.attach(to: statefulPlayer)
        }
        return statefulPlayer!
    }
}

// iOS 15+: idem.
class NowPlayingPlatformSwiftServiceImplementationHook: ClassHook<NSObject> {
    typealias Group = TriggerGroup
    static let targetName = "NowPlaying_PlatformImpl.NowPlayingPlatformSwiftServiceImplementation"
    
    func provideStatefulPlayerWithFeatureIdentifier(_ identifier: NSString) -> StatefulPlayerImplementation {
        statefulPlayer = orig.provideStatefulPlayerWithFeatureIdentifier(identifier)
        if let statefulPlayer {
            TriggerTrackDetector.shared.attach(to: statefulPlayer)
        }
        return statefulPlayer!
    }
}

// Hook de letras: mantém BaseLyricsGroup, não foi alterado.
class NowPlayingScrollPrivateServiceImplementationHook: ClassHook<NSObject> {
    typealias Group = BaseLyricsGroup
    static let targetName = "NowPlaying_ScrollImpl.NowPlayingScrollPrivateServiceImplementation"
    
    func provideScrollViewControllerWithDependencies(_ dependencies: NSObject) -> UIViewController {
        let scrollViewController = orig.provideScrollViewControllerWithDependencies(dependencies)
        
        if NSStringFromClass(type(of: scrollViewController)) ~= "NowPlayingScrollViewController" {
            nowPlayingScrollViewController = Dynamic.convert(
                scrollViewController,
                to: NowPlayingScrollViewController.self
            )
        }
        else {
            scrollDataSource = Ivars<NowPlayingScrollDataSourceImplementation>(target)
                .$__lazy_storage_$_scrollDataSource
            npvScrollViewController = Dynamic.convert(
                scrollViewController,
                to: NPVScrollViewController.self
            )
        }
        
        backgroundViewModel = Ivars<SPTNowPlayingBackgroundViewModel>(dependencies)
            .backgroundViewModel
        
        return scrollViewController
    }
}
