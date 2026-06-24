import UIKit
import AVFoundation
import AVKit

class VideoPlayerViewController: UIViewController {

    var videoURL: URL?
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playPauseButton: UIButton!
    private var timeLabel: UILabel!
    private var slider: UISlider!
    private var timeObserver: Any?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1)

        let scanlines = ScanlinesView(frame: view.bounds)
        scanlines.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scanlines)

        guard let url = videoURL else { return }

        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.bounds
        playerLayer?.videoGravity = .resizeAspect
        if let layer = playerLayer {
            view.layer.insertSublayer(layer, at: 0)
        }

        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = UIColor(red: 0.055, green: 0.055, blue: 0.055, alpha: 0.85)
        containerView.layer.borderWidth = 2
        containerView.layer.borderColor = UIColor.white.cgColor
        view.addSubview(containerView)

        let closeButton = UIButton(type: .system)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.setTitle("X", for: .normal)
        closeButton.titleLabel?.font = UIFont(name: "Menlo-Bold", size: 14)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1)
        closeButton.layer.borderWidth = 2
        closeButton.layer.borderColor = UIColor.white.cgColor
        closeButton.addTarget(self, action: #selector(closePlayer), for: .touchUpInside)
        containerView.addSubview(closeButton)

        playPauseButton = UIButton(type: .system)
        playPauseButton.translatesAutoresizingMaskIntoConstraints = false
        playPauseButton.setTitle("||", for: .normal)
        playPauseButton.titleLabel?.font = UIFont(name: "Menlo-Bold", size: 12)
        playPauseButton.setTitleColor(.white, for: .normal)
        playPauseButton.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1)
        playPauseButton.layer.borderWidth = 2
        playPauseButton.layer.borderColor = UIColor.white.cgColor
        playPauseButton.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        containerView.addSubview(playPauseButton)

        slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumTrackTintColor = UIColor(red: 0.3, green: 0.8, blue: 1, alpha: 1)
        slider.maximumTrackTintColor = .darkGray
        slider.setThumbImage(UIImage(), for: .normal)
        slider.addTarget(self, action: #selector(seek), for: .valueChanged)
        containerView.addSubview(slider)

        timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.font = UIFont(name: "Menlo", size: 9)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        timeLabel.text = "00:00 / 00:00"
        containerView.addSubview(timeLabel)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 6),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            playPauseButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8),
            playPauseButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 36),
            playPauseButton.heightAnchor.constraint(equalToConstant: 32),

            slider.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor, constant: 8),
            slider.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            slider.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -8),

            timeLabel.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 4),
            timeLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            timeLabel.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8)
        ])

        player?.addObserver(self, forKeyPath: "rate", options: [.new], context: nil)

        timeObserver = player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
            self?.updateTimeDisplay()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(toggleControls))
        view.addGestureRecognizer(tap)

        NotificationCenter.default.addObserver(self, selector: #selector(videoEnded), name: .AVPlayerItemDidPlayToEndTime, object: player?.currentItem)

        player?.play()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    deinit {
        player?.removeObserver(self, forKeyPath: "rate")
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }

    @objc private func closePlayer() {
        player?.pause()
        dismiss(animated: true)
    }

    @objc private func togglePlayPause() {
        if player?.rate == 0 {
            player?.play()
            playPauseButton.setTitle("||", for: .normal)
        } else {
            player?.pause()
            playPauseButton.setTitle(">", for: .normal)
        }
    }

    @objc private func seek() {
        guard let duration = player?.currentItem?.duration.seconds, duration > 0 else { return }
        let time = CMTime(seconds: Double(slider.value) * duration, preferredTimescale: 600)
        player?.seek(to: time)
    }

    @objc private func toggleControls() {
        // Toggle controls visibility - handled by the existing always-visible controls
    }

    @objc private func videoEnded() {
        playPauseButton.setTitle(">", for: .normal)
        player?.seek(to: .zero)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "rate" {
            playPauseButton.setTitle((player?.rate ?? 0) > 0 ? "||" : ">", for: .normal)
        }
    }

    private func updateTimeDisplay() {
        guard let player = player, let item = player.currentItem else { return }
        let total = item.duration.seconds
        let current = player.currentTime().seconds
        if total.isFinite && total > 0 {
            slider.value = Float(current / total)
        }
        timeLabel.text = "\(formatTime(current)) / \(formatTime(total))"
    }

    private func formatTime(_ seconds: Double) -> String {
        guard seconds.isFinite, seconds >= 0 else { return "00:00" }
        let s = Int(seconds) % 60
        let m = Int(seconds) / 60
        return String(format: "%02d:%02d", m, s)
    }
}
