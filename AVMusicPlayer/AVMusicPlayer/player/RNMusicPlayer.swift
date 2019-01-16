//
//  AudioPlayer.swift
//  blackboard
//
//  Created by roni on 2018/12/26.
//  Copyright © 2018 xkb. All rights reserved.
//

import Foundation
import AVFoundation
import MediaPlayer

class MenuControlTool: NSObject {
    @objc static func remoteControlReceived(event: UIEvent) {
        switch event.subtype {
        case .remoteControlPlay:
            RNMusicPlayer.sharedInstance.play()
        case .remoteControlPause:
            RNMusicPlayer.sharedInstance.pause()
        case .remoteControlNextTrack:
            RNMusicPlayer.sharedInstance.next()
        case .remoteControlPreviousTrack:
            RNMusicPlayer.sharedInstance.last()
        default:
            break
        }
    }
}

let isIgnoreCellularForever: String = "ISIGNORECELLULARFOREVER"
let isIgnoreCellularMoment: String = "ISIGNORECELLULARMOMENT"

enum MusicPlayerState {
    case playing
    case pause
    case stop
    case failed
    case outOfIndex
}

// eg:
class SongModel: SongUnitProtocol {
    let model: MusicModel
    init(model: MusicModel) {
        self.model = model
    }

    var id: Int {
        return model.id
    }
    var title: String {
        return model.title
    }
    var artist: String {
        return model.artist
    }
    var pic: String {
        return model.pic
    }
    var musicUrl: URL {
        return model.musicUrl
    }
    var fileName: String {
        return model.fileName
    }
    var content: String {
        return model.content
    }
    var image: UIImage?
}

protocol SongUnitProtocol {
    var id: Int { get }
    var title: String { get }
    var artist: String { get }
    var pic: String { get }
    var musicUrl: URL { get }
    var fileName: String { get }
    var content: String { get }
    var image: UIImage? { get set }
}

class RNMusicPlayer {
    static let sharedInstance = RNMusicPlayer()
    private init() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("session.setActive fail...")
        }
    }

    typealias PlayerHandler = (MusicPlayerState) -> Void

    private var player: AVPlayer?
    private var playerItem: AVPlayerItem?
    private var playerObserve: NSKeyValueObservation?
    private var durationObserve: NSKeyValueObservation?

    // output
    public var isPlaying = false
    public var playStateHandler: PlayerHandler?
    public var playModelHandler: ((SongUnitProtocol?) -> Void)?

    // input
    // conform: SongUnitProtocol
    public var playingIndex = 0
    public lazy var list: [SongUnitProtocol] = {
        let musicModels = generateMusicList().data
        var songs = [SongUnitProtocol]()
        for music in musicModels {
            let song = SongModel(model: music)
            songs.append(song)
        }
        return songs
    }()

    private lazy var playingModel: SongUnitProtocol? = {
        return list[safe: playingIndex]
    }()

    public func play() {
//        watchNetWork()
        realPlay()
    }

    private func realPlay() {
        guard let url = audioUrl(index: playingIndex) else {
            return
        }
        setupPlayer(url: url)
    }

    func setupPlayer(url: URL) {
        playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        registerPlayStateEvents()
    }

    public func stop() {
        player?.pause()
        isPlaying = false
        playStateHandler?(.stop)
        setLockMenuInfo()
    }

    public func pause() {
        player?.pause()
        isPlaying = false
        playStateHandler?(.pause)
        setLockMenuInfo()
    }

    public func resume() {
        player?.play()
        isPlaying = true
        playStateHandler?(.playing)
        setLockMenuInfo()
    }

    public func last() {
        guard !list.isEmpty else { return }
        var lastIndex = self.playingIndex - 1
        if lastIndex < 0 {
            lastIndex = list.count - 1
        }
        setupNextAudioHint(index: lastIndex)
    }

    public func next() {
        guard !list.isEmpty else { return }
        var nextIndex = self.playingIndex + 1
        if nextIndex >= list.count {
            nextIndex = 0
        }
        setupNextAudioHint(index: nextIndex)
    }

    private func setupNextAudioHint(index: Int) {
        guard let url = audioUrl(index: index) else {
            return
        }

        playingIndex = index
        isPlaying = false
        setupPlayer(url: url)
    }

    private func audioUrl(index: Int) -> URL? {
        var playIndex = index
        guard !list.isEmpty else {
            playStateHandler?(.outOfIndex)
            return nil
        }

        if let player = player,
            let model = playingModel,
            let futureModel = list[safe: index],
            model.id == futureModel.id {
            player.play()
            return nil
        }

        if playIndex < 0 {
            playIndex = list.count - 1
        }

        if playIndex >= list.count {
            playIndex = 0
        }
        self.playingIndex = playIndex
        let model = list[playIndex]
        playingModel = model
        setLockMenuInfo()
        return model.musicUrl
    }

    private func setLockMenuInfo() {
        var infoDic = processInfoDic()
        if let image = playingModel?.image {
            let item = MPMediaItemArtwork(image: image)
            infoDic?[MPMediaItemPropertyArtwork] = item
            MPNowPlayingInfoCenter.default().nowPlayingInfo = infoDic
        } else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = infoDic
            downloadImage()
        }
    }

    func getCurrentPlayTime() -> Double {
        if let item = playerItem {
            return item.currentTime().seconds
        }
        return 0
    }

    func getTotalPlayTime() -> Double {
        if let item = playerItem, item.duration.timescale > 0 {
             return item.duration.seconds
        }
        return 0
    }

    private func processInfoDic() -> [String: Any]? {
        guard let model = playingModel else {
            return nil
        }
        var infoDic = [String: Any]()
        infoDic[MPMediaItemPropertyTitle] = model.title
        infoDic[MPMediaItemPropertyArtist] = model.artist
        infoDic[MPMediaItemPropertyAlbumTitle] = String(describing: model.fileName)

        let timeLength = getTotalPlayTime()
        infoDic[MPMediaItemPropertyPlaybackDuration] = NSNumber(value: timeLength)

        let playedLength = getCurrentPlayTime()
        infoDic[MPNowPlayingInfoPropertyElapsedPlaybackTime] = NSNumber(value: playedLength)
        return infoDic
    }

    private func downloadImage() {
        guard let model = playingModel else {
            return
        }
        if let picUrl = URL(string: model.pic) {
            // todo: 下载图片方式自己写
//            KingfisherManager.shared.retrieveImage(with: picUrl, options: nil, progressBlock: nil) { [weak self] (image, _, _, _) in
//                if let image = image {
//                    self?.playingModel?.image = image
//                    var infoDic = self?.processInfoDic()
//                    let item = MPMediaItemArtwork(image: image)
//                    infoDic?[MPMediaItemPropertyArtwork] = item
//                    MPNowPlayingInfoCenter.default().nowPlayingInfo = infoDic
//                }
//            }
        }
    }

    private func watchNetWork() {
//        if SLNetworkStateManager.get().getState() == SLNetworkState.TYPE_NOT_CONNECTED {
//            HUD.tip(text: localizedString("Common.network.notConnect"))
//            return
//        }
//        let isAllowCellularForever = UserDefaults.standard.object(forKey: isIgnoreCellularForever) as? Bool ?? false
//        let isAllowCellularMement = UserDefaults.standard.object(forKey: isIgnoreCellularMoment) as? Bool ?? false
//        if isAllowCellularForever || isAllowCellularMement {
//            realPlay()
//        } else {
//            if SLNetworkStateManager.get().getState() == SLNetworkState.TYPE_DATA {
//                let alert = AlertController(styleAlert: localizedString("Common.network.tip"), message: localizedString("Common.network.cellular"))
//                alert.add(AlertAction(title: localizedString("Common.network.moment"), style: .normal, handler: { [weak self] _ in
//                    UserDefaults.standard.set(true, forKey: isIgnoreCellularMoment)
//                    self?.realPlay()
//                }))
//                alert.add(AlertAction(title: localizedString("Common.network.forever"), style: .normal, handler: { [weak self]_ in
//                    UserDefaults.standard.set(true, forKey: isIgnoreCellularForever)
//                    self?.realPlay()
//                }))
//                alert.add(title: localizedString("Common.cancel"))
//                alert.present()
//            } else {
//                realPlay()
//            }
//        }
    }
}

extension RNMusicPlayer {
    private func registerPlayStateEvents() {
        addNotifications()

        playerObserve = player?.observe(\.status, options: [.new, .old], changeHandler: { [weak self] (item, _) in
            self?.setLockMenuInfo()
            switch item.status {
            case .readyToPlay:
                self?.isPlaying = true
                self?.player?.play()
                self?.setLockMenuInfo()
                self?.playStateHandler?(.playing)
                self?.playModelHandler?(self?.playingModel)
            case .unknown, .failed:
                self?.isPlaying = false
                self?.playStateHandler?(.failed)
            }
        })

        durationObserve = playerItem?.observe(\.duration, options: .new, changeHandler: { [weak self] (_, _) in
            self?.setLockMenuInfo()
        })

        // 播放完成
        _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem, queue: nil, using: { [weak self] (_) in
            self?.isPlaying = false
            self?.next()
        })

        // 播放因错误而完成
        _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemFailedToPlayToEndTime, object: playerItem, queue: nil, using: { [weak self] (_) in
            self?.stop()
            self?.isPlaying = false
            self?.playStateHandler?(.failed)
        })

        // 快进
        _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemTimeJumped, object: playerItem, queue: nil, using: { (_) in
            //
        })

    }

    func addNotifications() {
        // 杀死 app, 重置4g网络播放状态
        _ = NotificationCenter.default.addObserver(forName: UIApplication.willTerminateNotification, object: nil, queue: nil) { (_) in
            UserDefaults.standard.set(false, forKey: isIgnoreCellularMoment)
        }

        // 耳机插入拔出
        _ = NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: nil, using: { [weak self] (notification) in
            guard let `self` = self else { return }
            guard let userInfo = notification.userInfo else { return }
            guard let changeReason = userInfo[AVAudioSessionRouteChangeReasonKey] as? AVAudioSession.RouteChangeReason else { return }
            switch changeReason {
            case .newDeviceAvailable:
                if UIApplication.shared.applicationState == .active {
                    self.resume()
                }
            case .oldDeviceUnavailable:
                self.pause()
            default:
                break
            }
        })

        // 播放被打断
        _ = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVPlayerItemPlaybackStalled, object: nil, queue: nil, using: { [weak self] (_) in
            guard let `self` = self else { return }
            self.pause()
        })

        // 音频中断
        _ = NotificationCenter.default.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: nil, using: { [weak self] (notification) in
            guard let `self` = self else { return }
            guard let userInfo = notification.userInfo else { return }
            guard let interruptType = userInfo[AVAudioSessionInterruptionTypeKey] as? AVAudioSession.InterruptionType else { return }
            switch interruptType {
            case .began:
                self.pause()
            case .ended:
                if UIApplication.shared.applicationState != .inactive {
                    self.resume()
                }
            }
        })

    }
}
