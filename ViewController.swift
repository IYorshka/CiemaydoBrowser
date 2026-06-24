import UIKit
import WebKit
import AVFoundation
import AVKit

class ViewController: UIViewController, WKNavigationDelegate, WKUIDelegate, UITextFieldDelegate {

    private var webView: WKWebView!
    private var urlField: UITextField!
    private var backButton: UIButton!
    private var forwardButton: UIButton!
    private var refreshButton: UIButton!
    private var mediaButton: UIButton!
    private var progressBar: UIProgressView!
    private var containerView: UIView!

    private let homeURL = "https://iyorshka.github.io/ciemaydo/"
    private var observation: NSKeyValueObservation?

    override var prefersStatusBarHidden: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1)

        let bg = BackgroundView(frame: view.bounds)
        bg.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(bg)

        let scanlines = ScanlinesView(frame: view.bounds)
        scanlines.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(scanlines)

        let vhsLeft = VHSLeftView(frame: CGRect(x: 0, y: 0, width: 60, height: view.bounds.height))
        vhsLeft.autoresizingMask = [.flexibleHeight, .flexibleRightMargin]
        view.addSubview(vhsLeft)

        let vhsRight = VHSRightView(frame: CGRect(x: view.bounds.width - 60, y: 0, width: 60, height: view.bounds.height))
        vhsRight.autoresizingMask = [.flexibleHeight, .flexibleLeftMargin]
        view.addSubview(vhsRight)

        let vhsBar = VHSBarView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 3))
        vhsBar.autoresizingMask = [.flexibleWidth]
        view.addSubview(vhsBar)

        let sideLight = SideLightView(frame: view.bounds)
        sideLight.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(sideLight)

        let topLine = UIView(frame: CGRect(x: 0, y: 50, width: view.bounds.width, height: 2))
        topLine.backgroundColor = .white
        topLine.autoresizingMask = [.flexibleWidth]
        view.addSubview(topLine)
        addChromaticBorder(to: topLine)

        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.layer.borderWidth = 3
        containerView.layer.borderColor = UIColor.white.cgColor
        view.addSubview(containerView)

        let headerView = UIView()
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.backgroundColor = UIColor(red: 0.055, green: 0.055, blue: 0.055, alpha: 1)
        containerView.addSubview(headerView)

        let headerLabel = UILabel()
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "CIEMAYDO BROWSER"
        headerLabel.font = UIFont(name: "Menlo-Bold", size: 10)
        headerLabel.textColor = .white
        headerLabel.textAlignment = .center
        headerView.addSubview(headerLabel)

        let lineBelowHeader = UIView()
        lineBelowHeader.translatesAutoresizingMaskIntoConstraints = false
        lineBelowHeader.backgroundColor = .white
        containerView.addSubview(lineBelowHeader)

        urlField = UITextField()
        urlField.translatesAutoresizingMaskIntoConstraints = false
        urlField.borderStyle = .none
        urlField.backgroundColor = .black
        urlField.textColor = .white
        urlField.font = UIFont(name: "Menlo", size: 10)
        urlField.layer.borderWidth = 2
        urlField.layer.borderColor = UIColor.white.cgColor
        urlField.attributedPlaceholder = NSAttributedString(string: "Enter URL...", attributes: [.foregroundColor: UIColor.gray])
        urlField.autocapitalizationType = .none
        urlField.autocorrectionType = .no
        urlField.keyboardAppearance = .dark
        urlField.returnKeyType = .go
        urlField.delegate = self
        urlField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 0))
        urlField.leftViewMode = .always
        containerView.addSubview(urlField)

        let buttonStack = UIStackView()
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 6
        containerView.addSubview(buttonStack)

        backButton = createNavButton(title: "<")
        backButton.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        buttonStack.addArrangedSubview(backButton)

        forwardButton = createNavButton(title: ">")
        forwardButton.addTarget(self, action: #selector(goForward), for: .touchUpInside)
        buttonStack.addArrangedSubview(forwardButton)

        refreshButton = createNavButton(title: "R")
        refreshButton.addTarget(self, action: #selector(refreshPage), for: .touchUpInside)
        buttonStack.addArrangedSubview(refreshButton)

        mediaButton = createNavButton(title: "M")
        mediaButton.addTarget(self, action: #selector(showMediaPicker), for: .touchUpInside)
        buttonStack.addArrangedSubview(mediaButton)

        let homeButton = createNavButton(title: "H")
        homeButton.addTarget(self, action: #selector(goHome), for: .touchUpInside)
        buttonStack.addArrangedSubview(homeButton)

        progressBar = UIProgressView(progressViewStyle: .bar)
        progressBar.translatesAutoresizingMaskIntoConstraints = false
        progressBar.progressTintColor = UIColor(red: 0.3, green: 0.8, blue: 1, alpha: 1)
        progressBar.trackTintColor = UIColor.darkGray
        progressBar.isHidden = true
        containerView.addSubview(progressBar)

        let webConfig = WKWebViewConfiguration()
        if #available(iOS 10.0, *) {
            webConfig.mediaTypesRequiringUserActionForPlayback = []
        }
        webConfig.allowsInlineMediaPlayback = true
        if #available(iOS 12.0, *) {
            // iOS 12+ specific config
        }

        webView = WKWebView(frame: .zero, configuration: webConfig)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1)
        webView.isOpaque = false
        containerView.addSubview(webView)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            containerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            containerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),

            headerView.topAnchor.constraint(equalTo: containerView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 28),

            headerLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            headerLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),

            lineBelowHeader.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            lineBelowHeader.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            lineBelowHeader.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            lineBelowHeader.heightAnchor.constraint(equalToConstant: 2),

            urlField.topAnchor.constraint(equalTo: lineBelowHeader.bottomAnchor, constant: 6),
            urlField.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            urlField.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),
            urlField.heightAnchor.constraint(equalToConstant: 32),

            buttonStack.topAnchor.constraint(equalTo: urlField.bottomAnchor, constant: 6),
            buttonStack.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            buttonStack.heightAnchor.constraint(equalToConstant: 36),
            buttonStack.widthAnchor.constraint(lessThanOrEqualToConstant: 300),

            progressBar.topAnchor.constraint(equalTo: buttonStack.bottomAnchor, constant: 4),
            progressBar.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 6),
            progressBar.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -6),

            webView.topAnchor.constraint(equalTo: progressBar.bottomAnchor, constant: 4),
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        addCornerDecorations(to: containerView)
        addChromaticBorder(to: containerView)
        addStatsLabels()
        addSocialIcons()
        addTimeDisplay()

        observation = webView.observe(\.estimatedProgress, options: [.new]) { [weak self] _, change in
            guard let self = self, let progress = change.newValue else { return }
            self.progressBar.isHidden = progress >= 1.0
            self.progressBar.setProgress(Float(progress), animated: true)
        }

        loadURL(homeURL)
    }

    // MARK: - Navigation

    private func loadURL(_ string: String) {
        var urlString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !urlString.contains(".") && !urlString.hasPrefix("about:") {
            urlString = "https://www.google.com/search?q=" + urlString.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        } else if !urlString.hasPrefix("http://") && !urlString.hasPrefix("https://") && !urlString.hasPrefix("about:") {
            urlString = "https://" + urlString
        }
        guard let url = URL(string: urlString) else { return }
        urlField.text = url.absoluteString
        webView.load(URLRequest(url: url))
    }

    @objc private func goBack() { webView.goBack() }
    @objc private func goForward() { webView.goForward() }
    @objc private func refreshPage() { webView.reload() }
    @objc private func goHome() { loadURL(homeURL) }

    @objc private func showMediaPicker() {
        let ac = UIAlertController(title: "OPEN MEDIA", message: "Enter video URL to play in custom player:", preferredStyle: .alert)
        ac.addTextField { tf in
            tf.placeholder = "https://example.com/video.mp4"
            tf.keyboardAppearance = .dark
        }
        ac.addAction(UIAlertAction(title: "PLAY", style: .default) { [weak self] _ in
            guard let text = ac.textFields?.first?.text, let url = URL(string: text) else { return }
            self?.playVideo(url: url)
        })
        ac.addAction(UIAlertAction(title: "CANCEL", style: .cancel))
        present(ac, animated: true)
    }

    private func playVideo(url: URL) {
        let playerVC = VideoPlayerViewController()
        playerVC.videoURL = url
        present(playerVC, animated: true)
    }

    // MARK: - WKNavigationDelegate

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        progressBar.isHidden = false
        progressBar.setProgress(0.1, animated: false)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        progressBar.setProgress(1.0, animated: true)
        urlField.text = webView.url?.absoluteString ?? ""
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        progressBar.isHidden = true
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        progressBar.isHidden = true
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let ext = url.pathExtension.lowercased()
            if ["mp4", "mov", "m4v", "webm", "avi"].contains(ext) || navigationAction.targetFrame == nil {
                if navigationAction.navigationType == .linkActivated {
                    playVideo(url: url)
                    decisionHandler(.cancel)
                    return
                }
            }
        }
        decisionHandler(.allow)
    }

    // MARK: - UITextFieldDelegate

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        if let text = textField.text, !text.isEmpty {
            loadURL(text)
        }
        return true
    }

    // MARK: - UI Helpers

    private func createNavButton(title: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(title, for: .normal)
        btn.titleLabel?.font = UIFont(name: "Menlo-Bold", size: 12)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1)
        btn.layer.borderWidth = 2
        btn.layer.borderColor = UIColor.white.cgColor
        btn.layer.shadowColor = UIColor.black.cgColor
        btn.layer.shadowOffset = CGSize(width: 3, height: 3)
        btn.layer.shadowOpacity = 0.8
        btn.layer.shadowRadius = 0
        return btn
    }

    private func addCornerDecorations(to view: UIView) {
        let positions: [(CGFloat, CGFloat, CGFloat, CGFloat, UIRectCorner)] = [
            (-1, -1, 8, 8, .topLeft),
            (-1, -1, 8, 8, .topRight),
            (-1, -1, 8, 8, .bottomLeft),
            (-1, -1, 8, 8, .bottomRight)
        ]
        for (x, y, w, h, _) in positions {
            let corner = UIView()
            corner.translatesAutoresizingMaskIntoConstraints = false
            corner.layer.borderWidth = 2
            corner.layer.borderColor = UIColor.white.cgColor
            view.addSubview(corner)
            NSLayoutConstraint.activate([
                corner.widthAnchor.constraint(equalToConstant: w),
                corner.heightAnchor.constraint(equalToConstant: h)
            ])
        }
    }

    private func addChromaticBorder(to view: UIView) {
        let redBorder = UIView(frame: view.bounds)
        redBorder.isUserInteractionEnabled = false
        redBorder.layer.borderWidth = 1
        redBorder.layer.borderColor = UIColor(red: 1, green: 0, blue: 0, alpha: 0.3).cgColor
        redBorder.transform = CGAffineTransform(translationX: -2, y: -1)
        redBorder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(redBorder)

        let cyanBorder = UIView(frame: view.bounds)
        cyanBorder.isUserInteractionEnabled = false
        cyanBorder.layer.borderWidth = 1
        cyanBorder.layer.borderColor = UIColor(red: 0, green: 1, blue: 1, alpha: 0.3).cgColor
        cyanBorder.transform = CGAffineTransform(translationX: 2, y: 1)
        cyanBorder.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(cyanBorder)
    }

    private func addStatsLabels() {
        let statsView = UIView()
        statsView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsView)

        let mediaLabel = UILabel()
        mediaLabel.translatesAutoresizingMaskIntoConstraints = false
        mediaLabel.text = "MEDIA: 0"
        mediaLabel.font = UIFont(name: "Menlo", size: 7)
        mediaLabel.textColor = UIColor(white: 0.5, alpha: 1)
        statsView.addSubview(mediaLabel)

        let modsLabel = UILabel()
        modsLabel.translatesAutoresizingMaskIntoConstraints = false
        modsLabel.text = "MODS: 9"
        modsLabel.font = UIFont(name: "Menlo", size: 7)
        modsLabel.textColor = UIColor(white: 0.5, alpha: 1)
        statsView.addSubview(modsLabel)

        NSLayoutConstraint.activate([
            statsView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            statsView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            mediaLabel.topAnchor.constraint(equalTo: statsView.topAnchor),
            mediaLabel.trailingAnchor.constraint(equalTo: statsView.trailingAnchor),
            modsLabel.topAnchor.constraint(equalTo: mediaLabel.bottomAnchor, constant: 4),
            modsLabel.trailingAnchor.constraint(equalTo: statsView.trailingAnchor),
            modsLabel.bottomAnchor.constraint(equalTo: statsView.bottomAnchor)
        ])
    }

    private func addSocialIcons() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "other social networks"
        titleLabel.font = UIFont(name: "Menlo", size: 6)
        titleLabel.textColor = .white
        container.addSubview(titleLabel)

        let icons = UIStackView()
        icons.translatesAutoresizingMaskIntoConstraints = false
        icons.axis = .horizontal
        icons.spacing = 4
        icons.distribution = .fillEqually
        container.addSubview(icons)

        let iconNames = ["fb", "yt", "tw", "pi", "tg"]
        for name in iconNames {
            let btn = UIButton(type: .system)
            btn.setTitle(["f", "y", "x", "p", "t"][iconNames.firstIndex(of: name)!], for: .normal)
            btn.titleLabel?.font = UIFont(name: "Menlo-Bold", size: 10)
            btn.setTitleColor(.white, for: .normal)
            btn.backgroundColor = UIColor(red: 0.039, green: 0.039, blue: 0.039, alpha: 1)
            btn.layer.borderWidth = 2
            btn.layer.borderColor = UIColor.white.cgColor
            btn.layer.shadowColor = UIColor.black.cgColor
            btn.layer.shadowOffset = CGSize(width: 2, height: 2)
            btn.layer.shadowOpacity = 0.8
            btn.layer.shadowRadius = 0
            btn.widthAnchor.constraint(equalToConstant: 28).isActive = true
            btn.heightAnchor.constraint(equalToConstant: 28).isActive = true
            icons.addArrangedSubview(btn)
        }

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            icons.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            icons.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            icons.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            icons.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func addTimeDisplay() {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(container)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "MY TIME"
        titleLabel.font = UIFont(name: "Menlo", size: 6)
        titleLabel.textColor = UIColor(white: 0.3, alpha: 1)
        titleLabel.textAlignment = .center
        container.addSubview(titleLabel)

        let timeLabel = UILabel()
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.tag = 1001
        timeLabel.font = UIFont(name: "Menlo", size: 9)
        timeLabel.textColor = .white
        timeLabel.textAlignment = .center
        container.addSubview(timeLabel)

        let dateLabel = UILabel()
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        dateLabel.tag = 1002
        dateLabel.font = UIFont(name: "Menlo", size: 8)
        dateLabel.textColor = UIColor(white: 0.5, alpha: 1)
        dateLabel.textAlignment = .center
        container.addSubview(dateLabel)

        NSLayoutConstraint.activate([
            container.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            container.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            timeLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            timeLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dateLabel.topAnchor.constraint(equalTo: timeLabel.bottomAnchor, constant: 2),
            dateLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            dateLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])

        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let now = Date()
            let df = DateFormatter()
            df.dateFormat = "HH:mm:ss"
            timeLabel.text = df.string(from: now)
            df.dateFormat = "dd.MM.yyyy"
            dateLabel.text = df.string(from: now)
        }
    }
}

// MARK: - Background Views

class BackgroundView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isOpaque = false
    }
    required init?(coder: NSCoder) { nil }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.12).cgColor)
        ctx.setLineWidth(0.5)
        let w: CGFloat = 28
        let h: CGFloat = 48.5
        for y in stride(from: -h, to: rect.height + h, by: h * 0.75) {
            let offset = (Int(y / (h * 0.75)) % 2 == 0) ? 0 : w * 0.5
            for x in stride(from: -w + offset, to: rect.width + w, by: w) {
                let path = CGMutablePath()
                path.move(to: CGPoint(x: x + w * 0.5, y: y))
                path.addLine(to: CGPoint(x: x + w, y: y + h * 0.25))
                path.addLine(to: CGPoint(x: x + w, y: y + h * 0.75))
                path.addLine(to: CGPoint(x: x + w * 0.5, y: y + h))
                path.addLine(to: CGPoint(x: x, y: y + h * 0.75))
                path.addLine(to: CGPoint(x: x, y: y + h * 0.25))
                path.closeSubpath()
                ctx.addPath(path)
            }
        }
        ctx.strokePath()
    }
}

class ScanlinesView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame); isOpaque = false; backgroundColor = .clear
    }
    required init?(coder: NSCoder) { nil }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setFillColor(UIColor.black.withAlphaComponent(0.08).cgColor)
        for y in stride(from: 0, to: rect.height, by: 3) {
            ctx.fill(CGRect(x: 0, y: y, width: rect.width, height: 1))
        }
    }
}

class VHSLeftView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame); isOpaque = false; backgroundColor = .clear
    }
    required init?(coder: NSCoder) { nil }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setFillColor(UIColor(red: 1, green: 0, blue: 0, alpha: 0.06).cgColor)
        ctx.fill(rect)
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.04).cgColor)
        for y in stride(from: 0, to: rect.height, by: 4) {
            ctx.fill(CGRect(x: 0, y: y, width: rect.width, height: 1))
        }
    }
}

class VHSRightView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame); isOpaque = false; backgroundColor = .clear
    }
    required init?(coder: NSCoder) { nil }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        ctx.setFillColor(UIColor(red: 0, green: 1, blue: 1, alpha: 0.06).cgColor)
        ctx.fill(rect)
        ctx.setFillColor(UIColor.white.withAlphaComponent(0.04).cgColor)
        for y in stride(from: 0, to: rect.height, by: 4) {
            ctx.fill(CGRect(x: 0, y: y, width: rect.width, height: 1))
        }
    }
}

class VHSBarView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame); isOpaque = false; backgroundColor = .clear
    }
    required init?(coder: NSCoder) { nil }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let colors = [UIColor(red: 1, green: 0, blue: 0, alpha: 0.2),
                       UIColor(white: 1, alpha: 0.1),
                       UIColor(red: 0, green: 1, blue: 1, alpha: 0.2)]
        let locations: [CGFloat] = [0, 0.5, 1]
        let gradient = CGGradient(colorsSpace: nil, colors: colors.map { $0.cgColor } as CFArray, locations: locations)
        ctx.drawLinearGradient(gradient!, start: CGPoint(x: 0, y: 0), end: CGPoint(x: rect.width, y: 0), options: [])
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        UIView.animate(withDuration: 8, delay: 0, options: [.repeat, .curveLinear]) {
            self.transform = CGAffineTransform(translationX: 0, y: UIScreen.main.bounds.height + 10)
        }
    }
}

class SideLightView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame); isOpaque = false; backgroundColor = .clear
    }
    required init?(coder: NSCoder) { nil }

    override func draw(_ rect: CGRect) {
        guard let ctx = UIGraphicsGetCurrentContext() else { return }
        let colors = [UIColor.white.withAlphaComponent(0.03).cgColor,
                       UIColor.clear.cgColor,
                       UIColor.clear.cgColor,
                       UIColor.white.withAlphaComponent(0.03).cgColor]
        let locations: [CGFloat] = [0, 0.2, 0.8, 1]
        let gradient = CGGradient(colorsSpace: nil, colors: colors as CFArray, locations: locations)
        ctx.drawLinearGradient(gradient!, start: CGPoint(x: 0, y: 0), end: CGPoint(x: rect.width, y: 0), options: [])
    }
}
