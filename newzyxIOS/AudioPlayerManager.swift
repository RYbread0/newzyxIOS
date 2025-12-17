//
//  AudioPlayerManager.swift
//  newzyxIOS
//
//  Manages audio playback for podcasts
//

import Foundation
import AVFoundation
import Combine

class AudioPlayerManager: NSObject, ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var isLoading = false
    @Published var error: String?
    
    private var player: AVPlayer?
    private var timeObserver: Any?
    private var currentEpisode: NewsEpisode?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set up audio session: \(error)")
        }
    }
    
    func loadEpisode(_ episode: NewsEpisode) {
        currentEpisode = episode
        isLoading = true
        error = nil
        
        print("🎵 Loading podcast from: \(episode.podcastURL.absoluteString)")
        
        // Create cache-busting URL
        var components = URLComponents(url: episode.podcastURL, resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "t", value: "\(Date().timeIntervalSince1970)")]
        
        guard let url = components?.url else {
            error = "Invalid URL"
            isLoading = false
            print("❌ Invalid podcast URL")
            return
        }
        
        print("🎵 Final URL: \(url.absoluteString)")
        
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Add observer for player item status
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: playerItem
        )
        
        // Add time observer
        addTimeObserver()
        
        // Load duration using modern async API
        Task { [weak self] in
            guard let self = self else { return }
            do {
                if let asset = self.player?.currentItem?.asset {
                    let duration = try await asset.load(.duration)
                    await MainActor.run {
                        self.duration = CMTimeGetSeconds(duration)
                        self.isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    self.error = "Failed to load audio: \(error.localizedDescription)"
                    self.isLoading = false
                }
            }
        }
    }
    
    private func addTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.currentTime = CMTimeGetSeconds(time)
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player?.seek(to: cmTime)
        currentTime = time
    }
    
    @objc private func playerDidFinishPlaying() {
        isPlaying = false
        currentTime = 0
        player?.seek(to: .zero)
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
        NotificationCenter.default.removeObserver(self)
    }
}

